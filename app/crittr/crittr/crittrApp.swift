import CoreLocation
import SwiftUI
let apiUrl = "https://crittrapi.firedogstuff.com"
// let apiUrl = "http://localhost:3000"
@main
struct crittrApp: App {
    @StateObject var serverManager: ServerManager = ServerManager()
    var body: some Scene {
        WindowGroup {
            ContentView(serverManager: serverManager)
        }
    }
}
class ServerManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published var locPosts: [CLLocation: [PostMutable]] = [:]
    var locPostsUpdated: [CLLocation: Date] = [:]
    @Published var locName:String = ""
    var geocoder = CLGeocoder()
    // curCoords is the current location of the user
    var curLoc:CLLocation = CLLocation()
    // locCoords is the coordinates of the nearest location
    var placeLoc:CLLocation = CLLocation()
    private var lastLocUpdate = Date(timeIntervalSince1970: 0)
    private var locUpdateReq = false
    private var locationManager:CLLocationManager
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
    }
    // Delegate Functions
    func locationManager(_: CLLocationManager, didUpdateLocations: [CLLocation]) {
        if (didUpdateLocations.first != nil) {
            let oldLoc = curLoc
            curLoc = didUpdateLocations.first!
            // If the user has moved less than 50 feet (converted to meters for comparison)
            if (oldLoc.distance(from: curLoc) > (50 * 0.3048)) {
                reqLocUpdate()
            }
        }
    }
    func locationManagerDidChangeAuthorization(_: CLLocationManager) {
        if (locationManager.authorizationStatus == .notDetermined) {
            locationManager.requestWhenInUseAuthorization()
        } else if (locationManager.authorizationStatus == .authorizedWhenInUse){
            locationManager.requestLocation()
            locationManager.startUpdatingLocation()
        }
    }
    func locationManager(_: CLLocationManager, didFailWithError: Error) {
        // Don't care about errors for now, but app crashes without handler (as per Apple specs)
    }
    func reqLocUpdate() {
        if (locUpdateReq) {
            return
        }
        locUpdateReq = true
        let timeSinceLast = Date.now.timeIntervalSince(lastLocUpdate)
        Task {
            if (timeSinceLast < 60) {
                try await Task.sleep(nanoseconds: UInt64(60 * 1_000_000_000))
            }
            lastLocUpdate = Date()
            geocoder.reverseGeocodeLocation(curLoc, completionHandler:gcHandler)
            locUpdateReq = false
        }
    }
    func gcHandler(placemarks: [CLPlacemark]?, _: Error?) {
        if (placemarks == nil || placemarks!.isEmpty  || (placemarks!.first!.subThoroughfare == nil) || (placemarks!.first!.thoroughfare == nil)) {
            placeLoc = CLLocation()
            locName = ""
            return
        }
        locName = "\(placemarks!.first!.subThoroughfare!) \(placemarks!.first!.thoroughfare!)"
        var doUpdate = false;
        // Use location's region coords because using the location's location coords varies
        if (placemarks!.first!.region! is CLCircularRegion) {
            let circRegion:CLCircularRegion = placemarks!.first!.region! as! CLCircularRegion
            let newPlaceLoc = CLLocation(latitude:circRegion.center.latitude, longitude:circRegion.center.longitude)
            doUpdate = (newPlaceLoc != placeLoc)
            placeLoc = newPlaceLoc
        }
        if (doUpdate) {
            Task {
                await updatePosts(location: placeLoc)
            }
        }
    }
    func sendPost(postText:String) {
        let locData = LocData(lat: self.placeLoc.coordinate.latitude, long: self.placeLoc.coordinate.longitude)
        let postData = RawPost(text:postText, location:locData)
        let urlSess:URLSession = URLSession.init(configuration: URLSessionConfiguration.ephemeral)
        var urlRequest = URLRequest(url:URL(string:"\(apiUrl)/newPost")!)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        do {
            urlRequest.httpBody = try! JSONEncoder().encode(postData)
            urlSess.dataTask(with: urlRequest, completionHandler: sendPostCompHandler).resume()
        }
    }
    func sendPostCompHandler(_: Data?, _:  URLResponse?, _: (any Error)?) {
        Task {
            await updatePosts(location: placeLoc)
        }
    }
    func ratePost(postId:String, ratingType:InteractionType) {
        let postData = PostRating(postId:postId, userId:UIDevice.current.identifierForVendor!.uuidString, interactionType: ratingType.rawValue)
        let urlSess:URLSession = URLSession.init(configuration: URLSessionConfiguration.ephemeral)
        var urlRequest = URLRequest(url:URL(string:"\(apiUrl)/ratePost")!)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        do {
            urlRequest.httpBody = try! JSONEncoder().encode(postData)
            urlSess.dataTask(with: urlRequest).resume()
        }
    }
    @MainActor func updatePosts(location:CLLocation) async {
        let urlSess:URLSession = URLSession.init(configuration: URLSessionConfiguration.ephemeral)
        do {
            let url = URL(string:"\(apiUrl)/getPosts?lat=\(location.coordinate.latitude.description.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)&long=\(location.coordinate.longitude.description.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)&user=\(UIDevice.current.identifierForVendor!.uuidString)")!
            let (data, _) = try await urlSess.data(from: url)
            if (data.isEmpty) {
                return
            }
            let postResponse = try? JSONDecoder().decode([Post].self, from: data)
            if (postResponse == nil) {
                return
            }
            var newLocPosts:[PostMutable] = []
            for post in postResponse! {
                newLocPosts.append(PostMutable(post: post))
            }
            locPostsUpdated[location] = Date()
            locPosts[location] = newLocPosts.sorted(by: { $0.date > $1.date })
        } catch {
            // TODO: Add error handling
        }
    }
}
struct LocData:Encodable, Decodable {
    let lat:Double
    let long:Double
}
struct RawPost:Encodable {
    let text:String
    let location:LocData
}
struct Post:Decodable {
    let text:String
    let location:LocData
    let score:Int
    let date:Int
    let id:String
    let userReview:Int
}
class PostMutable:ObservableObject {
    let text:String
    let location:CLLocation
    @Published var score:Int
    let date:Int
    let id:String
    @Published var userReview:Int
    init(post:Post) {
        self.text = post.text
        self.location = CLLocation(latitude:post.location.lat, longitude:post.location.long)
        self.score = post.score
        self.date = post.date
        self.id = post.id
        self.userReview = post.userReview
    }
}
struct PostRating: Encodable {
    let postId:String
    let userId:String
    var interactionType:Int
}
enum InteractionType: Int {
    case minus = -1
    case zero = 0
    case plus = 1
}
extension CLLocationCoordinate2D: Equatable {}
public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return (lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude)
}

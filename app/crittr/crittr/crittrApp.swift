import SwiftUI
import CoreLocation
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
    init() {
    }
}
// This should really be called something besides servermanager because it does location too but we ball i guess.
class ServerManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published var mapLocs:[MapLocation] = []
    @Published var locPosts: [String: [PostMutable]] = [:]
    @Published var location:String = ""
    var locationManager:CLLocationManager
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        Task {
            await updateLocations()
        }
    }
    // Delegate Functions
    func locationManager(_: CLLocationManager, didUpdateLocations: [CLLocation]) {
        setLocationFromCoords(newLocation: didUpdateLocations.last!)
    }
    func locationManagerDidChangeAuthorization(_: CLLocationManager) {
        if (locationManager.authorizationStatus == .notDetermined) {
            locationManager.requestWhenInUseAuthorization()
        } else {
            locationManager.requestLocation()
            locationManager.startUpdatingLocation()
        }
    }
    func locationManager(_: CLLocationManager, didFailWithError: Error) {
        // Don't care about errors for now
    }
    func setLocationFromCoords(newLocation:CLLocation) {
        var lowestDistanceFrom:Double = 10000
        var closestLoc = ""
        for location in mapLocs {
            let distance = newLocation.distance(from: CLLocation(latitude:location.xCoord, longitude:location.yCoord)) * 3.28084
            if ((distance < lowestDistanceFrom) && (distance <= location.radius)) {
                lowestDistanceFrom = distance
                closestLoc = location.name
            }
        }
        self.location = closestLoc
    }
    func sendPost(postText:String) {
        let postData = RawPost(text:postText, location:self.location)
        let urlSess:URLSession = URLSession.init(configuration: URLSessionConfiguration.ephemeral)
        var urlRequest = URLRequest(url:URL(string:"\(apiUrl)/newPost")!)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        do {
            urlRequest.httpBody = try! JSONEncoder().encode(postData)
            urlSess.dataTask(with: urlRequest).resume()
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
    @MainActor func updateLocations() async {
        let urlSess:URLSession = URLSession.init(configuration: URLSessionConfiguration.ephemeral)
        do {
            let url = URL(string:"\(apiUrl)/getLocations")!
            let (data, _) = try await urlSess.data(from: url)
            let locResponse = try! JSONDecoder().decode([Location].self, from: data)
            var newLocData:[MapLocation] = []
            for oldLoc in locResponse {
                newLocData.append(MapLocation(name:oldLoc.locName, radius: oldLoc.radius, xCoord:oldLoc.xCoord, yCoord: oldLoc.yCoord))
            }
            mapLocs = newLocData
            if (locationManager.location != nil) {
                setLocationFromCoords(newLocation: locationManager.location!)
            }
        } catch {
            // TODO: Add error handling
        }
    }
    @MainActor func updatePosts(location:String) async {
        let urlSess:URLSession = URLSession.init(configuration: URLSessionConfiguration.ephemeral)
        do {
            let url = URL(string:"\(apiUrl)/getPosts?location=\(location.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)&user=\(UIDevice.current.identifierForVendor!.uuidString)")!
            let (data, _) = try await urlSess.data(from: url)
            let postResponse = try? JSONDecoder().decode([Post].self, from: data)
            if (postResponse == nil) {
                return
            }
            var newLocPosts:[PostMutable] = []
            for post in postResponse! {
                newLocPosts.append(PostMutable(post: post))
            }
            locPosts[location] = newLocPosts.sorted(by: { $0.date > $1.date })
        } catch {
            // TODO: Add error handling
        }
    }
}
struct RawPost:Encodable {
    let text:String
    let location:String
}
struct Post:Decodable {
    let text:String
    let location:String
    let score:Int
    let date:Int
    let id:String
    let userReview:Int
}
class PostMutable:ObservableObject {
    let text:String
    let location:String
    @Published var score:Int
    let date:Int
    let id:String
    @Published var userReview:Int
    init(post:Post) {
        self.text = post.text
        self.location = post.location
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
struct MapLocation: Identifiable {
    let id = UUID()
    let name: String
    let xCoord: Double
    let yCoord: Double
    let radius: Double
    let coordinate: CLLocationCoordinate2D
    var show = true
    init(name: String, radius: Double, xCoord: Double, yCoord: Double) {
        self.name = name
        self.xCoord = xCoord
        self.yCoord = yCoord
        self.radius = radius
        coordinate = CLLocationCoordinate2D(latitude:xCoord, longitude: yCoord)
    }
}
struct Location: Codable {
    var locName: String
    var radius: Double
    var xCoord: Double
    var yCoord: Double
}
enum InteractionType: Int {
    case minus = -1
    case zero = 0
    case plus = 1
}

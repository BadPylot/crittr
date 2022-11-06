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
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
    }
}
class ServerManager: ObservableObject {
    @Published var mapLocs:[MapLocation] = []
    @Published var locPosts: [String: [Post]] = [:]
    init() {
        Task {
            await updateLocations()
        }
    }
    func getLocation() -> String {
        let locationManager = CLLocationManager()
        var lowestDistanceFrom:Double = 1000
        var closestLoc = ""
        if (locationManager.location == nil) {
            return ""
        }
        for location in mapLocs {
            let distance = locationManager.location!.distance(from: CLLocation(latitude:location.xCoord, longitude:location.yCoord)) * 3.28084
            if ((distance < lowestDistanceFrom) && (distance <= location.radius)) {
                lowestDistanceFrom = distance
                closestLoc = location.name
            }
        }
        return closestLoc
    }
    func sendPost(postText:String) {
        let postData = RawPost(text:postText, location:getLocation())
        let urlSess:URLSession = URLSession.init(configuration: URLSessionConfiguration.ephemeral)
        var urlRequest = URLRequest(url:URL(string:"\(apiUrl)/newPost")!)
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
        } catch {
            // TODO: Add error handling
        }
    }
    @MainActor func updatePosts(location:String) async {
        let urlSess:URLSession = URLSession.init(configuration: URLSessionConfiguration.ephemeral)
        do {
            let url = URL(string:"\(apiUrl)/getPosts?location=\(location.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)")!
            let (data, _) = try await urlSess.data(from: url)
            let postResponse = try! JSONDecoder().decode([Post].self, from: data)
            print(postResponse)
            locPosts[location] = postResponse
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

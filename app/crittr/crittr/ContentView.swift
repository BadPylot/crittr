import SwiftUI
import MapKit
struct ContentView: View {
    @ObservedObject var serverManager: ServerManager
    init(serverManager: ServerManager) {
        self.serverManager = serverManager
    }
    var body: some View {
        TabView {
            VStack {
                HeaderView {
                    VStack {
                        Text("Your current circle:")
                        if (serverManager.placeLoc.coordinate == CLLocation().coordinate) {
                            Text("Nowhere!")
                                .font(.system(size:24))
                                .bold()
                        } else {
                            Text(serverManager.locName)
                                .font(.system(size:24))
                                .bold()
                            Text("Your posts are visible to others at this location")
                                .multilineTextAlignment(.center)
                                .font(.system(size:9))
                        }
                    }
                    .frame(height:100)
                }
                CurrentLocationView(serverManager: serverManager)
            }
            .tabItem {
                Label("Here", systemImage: "mappin.and.ellipse")
            }
            VStack {
                HeaderView {
                    Text("Tap on a location to see its posts.")
                }
                ExploreView(serverManager: serverManager)
            }
            .tabItem {
                Label("Explore", systemImage:"map")
            }
        }
    }
    struct ContentView_Previews: PreviewProvider {
        static var serverManager = ServerManager()
        static var previews: some View {
            ContentView(serverManager: serverManager)
        }
    }
}
// StackExchange code to allow only certain corners to be rounded
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}


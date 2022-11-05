import SwiftUI
import MapKit
struct ContentView: View {
    @State private var selectedLoc = ""
    @State var locSheet = false
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35.9070, longitude: -79.0479), latitudinalMeters: 2000, longitudinalMeters: 1500)
    @State private var newPost: String = ""
    @FocusState private var newPostActive: Bool
    @ObservedObject var serverManager: ServerManager
    init(serverManager: ServerManager) {
        self.serverManager = serverManager
    }
    var body: some View {
        ZStack {
            GeometryReader { (geometry) in
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: serverManager.mapLocs) { mapLoc in
                    MapAnnotation(coordinate: mapLoc.coordinate) {
                        let footSize: Double = (geometry.size.height/(region.span.latitudeDelta * 288200))
                        let fillColor:Color = (selectedLoc != mapLoc.name) ? Color(UIColor(red: 0, green: 0, blue: 1, alpha: 0.2)) : Color(UIColor(red: 0, green: 0, blue: 1, alpha: 0.4))
                        ZStack {
                            Text(mapLoc.name)
                                .frame(width:(footSize * mapLoc.radius))
                                .scaledToFill()
                                .minimumScaleFactor(0.01)
                                .lineLimit(1)
                                .allowsHitTesting(false)
                            Circle()
                                .fill(fillColor)
                                .frame(width:(footSize * mapLoc.radius))
                                .onTapGesture {
                                    selectedLoc = mapLoc.name
                                    locSheet = true
                                }
                        }
                    }
                }
                .onTapGesture{
                    newPostActive = false
                }
            }
            VStack{
                Spacer()
                ZStack {
                    Rectangle().fill(.background)
                    VStack {
                        TextField("New Post", text:$newPost, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.center)
                            .focused($newPostActive)
                        Text(serverManager.getLocation())
                        Text("Send Post")
                            .fontWeight(.semibold)
                            .frame(maxHeight:10)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(40)
                            .onTapGesture {
                                serverManager.sendPost(postText: newPost)
                                newPostActive = false
                                newPost = ""
                            }
                    }
                }.frame(height:150)
            }
        }
        .edgesIgnoringSafeArea([.top])
        .sheet(isPresented: $locSheet, onDismiss: { selectedLoc = "" } ) {
            PostsViewSheet(selectedLoc: selectedLoc, serverManager: serverManager)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var serverManager = ServerManager()
    static var previews: some View {
        ContentView(serverManager: serverManager)
    }
}

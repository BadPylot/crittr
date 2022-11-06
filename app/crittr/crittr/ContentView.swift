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
        VStack {
            ZStack{
                Rectangle().fill(.background).frame(height:100)
                HStack{
                    VStack(alignment:.center, spacing:0){
                        Image(uiImage: UIImage(named: "Logo")!)
                            .resizable()
                            .frame(width:100, height:100)
                            .aspectRatio(contentMode: .fit)
                        HStack {
                            Text("crittr")
                            Text(".")
                                .padding([.leading], -12)
                        }
                        .font(.custom("AppleGothic", size: 33))
                        .padding([.top], -10)
                        .bold()
                    }
                    .padding(.leading)
                    Spacer()
                    VStack {
                        Text("Your current location:")
                        if (serverManager.location == "") {
                            Text("Nowhere!")
                                .font(.system(size:24))
                                .bold()
                            Text("Move to a building to start posting")
                                .font(.system(size:9))
                        } else {
                            Text(serverManager.location)
                                .font(.system(size:24))
                                .bold()
                        }
                    }.frame(height:100)
                    Spacer()
                }
            }
            ZStack {
                GeometryReader { (geometry) in
                    let footSize: Double = (geometry.size.height/(region.span.latitudeDelta * 288200))
                    Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: serverManager.mapLocs) { mapLoc in
                        MapAnnotation(coordinate: mapLoc.coordinate) {
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
                                    .overlay(Circle()
                                        .stroke(.blue.opacity(0.5), lineWidth: 1)
                                    )
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
                        Rectangle()
                            .fill(.background)
                            .cornerRadius(20, corners: [.topLeft, .topRight])
                        VStack {
                            TextField("Tap here to start a new post", text:$newPost, axis: .vertical)
                                .lineLimit(4...4)
                                .cornerRadius(10.0)
                                .focused($newPostActive)
                                .padding([.top], 16)
                                .padding([.leading, .trailing, .bottom], 10)
                                .textFieldStyle(.roundedBorder)
                            Text("Send Post")
                                .fontWeight(.semibold)
                                .frame(maxHeight:10)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(40)
                                .onTapGesture {
                                    if ((serverManager.location == "") || newPost == "") {
                                        return
                                    }
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
}
struct ContentView_Previews: PreviewProvider {
    static var serverManager = ServerManager()
    static var previews: some View {
        ContentView(serverManager: serverManager)
    }
}
// StackExchange code to allow only certain corners to be rounded
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
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


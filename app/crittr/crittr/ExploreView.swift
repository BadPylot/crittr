import MapKit
import SwiftUI
struct ExploreView: View {
    @ObservedObject var serverManager:ServerManager
    @State var mapCenter:CLLocationCoordinate2D
    @State var displayLoc:HelperCoord? = nil
    @State var displayedLoc:CLLocation = CLLocation()
    @State var locName:String = ""
    init(serverManager:ServerManager) {
        self.serverManager = serverManager
        _mapCenter = State(initialValue:serverManager.curLoc.coordinate)
    }
    var body: some View {
        MapView(centerCoordinate: $mapCenter, displayLoc: $displayLoc, displayedLoc: $displayedLoc, locName: $locName, serverManager: serverManager)
            .ignoresSafeArea(edges:.top)
            .sheet(item:$displayLoc) { newLoc in
                VStack{
                    VStack {
                        Spacer()
                        Text(locName)
                        Spacer()
                    }
                    .frame(height:50)
                    PostListView(serverManager:serverManager, targetLoc: $displayedLoc)
                }
                .background(Color(UIColor.tertiarySystemFill))
            }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var serverManager = ServerManager()
    static var previews: some View {
        ExploreView(serverManager: serverManager)
    }
}

struct MapView: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D
    @Binding var displayLoc:HelperCoord?
    @Binding var displayedLoc:CLLocation
    @Binding var locName:String
    var serverManager:ServerManager
    let mapView = MKMapView()
    func makeUIView(context: Context) -> MKMapView {
        mapView.region = MKCoordinateRegion(center: serverManager.curLoc.coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        return mapView
    }
    func updateUIView(_ view: MKMapView, context: Context) {
    }
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: MapView
        var gRecognizer = UITapGestureRecognizer()
        init(_ parent: MapView) {
            self.parent = parent
            super.init()
            self.gRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
            self.gRecognizer.delegate = self
            self.parent.mapView.addGestureRecognizer(gRecognizer)
        }
        @objc func tapHandler(_ gesture: UITapGestureRecognizer) {
            // position on the screen, CGPoint
            let location = gRecognizer.location(in: self.parent.mapView)
            // position on the map, CLLocationCoordinate2D
            let coordinate = self.parent.mapView.convert(location, toCoordinateFrom: self.parent.mapView)
            parent.serverManager.geocoder.reverseGeocodeLocation(CLLocation(latitude:coordinate.latitude, longitude: coordinate.longitude), completionHandler:gcHandler)
        }
        func gcHandler(placemarks: [CLPlacemark]?, _: Error?) {
            if (!(placemarks == nil || placemarks!.isEmpty  || (placemarks!.first!.subThoroughfare == nil) || (placemarks!.first!.thoroughfare == nil))) {
                parent.locName = "\(placemarks!.first!.subThoroughfare!) \(placemarks!.first!.thoroughfare!)"
                if (placemarks!.first!.region! is CLCircularRegion) {
                    let circRegion:CLCircularRegion = placemarks!.first!.region! as! CLCircularRegion
                    let newPlaceLoc = CLLocation(latitude:circRegion.center.latitude, longitude:circRegion.center.longitude)
                    parent.displayedLoc = newPlaceLoc
                    Task {
                        await parent.serverManager.updatePosts(location: parent.displayedLoc)
                    }
                    parent.displayLoc = HelperCoord(lat: newPlaceLoc.coordinate.latitude, long: newPlaceLoc.coordinate.longitude)
                }
            }
        }
    }
}
struct HelperCoord:Identifiable {
    var id = UUID()
    var lat: Double
    var long: Double
    init(lat: Double, long: Double) {
        self.lat = lat
        self.long = long
    }
}

import SwiftUI
import MapKit
struct CurrentLocationView: View {
    @State private var newPost: String = ""
    @FocusState private var newPostActive: Bool
    @ObservedObject var serverManager: ServerManager
    init(serverManager: ServerManager) {
        self.serverManager = serverManager
    }
    var body: some View {
        VStack {
            Group {
                PostListView(serverManager: serverManager, targetLoc:$serverManager.placeLoc)
                Spacer()
            }
            .background(Color(UIColor.quaternarySystemFill))
            ZStack {
                Rectangle()
                    .fill(.background)
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                VStack {
                    TextField((serverManager.placeLoc.coordinate != CLLocation().coordinate) ? "Tap here to start a new post" : "Move to a building to start posting", text:$newPost, axis: .vertical)
                        .lineLimit(4...4)
                        .focused($newPostActive)
                        .padding([.top], 16)
                        .padding([.leading, .trailing, .bottom], 10)
                        .disabled(serverManager.locName == "")
                    Text("Send Post")
                        .fontWeight(.semibold)
                        .frame(maxHeight:10)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue.opacity((serverManager.locName == "") ? 0.6 : 1 ))
                        .cornerRadius(40)
                        .onTapGesture {
                            if ((serverManager.locName == "") || newPost == "") {
                                return
                            }
                            serverManager.sendPost(postText: newPost)
                            newPostActive = false
                            newPost = ""
                        }
                }
            }
            .frame(height:150)
        }
        .onTapGesture {
            newPostActive = false
        }
    }
    struct ContentView_Previews: PreviewProvider {
        static var serverManager = ServerManager()
        static var previews: some View {
            CurrentLocationView(serverManager: serverManager)
        }
    }
}

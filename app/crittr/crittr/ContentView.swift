import SwiftUI
import MapKit
struct ContentView: View {
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
                        Text("Your current circle:")
                        if (serverManager.locName == "") {
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
                    }.frame(height:100)
                    Spacer()
                }
            }
            Group {
                PostsViewSheet(serverManager: serverManager)
                Spacer()
            }
            .background(Color(UIColor.quaternarySystemFill))
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
            }.frame(height:150)
        }
        .onTapGesture {
            newPostActive = false
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


import SwiftUI
import MapKit
struct HeaderView<Content: View>: View {
    @State var showAlert:Bool = false
    @ViewBuilder var content: Content
    var body: some View {
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
                VStack{
                    content
                }.frame(height:100)
                Spacer()
                VStack{
                    Image(systemName:"info.circle")
                        .padding([.top, .trailing], 8.0)
                    Spacer()
                }
                .frame(height:100)
                .onTapGesture {
                    showAlert = true
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Info"), message: Text("FriendTracker v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))\nDesigned by Ryder Klein\nNeed to get in contact? Email me at Ryder679@live.com"), dismissButton: .default(Text("Dismiss")))
                }
            }
        }
    }
}

import Foundation
import SwiftUI
struct PostsViewSheet: View {
    var selectedLoc: String
    @ObservedObject var serverManager: ServerManager
    var body: some View {
        VStack {
            Text(selectedLoc)
                .padding(.top, 16.0)
                .font(.title)
            if (serverManager.locPosts[selectedLoc] == nil) {
                HStack{
                    Spacer()
                    Text("Loading...")
                    Spacer()
                }
            } else {
                let timeSortedPosts = serverManager.locPosts[selectedLoc]!.sorted(by: { $0.date > $1.date })
                List {
                    ForEach(timeSortedPosts, id: \.id) { post in
                        PostView(displayPost:post)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await serverManager.updatePosts(location:selectedLoc)
            }
        }
    }
}
struct PostView: View {
    var displayPost:Post
    let formatter = RelativeDateTimeFormatter()
    var body: some View {
        HStack {
            VStack(alignment:.leading) {
                Text(displayPost.text)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.5)
                Spacer()
                Text(formatter.localizedString(for: Date.init(timeIntervalSince1970: TimeInterval(displayPost.date / 1000)), relativeTo: Date()))
                    .font(.system(size: 12))
            }
            Spacer()
            VStack {
                Spacer()
                
                Spacer()
            }
        }
        .frame(height:75)
    }
}
enum InteractionTypes {
    case none
    case plus
    case minus
}

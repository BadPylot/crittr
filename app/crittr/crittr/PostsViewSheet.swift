import Foundation
import SwiftUI
struct PostsViewSheet: View {
    @ObservedObject var serverManager: ServerManager
    var body: some View {
        VStack {
            if (serverManager.locPosts[serverManager.locCoords] == nil) {
                HStack{
                    Spacer()
                    Text("Loading...")
                    Spacer()
                }
                Spacer()
            } else {
                List {
                    if (serverManager.locPosts[serverManager.locCoords]!.isEmpty) {
                        Text("No posts here just yet.")
                    }
                    ForEach(serverManager.locPosts[serverManager.locCoords]!, id: \.id) { post in
                        PostView(post:post, serverManager: serverManager)
                    }
                }
                .refreshable {
                    await serverManager.updatePosts(location: serverManager.locCoords)
                }
            }
        }
    }
}
struct PostView: View {
    @ObservedObject var post:PostMutable
    var serverManager:ServerManager
    let formatter = RelativeDateTimeFormatter()
    init(post: PostMutable, serverManager: ServerManager) {
        self.post = post
        self.serverManager = serverManager
    }
    var body: some View {
        HStack {
            VStack(alignment:.leading) {
                Text(post.text)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.5)
                Spacer()
                Text(formatter.localizedString(for: Date.init(timeIntervalSince1970: TimeInterval(post.date / 1000)), relativeTo: Date()))
                    .font(.system(size: 12))
            }
            Spacer()
            VStack {
                Spacer()
                Group {
                    if (post.userReview != InteractionType.plus.rawValue) {
                        if (serverManager.locCoords.coordinate == post.location.coordinate) {
                            Image(systemName:"pawprint")
                        } else {
                            Image(systemName:"pawprint.fill")
                                .foregroundColor(.gray)
                        }
                    } else {
                        Image(systemName:"pawprint.fill")
                            .foregroundColor(.orange)
                    }
                }
                .onTapGesture {
                    if (!(serverManager.locCoords.coordinate == post.location.coordinate))
                    {
                        return
                    }
                    post.score -= post.userReview
                    if (post.userReview != InteractionType.plus.rawValue) {
                        post.userReview = InteractionType.plus.rawValue
                    } else {
                        post.userReview = InteractionType.zero.rawValue
                    }
                    post.score += post.userReview
                    serverManager.ratePost(postId:post.id, ratingType: InteractionType(rawValue: post.userReview)!)
                    UISelectionFeedbackGenerator().selectionChanged()
                }
                Text(post.score.description)
                Group {
                    if (post.userReview != InteractionType.minus.rawValue) {
                        if (serverManager.locCoords.coordinate == post.location.coordinate) {
                            Image(systemName:"pawprint")
                        } else {
                            Image(systemName:"pawprint.fill")
                                .foregroundColor(.gray)
                        }
                    } else {
                        Image(systemName:"pawprint.fill")
                            .foregroundColor(.blue)
                    }
                }
                .onTapGesture {
                    if (!(serverManager.locCoords.coordinate == post.location.coordinate))
                    {
                        return
                    }
                    post.score -= post.userReview
                    if (post.userReview != InteractionType.minus.rawValue) {
                        post.userReview = InteractionType.minus.rawValue
                    } else {
                        post.userReview = InteractionType.zero.rawValue
                    }
                    post.score += post.userReview
                    serverManager.ratePost(postId:post.id, ratingType: InteractionType(rawValue: post.userReview)!)
                    UISelectionFeedbackGenerator().selectionChanged()
                }
                .rotationEffect(.degrees(180))
                Spacer()
            }
        }
        .frame(height:60)
    }
}

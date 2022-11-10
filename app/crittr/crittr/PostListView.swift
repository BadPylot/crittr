import CoreLocation
import Foundation
import SwiftUI
struct PostListView: View {
    @ObservedObject var serverManager: ServerManager
    @Binding var targetLoc:CLLocation
    var body: some View {
        VStack {
            List {
                if (targetLoc.coordinate == CLLocation().coordinate) {
                    Text("Move to a building to view posts.")
                } else if (serverManager.locPosts[targetLoc] == nil) {
                    Text("Loading...")
                } else if (serverManager.locPosts[targetLoc]!.isEmpty) {
                    Text("No posts here just yet.")
                } else {
                    ForEach(serverManager.locPosts[targetLoc]!, id: \.id) { post in
                        PostView(post:post, targetLoc:targetLoc, serverManager: serverManager)
                    }
                }
            }
            .refreshable {
                if (!(targetLoc.coordinate == CLLocation().coordinate)) {
                    await serverManager.updatePosts(location: targetLoc)
                }
            }
            .scrollContentBackground(.hidden)
        }
    }
}
struct PostView: View {
    @ObservedObject var post:PostMutable
    let targetLoc:CLLocation
    @ObservedObject var serverManager:ServerManager
    let formatter = RelativeDateTimeFormatter()
    init(post: PostMutable, targetLoc:CLLocation, serverManager: ServerManager) {
        self.post = post
        self.targetLoc = targetLoc
        self.serverManager = serverManager
    }
    var body: some View {
        HStack {
            VStack(alignment:.leading) {
                Text(post.text)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.5)
                Spacer()
                Text(formatter.localizedString(for: Date.init(timeIntervalSince1970: TimeInterval(post.date / 1000)), relativeTo: (serverManager.locPostsUpdated[targetLoc] ?? Date.now)))
                    .font(.system(size: 12))
            }
            Spacer()
            VStack {
                Spacer()
                Group {
                    if (post.userReview != InteractionType.plus.rawValue) {
                        if (serverManager.placeLoc.coordinate == post.location.coordinate) {
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
                    if (!(serverManager.placeLoc.coordinate == post.location.coordinate))
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
                        if (serverManager.placeLoc.coordinate == post.location.coordinate) {
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
                    if (!(serverManager.placeLoc.coordinate == post.location.coordinate))
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

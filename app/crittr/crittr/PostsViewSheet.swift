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
            if (serverManager.location != selectedLoc) {
                Text("This building is locked")
                Text("Move closer to interact")
                    .font(.system(size:12))
            }
            Spacer()
            if (serverManager.locPosts[selectedLoc] == nil) {
                HStack{
                    Spacer()
                    Text("Loading...")
                    Spacer()
                }
                Spacer()
            } else {
                if (serverManager.locPosts[selectedLoc]!.isEmpty) {
                    Text("No posts here just yet")
                    Spacer()
                } else {
                    List {
                        ForEach(serverManager.locPosts[selectedLoc]!, id: \.id) { post in
                            PostView(post:post, serverManager: serverManager)
                        }
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
                        if (!(serverManager.location != post.location)) {
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
                    if (serverManager.location != post.location)
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
                        if (!(serverManager.location != post.location)) {
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
                    if (serverManager.location != post.location)
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
                //                Image(systemName:"pawprint")
                //                    .rotationEffect(.degrees(180))
                Spacer()
            }
        }
        .frame(height:60)
    }
}

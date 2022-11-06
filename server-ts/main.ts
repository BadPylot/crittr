import express from "express";
import fs from "fs";
import { Schema, model, connect } from "mongoose";
interface Config {
    port:number,
    dbUri:string
}
interface Location {
locName:string,
radius:number,
xCoord:number,
yCoord:number
}
interface RawPost {
    text:string,
    location:string
}
interface StoragePost extends RawPost {
    // Unix Timestamp of Post
    date:number,
    ratings:[PostRatingStorage]
}
interface RemotePost extends RawPost {
    id:string,
    date:number,
    score:number,
    userReview:InteractionType
}
interface PostRatingStorage {
userId:string
interactionType:InteractionType
}
interface PostRating extends PostRatingStorage {
    postId:string
}
enum InteractionType {
    "minus" = -1,
    "zero" = 0,
    "plus" = 1
}
const PostRatingStorageSchema = new Schema<PostRatingStorage>({
    userId: String,
    interactionType: Number,
});
const postSchema = new Schema<StoragePost>({
    text: { type: String, required: true },
    location: { type: String, required: true },
    date: {type: Number, required: true},
    ratings: {type: [PostRatingStorageSchema], required: true},
});
const Post = model<StoragePost>("Post", postSchema);

const app = express();
app.use(express.json());
let locationsData:[Location] = JSON.parse(fs.readFileSync("./config/locations.json", {"encoding":"utf-8"}));
let config:Config = JSON.parse(fs.readFileSync("./config/config.json", {"encoding":"utf-8"}));
app.get("/getLocations", (req, res) => {
    res.json(locationsData);
});
app.get("/getPosts", async (req, res) => {
    const location:string = req.query.location as string;
    const user:string = req.query.user as string;
    if (!location || !locationsData.find((e) => e.locName == location)) return res.sendStatus(400);
    if (!user) return res.send(401);
    const relevPosts = await Post.find({ location: location });
    const returnPosts:Array<RemotePost> = [];
    for (const post of relevPosts) {
        let userReview:InteractionType = InteractionType.zero;
        let postRating = 0;
        for (const rating of post.ratings) {
            postRating += rating.interactionType;
            if (rating.userId == user) userReview = rating.interactionType;
        }
        const cleanPost:RemotePost = {
            text: post.text,
            score: postRating,
            location: post.location,
            date: post.date,
            id: post._id.toString(),
            userReview: userReview,
        };
        returnPosts.push(cleanPost);
    }
    res.json(returnPosts);
});
app.post("/newPost", async (req, res) => {
    const postData = req.body as RawPost;
    if (typeof postData.text != "string") return res.sendStatus(400);
    await (new Post({
        text: postData.text || "",
        score: 0,
        location: postData.location || "",
        date: (new Date()).getTime(),
    }).save());
    res.sendStatus(200);
});
app.post("/ratePost", async (req, res) => {
    const postData = req.body as PostRating;
    const postToRate = await Post.findOne({ _id: postData.postId });
    if (!postToRate) return res.sendStatus(200);
    const oldRatingIndex = postToRate.ratings.findIndex((e) => e.userId === postData.userId);
    if (oldRatingIndex > -1) {
        postToRate.ratings[oldRatingIndex].interactionType = postData.interactionType;
    } else {
        postToRate.ratings.push({
            userId: postData.userId,
            interactionType: postData.interactionType,
        });
    }
    await postToRate.save();
    res.sendStatus(200);
});
fs.watch("./config/locations.json", async () => {
    const locationsText = await fs.promises.readFile("./config/locations.json", {"encoding":"utf-8"});
    try {
        locationsData = JSON.parse(locationsText);
    } catch {
        // Who cares?
    }
});
fs.watch("./config/config.json", async () => {
    const configText = await fs.promises.readFile("./config/config.json", {"encoding":"utf-8"});
    try {
        config = JSON.parse(configText);
    } catch {
        // Who cares?
    }
});
async function main() {
    await connect(config.dbUri);
    app.listen(config.port, () => {
        console.log(`Example app listening on port ${config.port}`);
    });

}
main();
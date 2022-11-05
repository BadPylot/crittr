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
interface Post extends RawPost {
    score:number,
    // Unix Timestamp of Post
    date:number
}
const postSchema = new Schema<Post>({
    text: { type: String, required: true },
    score: { type: Number, required: true },
    location: { type: String, required: true },
    date: {type: Number, required: true},
});
const Post = model<Post>("Post", postSchema);

const app = express();
app.use(express.json());
let locationsData:[Location] = JSON.parse(fs.readFileSync("./config/locations.json", {"encoding":"utf-8"}));
let config:Config = JSON.parse(fs.readFileSync("./config/config.json", {"encoding":"utf-8"}));
app.get("/getLocations", (req, res) => {
    res.json(locationsData);
});
app.get("/getPosts", async (req, res) => {
    const location:string = req.query.location as string;
    if (!location || !locationsData.find((e) => e.locName == location)) return;
    const relevPosts = await Post.find({ location: location });
    const returnPosts:Array<Post> = [];
    for (const post of relevPosts) {
        const cleanPost = {
            text: post.text,
            score: post.score,
            location: post.location,
            date: post.date,
            id: post._id,
        };
        returnPosts.push(cleanPost);
    }
    res.json(returnPosts);
});
app.post("/newPost", async (req, res) => {
    const postData = req.body as RawPost;
    await (new Post({
        text: postData.text || "",
        score: 0,
        location: postData.location || "",
        date: (new Date()).getTime(),
    }).save());
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
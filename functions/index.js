const functions = require('firebase-functions');
const admin = require('firebase-admin')
admin.initializeApp();
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });


//to get the posts on timeline when user follow some other person
exports.onCreateFollower = functions.firestore
.document("/followers/{userId}/userFollowers/{followerId}")
.onCreate(async (snapshot, context) => {
console.log("Follower created", snapshot.data());
    const userId = context.params.userId;
    const followerId = context.params.followerId;

// Get followed users posts
const followedUserPostsRef = admin.firestore().collection('posts')
.doc(userId)
.collection('userPosts');


// get the following user's timeline
const timelinePostsRef = admin
.firestore()
.collection('timeline')
.doc(followerId)
.collection('timelinePosts');

// get the followed user posts

const querySnapshot = await followedUserPostsRef.get();

// add each user post to following user's timeline
querySnapshot.forEach(doc => {

if(doc.exists){
const postId = doc.id;
const postData = doc.data();
    timelinePostsRef.doc(postId).set(postData);
    }
})

});

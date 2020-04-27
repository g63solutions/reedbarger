const functions = require('firebase-functions');

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

//This Is The Trigger
exports.onCreateFollower = functions.firestore
    .document('/followers/{userId}/userFollowers/{followerId}')
    .onCreate((snapshot, context) => {
//After onCreate you get the userId & followerId
        const userId = context.params.userId;
        const followerId = context.params.followerId;

//admin.firestore() is the same as Firestore.instance
// 1) Create Followed Users Posts
        const followedUserPostsRef = admin
            .firestore().collection('posts')
            .collection('posts')
            .doc(userId)
            .collection('userPosts');

// 2) Create  Following Users Timeline Ref
        const timelinePostsRef = admin
            .firestore()
            .collection('timeline')
            .doc(followerId)
            .collection('timelinePosts');
})
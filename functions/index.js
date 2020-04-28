const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

//This Is The Trigger
exports.onCreateFollower = functions.firestore
    .document('/followers/{userId}/userFollowers/{followerId}')
    .onCreate(async (snapshot, context) => {
//After onCreate get the userId & followerId from context.params
        console.log('Follower Created', snapshot.id);
        const userId = context.params.userId;
        const followerId = context.params.followerId;
        console.log('userId', userId);
        console.log('followerId', followerId);

//admin.firestore() is the same as Firestore.instance
// 1) Create Followed Users Posts Ref
        const followedUserPostsRef = admin
        .firestore()
        .collection('posts')
        .doc(userId)
        .collection('userPosts');


// 2) Create  Following Users Timeline Ref
        const timelinePostsRef = admin
        .firestore()
        .collection('timeline')
        .doc(followerId)
        .collection('timelinePosts');


// 3) Get Followed Users Posts
        const querySnapshot = await followedUserPostsRef.get();
        console.log('QuerySnapShot Size:', querySnapshot.size);

// 4) Add Each USer Post To Following User's Timeline
querySnapshot.forEach(doc => {
    if (doc.exists) {
        const postId = doc.id;
        console.log('postId', postId);
        const postData = doc.data();
        console.log('postData', postData);
        timelinePostsRef.doc(postId).set(postData);
    }
})


});
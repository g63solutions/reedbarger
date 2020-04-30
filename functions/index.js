//Stuff You Need ForTHe App To Run
//For this sample, your project must import the Cloud
//Functions and Admin SDK modules using Node require statements.
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

/*Using our new on create follower firebase function using
the on create fire store cloud trigger we have the ability
to listen for when the new followers created when one user
follows another. We get all of that followed users posts
and added to the following user's timeline on this timeline
collection.*/


//This Is The Trigger
exports.onCreateFollower = functions.firestore
//If you want to attach a trigger to a group of documents,
//such as any document in a certain collection, then
//use a {wildcard} in place of the document ID:
/*Note: Your trigger must always point to a document,
even if you're using a wildcard. For example,
users/{userId}/{messageCollectionId} is not valid
because {messageCollectionId} is a collection.
However, users/{userId}/{messageCollectionId}/{messageId}
is valid because {messageId} will always point to a document.*/
    .document('/followers/{userId}/userFollowers/{followerId}')
/*Snapshot is the OUTPUT, Context is the INPUT*/
    .onCreate(async (snapshot, context) => {
//Person Being Followed Supa Dupa Star
        const userId = context.params.userId;
///Person Following Stalker
        const followerId = context.params.followerId;

        console.log('userId', userId);
        console.log('followerId', followerId);
        console.log('Follower Created', snapshot.id);

//admin.firestore() is the same as Firestore.instance
// 1) Create Followed Users Posts Ref
//Supa Stars Post
        const followedUserPostsRef = admin
        .firestore()
        .collection('posts')
        .doc(userId)
        .collection('userPosts');

// 2) Create  Following Users Timeline Ref
//Stalkers Timeline
        const timelinePostsRef = admin
        .firestore()
        .collection('timeline')
        .doc(followerId)
        .collection('timelinePosts');


// 3) Get Followed/Stars Users Posts
        const querySnapshot = await followedUserPostsRef.get();
        console.log('QuerySnapShot Size:', querySnapshot.size);

// 4) Add Each USer Post To Following/Stalker User's Timeline
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


/*We want to have a fire store a fire base function called on delete follower.

  So when a user UN follows another user we want to remove all of that user's posts that were added to

  their timeline from the timeline so say our current user unfollow is the user Abe we want to go to the

  current users timeline a timeline posts and find every post where the owner I.D. is equal to the I.D.

  of the user that were that we UN followed.*/

exports.onDeleteFollower = functions.firestore
    .document('/followers/{userId}/userFollowers/{followerId}')
    .onDelete(async(snapshot, context) =>{
        console.log('Follower Deleted', snapshot.id);

        const userId = context.params.userId;
        const followerId = context.params.followerId;

        console.log('Deleted User Id ', userId);
        console.log('Deleted Follower Id ', followerId);
        console.log('Follower Deleted ', snapshot.id);

        const timelinePostsRef = admin
            .firestore()
            .collection('timeline')
            .doc(followerId)
            .collection('timelinePosts')
            .where('ownerId', '==', userId);

        const querySnapshot = await timelinePostsRef.get();
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                doc.ref.delete();
            }
        });
    });


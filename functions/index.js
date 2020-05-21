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
/*Snapshot is the OUTPUT, Context is the INPUT
snapshot.data is all the data/fields */
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
    .onDelete(async (snapshot, context) =>{
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
            .where('ownerid', '==', userId);

        const querySnapshot = await timelinePostsRef.get();
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                doc.ref.delete();
            }
        });
    });

///POSTS STUFF
//When A Post Is Created Add post To Timeline
//Of Each Followers (Of Post Owner)
exports.onCreatePost = functions.firestore
    .document('/posts/{userId}/userPosts/{postId}')
    .onCreate(async (snapshot, context) => {
        const postCreated = snapshot.data();
        const userId = context.params.userId;
        const postId = context.params.postId;

// 1) Get All THe Followers Of The User Who made The Post
const userFollowersRef = admin.firestore()
    .collection('followers')
    .doc(userId)
    .collection('userFollowers');

    //All The Users Followers
        const querySnapshot = await userFollowersRef.get();
    // 2) Add New Post To Each Followers Timeline
    //QuerySnapshot is all the followers
    //forEach returns individual snapshots called doc
    //set the post to each users timeline
    querySnapshot.forEach(doc => {
    //All The User Followers Ids
        const followerId = doc.id;

        admin
            .firestore()
            .collection('timeline')
            .doc(followerId)
            .collection('timelinePosts')
            .doc(postId)
            .set(postCreated);
    });

});

exports.onUpdatePost = functions.firestore
.document('/posts/{userId}/userPosts/{postId}')
.onUpdate(async (change, context) => {
const postUpdated = change.after.data();
const userId = context.params.userId;
const postId = context.params.postId;

// 1) Get all the followers of the user who made the post
const userFollowersRef = admin.firestore()
.collection('followers')
.doc(userId)
.collection('userFollowers');

const querySnapshot = await userFollowersRef.get();
//Update each post in each followers timeline
    querySnapshot.forEach(doc => {
    //All The User Followers Ids
        const followerId = doc.id;

        admin
            .firestore()
            .collection('timeline')
            .doc(followerId)
            .collection('timelinePosts')
            .doc(postId)
            .get()
            .then(doc => {
            if (doc.exists){
                doc.ref.update(postUpdated);
            }
            });
    });

});

exports.onDeletePost = functions.firestore
.document('/posts/{userId}/userPosts/{postId}')
.onDelete(async (snapshot, context) => {

         const userId = context.params.userId;
         const postId = context.params.postId;

         // 1) Get all the followers of the user who made the post
         const userFollowersRef = admin.firestore()
         .collection('followers')
         .doc(userId)
         .collection('userFollowers');

         const querySnapshot = await userFollowersRef.get();
         // 2) Delete each post in each followers timeline
             querySnapshot.forEach(doc => {
             //All The User Followers Ids
                 const followerId = doc.id;

                 admin
                     .firestore()
                     .collection('timeline')
                     .doc(followerId)
                     .collection('timelinePosts')
                     .doc(postId)
                     .get()
                     .then(doc => {
                     if (doc.exists){
                         doc.ref.delete();
                     }
                 });
             });
         });



/*Snapshot is the OUTPUT, Context is the INPUT
snapshot.data is all the data/fields */
//Collection To Watch
    exports.onCreateActivityFeedItem = functions.firestore
        .document('/feed/{userId}/feedItems/{activityFeedItem}')
        .onCreate(async(snapshot, context) => {
        console.log('Activity Feed Item Created', snapshot.data());

        // Get User Who's Feed Was Added To
        const userId = context.params.userId;
        //Users Collection and Document that Is The User Id
        //Back Ticks And ${} to Interpolate
        const userRef = admin.firestore().doc(`users/${userId}`);
        //Get All The Fields
        const doc = await userRef.get();

// 2) Once We Have The User Check If They Have A Notification Token
    //This Is There When A User Checks In
    const androidNotificationToken = doc.data()
    .androidNotificationToken;
    const createdActivityFeedItem = snapshot.data();

    if (androidNotificationToken) {
        //Send Notification
        sendNotification(androidNotificationToken, createdActivityFeedItem);

    } else {
        console.log("No Token For User, Cannot Send Notification");
    }

    function sendNotification(androidNotificationToken, activityFeedItem) {
        //const Cannot Change let Can
        let body;

// 3) Switch Body Value Based Off Of Notification Type
    switch (activityFeedItem.type) {
        case "comment":
            body = `${activityFeedItem.username} replied:
            ${activityFeedItem.commentData}`;
            //break lets you escape switch return
            //exits iteration
                break;
        case "like":
            body = `${activityFeedItem.username} liked your post`;
            break;
        case "follow":
            body = `${activityFeedItem.username} started following you`;
                break;
            default:
                break;
        }

// 4) Create Message For Push Notification
        const message = {
            //notification: { title: "Hello" body: body}
            notification: {body},
            token: androidNotificationToken,
            data: {recipient: userId}
        };

// 5) Send Message With admin.messaging()

        admin
            .messaging()
            .send(message)
            .then(response => {
            //response Is A Message String
            console.log("Successfully Sent Message", response);
            })
            .catch(error => {
                console.log("Error Sending Message", error);
            })
    }
})












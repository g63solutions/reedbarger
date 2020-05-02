import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/comments.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/progress.dart';

// #3 All The Variables That Are Stored And Have State
class Post extends StatefulWidget {
  final String postId;
  final String ownerid;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  // #2 All Post Stuff From Snapshot
  Post({
    this.postId,
    this.ownerid,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
  });

  // #1 Document Snapshot Is Made Into Post
  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerid: doc['ownerid'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }

  int getLikeCount(likes) {
    // if no likes, return 0
    if (likes == null) {
      return 0;
    }
    int count = 0;
    // if the key is explicitly set to true, add a like
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  //Passed all the values from the widget to the
  // _PostState constructor No widget.variable
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerid: this.ownerid,
        username: this.username,
        location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        //method done here and passed in
        likeCount: getLikeCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerid;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  bool isLiked;
  bool showHeart = false;
  int likeCount;
  Map likes;

  _PostState(
      {this.postId,
      this.ownerid,
      this.username,
      this.location,
      this.description,
      this.mediaUrl,
      this.likes,
      this.likeCount});

  buildPostHeader() {
    return FutureBuilder(
        future: usersRef.document(ownerid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            //Stops Here With Return If No Data
            return circularProgress();
          }
          User user = User.fromDocument(snapshot.data);
          bool isPostOwner = currentUserId == ownerid;
          return Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                backgroundColor: Colors.grey,
              ),
              title: GestureDetector(
                onTap: () => showProfile(context, profileId: user.id),
                child: Text(
                  user.username,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              subtitle: Text(location),
              //See If You Are The Post Ower
              trailing: isPostOwner
                  ? IconButton(
                      //Passed In Context Since Modal Needs Context
                      onPressed: () => handleDeletePost(context),
                      icon: Icon(
                        Icons.more_vert,
                      ),
                    )
                  : Text(''),
            ),
          );
        });
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text('Remove The Post?'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  deletePost();
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              )
            ],
          );
        });
  }

  deletePost() async {
    //Delete Post
    postsRef
        .document(ownerid)
        .collection('userPosts')
        .document(postId)
//You Can Call Delete Here Yet You Should Make Sure It Exists First
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
//Delete Uploaded Image From Post
    storageRef.child('post_$postId.jpg').delete();
//Then Delete All Activity Feed Notifications
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .document(ownerid)
        .collection('feedItems')
        .where('postId', isEqualTo: postId)
        .getDocuments();
    activityFeedSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
//Then Delete All Comments
    QuerySnapshot commentsSnapshot = await commentsRef
        .document(postId)
        .collection('comments')
        .getDocuments();
    commentsSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleLikePost() {
    //If current user liked this set this to true
    bool _isLiked = likes[currentUserId] == true;
    //If They Liked It Take Like Away
    if (_isLiked) {
      postsRef
          .document(ownerid)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': false});
      removeLikeFromActivityFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
      //If They Didn't Like It Already Add Like
    } else if (!_isLiked) {
      postsRef
          .document(ownerid)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addLikeToActivityFeed() {
    //Don't add to feed if you like your own stuff
    //isNotPostOwner Only Exists Here
    bool isNotPostOwner = currentUserId != ownerid;
    if (isNotPostOwner) {
      activityFeedRef
          //Send Notification To THe Owner Of The Post
          .document(ownerid)
          .collection('feedItems')
          .document(postId)
          .setData({
        'type': 'like',
        //User Who Liked The Post
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImg': currentUser.photoUrl,
        'postId': postId,
        'mediaUrl': mediaUrl,
        'timestamp': timestamp,
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerid;
    if (isNotPostOwner) {
      activityFeedRef
          .document(ownerid)
          .collection('feedItems')
          .document(postId)
          .get()
          //Whatever Comes From Get Is Sent To Then And Named doc
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showHeart
              ? Icon(
                  Icons.favorite,
                  size: 100.0,
                  color: Colors.red.withOpacity(0.5),
                )
              : Text(''),
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(
                top: 40.0,
                left: 20.0,
              ),
            ),
            //Like Button
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.pink,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: 40.0,
                right: 20.0,
              ),
            ),
            GestureDetector(
              //Need context since It will be Shown
              // outside of post widget
              onTap: () => showComments(
                context,
                postId: postId,
                ownerid: ownerid,
                mediaUrl: mediaUrl,
              ),
              child: Icon(
                Icons.chat,
                size: 28.0,
                color: Colors.blue[900],
              ),
            )
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                '$likeCount likes',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                '$username ',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Text(description),
            )
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
}

showComments(BuildContext context,
    {String postId, String ownerid, String mediaUrl}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Comments(
      postId: postId,
      postOwnerId: ownerid,
      postMediaUrl: mediaUrl,
    );
  }));
}

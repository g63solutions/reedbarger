import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/progress.dart';

//Reference Points to Collection
final CollectionReference usersRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;

  Timeline({this.currentUser});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  @override
  void initState() {
    super.initState();
    getFollowing();
  }

  //Used To Save A List To Use Elsewhere In Program Used With SetState
  List<String> followingList = [];
  List<Post> posts;

  List<dynamic> users = [];

  notFollowingMethod() {
    return StreamBuilder(
      stream:
          usersRef.orderBy('timestamp', descending: true).limit(30).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> userResults = [];
        //ForEach Loop Everything in it is done once
        snapshot.data.documents.forEach((doc) {
          //Take snapshot and return 1 User Object
          User user = User.fromDocument(doc);
          //Check if your user profile comes up so You don't add yourself
          final bool isAuthUser = currentUser.id == user.id;
          //Check you are not already following the person
          final bool isFollowingUser = followingList.contains(user.id);
          //Remove AuthUser from recommended list if true
          if (isAuthUser) {
            return;
          } else if (isFollowingUser) {
            return;
          } else {
            UserResult userResult = UserResult(user);
            userResults.add(userResult);
          }
        });
        return Container(
          color: Theme.of(context).accentColor.withOpacity(0.2),
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.person_add,
                      color: Theme.of(context).primaryColor,
                      size: 30.0,
                    ),
                    SizedBox(
                      width: 8.0,
                    ),
                    Text(
                      'Users To Follow',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 30.0,
                      ),
                    ),
                  ],
                ),
              ),
              //Column(children: userResults)
              Expanded(
                child: ListView(
                  children: userResults,
                ),
              )
            ],
          ),
        );
      },
    );
    // This line at the very end after the last `if` statement
    // if You get needs a return cause return type is container
    // return Center(child: Text('Data unavailable'));
  }

//    return Center(
//      child: Container(
//        child: Text(
//          'Not Following Anyone',
//          style: TextStyle(
//            fontSize: 30,
//            color: Colors.red,
//          ),
//        ),
//      ),
//    );

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(currentUser.id)
        .collection('userFollowing')
        .getDocuments();
    //SetState Is Used To Save Ish To Defined Variables On Top
    setState(() {
      //Gets Document Id Field Of Each UserFollowing Document Which Is A User Id
      followingList = snapshot.documents.map((doc) => doc.documentID).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(
        context,
        isAppTitle: true,
        titleText: 'Time Lizzo',
        removeBackButton: false,
        removeLogoutButton: false,
      ),
      //Refreshes Instantly Unlike A Future Builder
      body:
//      widget.currentUser.id == null
//          ? notFollowingMethod() :
          StreamBuilder<QuerySnapshot>(
        //initialData: null,
        stream: timelineRef
            .document(widget.currentUser.id)
            .collection('timelinePosts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
//          else if (snapshot == null) {
//            return circularProgress();
//          }
          List<Post> children = [];
          snapshot.data.documents.forEach((doc) {
            children.add(Post.fromDocument(doc));
          });

//          List<Post> children = snapshot.data.documents
//              //final List<Post> children = snapshot.data.documents
//              //get each doc and get username
//              .map((doc) => Post.fromDocument(doc))
//              .toList();
          //print('children.length ${children.length}');

          return Container(
            child: children.length > 0
                ? ListView(
                    children: children,
                  )
                : notFollowingMethod(),
          );
        },
      ),
    );
  }
}

//  void userInfo() async {
//    mySelf = await widget.currentUser?.id;
//
//    print('User Info $mySelf');
//  }

//  createUser() {
//    //.add returns a unique Id
//    //.setData lets you set an ID/document
//    usersRef.document('zC0zUEzIsLLVhhl28oyZ').setData({
//      'username': 'Jeff Crate',
//      'postsCount': 0,
//      'isAdmin': false,
//    });
//  }

//  updateUser() async {
//    final DocumentSnapshot doc =
//        //Check It Before Looking To Delete It
//        await usersRef.document('zC0zUEzIsLLVhhl28oyZ').get();
//    if (doc.exists) {
//      doc.reference
//        ..updateData({
//          'username': 'Johnny Update ',
//          'postsCount': 0,
//          'isAdmin': false,
//        });
//    }
//  }

//  deleteData() async {
//    final DocumentSnapshot doc =
//        //Check It Before Looking To Delete It
//        await usersRef.document('zC0zUEzIsLLVhhl28oyZ').get();
//    if (doc.exists) {
//      doc.reference.delete();
//    }
//    usersRef.document('asdfghjkl').delete();
//  }

//  currentUserId(){
//    current = widget.currentUser.id;
//
//    setState(() {
//      this.current = current;
//    });
//  }

//  buildTimeline() {
//    if (posts == null) {
//      return circularProgress();
//    } else if (posts.isEmpty) {
//      return Text('NO POSTS');
//    } else {
//      return ListView(children: posts);
//    }
//  }

//Fetching Users Timeline
//  getTimeline() async {
//    QuerySnapshot snapshot = await timelineRef
//        .document(widget.currentUser.id)
//        //.document(currentUser)
//        .collection('timelinePosts')
//        .orderBy('timestamp', descending: true)
//        .getDocuments();
//    List<Post> posts =
//        snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
//    setState(() {
//      this.posts = posts;
//    });
//  }

//@override
//void initState() {
//This Here
//createUser();
//updateUser();
//deleteData();
//super.initState();
//getCurrentUser();
//getTimeline();
//userInfo();
//}

//  //TODO Here Lies The Issue
//  @override
//  Widget build(context) {
//    return Scaffold(
//      appBar: header(context, isAppTitle: true),
//      body: RefreshIndicator(
//        onRefresh: () => getTimeline(),
//        child: buildTimeline(),
//      ),
//    );
//  }

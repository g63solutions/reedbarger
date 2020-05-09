import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
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
  List<Post> posts;

  String currentUser;

  List<dynamic> users = [];

  @override
  void initState() {
    //This Here
    //createUser();
    //updateUser();
    //deleteData();
    super.initState();
    //getCurrentUser();
    //getTimeline();
  }

  createUser() {
    //.add returns a unique Id
    //.setData lets you set an ID/document
    usersRef.document('zC0zUEzIsLLVhhl28oyZ').setData({
      'username': 'Jeff Crate',
      'postsCount': 0,
      'isAdmin': false,
    });
  }

  updateUser() async {
    final DocumentSnapshot doc =
        //Check It Before Looking To Delete It
        await usersRef.document('zC0zUEzIsLLVhhl28oyZ').get();
    if (doc.exists) {
      doc.reference
        ..updateData({
          'username': 'Johnny Update ',
          'postsCount': 0,
          'isAdmin': false,
        });
    }
  }

  deleteData() async {
    final DocumentSnapshot doc =
        //Check It Before Looking To Delete It
        await usersRef.document('zC0zUEzIsLLVhhl28oyZ').get();
    if (doc.exists) {
      doc.reference.delete();
    }
    usersRef.document('asdfghjkl').delete();
  }

  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Text('NO POSTS');
    } else {
      return ListView(children: posts);
    }
  }

  //Fetching Users Timeline
  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .document(widget.currentUser.id)
        //.document(currentUser)
        .collection('timelinePosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Post> posts =
        snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

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

  Widget notFollowingMethod() {
    return Center(
      child: Container(
        child: Text(
          'Not Following Anyone',
          style: TextStyle(
            fontSize: 30,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(
        context,
        isAppTitle: true,
        titleText: 'Time Lizzo',
        removeBackButton: false,
        removeLogoutButton: false,
      ),
      //Refreshes Instantly Unlike A Future Builder
      body: StreamBuilder<QuerySnapshot>(
        stream: timelineRef
            .document(widget.currentUser?.id)
            .collection('timelinePosts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }

//        List<Post> childrensss =
//        snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
//        setState(() {
//          this.posts = posts;
//        });

          final List<Post> children = snapshot.data.documents
              //get each doc and get username
              .map((doc) => Post.fromDocument(doc))
              .toList();
          print('children.length ${children.length}');
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

//@override
//Widget build(context) {
//  return Scaffold(
//    appBar: header(
//      context,
//      isAppTitle: true,
//      titleText: 'Profile',
//      removeBackButton: false,
//      removeLogoutButton: false,
//    ),
//    //Refreshes Instantly Unlike A Future Builder
//    body: StreamBuilder<QuerySnapshot>(
//      stream: Firestore.instance.collection('users').snapshots(),
//      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//        if (!snapshot.hasData) {
//          return circularProgress();
//        }
//        final List<Text> children = snapshot.data.documents
//        //get each doc and get username
//            .map((doc) => Text(doc['username'].toString()))
//            .toList();
//        return Container(
//          child: ListView(
//            children: children,
//          ),
//        );
//      },
//    ),
//  );
//}

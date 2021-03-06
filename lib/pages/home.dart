import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/create_account.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/pages/timeline.dart';
import 'package:fluttershare/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';

//Reference Now We Can Use The Methods Login/Logout etc.
//References Used To Access Firebase etc.
final GoogleSignIn googleSignIn = GoogleSignIn();
final StorageReference storageRef = FirebaseStorage.instance.ref();
final FirebaseAuth _auth = FirebaseAuth.instance;
//Path References In FireStore
final usersRef = Firestore.instance.collection('users');
final postsRef = Firestore.instance.collection('posts');
final commentsRef = Firestore.instance.collection('comments');
final activityFeedRef = Firestore.instance.collection('feed');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final timelineRef = Firestore.instance.collection('timeline');
final DateTime timestamp = DateTime.now();

//ownerid not ownerId

//Able To Pass User Data To All The Pages From Here
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();

  ///Logout
  logout() {
    googleSignIn.signOut();
    print('Logout\n');
  }
}

class _HomeState extends State<Home> {
  //FireBaseMessaging Stuff
  // With The Key _scaffoldKey.currentState.showSnackbar();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool isAuth = false;
  //Make Sure To Dispose When Not On The HomePage
  PageController pageController;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    //Widgets Initialized In InitState Must Be disposed
    pageController = PageController();

    ///Detects When User Signed In
    //account is a return type of googleSignInAccount
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account: account);
    }, onError: (err) {
      print('Error Signing In: $err');
    });

    ///ReAuthenticate user when app is opened
    //App Doesn't Keep State
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account: account);
      print('Signed In Silently\n');
    }).catchError((err) {
      print('Error Signing In: $err');
    });
  }

  handleSignIn({GoogleSignInAccount account}) async {
    if (account != null) {
      //Await has to be used if you call an ASYNC FUNCTION
      await createUserInFirestore();
      print('Google Sign In Account Info => $account\n');
      setState(() {
        print('isAuth = true\n');
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        print('isAuth = false\n');
        isAuth = false;
      });
    }
  }

  configurePushNotifications() {
    //Get User
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if (Platform.isIOS) getIOSPermission();
    //Get Notification Token And Associate It With The User Data
    _firebaseMessaging.getToken().then((token) {
      print("Firebase Messaging TOKEN:::: $token\n");
      //Associate It With The User Store It. Whenever
      // It Is Needed Get It
      usersRef
          .document(user.id)
          .updateData({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
      //Map Strings As Keys And Dynamic For Its Value
      // const message = {
      //            //notification: { title: "Hello" body: body}
      //            notification: {body},
      //            token: androidNotificationToken,
      //            data: {recipient: userId}
      //        };
//      //Send A Notification When App Is Off
//      onLaunch: (Map<String, dynamic> message) async {},
//      //Send A Message When App Is In The Background
//      onResume: (Map<String, dynamic> message) async {},
      //Send A Message While They Are Actively Using The App
      onMessage: (Map<String, dynamic> message) async {
        print('onMessage: $message\n');
        //From message map  data object recipient property
        final String recipientId = message['data']['recipient'];
        //From message map notification object body property
        final String body = message['notification']['body'];
        if (recipientId == user.id) {
          print("Notification Shown");
          SnackBar snackbar = SnackBar(
              content: Text(
            body,
            overflow: TextOverflow.ellipsis,
          ));
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
        print('NOTIFICATION Not Shown');
      },
    );
  }

  getIOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, badge: true, sound: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Settings Registered: $settings");
    });
  }

  //Whenever This Is Called You Need To Use ASYNC ans AWAIT
  createUserInFirestore() async {
    // 1) Check if user exists in users collections in database
    // according to their ID
    //googleSignIn.currentUSer returns same info as account/GoogleSignIn
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(user.id).get();

    if (!doc.exists) {
      // 2) if the user doesn't exist, then we want to take them
      // to the create user account page
      //This userName Is Returned After The pushed page pops
      // back, it is in the POP constructor
      final username = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateAccount(),
          ));
      print('$username');
      // 3) get username from create account use
      // it to make new user document in users
      // collection with the user id as the document id
      usersRef.document(user.id).setData({
        'id': user.id,
        //If A User Backs Out It Will Create An Error == Null
        'username': username ?? 'John Doe',
        'photoUrl': user.photoUrl,
        'email': user.email,
        'displayName': user.displayName,
        'bio': " ",
        'timestamp': timestamp,
      });
      print('${user.id}');
      //If Document Does Not Exist All These Variables Are
      // Set In The Database. This Line Retrieves Those
      // Documents and Stores The in A User Object.

      //Make user their own follower(to include their
      // posts in their timeline)
      await followersRef
          .document(user.id)
          .collection('userFollowers')
          .document(user.id)
          .setData({});

      doc = await usersRef.document(user.id).get();
    }
    //DocumentSnapshot turned into user object.
    currentUser = User.fromDocument(doc);
    print(currentUser);
    print(currentUser.username);
  }

  @override
  void dispose() {
    pageController.dispose();
    //THis Has To Be Last Or Ish Wont Work
    super.dispose();
  } //

  ///Login Called By UnAuth
  login2() {
    googleSignIn.signIn();
  }

  login() async {
    // hold the instance of the authenticated user
    FirebaseUser user;
    // flag to check whether we're signed in already
//    bool isSignedIn = await googleSignIn.isSignedIn();
//    if (isSignedIn) {
//      // if so, return the current user
//      user = await _auth.currentUser();
//    }
//    else {
    final GoogleSignInAccount googleUser = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    // get the credentials to (access / id token)
    // to sign in via Firebase Authentication
    final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
    user = (await _auth.signInWithCredential(credential)).user;
    //}
    print('This Is Working $user');
    //return user;
  }

  ///Logout
  logout() async {
    await _auth.signOut();
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(pageIndex,
        duration: Duration(milliseconds: 300), curve: Curves.bounceInOut);
  }

  ///AuthScreen
  Widget buildAuthScreen() {
    return Scaffold(
      //Key For Messaging
      //Scaffold wraps all these pages
      //Snackbar Will Show Here Only
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          //currentUser?.id Null Aware Operator If Null
          // Don't Pass It
          Profile(profileId: currentUser?.id),
        ],
        //Controller To switch Between Pages
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.whatshot),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.photo_camera,
              size: 35.0,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
          ),
        ],
      ),
    );
  }

  ///Login Screen
  Scaffold buildUnAuthScreen() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Theme.of(context).accentColor.withOpacity(0.9),
                Theme.of(context).primaryColor.withOpacity(0.9),
              ]),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'FlutterShare',
              style: TextStyle(
                fontFamily: "Signatra",
                fontSize: orientation == Orientation.portrait ? 90.0 : 150.0,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () {
                login();
                print('Tapped');
              },
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/google_signin_button.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  ///Uses isAuth State to Load Screens
  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}

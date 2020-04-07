import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/create_account.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/pages/timeline.dart';
import 'package:fluttershare/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';

//Reference Now We Can Use The Methods Login/Logout etc.
final GoogleSignIn googleSignIn = GoogleSignIn();
final FirebaseAuth _auth = FirebaseAuth.instance;
//final userRef = Firestore.instance.collection('users');
final userRef = Firestore.instance.collection('users');
final DateTime timestamp = DateTime.now();

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();

  ///Logout
  logout() {
    googleSignIn.signOut();
  }
}

class _HomeState extends State<Home> {
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
      print('Signed In Silently');
    }).catchError((err) {
      print('Error Signing In: $err');
    });
  }

  handleSignIn({GoogleSignInAccount account}) {
    if (account != null) {
      createUserInFirestore();
      print('Google Sign In Account Info => $account');
      setState(() {
        print('isAuth = true');
        isAuth = true;
      });
    } else {
      setState(() {
        print('isAuth = false');
        isAuth = false;
      });
    }
  }

  createUserInFirestore() async {
    // 1) Check if user exists in users collections in database
    // according to their ID
    //googleSignIn.currentUSer returns same info as account/GoogleSignIn
    final GoogleSignInAccount user = googleSignIn.currentUser;
    final DocumentSnapshot doc = await userRef.document(user.id).get();

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
      userRef.document(user.id).setData({
        'id': user.id,
        'username': username,
        'photoUrl': user.photoUrl,
        'email': user.email,
        'displayName': user.displayName,
        'bio': '',
        'timestamp': timestamp,
      });
      print('${user.id}');
    }
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

  ///Page Controller Houses Pages
  Widget buildAuthScreen() {
    return Scaffold(
      body: PageView(
        children: <Widget>[
          Timeline(),
          ActivityFeed(),
          Upload(),
          Search(),
          Profile(),
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
                fontSize: 90.0,
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

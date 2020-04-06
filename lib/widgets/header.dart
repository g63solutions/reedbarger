import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:google_sign_in/google_sign_in.dart';

//Context Is Passed Without Constructor since
// this is a function and not a class
//Context is needed, isAppTitle is optional
// since its default is false, titleText is required
GoogleSignIn googleSignIn = GoogleSignIn();
Home home = Home();

AppBar header(BuildContext context,
    {bool isAppTitle = false, String titleText}) {
  return AppBar(
    title: Text(
      isAppTitle ? "FlutterShare" : titleText,
      style: TextStyle(
        color: Colors.white,
        fontFamily: isAppTitle ? 'Signatra' : '',
        fontSize: isAppTitle ? 50.0 : 22.0,
      ),
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).primaryColor,
    actions: <Widget>[
      IconButton(
        icon: Icon(Icons.cancel),
        tooltip: 'LOGOUT',
        onPressed:
            //logout,
            //(){}
            home.logout,
      )
    ],
  );
}

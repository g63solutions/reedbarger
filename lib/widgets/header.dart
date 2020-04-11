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
    {bool isAppTitle = false,
    String titleText,
    //Giving It A Value Makes It Optional
    removeBackButton = false,
    removeLogoutButton = true}) {
  return AppBar(
    //automaticallyImplyLeading set to  false removes
    // back button. So if remove backButton is true
    // return false and remove it
    automaticallyImplyLeading: removeBackButton ? false : true,
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
      removeLogoutButton
          ? Text('')
          : IconButton(
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

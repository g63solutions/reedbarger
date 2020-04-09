//import 'dart:html';

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  //Needed For Forms
  final _formKey = GlobalKey<FormState>();
  //SnackBar Display
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String username;

  submit() {
    final form = _formKey.currentState;
    //Saves every [FormField] that
    // is a descendant of this [Form] aka _formKey.
    if (form.validate()) {
      form.save();
      //SnackBar
      SnackBar snackBar = SnackBar(
        content: Text('Welcome $username'),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
      //Timer So That Page Doesn't disappear before SnackBar
      Timer(
        Duration(seconds: 2),
        () {
          //Sends Username back
          Navigator.pop(context, username);
        },
      );
    }
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(
        context,
        titleText: 'Set Up Your Profile',
        removeBackButton: true,
      ),
      body: ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 25.0),
                  child: Text(
                    'Create A Username',
                    style: TextStyle(fontSize: 25.0),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Container(
                    //Form Has  A FormKey So That You Can Refer
                    // To It And The onSaved Value
                    child: Form(
                        key: _formKey,
                        autovalidate: true,
                        child: TextFormField(
                          validator: (val) {
                            //Returns the string without any leading and
                            // trailing whitespace. If the string
                            // contains leading or trailing whitespace,
                            // a new string with no leading and no trailing
                            // whitespace is returned:
                            if (val.trim().length < 3 || val.isEmpty) {
                              return 'Username too short';
                            } else if (val.trim().length > 16) {
                              return 'Username Too Long';
                            } else {
                              return null;
                            }
                          },
                          onSaved: (val) => username = val,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Username',
                            labelStyle: TextStyle(fontSize: 15.0),
                            hintText: 'Must Be atleast 3 Characters',
                          ),
                        )),
                  ),
                ),
                GestureDetector(
                  onTap: submit,
                  child: Container(
                    height: 50,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                    child: Center(
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

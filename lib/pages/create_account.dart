//import 'dart:html';

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
  String username;

  submit() {
    //Saves every [FormField] that
    // is a descendant of this [Form] aka _formKey.
    _formKey.currentState.save();
    //Sends Username back
    Navigator.pop(context, username);
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      appBar: header(context, titleText: 'Set Up Your Profile'),
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
                        child: TextFormField(
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
                    width: 350,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                    child: Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
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

import 'package:cloud_firestore/cloud_firestore.dart';

//This Model Takes In A Snapshot And Returns A User Object
//If this were a stateful widget this would be in the
// widget location
class User {
  final String id;
  final String username;
  final String email;
  final String photoUrl;
  final String displayName;
  final String bio;

  User({
    this.id,
    this.username,
    this.email,
    this.photoUrl,
    this.displayName,
    this.bio,
  });

  //From Firestore A DocumentSnapshot. Doc Is A Map.
  // This Is A From Document Factory
  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc['id'],
      email: doc['email'],
      username: doc['username'],
      photoUrl: doc['photoUrl'],
      displayName: doc['displayName'],
      bio: doc['bio'],
    );
  }
}

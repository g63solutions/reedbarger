import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as Im;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final User currentUser;

  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  //Once This File Is Not Null And Is In State
  // We Need To Change View
  //Has to be stored in state
  File file;
  bool isUpLoading = false;
  String postId = Uuid().v4();

  handleTakePhoto(context) async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      this.file = file;
    });
  }

  //Can't Do On IOS
  handleChooseFromGallery(context) async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );
    setState(() {
      this.file = file;
    });
  }

  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text('Create Post'),
          children: <Widget>[
            SimpleDialogOption(
              child: Text('Photo with Camera'),
              onPressed: () => handleTakePhoto(context),
            ),
            SimpleDialogOption(
              child: Text('Image From Gallery'),
              onPressed: () => handleChooseFromGallery(context),
            ),
            SimpleDialogOption(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  Container buildSplashScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset('assets/images/upload.svg', height: 260.0),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'Upload Image',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.00,
                ),
              ),
              color: Colors.deepOrange,
              onPressed: () => selectImage(context),
            ),
          )
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    //Read Image File We Have In State Putting It In imageFile
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressesImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 50));
    setState(() {
      file = compressesImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadTask =
        storageRef.child('post_$postId.jpg').putFile(imageFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFirestore(
      {String mediaUrl, String location, String description}) {
    postsRef
        .document(widget.currentUser.id)
        .collection('userPosts')
        .document(postId)
        .setData({
      'postId': postId,
      'ownerid': widget.currentUser.id,
      'username': widget.currentUser.username,
      'mediaUrl': mediaUrl,
      'description': description,
      'location': location,
      'timestamp': timestamp,
      'likes': {},
    });
  }

  handleSubmit() async {
    setState(() {
      isUpLoading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text,
    );
    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isUpLoading = false;
      postId = Uuid().v4();
    });
  }

  //After Modal Popup and Image is selected
  buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          //onPressed: clearImage,
          onPressed: () {
            locationController.clear();
            captionController.clear();
            clearImage();
          },
        ),
        title: Text(
          'Caption Post',
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          FlatButton(
            //Null disables Button while loading
            //()=> handleSubmit is fat arrowed, if not it will
            // be called as soon as the button isn't null/enabled vs
            // being called only when pressed. It waits to be
            // pressed instead of being activated immediately
            onPressed: isUpLoading ? null : () => handleSubmit(),
            child: Text(
              'Post',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUpLoading ? linearProgress() : Text(''),
          Container(
            height: 220.0,
            //Take up 80 percent of screen
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                    fit: BoxFit.cover,
                    image: FileImage(file),
                  )),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'Write A Caption...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35.0,
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: 'Where Was The Photo Taken',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100.00,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              label: Text(
                'USE CURRENT LOCATION',
                style: TextStyle(color: Colors.white),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              color: Colors.blue,
              onPressed: getUserLocation,
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }

  getUserLocation() async {
    Position position = await Geolocator().getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    List<Placemark> placeMarks = await Geolocator().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    Placemark placeMark = placeMarks[0];
    String completeAddress =
        '${placeMark.subThoroughfare} ${placeMark.thoroughfare} ${placeMark.subLocality} ${placeMark.locality} ${placeMark.subAdministrativeArea} ${placeMark.administrativeArea} ${placeMark.postalCode} ${placeMark.country}';
    print(completeAddress);
    String formattedAddress =
        '${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.country}';
    locationController.text = formattedAddress;
  }

  @override
  Widget build(BuildContext context) {
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}

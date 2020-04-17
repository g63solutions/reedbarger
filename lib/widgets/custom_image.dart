import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

cachedNetworkImage(String mediaUrl) {
  return CachedNetworkImage(
    imageUrl: mediaUrl,
    //Cover Entire Space
    fit: BoxFit.cover,
    placeholder: (context, url) => Padding(
      child: CircularProgressIndicator(
        backgroundColor: Colors.deepOrange,
      ),
      padding: EdgeInsets.all(20.0),
    ),
    errorWidget: (context, url, error) => Icon(Icons.error),
  );
}

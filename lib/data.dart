import 'package:xml/xml.dart';
import 'package:favicon/favicon.dart' as favicon;
import 'package:flutter/material.dart';

class Data {
  String AccountID;
  String URL;
  String Password;
  String BindAddress;
  late Widget image;
  Data(this.AccountID, this.BindAddress, this.Password, this.URL);

  Future<String> getFaviconURLAsync() async {
    var icon = await favicon.Favicon.getBest(URL);
    return (icon == null) ? '' : icon.url;
  }

  Future<void> getFavicon() async {
    try {
      image = Image.network(
        await getFaviconURLAsync(),
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.error,
          color: Colors.red,
        ),
        width: 50,
        height: 50,
      );
    } catch (e) {
      image = const Icon(Icons.image_not_supported);
    }
  }

  factory Data.fromXmlElement(XmlElement xmlElement) {
    String _AccountID = '', _BindAddress = '', _Password = '', _URL = '';
    try {
      _AccountID = xmlElement.findElements('AccountID').first.text;
    } catch (e) {
      _AccountID = "";
    }
    try {
      _BindAddress = xmlElement.findElements('BindAddress').first.text;
    } catch (e) {
      _BindAddress = "";
    }
    try {
      _Password = xmlElement.findElements('Password').first.text;
    } catch (e) {
      _Password = "";
    }
    try {
      _URL = xmlElement.findElements('URL').first.text;
    } catch (e) {
      _URL = "";
    }
    return Data(_AccountID, _BindAddress, _Password, _URL);
  }
}

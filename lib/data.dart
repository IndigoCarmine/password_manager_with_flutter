// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:aes_crypt_null_safe/aes_crypt_null_safe.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'package:favicon/favicon.dart' as favicon;
import 'package:flutter/material.dart';

import 'my_pdkdf2.dart';

class Data {
  String AccountID;
  String URL;
  String Password;
  String BindAddress;
  final double iconsize = 40;
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
        errorBuilder: (context, error, stackTrace) => SizedBox(
          child: const Icon(
            Icons.error,
            color: Colors.red,
          ),
          width: iconsize,
          height: iconsize,
        ),
        width: iconsize,
        height: iconsize,
      );
    } catch (e) {
      image = SizedBox(
        child: const Icon(Icons.image_not_supported),
        width: iconsize,
        height: iconsize,
      );
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

class FileData {
  String _path;
  String _password;
  FileData(this._path, this._password);

  String getPath() => _path;
  String getPassword() => _password;

  //if file is not exist or invailed, it return null.
  Future<List<Data>?> getData() async {
    File file = File(_path);
    if (!(await file.exists())) return null;

    Uint8List fileContent = file.readAsBytesSync();
    //fileopen finish!
    String planetext = decrypt(fileContent, _password);

    return xmlserialize(planetext);
  }

  void editSettings({String? path, String? password}) {
    _path = path ?? _path;
    _password = password ?? _password;
  }

  List<Data>? xmlserialize(String xmlcontext) {
    try {
      var xml = XmlDocument.parse(xmlcontext);
      return xml
          .findAllElements('Data')
          .map((xmlElement) => Data.fromXmlElement(xmlElement))
          .toList();
    } on XmlParserException catch (_) {
      return null;
    }
  }

  String decrypt(Uint8List fileContent, String password) {
    int keysize = 256;
    int blocksize = 128;
    String salt = "saltは必ず8バイト以上";

    var crypt = AesCrypt();
    var gen = PBKDF2();
    Uint8List key =
        Uint8List.fromList(gen.generateKey(password, salt, 1000, keysize ~/ 8));
    Uint8List iv = Uint8List.fromList(
        gen.generateKey(password, salt, 1000, blocksize ~/ 8));
    crypt.aesSetKeys(key, iv);
    Uint8List dec = crypt.aesDecrypt(fileContent);

    //全体の調整(なせ必要なのか不明)
    //todo #1

    String planetext = utf8.decode(
        dec.toList().getRange(22, dec.length).toList(),
        allowMalformed: true);
    log(planetext);
    planetext = '<?xml version="1.0" encoding="utf-8"?>' + planetext;
    planetext = planetext.replaceAll('\x0E', '');
    return planetext;
  }
}

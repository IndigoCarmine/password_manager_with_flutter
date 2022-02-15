import 'package:xml/xml.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:password_manager_with_flutter/data.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:typed_data';
// ignore: import_of_legacy_library_into_null_safe
import 'package:aes_crypt/aes_crypt.dart';
import 'package:password_manager_with_flutter/my_pdkdf2.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Password Manager'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<String> inputDialog(BuildContext context) async {
    TextEditingController editingController = TextEditingController();
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Password'),
            content: TextField(
              obscureText: true,
              controller: editingController,
              decoration: const InputDecoration(hintText: "ここに入力"),
            ),
            actions: <Widget>[
              TextButton(
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.white)),
                child:
                    const Text('キャンセル', style: TextStyle(color: Colors.black)),
                onPressed: () {
                  editingController.text = '';
                  Navigator.pop(context);
                },
              ),
              TextButton(
                autofocus: true,
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.white)),
                child: const Text('OK', style: TextStyle(color: Colors.black)),
                onPressed: () {
                  //OKを押したあとの処理
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
    return editingController.text;
  }

  //OKを押したあとの処理
  List<Data> dataList = [];
  void xmlserialize(String xmlcontext) {
    var xml = XmlDocument.parse(xmlcontext);
    List<Data> _dataList = xml
        .findAllElements('Data')
        .map((xmlElement) => Data.fromXmlElement(xmlElement))
        .toList();
    setState(() {
      dataList = _dataList;
    });
  }

  void openfile() async {
    //fileopen
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'password manager用ファイル',
      extensions: ['pwm'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) {
      return;
    }
    Uint8List fileContent = await file.readAsBytes();
    //fileopen finish!

    //encrypt
    int keysize = 256;
    int blocksize = 128;
    String salt = "saltは必ず8バイト以上";

    String password = await inputDialog(context);
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
    planetext = '<?xml version="1.0" encoding="utf-8"?>' + planetext;
    planetext = planetext.replaceAll('\x0E', '');
    //全体の調整 finish!
    //encrtpt finish!
    xmlserialize(planetext);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black38),
                  ),
                ),
                child: ListTile(
                  leading: FutureBuilder(
                      future: dataList[index].getFavicon(),
                      builder: (bind, image) {
                        if (image.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else {
                          return dataList[index].image;
                        }
                      }),
                  title: Text(dataList[index].AccountID),
                  subtitle: Text('Binding:' +
                      dataList[index].BindAddress +
                      '  URL:' +
                      dataList[index].URL),
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: dataList[index].Password));
                  },
                ));
          },
          itemCount: dataList.length,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openfile,
        tooltip: 'Increment',
        child: const Icon(Icons.open_in_browser),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:password_manager_with_flutter/data.dart';
import 'package:file_picker/file_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:secure_shared_preferences/secure_shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'input_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  _MyHomePageState() {
    loadPathes().then((value) => loadRecentFile());
  }

  //load file list from shared preferences
  Future<void> loadPathes() async {
    var pref = await SharedPreferences.getInstance();
    const  securePref = FlutterSecureStorage();
    List<String> pathes = pref.getStringList("pathes") ?? [];
    final passwords = (await securePref.readAll());
    List<FileData> fileList = [];
    for (int i = 0; i < pathes.length; i++) {
      fileList.add(FileData(pathes[i], passwords[pathes[0]]));
    }
    setState(() {
      fileList = fileList;
    });
  }

  Future<void> loadRecentFile() async {
    var pref = await SharedPreferences.getInstance();
    int? index = pref.getInt("recentFile");
    if (index != null && 0 <=  index&& index< fileList.length) {
      await openFile(fileList[index]);
    }
  }

  Future<void> updateSharedData({FileData? data}) async {
    List<String> pathes = [];
    List<String?> passwords = [];
    for (var filedata in fileList) {
      pathes.add(filedata.getPath());
      passwords.add(filedata.getPassword());
    }
    var pref = await SharedPreferences.getInstance();
    const securePref = FlutterSecureStorage();
    pref.setStringList("pathes", pathes);
    securePref.deleteAll();
    for(int i =0; i<pathes.length;i++){
      securePref.write(key: pathes[i], value: passwords[i]);
    }
    if (data != null) pref.setInt("recentFile", fileList.indexOf(data));
  }

  List<FileData> fileList = [];
  List<Data> dataList = [];

  //authenticate with biometric. if pass, return true.
  Future<bool> authenticate() async {
    //linux is not implementation getAvaliableBiometrix function.
    if(Platform.isLinux)return false;
    LocalAuthentication localAuth = LocalAuthentication();

    List<BiometricType> availableBiometricTypes =
        await localAuth.getAvailableBiometrics();

    if (availableBiometricTypes.contains(BiometricType.strong)) {
      try {
        return await localAuth.authenticate(localizedReason: "自動認証します。");
      } on PlatformException catch (_) {
        return false;
      }
    } else {
      return false;
    }
  }

  Future<void> openFile(FileData fileData) async {
    if (!(await authenticate())) {
      if(!mounted) return;
      final password = await inputDialog(context);
      fileData.editSettings(password: password);
    }

      dataList = (await fileData.getData()) ?? [];
      setState(() {});
  }

  Future<void> selectNewFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.isSinglePick) {
      if(!mounted)return;
      var newFile = FileData(result.paths.first!, await inputDialog(context));
      fileList.add(newFile);
      await updateSharedData(data: newFile);
      await openFile(newFile);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
          child: ListView.builder(
              itemCount: fileList.length,
              itemBuilder: ((context, index) => Row(
                    children: [
                      TextButton(
                          onPressed: () {
                            openFile(fileList[index]);
                          },
                          child: Text(fileList[index].getPath().substring(
                              fileList[index].getPath().length - 20,
                              fileList[index].getPath().length))),
                      IconButton(
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return KeyboardListener(
                                    focusNode: FocusNode(),
                                    autofocus:  true,
                                    onKeyEvent: (value) async{
                                      if(value.logicalKey == LogicalKeyboardKey.enter){
                                        fileList.removeAt(index);
                                        await updateSharedData();
                                        
                                        if(mounted) {
                                          Navigator.pop(context);
                                        }
                                      }
                                    },
                                    child: AlertDialog(
                                      content: const Text("消去しますか。"),
                                      actions: [
                                        TextButton(
                                            onPressed: (()async {
                                              fileList.removeAt(index);
                                              await updateSharedData();
                                              setState(() {});
                                              
                                              Navigator.pop(context);
                                            }),
                                            child: const Text('Yes')),
                                        TextButton(
                                            onPressed: (() {
                                              Navigator.pop(context);
                                            }),
                                            child: const Text('No'))
                                      ],
                                    ),
                                  );
                                });
                          },
                          icon: const Icon(Icons.delete))
                    ],
                  )))),
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(onPressed: selectNewFile, icon: const Icon(Icons.plus_one))
        ],
      ),
      body: MainView(dataList: dataList),
      floatingActionButton: FloatingActionButton(
        onPressed: (() {
          setState(() {});
        }),
        tooltip: 'Increment',
        child: const Icon(Icons.open_in_browser),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class MainView extends StatelessWidget {
  const MainView({
    super.key,
    required this.dataList,
  });

  final List<Data> dataList;

  @override
  Widget build(BuildContext context) {
    return Center(
      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
      child: ListView.builder(
        itemBuilder: (BuildContext context, int index) {

          print(dataList[index].AccountID);
          return Card(
            child: ListTile(
              leading: FutureBuilder(
                  future: dataList[index].getFavicon(),
                  builder: (bind, image) {
                    if (image.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else {
                      return dataList[index].image ?? const SizedBox();
                    }
                  }),
              title: Text(dataList[index].AccountID),
              subtitle: Text('Binding:${dataList[index].BindAddress}  URL:${dataList[index].URL}'),
              onTap: () {
                Clipboard.setData(
                    ClipboardData(text: dataList[index].Password));
              },
            ),
          );
        },
        itemCount: dataList.length,
      ),
    );
  }
}

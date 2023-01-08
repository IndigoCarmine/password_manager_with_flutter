import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:password_manager_with_flutter/data.dart';
import 'package:file_picker/file_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_shared_preferences/secure_shared_preferences.dart';
import 'input_dialog.dart';

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
  _MyHomePageState() {
    getSettings().then((value) => loadRecentFile());
  }

  Future<void> getSettings() async {
    var _pref = await SharedPreferences.getInstance();
    var _securePref = await SecureSharedPref.getInstance();
    List<String> pathes = _pref.getStringList("pathes") ?? [];
    List<String> passwords = (await _securePref.getStringList("passwords"));
    List<FileData> _fileList = [];
    for (int i = 0; i < pathes.length; i++) {
      _fileList.add(FileData(pathes[i], passwords[i]));
    }
    setState(() {
      fileList = _fileList;
    });
  }

  Future<void> loadRecentFile() async {
    var _pref = await SharedPreferences.getInstance();
    int? index = _pref.getInt("recentFile");
    if (index != null) {
      await openFile(fileList[index]);
    }
  }

  Future<void> updateSharedData({FileData? data}) async {
    List<String> pathes = [];
    List<String> passwords = [];
    for (var filedata in fileList) {
      pathes.add(filedata.getPath());
      passwords.add(filedata.getPassword());
    }
    var _pref = await SharedPreferences.getInstance();
    var _securePref = await SecureSharedPref.getInstance();
    _pref.setStringList("pathes", pathes);
    _securePref.putStringList("passwords", passwords);
    if (data != null) _pref.setInt("recentFile", fileList.indexOf(data));
  }

  List<FileData> fileList = [];
  List<Data> dataList = [];

  Future<bool> authenticate() async {
    LocalAuthentication _localAuth = LocalAuthentication();

    List<BiometricType> availableBiometricTypes =
        await _localAuth.getAvailableBiometrics();

    if (availableBiometricTypes.contains(BiometricType.strong)) {
      try {
        return await _localAuth.authenticate(localizedReason: "自動認証します。");
      } on PlatformException catch (_) {
        return false;
      }
    } else {
      return true;
    }
  }

  Future<void> openFile(FileData fileData) async {
    if (await authenticate()) {
      dataList = (await fileData.getData()) ?? [];
      setState(() {});
    }
  }

  Future<void> newFileSelect() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.isSinglePick) {
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
                              fileList[index].getPath().length - 10,
                              fileList[index].getPath().length))),
                      IconButton(
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    content: const Text("消去しますか。"),
                                    actions: [
                                      TextButton(
                                          onPressed: (() {
                                            fileList.removeAt(index);
                                            updateSharedData().then((value) {
                                              setState(() {});
                                            });
                                            Navigator.pop(context);
                                          }),
                                          child: const Text('Yes')),
                                      TextButton(
                                          onPressed: (() {
                                            Navigator.pop(context);
                                          }),
                                          child: const Text('No'))
                                    ],
                                  );
                                });
                          },
                          icon: const Icon(Icons.delete))
                    ],
                  )))),
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(onPressed: newFileSelect, icon: const Icon(Icons.plus_one))
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
    Key? key,
    required this.dataList,
  }) : super(key: key);

  final List<Data> dataList;

  @override
  Widget build(BuildContext context) {
    return Center(
      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
      child: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          return Card(
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
            ),
          );
        },
        itemCount: dataList.length,
      ),
    );
  }
}

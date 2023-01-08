import 'package:flutter/material.dart';

Future<String> inputDialog(BuildContext context) async {
  TextEditingController editingController = TextEditingController();
  await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('recent_password'),
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
              child: const Text('キャンセル', style: TextStyle(color: Colors.black)),
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

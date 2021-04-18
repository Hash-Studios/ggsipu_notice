import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

class ActionModal extends StatelessWidget {
  final bool download;
  final DocumentSnapshot document;
  ActionModal({
    @required this.download,
    @required this.document,
  });

  Future<String> _findLocalPath() async {
    final directory = await getExternalStorageDirectory();
    return directory.path;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: Text("Notice"),
      message: Text(document.data()["title"]),
      actions: [
        CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
            String link = "http://www.ipu.ac.in${document.data()["url"]}";
            _launchURL(link);
          },
          child: Text("View"),
        ),
        download
            ? CupertinoActionSheetAction(
                isDefaultAction: false,
                onPressed: () async {
                  Navigator.pop(context);
                  var status = await Permission.storage.status;
                  if (!status.isGranted) {
                    await Permission.storage.request();
                  }
                  String link = "http://www.ipu.ac.in${document.data()["url"]}";
                  String _localPath = (await _findLocalPath()) + '/Notices';
                  final savedDir = Directory(_localPath);
                  bool hasExisted = await savedDir.exists();
                  if (!hasExisted) {
                    savedDir.create();
                  }
                  final f = Random();
                  String name = "";
                  for (int i = 0; i < 10; i++) {
                    name = name + f.nextInt(9).toString();
                  }
                  final taskId = await FlutterDownloader.enqueue(
                    url: link,
                    fileName:
                        '${document.data()["title"].toString().replaceAll("/", "")} $name.pdf',
                    savedDir: _localPath,
                    showNotification: true,
                    openFileFromNotification: true,
                  );
                  print(_localPath);
                },
                child: Text("Save to Storage"),
              )
            : Container(),
        CupertinoActionSheetAction(
          isDefaultAction: false,
          onPressed: () {
            Navigator.pop(context);
            String link = "http://www.ipu.ac.in${document.data()["url"]}";
            Share.share("${document.data()["title"]} ->\n$link");
          },
          child: Text("Share"),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: false,
        isDestructiveAction: true,
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text("Cancel"),
      ),
    );
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

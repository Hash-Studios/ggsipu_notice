import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:ggsipu_notice/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

class NoticeTile extends StatelessWidget {
  const NoticeTile({
    Key key,
    @required this.document,
    @required this.download,
  }) : super(key: key);

  final DocumentSnapshot document;
  final bool download;

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<String> _findLocalPath() async {
    final directory = await getExternalStorageDirectory();
    return directory.path;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: CupertinoContextMenu(
          previewBuilder: (context, animation, child) => Card(
            color: prefs.get('theme') == 0
                ? Color(0xFFDDDDDD)
                : prefs.get('theme') == 1
                    ? Color(0xFF222222)
                    : Colors.black,
            elevation: 0,
            margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: ListTile(
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              leading: Container(
                padding: EdgeInsets.only(right: 12.0),
                decoration: new BoxDecoration(
                    border: new Border(
                        right: new BorderSide(
                            width: 1.0,
                            color: NeumorphicTheme.defaultTextColor(context)
                                .withOpacity(0.1)))),
                child: Icon(CupertinoIcons.doc_text,
                    color: Colors.red[400], size: 30.0),
              ),
              title: Text(
                (document.data() as Map)["title"],
                style: TextStyle(
                  color: prefs.get('theme') == 0
                      ? Color(0xFF333333)
                      : prefs.get('theme') == 1
                          ? Color(0xFFDDDDDD)
                          : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: Row(
                children: <Widget>[
                  Icon(
                    Icons.calendar_today,
                    color: Colors.yellow[400],
                    size: 12,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      " ${(document.data() as Map)["date"]}",
                      style: TextStyle(
                        color: prefs.get('theme') == 0
                            ? Color(0xFF333333).withOpacity(0.8)
                            : prefs.get('theme') == 1
                                ? Color(0xFFDDDDDD).withOpacity(0.8)
                                : Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          actions: download
              ? [
                  CupertinoContextMenuAction(
                    child: Text("View Notice"),
                    isDefaultAction: true,
                    trailingIcon: CupertinoIcons.doc_text,
                    onPressed: () {
                      Navigator.pop(context);
                      String link =
                          "http://www.ipu.ac.in${(document.data() as Map)["url"]}";
                      _launchURL(link);
                    },
                  ),
                  CupertinoContextMenuAction(
                    child: Text("Download"),
                    trailingIcon: CupertinoIcons.cloud_download,
                    onPressed: () async {
                      Navigator.pop(context);
                      var status = await Permission.storage.status;
                      if (!status.isGranted) {
                        await Permission.storage.request();
                      }
                      String link =
                          "http://www.ipu.ac.in${(document.data() as Map)["url"]}";
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
                            '${(document.data() as Map)["title"].toString().replaceAll("/", "")} $name.pdf',
                        savedDir: _localPath,
                        showNotification: true,
                        openFileFromNotification: true,
                      );
                      print(_localPath);
                    },
                  ),
                  CupertinoContextMenuAction(
                    child: Text("Share"),
                    trailingIcon: CupertinoIcons.share,
                    onPressed: () {
                      Navigator.pop(context);
                      String link =
                          "http://www.ipu.ac.in${(document.data() as Map)["url"]}";
                      Share.share(
                          "$link\n${(document.data() as Map)["title"]}");
                    },
                  )
                ]
              : [
                  CupertinoContextMenuAction(
                    child: Text("View Notice"),
                    isDefaultAction: true,
                    trailingIcon: CupertinoIcons.doc_text,
                    onPressed: () {
                      Navigator.pop(context);
                      String link =
                          "http://www.ipu.ac.in${(document.data() as Map)["url"]}";
                      _launchURL(link);
                    },
                  ),
                  CupertinoContextMenuAction(
                    child: Text("Share"),
                    trailingIcon: CupertinoIcons.share,
                    onPressed: () {
                      Navigator.pop(context);
                      String link =
                          "http://www.ipu.ac.in${(document.data() as Map)["url"]}";
                      Share.share(
                          "$link\n${(document.data() as Map)["title"]}");
                    },
                  )
                ],
          child: Card(
            color: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Neumorphic(
              duration: Duration.zero,
              style: NeumorphicStyle(
                shape: NeumorphicShape.flat,
                depth: 4,
                color: prefs.get('theme') == 0
                    ? Color(0xFFDDDDDD)
                    : prefs.get('theme') == 1
                        ? Color(0xFF222222)
                        : Colors.black,
              ),
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
              child: ListTile(
                enableFeedback: true,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                onLongPress: () {
                  debugPrint("Long Press");
                },
                onTap: () {
                  String link =
                      "http://www.ipu.ac.in${(document.data() as Map)["url"]}";
                  _launchURL(link);
                },
                contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                leading: Container(
                  padding: EdgeInsets.only(right: 12.0),
                  decoration: new BoxDecoration(
                      border: new Border(
                          right: new BorderSide(
                              width: 1.0,
                              color: NeumorphicTheme.defaultTextColor(context)
                                  .withOpacity(0.1)))),
                  child: Icon(CupertinoIcons.doc_text,
                      color: Colors.red[400], size: 30.0),
                ),
                title: Text(
                  (document.data() as Map)["title"],
                  style: TextStyle(
                    color: NeumorphicTheme.defaultTextColor(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Row(
                  children: <Widget>[
                    Icon(
                      Icons.calendar_today,
                      color: Colors.yellow[400],
                      size: 12,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        " ${(document.data() as Map)["date"]}",
                        style: TextStyle(
                          color: NeumorphicTheme.defaultTextColor(context)
                              .withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

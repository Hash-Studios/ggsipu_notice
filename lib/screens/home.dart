import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ggsipu_notice/ui/about.dart';
import 'package:ggsipu_notice/ui/noticetile.dart';
import 'package:ggsipu_notice/ui/themeswitch.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final databaseReference =
      FirebaseDatabase.instance.reference().child("notices");
  List lists = [];
  bool priority = false;
  List priorityLists;
  List latestLists;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            leading: AboutButton(),
            trailing: ThemeSwitchButton(),
            automaticallyImplyLeading: false,
            padding: EdgeInsetsDirectional.zero,
            largeTitle: Text(
              widget.title,
              style: TextStyle(
                color: NeumorphicTheme.defaultTextColor(context),
              ),
            ),
            backgroundColor: NeumorphicTheme.accentColor(context),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () {
              return Future<void>.delayed(const Duration(seconds: 1))
                ..then<void>((_) {
                  if (mounted) {
                    http.get("https://ggsipu-notices.herokuapp.com/");
                    setState(() {});
                  }
                });
            },
          ),
          FutureBuilder(
            future: databaseReference.once(),
            builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
              print("Loading data from Realtime Database");
              print(snapshot.connectionState);
              if (snapshot.hasData) {
                print("Data Loaded");
                lists = [];
                List<dynamic> values = snapshot.data.value;
                lists = values;
                latestLists = lists;
                return new SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 5, 20),
                          child: Row(
                            children: [
                              Text(
                                priority ? "Priority" : "Latest",
                                style: TextStyle(
                                  color:
                                      NeumorphicTheme.defaultTextColor(context)
                                          .withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                ),
                              ),
                              Spacer(),
                              ClipOval(
                                child: Material(
                                  elevation: 0,
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(500),
                                  child: IconButton(
                                    icon: priority
                                        ? Icon(CupertinoIcons.time)
                                        : Icon(CupertinoIcons.star),
                                    color: NeumorphicTheme.defaultTextColor(
                                            context)
                                        .withOpacity(0.8),
                                    onPressed: () {
                                      setState(() {
                                        priority = !priority;
                                      });
                                      priorityLists = [];
                                      lists.forEach(
                                        (element) {
                                          element["title"]
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains("datesheet")
                                              ? priorityLists.add(element)
                                              : element["title"]
                                                      .toString()
                                                      .toLowerCase()
                                                      .contains("final")
                                                  ? priorityLists.add(element)
                                                  : element["title"]
                                                          .toString()
                                                          .toLowerCase()
                                                          .contains("exam")
                                                      ? priorityLists
                                                          .add(element)
                                                      : element["title"]
                                                              .toString()
                                                              .toLowerCase()
                                                              .contains(
                                                                  "examination")
                                                          ? priorityLists
                                                              .add(element)
                                                          : print("");
                                        },
                                      );
                                      print(priorityLists.length);
                                      print(latestLists.length);
                                    },
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      }
                      if (priority
                          ? index == priorityLists.length + 1
                          : index == latestLists.length + 1) {
                        return SizedBox(height: 20);
                      }
                      if (priorityLists != null) {
                        if (priorityLists.isEmpty && priority) {
                          return SizedBox(
                            height: MediaQuery.of(context).size.height - 400.0,
                            width: MediaQuery.of(context).size.width,
                            child: Center(
                              child: Text(
                                "No Priority Notices!",
                                style: TextStyle(
                                  color:
                                      NeumorphicTheme.defaultTextColor(context),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          );
                        }
                      }
                      return NoticeTile(
                        lists: priority ? priorityLists : latestLists,
                        index: index - 1,
                        func: () async {
                          // HapticFeedback.vibrate();
                          bool download = priority
                              ? priorityLists[index - 1]["url"]
                                  .toString()
                                  .toLowerCase()
                                  .contains(".pdf")
                              : latestLists[index - 1]["url"]
                                  .toString()
                                  .toLowerCase()
                                  .contains(".pdf");
                          showCupertinoModalPopup(
                              context: context,
                              builder: (BuildContext context) => ActionModal(
                                    download: download,
                                    lists:
                                        priority ? priorityLists : latestLists,
                                    index: index - 1,
                                  ));
                        },
                      );
                    },
                    childCount: priority
                        ? priorityLists.length == 0
                            ? priorityLists.length + 3
                            : priorityLists.length + 2
                        : latestLists.length + 2,
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 200.0,
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                          child: CupertinoActivityIndicator(
                            animating: true,
                            radius: 20,
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: 1,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ActionModal extends StatelessWidget {
  final download;
  final lists;
  final index;
  ActionModal({
    @required this.download,
    @required this.lists,
    @required this.index,
  });

  Future<String> _findLocalPath() async {
    final directory = await getExternalStorageDirectory();
    return directory.path;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: Text("Notice"),
      message: Text(lists[index]["title"]),
      actions: [
        CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
            String link = "http://www.ipu.ac.in${lists[index]["url"]}";
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
                  String link = "http://www.ipu.ac.in${lists[index]["url"]}";
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
                        '${lists[index]["title"].toString().replaceAll("/", "")} $name.pdf',
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
            String link = "http://www.ipu.ac.in${lists[index]["url"]}";
            Share.share("${lists[index]["title"]} ->\n$link");
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

import 'package:flutter/services.dart';
// import 'package:ggsipu_notice/keys.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ggsipu_notice/ui/about.dart';
import 'package:ggsipu_notice/ui/noticetile.dart';
import 'package:ggsipu_notice/ui/themeswitch.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Timer _timerForInter;

  // MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
  //   keywords: <String>['flutterio', 'beautiful apps'],
  //   contentUrl: 'https://flutter.io',
  //   childDirected: false,
  //   // testDevices: <String>["9033810B9AD198E151CFEC2CB5073E2B"],
  //   testDevices: <String>[],
  // );
  // InterstitialAd _interstitialAd;

  // InterstitialAd createInterstitialAd(int index) {
  //   return InterstitialAd(
  //     // adUnitId: InterstitialAd.testAdUnitId,
  //     adUnitId: adUnitId,
  //     targetingInfo: targetingInfo,
  //     listener: (MobileAdEvent event) {
  //       print("InterstitialAd event $event");
  //       if (event == MobileAdEvent.closed) {
  //         print('Interstitial closed');
  //         if (index != null) {
  //           Navigator.pop(context);
  //           String link = "http://www.ipu.ac.in${lists[index]["url"]}";
  //           _launchURL(link);
  //         }
  //       } else if (event == MobileAdEvent.failedToLoad) {
  //         if (index != null) {
  //           Navigator.pop(context);
  //           String link = "http://www.ipu.ac.in${lists[index]["url"]}";
  //           _launchURL(link);
  //         }
  //       }
  //     },
  //   );
  // }

  @override
  void initState() {
    // FirebaseAdMob.instance.initialize(appId: appId);
    super.initState();
  }

  @override
  void dispose() {
    // _timerForInter.cancel();
    // _interstitialAd.dispose();
    super.dispose();
  }

  final databaseReference =
      FirebaseDatabase.instance.reference().child("notices");
  List lists = [];

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
                return new SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return NoticeTile(
                        lists: lists,
                        index: index,
                        func: () async {
                          HapticFeedback.vibrate();
                          // showCupertinoDialog(
                          //     context: context,
                          //     barrierDismissible: false,
                          //     builder: (BuildContext context) =>
                          //         CupertinoAlertDialog(
                          //           content: Padding(
                          //             padding: const EdgeInsets.all(8.0),
                          //             child: CupertinoActivityIndicator(),
                          //           ),
                          //         ));
                          // var _interstitialAd1 = createInterstitialAd(index);
                          // await _interstitialAd1.load();
                          // _interstitialAd1.show();
                          // Navigator.pop(context);
                          Fluttertoast.showToast(
                            msg: "Tap and hold to download the notice.",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.CENTER,
                          );
                          String link =
                              "http://www.ipu.ac.in${lists[index]["url"]}";
                          _launchURL(link);
                        },
                        dfunc: () async {
                          HapticFeedback.vibrate();
                          showCupertinoModalPopup(
                              context: context,
                              builder: (BuildContext context) =>
                                  CupertinoActionSheet(
                                    actions: [
                                      CupertinoActionSheetAction(
                                        isDefaultAction: true,
                                        onPressed: () {
                                          String link =
                                              "http://www.ipu.ac.in${lists[index]["url"]}";
                                          _launchURL(link);
                                        },
                                        child: Text("Download"),
                                      )
                                    ],
                                  ));
                        },
                      );
                    },
                    childCount: lists.length,
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

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

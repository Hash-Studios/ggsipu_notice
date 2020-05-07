import 'package:another/push_nofitications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final push = PushNotificationsManager();
    push.init();
    return CupertinoApp(
      title: 'GGSIPU Notices',
      theme: CupertinoThemeData(
          // brightness: Brightness.light,
          ),
      home: NeumorphicTheme(
        usedTheme: UsedTheme.SYSTEM,
        theme: NeumorphicThemeData(
          baseColor: Color(0xFFDDDDDD),
          accentColor: Color(0x00CCCCCC),
          defaultTextColor: Color(0xFF333333),
          shadowLightColor: Color(0xFFFFFFFF),
          shadowDarkColor: Color(0xFFAAAAAA),
          intensity: 0.6,
          lightSource: LightSource.topLeft,
          depth: 8,
        ),
        darkTheme: NeumorphicThemeData(
          baseColor: Color(0xFF222222),
          accentColor: Color(0x00111111),
          defaultTextColor: Color(0xFFDDDDDD),
          shadowLightColor: Color(0xFF444444),
          shadowDarkColor: Color(0xFF000000),
          intensity: 0.6,
          lightSource: LightSource.topLeft,
          depth: 8,
        ),
        child: MyHomePage(title: 'GGSIPU Notices'),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      navigationBar: CupertinoNavigationBar(
        leading: Card(
          elevation: 0,
          color: Colors.transparent,
          child: IconButton(
            padding: EdgeInsets.only(bottom: 2),
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            onPressed: () {
              showCupertinoDialog(
                  context: context,
                  builder: (BuildContext context) => CupertinoAlertDialog(
                        title: new Text("GGSIPU Notices"),
                        content: Column(
                          children: <Widget>[
                            Padding(
                                padding: EdgeInsets.only(top: 20),
                                child: Text("Developed and Maintained by")),
                            Card(
                              elevation: 0,
                              color: Colors.transparent,
                              child: new ListTile(
                                contentPadding:
                                    EdgeInsets.fromLTRB(20, 10, 5, 10),
                                leading: Container(
                                    padding: EdgeInsets.only(right: 12.0),
                                    decoration: new BoxDecoration(
                                      border: new Border(
                                        right: new BorderSide(
                                            width: 1.0, color: Colors.white54),
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      backgroundImage:
                                          AssetImage("assets/images/dev.png"),
                                    )),
                                title: Text(
                                  "Abhay Maurya",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "ECE, USICT",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                        actions: <Widget>[
                          CupertinoDialogAction(
                            child: Text("Github"),
                            onPressed: () {
                              Navigator.of(context).pop();
                              String link =
                                  "https://www.github.com/LiquidatorCoder";
                              _launchURL(link);
                            },
                          ),
                          CupertinoDialogAction(
                            child: Text("LinkedIn"),
                            onPressed: () {
                              Navigator.of(context).pop();
                              String link =
                                  "https://www.linkedin.com/in/liquidatorcoder/";
                              _launchURL(link);
                            },
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: Text("Back"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          )
                        ],
                      ));
            },
            icon: Icon(
              NeumorphicTheme.isUsingDark(context)
                  ? CupertinoIcons.info
                  : CupertinoIcons.info,
            ),
            color: NeumorphicTheme.defaultTextColor(context),
            iconSize: 20,
          ),
        ),
        trailing: Card(
          elevation: 0,
          color: Colors.transparent,
          child: IconButton(
            padding: EdgeInsets.only(bottom: 2),
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            onPressed: () {
              NeumorphicTheme.of(context).usedTheme =
                  NeumorphicTheme.isUsingDark(context)
                      ? UsedTheme.LIGHT
                      : UsedTheme.DARK;
            },
            icon: Icon(
              NeumorphicTheme.isUsingDark(context)
                  ? CupertinoIcons.brightness
                  : CupertinoIcons.brightness_solid,
            ),
            color: NeumorphicTheme.defaultTextColor(context),
          ),
        ),
        middle: Text(
          widget.title,
          style: TextStyle(
            color: NeumorphicTheme.defaultTextColor(context),
          ),
        ),
        backgroundColor: NeumorphicTheme.accentColor(context),
      ),
      child: Center(
        child: FutureBuilder(
          future: databaseReference.once(),
          builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
            if (snapshot.hasData) {
              lists = [];
              List<dynamic> values = snapshot.data.value;
              lists = values;
              return new ListView.builder(
                shrinkWrap: true,
                itemCount: lists.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    color: NeumorphicTheme.accentColor(context),
                    elevation: 0,
                    margin: new EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 6.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Neumorphic(
                      style: NeumorphicStyle(
                          shape: NeumorphicShape.flat, depth: 4),
                      boxShape: NeumorphicBoxShape.roundRect(
                          borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                          contentPadding: EdgeInsets.fromLTRB(20, 10, 5, 10),
                          leading: Container(
                            padding: EdgeInsets.only(right: 12.0),
                            decoration: new BoxDecoration(
                                border: new Border(
                                    right: new BorderSide(
                                        width: 1.0,
                                        color: NeumorphicTheme.accentColor(
                                            context)))),
                            child: Icon(Icons.picture_as_pdf,
                                color: Colors.red[400], size: 30.0),
                          ),
                          title: Text(
                            lists[index]["title"],
                            style: TextStyle(
                                color:
                                    NeumorphicTheme.defaultTextColor(context),
                                fontWeight: FontWeight.bold),
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
                                child: Text(" ${lists[index]["date"]}",
                                    style: TextStyle(
                                        color: NeumorphicTheme.defaultTextColor(
                                            context))),
                              )
                            ],
                          ),
                          trailing: NeumorphicButton(
                            style: NeumorphicStyle(
                                shape: NeumorphicShape.flat, depth: 2),
                            boxShape: NeumorphicBoxShape.circle(),
                            child: Icon(Icons.keyboard_arrow_right,
                                color:
                                    NeumorphicTheme.defaultTextColor(context),
                                size: 30.0),
                            onClick: () {
                              String link =
                                  "http://www.ipu.ac.in${lists[index]["url"]}";
                              _launchURL(link);
                            },
                          )),
                    ),
                  );
                },
              );
            }
            return CupertinoActivityIndicator(
              animating: true,
              radius: 20,
            );
          },
        ),
      ),
    );
  }
}

_launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

// NeumorphicButton(
//           onClick: () {
// NeumorphicTheme.of(context).usedTheme =
//     NeumorphicTheme.isUsingDark(context)
//         ? UsedTheme.LIGHT
//         : UsedTheme.DARK;
//           },
//           style: NeumorphicStyle(shape: NeumorphicShape.flat),
//           boxShape: NeumorphicBoxShape.circle(),
//           padding: const EdgeInsets.all(12.0),
//           child: Icon(
//             CupertinoIcons.heart,
//             color: NeumorphicTheme.defaultTextColor(context),
//           ),
//         ),

// Navigator.push(
//                                 context,
//                                 CupertinoPageRoute(builder: (context) {
//                                   return WebPage(notice: lists[index]);
//                                 }),
//                               );

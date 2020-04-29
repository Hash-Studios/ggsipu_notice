import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:firebase_database/firebase_database.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'GGSIPU Notices',
      theme: CupertinoThemeData(
          // brightness: Brightness.light,
          ),
      home: NeumorphicTheme(
        usedTheme: UsedTheme.LIGHT,
        theme: NeumorphicThemeData(
          baseColor: Color(0xFFDDDDDD),
          accentColor: Color(0xFFCCCCCC),
          defaultTextColor: Color(0xFF333333),
          shadowLightColor: Color(0xFFFFFFFF),
          shadowDarkColor: Color(0xFFAAAAAA),
          intensity: 0.6,
          lightSource: LightSource.topLeft,
          depth: 8,
        ),
        darkTheme: NeumorphicThemeData(
          baseColor: Color(0xFF3E3E3E),
          accentColor: Color(0xFF4F4F4F),
          defaultTextColor: Color(0xFFEEEEEE),
          shadowLightColor: Color(0xFF666666),
          shadowDarkColor: Color(0xFF111111),
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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      navigationBar: CupertinoNavigationBar(
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
                      child: ListTile(
                          contentPadding: EdgeInsets.fromLTRB(20, 10, 5, 10),
                          leading: Container(
                            padding: EdgeInsets.only(right: 12.0),
                            decoration: new BoxDecoration(
                                border: new Border(
                                    right: new BorderSide(
                                        width: 1.0, color: Colors.white24))),
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
                          // subtitle: Text("Intermediate", style: TextStyle(color: Colors.white)),

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
                                shape: NeumorphicShape.flat, depth: -2),
                            boxShape: NeumorphicBoxShape.circle(),
                            child: Icon(Icons.keyboard_arrow_right,
                                color:
                                    NeumorphicTheme.defaultTextColor(context),
                                size: 30.0),
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

// NeumorphicButton(
//           onClick: () {
//             NeumorphicTheme.of(context).usedTheme =
//                 NeumorphicTheme.isUsingDark(context)
//                     ? UsedTheme.LIGHT
//                     : UsedTheme.DARK;
//           },
//           style: NeumorphicStyle(shape: NeumorphicShape.flat),
//           boxShape: NeumorphicBoxShape.circle(),
//           padding: const EdgeInsets.all(12.0),
//           child: Icon(
//             CupertinoIcons.heart,
//             color: NeumorphicTheme.defaultTextColor(context),
//           ),
//         ),

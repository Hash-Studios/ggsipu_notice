import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:another/ui/about.dart';
import 'package:another/ui/noticetile.dart';
import 'package:another/ui/themeswitch.dart';

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
        leading: AboutButton(),
        trailing: ThemeSwitchButton(),
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
                  return NoticeTile(lists: lists, index: index);
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

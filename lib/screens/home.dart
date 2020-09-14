import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:another/ui/about.dart';
import 'package:another/ui/noticetile.dart';
import 'package:another/ui/themeswitch.dart';
import 'package:http/http.dart' as http;

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
              if (snapshot.hasData) {
                lists = [];
                List<dynamic> values = snapshot.data.value;
                lists = values;
                return new SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return NoticeTile(lists: lists, index: index);
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
}

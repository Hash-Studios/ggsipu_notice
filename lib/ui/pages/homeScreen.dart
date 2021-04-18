import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:ggsipu_notice/ui/widgets/about.dart';
import 'package:ggsipu_notice/ui/widgets/newNoticeTile.dart';
import 'package:ggsipu_notice/ui/widgets/themeswitch.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Query notices = FirebaseFirestore.instance
        .collection('notices')
        .orderBy('createdAt', descending: true);
    return CupertinoPageScaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            leading: AboutButton(),
            trailing: ThemeSwitchButton(),
            automaticallyImplyLeading: false,
            padding: EdgeInsetsDirectional.zero,
            largeTitle: Text(
              'Notices',
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
                  // if (mounted) {
                  //   // http.get(Uri.parse("https://ggsipu-notices.herokuapp.com/"));
                  //   setState(() {});
                  // }
                });
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: notices.snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
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
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
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
              }

              return SliverList(delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return NewNoticeTile(
                    document: snapshot.data.docs[index],
                    func: () {},
                  );
                },
              ));
            },
          )
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:ggsipu_notice/ui/widgets/about.dart';
import 'package:ggsipu_notice/ui/widgets/newNoticeTile.dart';
import 'package:ggsipu_notice/ui/widgets/themeswitch.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool priorityCheck = false;

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
                ..then<void>((_) {});
            },
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 5, 8),
                    child: Row(
                      children: [
                        Text(
                          priorityCheck ? "Priority" : "Latest",
                          style: TextStyle(
                            color: NeumorphicTheme.defaultTextColor(context)
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
                              icon: priorityCheck
                                  ? Icon(CupertinoIcons.star)
                                  : Icon(CupertinoIcons.time),
                              color: NeumorphicTheme.defaultTextColor(context)
                                  .withOpacity(0.8),
                              onPressed: () {
                                setState(() {
                                  priorityCheck = !priorityCheck;
                                });
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
              childCount: 1,
            ),
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
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final bool download = snapshot.data.docs[index]['url']
                        .toString()
                        .toLowerCase()
                        .contains(".pdf");
                    if (priorityCheck) {
                      if (snapshot.data.docs[index]['priority']) {
                        return NewNoticeTile(
                          download: download,
                          document: snapshot.data.docs[index],
                        );
                      }
                    } else {
                      return NewNoticeTile(
                        download: download,
                        document: snapshot.data.docs[index],
                      );
                    }
                    return Container();
                  },
                  childCount: snapshot.data.docs.length,
                ),
              );
            },
          )
        ],
      ),
    );
  }
}

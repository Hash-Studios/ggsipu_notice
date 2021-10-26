import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ip_notices/models/notice.dart';
import 'package:ip_notices/notifiers/firestore_notifier.dart';
import 'package:ip_notices/services/logger.dart';
import 'package:ip_notices/widgets/about_button.dart';
import 'package:ip_notices/widgets/notice_tile.dart';
import 'package:ip_notices/widgets/theme_switch.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = false;
  ScrollController controller = ScrollController();
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration())
        .then((value) => context.read<FirestoreNotifier>().initNoticeStream());
    controller.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (controller.position.pixels == controller.position.maxScrollExtent) {
      logger.d("at the end of list");
      setState(() {
        context.read<FirestoreNotifier>().loadMore();
      });
      logger.i(context.read<FirestoreNotifier>().limit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.white,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        controller: controller,
        slivers: [
          const CupertinoSliverNavigationBar(
            leading: AboutButton(),
            trailing: ThemeSwitchButton(),
            border: null,
            automaticallyImplyLeading: false,
            padding: EdgeInsetsDirectional.zero,
            largeTitle: Text(
              'Notices',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            backgroundColor: Colors.transparent,
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () {
              context.read<FirestoreNotifier>().initNoticeStream();
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
                          context.watch<FirestoreNotifier>().priorityCheck
                              ? "Priority"
                              : "Latest",
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        const Spacer(),
                        ClipOval(
                          child: Material(
                            elevation: 0,
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(500),
                            child: IconButton(
                              icon: context
                                      .watch<FirestoreNotifier>()
                                      .priorityCheck
                                  ? const Icon(CupertinoIcons.star)
                                  : const Icon(CupertinoIcons.time),
                              color: Colors.black.withOpacity(0.8),
                              onPressed: () {
                                context
                                    .read<FirestoreNotifier>()
                                    .togglePriorityCheck();
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
          StreamBuilder<List<Notice>>(
            stream: context.watch<FirestoreNotifier>().noticesStream,
            builder:
                (BuildContext context, AsyncSnapshot<List<Notice>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                loading = true;
              } else {
                loading = false;
              }
              if (snapshot.hasError) {
                logger.e(snapshot.error);
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height - 200.0,
                          width: MediaQuery.of(context).size.width,
                          child: Center(
                            child: Icon(
                              CupertinoIcons.multiply_circle,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: 1,
                  ),
                );
              }
              if (snapshot.hasData) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      if (index == snapshot.data?.length) {
                        return SizedBox(
                          height: 100,
                          width: 100,
                          child: Center(
                              child: loading
                                  ? CupertinoActivityIndicator(
                                      animating: true,
                                      radius: 14,
                                    )
                                  : Container()),
                        );
                      }
                      final bool download = snapshot.data?[index].url
                              .toString()
                              .toLowerCase()
                              .contains(".pdf") ??
                          false;
                      if (context.watch<FirestoreNotifier>().priorityCheck) {
                        if (snapshot.data?[index].priority ?? false) {
                          return NoticeTile(
                            download: download,
                            document: snapshot.data?[index],
                          );
                        }
                      } else {
                        return NoticeTile(
                          download: download,
                          document: snapshot.data?[index],
                        );
                      }
                      return Container();
                    },
                    childCount: snapshot.data?.length ?? 0 + 1,
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
          )
        ],
      ),
    );
  }
}

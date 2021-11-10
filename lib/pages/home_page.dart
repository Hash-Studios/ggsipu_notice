import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:ip_notices/models/notice.dart';
import 'package:ip_notices/notifiers/firestore_notifier.dart';
import 'package:ip_notices/services/locator.dart';
import 'package:ip_notices/services/logger.dart';
import 'package:ip_notices/services/theme_service.dart';
import 'package:ip_notices/widgets/about_button.dart';
import 'package:ip_notices/widgets/notice_tile.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    final _themeService = locator<ThemeService>();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            MediaQuery.of(context).platformBrightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
        statusBarBrightness:
            MediaQuery.of(context).platformBrightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
      ),
    );
    return CupertinoPageScaffold(
      backgroundColor: _themeService.background(context),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          controller: controller,
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () {
                context.read<FirestoreNotifier>().initNoticeStream();
                return Future<void>.delayed(const Duration(seconds: 1))
                  ..then<void>((_) {});
              },
            ),
            CupertinoSliverNavigationBar(
              brightness: Theme.of(context).brightness == Brightness.dark
                  ? Brightness.dark
                  : Brightness.light,
              leading: const AboutButton(),
              border: Border(
                  bottom: BorderSide(
                      color:
                          _themeService.onBackground(context).withOpacity(0.1),
                      width: 1)),
              automaticallyImplyLeading: false,
              padding: EdgeInsetsDirectional.zero,
              stretch: true,
              largeTitle: Text(
                'Notices',
                style: TextStyle(
                  color: _themeService.onBackground(context),
                ),
              ),
              backgroundColor: _themeService.background(context),
            ),
            SliverToBoxAdapter(
              child: Material(
                color: _themeService.background(context),
                child: InkWell(
                  onTap: () {
                    context.read<FirestoreNotifier>().togglePriorityCheck();
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Row(
                      children: [
                        Text(
                          context.watch<FirestoreNotifier>().priorityCheck
                              ? "Priority"
                              : "Latest",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: _themeService.onBackground(context),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          context.watch<FirestoreNotifier>().priorityCheck
                              ? CupertinoIcons.star
                              : CupertinoIcons.time,
                          color: _themeService
                              .onBackground(context)
                              .withOpacity(0.8),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            StreamBuilder<List<Notice>>(
              stream: context.watch<FirestoreNotifier>().noticesStream,
              builder:
                  (BuildContext context, AsyncSnapshot<List<Notice>> snapshot) {
                if (snapshot.hasError) {
                  logger.e(snapshot.error);
                  return SliverToBoxAdapter(
                    child: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.8,
                        width: MediaQuery.of(context).size.width,
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.multiply_circle,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                if (snapshot.hasData) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        if (index == (snapshot.data?.length ?? 0) - 1) {
                          return const SizedBox(
                            height: 100,
                            width: 100,
                            child: Center(
                                child: CupertinoActivityIndicator(
                              animating: true,
                              radius: 14,
                            )),
                          );
                        }
                        final bool download = snapshot.data?[index].url
                                .toString()
                                .toLowerCase()
                                .contains(".pdf") ??
                            false;
                        return NoticeTile(
                          download: download,
                          document: snapshot.data?[index],
                        );
                      },
                      childCount: snapshot.data?.length ?? 0,
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.8,
                          width: MediaQuery.of(context).size.width,
                          child: const Center(
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
      ),
    );
  }
}

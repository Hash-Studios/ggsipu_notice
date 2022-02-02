import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ip_notices/models/notice.dart';
import 'package:ip_notices/notifiers/algolia_notifier.dart';
import 'package:ip_notices/notifiers/firestore_notifier.dart';
import 'package:ip_notices/services/locator.dart';
import 'package:ip_notices/services/logger.dart';
import 'package:ip_notices/services/theme_service.dart';
import 'package:ip_notices/widgets/about_button.dart';
import 'package:ip_notices/widgets/error_sliver.dart';
import 'package:ip_notices/widgets/go_to_top_fab.dart';
import 'package:ip_notices/widgets/loading_sliver.dart';
import 'package:ip_notices/widgets/notice_tile.dart';
import 'package:ip_notices/widgets/search_bar.dart';
import 'package:ip_notices/widgets/search_button.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ScrollController controller = ScrollController();
  TextEditingController searchController = TextEditingController();
  late FocusNode searchFocusNode;

  String? query;
  bool showFab = false;
  bool showSearch = false;
  bool animating = false;

  void _scrollListener() {
    if (controller.position.pixels <= 10 && animating) {
      setState(() {
        animating = false;
      });
    }
    if (controller.position.pixels >= 100 && showSearch == false) {
      logger.d("Search Shown");
      setState(() {
        showSearch = true;
      });
      FocusScopeNode currentFocus = FocusScope.of(context);

      if (!currentFocus.hasPrimaryFocus) {
        currentFocus.unfocus();
      }
    }
    if (controller.position.pixels < 100 && showSearch == true) {
      logger.d("Search Hidden");
      setState(() {
        showSearch = false;
      });
    }
    if (controller.position.pixels >= 380 && showFab == false && !animating) {
      logger.d("FAB Shown");
      setState(() {
        showFab = true;
      });
    }
    if (controller.position.pixels < 380 && showFab == true && !animating) {
      logger.d("FAB Hidden");
      setState(() {
        showFab = false;
      });
    }
    if (controller.position.pixels == controller.position.maxScrollExtent) {
      logger.d("at the end of list");
      setState(() {
        context.read<FirestoreNotifier>().loadMore();
      });
      logger.i(context.read<FirestoreNotifier>().limit);
    }
  }

  @override
  void initState() {
    super.initState();
    searchFocusNode = FocusNode();
    Future.delayed(const Duration())
        .then((value) => context.read<FirestoreNotifier>().initNoticeStream());
    controller.addListener(_scrollListener);
  }

  @override
  void dispose() {
    searchFocusNode.dispose();
    searchController.dispose();
    controller.dispose();
    super.dispose();
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

    onChanged(value) {
      if (value.trim().isNotEmpty) {
        setState(() {
          query = value;
        });
        context.read<AlgoliaNotifier>().getNoticeSearch(value);
      }
    }

    onPressed() {
      setState(() {
        animating = true;
      });
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      searchFocusNode.requestFocus();
    }

    onFABPressed() {
      setState(() {
        showFab = false;
        animating = true;
      });
      controller.animateTo(0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic);
    }

    return CupertinoPageScaffold(
      backgroundColor: _themeService.background(context),
      child: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
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
                          color: _themeService
                              .onBackground(context)
                              .withOpacity(0.1),
                          width: 1)),
                  automaticallyImplyLeading: false,
                  trailing: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: showSearch
                        ? SearchButton(
                            onPressed: onPressed,
                          )
                        : null,
                  ),
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
                SearchBar(
                  searchController: searchController,
                  searchFocusNode: searchFocusNode,
                  onChanged: onChanged,
                ),
                (searchController.text.trim().isNotEmpty)
                    ? () {
                        final snapshot =
                            context.watch<AlgoliaNotifier>().snapshot;
                        if (snapshot?.empty ?? false) {
                          // logger.e(snapshot.error);
                          return const ErrorSliver();
                        }
                        if (snapshot?.hits.isNotEmpty ?? false) {
                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (BuildContext context, int index) {
                                if (index == (snapshot?.hits.length ?? 0)) {
                                  return const SizedBox(
                                    height: 100,
                                    width: 100,
                                  );
                                }
                                final bool? download = snapshot
                                    ?.hits[index].data['url']
                                    .toString()
                                    .toLowerCase()
                                    .contains(".pdf");
                                final Map? map = snapshot?.hits[index].data;
                                return NoticeTile(
                                  key: ValueKey(map?['title']),
                                  download: download ?? false,
                                  document: Notice.fromJson(
                                      map as Map<String, dynamic>),
                                );
                              },
                              childCount: (snapshot?.hits.length ?? 0) + 1,
                            ),
                          );
                        }
                        return const LoadingSliver();
                      }()
                    : StreamBuilder<List<Notice>>(
                        stream:
                            context.watch<FirestoreNotifier>().noticesStream,
                        builder: (BuildContext context,
                            AsyncSnapshot<List<Notice>> snapshot) {
                          if (snapshot.hasError) {
                            logger.e(snapshot.error);
                            return const ErrorSliver();
                          }
                          if (snapshot.hasData) {
                            return SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (BuildContext context, int index) {
                                  if (index ==
                                      (snapshot.data?.length ?? 0) - 1) {
                                    return const SizedBox(
                                      height: 100,
                                      width: 100,
                                      child: Center(
                                        child: CupertinoActivityIndicator(
                                          animating: true,
                                          radius: 14,
                                        ),
                                      ),
                                    );
                                  }
                                  final bool download = snapshot
                                          .data?[index].url
                                          .toString()
                                          .toLowerCase()
                                          .contains(".pdf") ??
                                      false;
                                  return NoticeTile(
                                    key: ValueKey(snapshot.data?[index].title),
                                    download: download,
                                    document: snapshot.data?[index],
                                  );
                                },
                                childCount: snapshot.data?.length ?? 0,
                              ),
                            );
                          }
                          return const LoadingSliver();
                        },
                      )
              ],
            ),
            GoToTopFAB(
              showFab: showFab,
              onFABPressed: onFABPressed,
            ),
          ],
        ),
      ),
    );
  }
}

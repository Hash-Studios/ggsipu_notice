import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:oktoast/oktoast.dart';
import 'package:intl/intl.dart';
import 'package:ip_notices/models/notice.dart';
import 'package:ip_notices/services/locator.dart';
import 'package:ip_notices/services/logger.dart';
import 'package:ip_notices/services/theme_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

class NoticeTile extends StatefulWidget {
  const NoticeTile({
    super.key,
    required this.document,
    required this.download,
  });

  final Notice? document;
  final bool download;

  @override
  State<NoticeTile> createState() => _NoticeTileState();
}

class _NoticeTileState extends State<NoticeTile> {
  _launchURL(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      showToast("Couldn't open this link. Try again.");
    }
  }

  Future<String> _findLocalPath() async {
    final directory = await getExternalStorageDirectory()
        ?? await getApplicationDocumentsDirectory();
    return directory.path;
  }

  @override
  Widget build(BuildContext context) {
    final themeService = locator<ThemeService>();
    return Slidable(
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.4,
        children: [
          SlidableAction(
            label: 'Download',
            backgroundColor: themeService.accent(context),
            foregroundColor: themeService.onAccent(context),
            icon: CupertinoIcons.cloud_download,
            onPressed: (context) async {
              if (widget.download) {
                // path_provider's getExternalStorageDirectory() returns the
                // app-specific directory which needs no storage permission
                // on Android 4.4+ (API 19+, our minSdk).
                try {
                  final String link = widget.document?.url ?? '';
                  final String localPath = '${await _findLocalPath()}/Notices';
                  await Directory(localPath).create(recursive: true);
                  final String name = Random().nextInt(1000000000).toString();
                  final taskId = await FlutterDownloader.enqueue(
                    url: link,
                    fileName:
                        '${widget.document?.title.toString().replaceAll("/", "").replaceAll("\\", "")} $name.pdf',
                    savedDir: localPath,
                    showNotification: true,
                    openFileFromNotification: true,
                  );
                  logger.d("Task Id - $taskId | Path - $localPath");
                } catch (e) {
                  logger.e('Download failed: $e');
                  showToast('Download failed. Tap to open in browser instead.');
                }
              } else {
                _launchURL(widget.document?.url ?? '');
              }
            },
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.3,
        children: [
          SlidableAction(
            label: 'Share',
            backgroundColor: themeService.accent(context),
            foregroundColor: themeService.onAccent(context),
            icon: CupertinoIcons.share,
            onPressed: (_) {
              String link = widget.document?.url ?? '';
              Share.share("$link\n${widget.document?.title}");
            },
          ),
        ],
      ),
      child: Card(
        color: themeService.background(context),
        margin: const EdgeInsets.all(0),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0.0),
        ),
        child: Container(
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color:
                          themeService.onBackground(context).withValues(alpha:0.1),
                      width: 1))),
          child: ListTile(
            enableFeedback: true,
            onLongPress: () {
              showToast(
                "Swipe right to download, left to share.",
                duration: const Duration(seconds: 1),
                position: ToastPosition.bottom,
                textStyle: TextStyle(
                  color: themeService.onBackground(context),
                  fontSize: 16.0,
                ),
                backgroundColor:
                    themeService.background(context).withValues(alpha: 0.8),
              );
            },
            onTap: () {
              String link = widget.document?.url ?? '';
              _launchURL(link);
            },
            contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            leading:
                //  SizedBox(
                //   width: 48,
                //   height: 48,
                //   child:
                //    Stack(
                //     children: [
                //   Center(
                // child:
                CircleAvatar(
              backgroundColor: HexColor.fromHex(widget.document?.color ??
                  Colors.grey.withValues(alpha:0.3).toHex()),
              child: Text(
                widget.document?.title[0] ?? '',
                style: TextStyle(
                  color: themeService.onBackground(context).withValues(alpha:0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            // ),
            // if (downloading)
            //   Center(
            //     child: CircularProgressIndicator(
            //       value: progress == null
            //           ? null
            //           : (progress! / 100.0).clamp(0, 100),
            //       strokeWidth: 3,
            //       valueColor: AlwaysStoppedAnimation<Color>(_themeService
            //           .onBackground(context)
            //           .withValues(alpha:0.9)),
            //       backgroundColor: _themeService
            //           .onBackground(context)
            //           .withValues(alpha:0.1),
            //     ),
            //   )
            //     ],
            //   ),
            // ),
            title: Text(
              (widget.document?.college ?? '').toUpperCase().trim() != ""
                  ? (widget.document?.college ?? '').toUpperCase().trim()
                  : widget.document?.title ?? '',
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: themeService.onBackground(context),
                fontWeight:
                    (widget.document?.college ?? '').toUpperCase().trim() == ""
                        ? FontWeight.normal
                        : FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: (widget.document?.college ?? '').toUpperCase().trim() ==
                    ""
                ? ((widget.document?.tags ?? []).isNotEmpty)
                    ? null
                    // ? Padding(
                    //     padding: const EdgeInsets.only(top: 8.0),
                    //     child: SizedBox(
                    //       width: MediaQuery.of(context).size.width,
                    //       height: 40,
                    //       child: ListView(
                    //         padding: const EdgeInsets.all(0),
                    //         shrinkWrap: true,
                    //         scrollDirection: Axis.horizontal,
                    //         children: [
                    //           for (final tag in document?.tags ?? [])
                    //             Padding(
                    //               padding: const EdgeInsets.only(right: 6),
                    //               child: Tagchip(tag: tag),
                    //             ),
                    //         ],
                    //       ),
                    //     ),
                    //   )
                    : null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.document?.title ?? '',
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: themeService.onBackground(context),
                          fontSize: 14,
                        ),
                      ),
                      // if ((document?.tags ?? []).isNotEmpty)
                      //   SizedBox(
                      //     width: MediaQuery.of(context).size.width,
                      //     height: 40,
                      //     child: ListView(
                      //       scrollDirection: Axis.horizontal,
                      //       children: [
                      //         for (final tag in document?.tags ?? [])
                      //           Padding(
                      //             padding: const EdgeInsets.only(right: 6),
                      //             child: Tagchip(tag: tag),
                      //           ),
                      //       ],
                      //     ),
                      //   ),
                    ],
                  ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (timeago
                              .format(DateTime.parse(
                                  widget.document?.createdAt.toString() ?? '0'))
                              .contains('day') ||
                          timeago
                              .format(DateTime.parse(
                                  widget.document?.createdAt.toString() ?? '0'))
                              .contains('month') ||
                          timeago
                              .format(DateTime.parse(
                                  widget.document?.createdAt.toString() ?? '0'))
                              .contains('year'))
                      ? widget.document?.date.isNotEmpty == true
                          ? "${widget.document?.date.split('-')[0]} ${DateFormat('MMM').format(DateTime(0, int.parse(widget.document?.date.split('-')[1] ?? '0')))}"
                          : DateFormat('dd MMM').format(
                              widget.document?.createdAt ?? DateTime.now())
                      : timeago
                          .format(DateTime.parse(
                              widget.document?.createdAt.toString() ?? '0'))
                          .replaceAll('about', '')
                          .replaceAll('hour', 'hr')
                          .replaceAll('minute', 'min')
                          .replaceAll('ago', '')
                          .replaceAll('an', '1')
                          .trim(),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: themeService.onBackground(context).withValues(alpha:0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                // const SizedBox(
                //   height: 6,
                // ),
                // Text(
                //   (document?.college ?? '').toUpperCase().trim(),
                //   textAlign: TextAlign.end,
                //   style: TextStyle(
                //     color: Colors.black.withValues(alpha:0.6),
                //     fontSize: 12,
                //     fontWeight: FontWeight.w300,
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Tagchip extends StatelessWidget {
  const Tagchip({
    super.key,
    required this.tag,
  });

  final String tag;

  @override
  Widget build(BuildContext context) {
    final themeService = locator<ThemeService>();
    return Chip(
      backgroundColor: themeService.onBackground(context),
      elevation: 0,
      shadowColor: Colors.transparent,
      label: Text(tag),
      padding: const EdgeInsets.all(0),
      labelStyle: TextStyle(
        color: themeService.background(context).withValues(alpha: 0.8),
        fontSize: 12,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

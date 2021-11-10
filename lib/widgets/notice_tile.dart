import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:intl/intl.dart';
import 'package:ip_notices/models/notice.dart';
import 'package:ip_notices/services/locator.dart';
import 'package:ip_notices/services/logger.dart';
import 'package:ip_notices/services/theme_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

class NoticeTile extends StatelessWidget {
  const NoticeTile({
    Key? key,
    required this.document,
    required this.download,
  }) : super(key: key);

  final Notice? document;
  final bool download;

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<String> _findLocalPath() async {
    final directory = await getExternalStorageDirectory();
    return directory?.path ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final _themeService = locator<ThemeService>();
    return CupertinoContextMenu(
      key: ValueKey(document?.title ?? ''),
      previewBuilder: (context, animation, child) => Card(
        color: _themeService.background(context),
        margin: const EdgeInsets.all(0),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: ListTile(
          isThreeLine: (document?.college ?? '').toUpperCase().trim() != "",
          enableFeedback: true,
          onTap: () {
            String link = "http://www.ipu.ac.in${document?.url}";
            _launchURL(link);
          },
          contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          leading: CircleAvatar(
              backgroundColor: HexColor.fromHex(
                  document?.color ?? Colors.grey.withOpacity(0.3).toHex()),
              child: Text(
                document?.title[0] ?? '',
                style: TextStyle(
                  color: _themeService.onBackground(context).withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              )),
          title: Text(
            (document?.college ?? '').toUpperCase().trim() != ""
                ? (document?.college ?? '').toUpperCase().trim()
                : document?.title ?? '',
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _themeService.onBackground(context),
              fontWeight: (document?.college ?? '').toUpperCase().trim() == ""
                  ? FontWeight.normal
                  : FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: (document?.college ?? '').toUpperCase().trim() == ""
              ? null
              : Text(
                  document?.title ?? '',
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _themeService.onBackground(context),
                    fontSize: 14,
                  ),
                ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeago
                        .format(DateTime.parse(
                            document?.createdAt.toString() ?? '0'))
                        .contains('day')
                    ? "${document?.date.split('-')[0]} ${DateFormat('MMM').format(DateTime(0, int.parse(document?.date.split('-')[1] ?? '0')))}"
                    : timeago
                        .format(DateTime.parse(
                            document?.createdAt.toString() ?? '0'))
                        .replaceAll('about', '')
                        .replaceAll('hour', 'hr')
                        .replaceAll('minute', 'min')
                        .replaceAll('ago', '')
                        .replaceAll('an', '1')
                        .trim(),
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: _themeService.onBackground(context).withOpacity(0.8),
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
              //     color: Colors.black.withOpacity(0.6),
              //     fontSize: 12,
              //     fontWeight: FontWeight.w300,
              //   ),
              // ),
            ],
          ),
        ),
      ),
      actions: download
          ? [
              CupertinoContextMenuAction(
                child: const Text("View Notice"),
                isDefaultAction: true,
                trailingIcon: CupertinoIcons.doc_text,
                onPressed: () {
                  Navigator.pop(context);
                  String link = "http://www.ipu.ac.in${document?.url}";
                  _launchURL(link);
                },
              ),
              CupertinoContextMenuAction(
                child: const Text("Download"),
                trailingIcon: CupertinoIcons.cloud_download,
                onPressed: () async {
                  Navigator.pop(context);
                  var status = await Permission.storage.status;
                  if (!status.isGranted) {
                    await Permission.storage.request();
                  }
                  String link = "http://www.ipu.ac.in${document?.url}";
                  String _localPath = (await _findLocalPath()) + '/Notices';
                  final savedDir = Directory(_localPath);
                  bool hasExisted = await savedDir.exists();
                  if (!hasExisted) {
                    savedDir.create();
                  }
                  final f = Random();
                  String name = "";
                  for (int i = 0; i < 10; i++) {
                    name = name + f.nextInt(9).toString();
                  }
                  final taskId = await FlutterDownloader.enqueue(
                    url: link,
                    fileName:
                        '${document?.title.toString().replaceAll("/", "")} $name.pdf',
                    savedDir: _localPath,
                    showNotification: true,
                    openFileFromNotification: true,
                  );
                  print(_localPath);
                },
              ),
              CupertinoContextMenuAction(
                child: const Text("Share"),
                trailingIcon: CupertinoIcons.share,
                onPressed: () {
                  Navigator.pop(context);
                  String link = "http://www.ipu.ac.in${document?.url}";
                  Share.share("$link\n${document?.title}");
                },
              )
            ]
          : [
              CupertinoContextMenuAction(
                child: const Text("View Notice"),
                isDefaultAction: true,
                trailingIcon: CupertinoIcons.doc_text,
                onPressed: () {
                  Navigator.pop(context);
                  String link = "http://www.ipu.ac.in${document?.url}";
                  _launchURL(link);
                },
              ),
              CupertinoContextMenuAction(
                child: const Text("Share"),
                trailingIcon: CupertinoIcons.share,
                onPressed: () {
                  Navigator.pop(context);
                  String link = "http://www.ipu.ac.in${document?.url}";
                  Share.share("$link\n${document?.title}");
                },
              )
            ],
      child: Card(
        color: _themeService.background(context),
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
                          _themeService.onBackground(context).withOpacity(0.1),
                      width: 1))),
          child: ListTile(
            isThreeLine:
                (document?.college ?? '').toUpperCase().trim().isNotEmpty,
            // || ((document?.tags ?? []).isNotEmpty),
            enableFeedback: true,
            onLongPress: () {
              logger.d("Long Press");
            },
            onTap: () {
              String link = "http://www.ipu.ac.in${document?.url}";
              _launchURL(link);
            },
            contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            leading: CircleAvatar(
                backgroundColor: HexColor.fromHex(
                    document?.color ?? Colors.grey.withOpacity(0.3).toHex()),
                child: Text(
                  document?.title[0] ?? '',
                  style: TextStyle(
                    color: _themeService.onBackground(context).withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                )),
            title: Text(
              (document?.college ?? '').toUpperCase().trim() != ""
                  ? (document?.college ?? '').toUpperCase().trim()
                  : document?.title ?? '',
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _themeService.onBackground(context),
                fontWeight: (document?.college ?? '').toUpperCase().trim() == ""
                    ? FontWeight.normal
                    : FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: (document?.college ?? '').toUpperCase().trim() == ""
                ? ((document?.tags ?? []).isNotEmpty)
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
                    children: [
                      Text(
                        document?.title ?? '',
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _themeService.onBackground(context),
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
                  timeago
                          .format(DateTime.parse(
                              document?.createdAt.toString() ?? '0'))
                          .contains('day')
                      ? "${document?.date.split('-')[0]} ${DateFormat('MMM').format(DateTime(0, int.parse(document?.date.split('-')[1] ?? '0')))}"
                      : timeago
                          .format(DateTime.parse(
                              document?.createdAt.toString() ?? '0'))
                          .replaceAll('about', '')
                          .replaceAll('hour', 'hr')
                          .replaceAll('minute', 'min')
                          .replaceAll('ago', '')
                          .replaceAll('an', '1')
                          .trim(),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: _themeService.onBackground(context).withOpacity(0.8),
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
                //     color: Colors.black.withOpacity(0.6),
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
    Key? key,
    required this.tag,
  }) : super(key: key);

  final String tag;

  @override
  Widget build(BuildContext context) {
    final _themeService = locator<ThemeService>();
    return Chip(
      backgroundColor: _themeService.onBackground(context).withOpacity(1),
      elevation: 0,
      shadowColor: Colors.transparent,
      label: Text(tag),
      padding: const EdgeInsets.all(0),
      labelStyle: TextStyle(
        color: _themeService.background(context).withOpacity(0.8),
        fontSize: 12,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

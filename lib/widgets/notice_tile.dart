import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

class NoticeTile extends StatefulWidget {
  const NoticeTile({
    Key? key,
    required this.document,
    required this.download,
  }) : super(key: key);

  final Notice? document;
  final bool download;

  @override
  State<NoticeTile> createState() => _NoticeTileState();
}

class _NoticeTileState extends State<NoticeTile> {
  final ReceivePort _port = ReceivePort();
  bool downloading = false;
  bool downloaded = false;
  int? progress;

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      DownloadTaskStatus status = data[1];
      if (status == const DownloadTaskStatus(3)) {
        setState(() {
          downloaded = true;
        });
      }
      setState(() {
        if (status == const DownloadTaskStatus(2)) {
          downloading = true;
          progress = data[2];
        } else {
          downloading = false;
          progress = 0;
        }
      });
    });
    FlutterDownloader.registerCallback(callback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  static void callback(String id, DownloadTaskStatus status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

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
    final SlidableController slidableController = SlidableController();
    final _themeService = locator<ThemeService>();
    return Slidable(
      controller: slidableController,
      actionPane: const SlidableBehindActionPane(),
      actionExtentRatio: 0.25,
      closeOnScroll: true,
      actions: <Widget>[
        IconSlideAction(
          caption: 'Download',
          color: _themeService.accent(context),
          foregroundColor: _themeService.onAccent(context),
          iconWidget: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Icon(
              CupertinoIcons.cloud_download,
              color: _themeService.onAccent(context),
            ),
          ),
          onTap: () async {
            if (widget.download) {
              var status = await Permission.storage.status;
              if (!status.isGranted) {
                await Permission.storage.request();
              }
              String link = "http://www.ipu.ac.in${widget.document?.url}";
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
                    '${widget.document?.title.toString().replaceAll("/", "")} $name.pdf',
                savedDir: _localPath,
                showNotification: true,
                openFileFromNotification: true,
              );
              logger.d("Task Id - $taskId");
              logger.d("Local Path - $_localPath");
            } else {
              String link = "http://www.ipu.ac.in${widget.document?.url}";
              _launchURL(link);
            }
          },
        ),
      ],
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: 'Share',
          color: _themeService.accent(context),
          foregroundColor: _themeService.onAccent(context),
          iconWidget: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Icon(
              CupertinoIcons.share,
              color: _themeService.onAccent(context),
            ),
          ),
          onTap: () {
            String link = "http://www.ipu.ac.in${widget.document?.url}";
            Share.share("$link\n${widget.document?.title}");
          },
        ),
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
            isThreeLine: (widget.document?.college ?? '')
                .toUpperCase()
                .trim()
                .isNotEmpty,
            // || ((document?.tags ?? []).isNotEmpty),
            enableFeedback: true,
            onLongPress: () {
              Fluttertoast.showToast(
                msg: "Swipe to download & share.",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor:
                    _themeService.background(context).withOpacity(0.8),
                textColor: _themeService.onBackground(context),
                fontSize: 16.0,
              );
            },
            onTap: () {
              String link = "http://www.ipu.ac.in${widget.document?.url}";
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
                  Colors.grey.withOpacity(0.3).toHex()),
              child: Text(
                widget.document?.title[0] ?? '',
                style: TextStyle(
                  color: _themeService.onBackground(context).withOpacity(0.7),
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
            //           .withOpacity(0.9)),
            //       backgroundColor: _themeService
            //           .onBackground(context)
            //           .withOpacity(0.1),
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
                color: _themeService.onBackground(context),
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
                    children: [
                      Text(
                        widget.document?.title ?? '',
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

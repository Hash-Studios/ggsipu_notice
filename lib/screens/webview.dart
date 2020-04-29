// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
// import 'package:share/share.dart';
// import 'package:flutter_neumorphic/flutter_neumorphic.dart';

// class WebPage extends StatefulWidget {
//   Map notice;
//   WebPage({@required this.notice});
//   @override
//   _WebPageState createState() => _WebPageState();
// }

// class _WebPageState extends State<WebPage> {
//   final flutterWebviewPlugin = new FlutterWebviewPlugin();

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     flutterWebviewPlugin.dispose(); // disposing the webview widget
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 400,
//       child: WebviewScaffold(
//         url: widget.notice["url"] == null
//             ? 'https://www.incrediblelab.com/wp-content/uploads/2015/06/2015-05-13_21581000.jpg'
//             : "www.ipu.ac.in${widget.notice["url"]}",
//         withJavascript: true, // run javascript
//         withZoom: true, // if you want the user zoom-in and zoom-out
//         hidden:
//             true, // put it true if you want to show CircularProgressIndicator while waiting for the page to load

//         appBar: CupertinoNavigationBar(
//           trailing: CupertinoButton(
//             child: Icon(Icons.share),
//             onPressed: () {
//               Share.share("www.ipu.ac.in${widget.notice["url"]}",
//                   subject:
//                       'Check out this notice! Send from GGSIPU Notices App.');
//             },
//           ),
//           middle: Text(
//             widget.notice["date"],
//             style: TextStyle(
//               color: NeumorphicTheme.defaultTextColor(context),
//             ),
//           ),
//           backgroundColor: NeumorphicTheme.accentColor(context),
//         ),

//         // CupertinoNavigationBar(
//         //   middle: Text(
//         //     widget.notice["date"],
//         //     style: TextStyle(
//         //       fontFamily: "Helvetica",
//         //       color: Color(0xFF34234d),
//         //     ),
//         //   ),
//         //   leading: IconButton(
//         //       icon: Icon(
//         //         Icons.arrow_back,
//         //         color: Color(0xFF34234d),
//         //       ),
//         //       onPressed: () => Navigator.pop(context)),
//         // actions: <Widget>[
//         //   IconButton(
//         //   icon: Icon(Icons.share, color: Color(0xFF34234d)),
//         //   onPressed: () {
//         //     Share.share("https://ipu.ac.in${widget.notice["url"]}",
//         //         subject:
//         //             'Check out this notice! Send from GGSIPU Notices App.');
//         //   },
//         // ),
//         //   IconButton(
//         //     icon: Icon(Icons.arrow_back_ios, color: Color(0xFF34234d)),
//         //     onPressed: () {
//         //       flutterWebviewPlugin.goBack(); // for going back
//         //     },
//         //   ),
//         //   IconButton(
//         //     icon: Icon(Icons.arrow_forward_ios, color: Color(0xFF34234d)),
//         //     onPressed: () {
//         //       flutterWebviewPlugin.goForward(); // for going forward
//         //     },
//         //   ),
//         // ],
//       ),
//     );
//   }
// }

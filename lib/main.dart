import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:ggsipu_notice/core/push_nofitications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:ggsipu_notice/screens/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences prefs;
List<NeumorphicThemeData> themes = [
  NeumorphicThemeData(
    baseColor: Color(0xFFDDDDDD),
    accentColor: Color(0x00CCCCCC),
    defaultTextColor: Color(0xFF333333),
    shadowLightColor: Color(0xFFFFFFFF),
    shadowDarkColor: Color(0xFFAAAAAA),
    intensity: 0.6,
    lightSource: LightSource.topLeft,
    depth: 8,
  ),
  NeumorphicThemeData(
    baseColor: Color(0xFF222222),
    accentColor: Color(0x00111111),
    defaultTextColor: Color(0xFFDDDDDD),
    shadowLightColor: Color(0xFF444444),
    shadowDarkColor: Color(0xFF000000),
    intensity: 0.6,
    lightSource: LightSource.topLeft,
    depth: 8,
  ),
  NeumorphicThemeData(
    baseColor: Color(0xFF000000),
    accentColor: Color(0x00000000),
    defaultTextColor: Color(0xFFFFFFFF),
    shadowLightColor: Color(0xFF181818),
    shadowDarkColor: Color(0xFF080808),
    intensity: 0.6,
    lightSource: LightSource.topLeft,
    depth: 8,
  ),
];
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  await FlutterDownloader.initialize(debug: true);
  GestureBinding.instance.resamplingEnabled = true;
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.transparent));
    final push = PushNotificationsManager();
    push.init();
    return CupertinoApp(
      title: 'GGSIPU Notices',
      theme: CupertinoThemeData(),
      home: NeumorphicTheme(
        usedTheme:
            prefs.get('theme') == 0 ?? 1 ? UsedTheme.LIGHT : UsedTheme.DARK,
        theme: NeumorphicThemeData(
          baseColor: Color(0xFFDDDDDD),
          accentColor: Color(0x00CCCCCC),
          defaultTextColor: Color(0xFF333333),
          shadowLightColor: Color(0xFFFFFFFF),
          shadowDarkColor: Color(0xFFAAAAAA),
          intensity: 0.6,
          lightSource: LightSource.topLeft,
          depth: 8,
        ),
        darkTheme: prefs.get('theme') == 1 ?? 1
            ? NeumorphicThemeData(
                baseColor: Color(0xFF222222),
                accentColor: Color(0x00111111),
                defaultTextColor: Color(0xFFDDDDDD),
                shadowLightColor: Color(0xFF444444),
                shadowDarkColor: Color(0xFF000000),
                intensity: 0.6,
                lightSource: LightSource.topLeft,
                depth: 8,
              )
            : NeumorphicThemeData(
                baseColor: Color(0xFF000000),
                accentColor: Color(0x00000000),
                defaultTextColor: Color(0xFFFFFFFF),
                shadowLightColor: Color(0xFF181818),
                shadowDarkColor: Color(0xFF080808),
                intensity: 0.6,
                lightSource: LightSource.topLeft,
                depth: 8,
              ),
        child: MyHomePage(title: 'Notices'),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

import 'package:another/core/push_nofitications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:another/screens/home.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'GGSIPU Notices',
      theme: CupertinoThemeData(),
      home: NeumorphicTheme(
        usedTheme: UsedTheme.SYSTEM,
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
        darkTheme: NeumorphicThemeData(
          baseColor: Color(0xFF222222),
          accentColor: Color(0x00111111),
          defaultTextColor: Color(0xFFDDDDDD),
          shadowLightColor: Color(0xFF444444),
          shadowDarkColor: Color(0xFF000000),
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

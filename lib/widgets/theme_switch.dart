import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ThemeSwitchButton extends StatelessWidget {
  const ThemeSwitchButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: IconButton(
        padding: EdgeInsets.only(bottom: 2),
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        onPressed: () {
          // print(NeumorphicTheme.of(context).value.current.baseColor);
          // if (NeumorphicTheme.of(context).value.current.baseColor ==
          //     Color(0xffdddddd)) {
          //   NeumorphicTheme.of(context).update((current) => main.themes[1]);
          //   main.prefs.setInt('theme', 1);
          // } else {
          //   if (NeumorphicTheme.of(context).value.current.baseColor ==
          //       Color(0xff222222)) {
          //     NeumorphicTheme.of(context).update((current) => main.themes[2]);
          //     main.prefs.setInt('theme', 2);
          //   } else {
          //     NeumorphicTheme.of(context).update((current) => main.themes[0]);
          //     main.prefs.setInt('theme', 0);
          //   }
          // }
        },
        icon: Icon(
          // NeumorphicTheme.of(context).value.current.baseColor ==
          //         Color(0xffdddddd)
          //     ? CupertinoIcons.brightness
          //     : NeumorphicTheme.of(context).value.current.baseColor ==
          //             Color(0xff222222)
          //         ? CupertinoIcons.brightness
          //         :
          CupertinoIcons.brightness_solid,
        ),
        color: Colors.black,
      ),
    );
  }
}

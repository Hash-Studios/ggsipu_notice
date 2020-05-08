import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

class ThemeSwitchButton extends StatelessWidget {
  const ThemeSwitchButton({
    Key key,
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
          NeumorphicTheme.of(context).usedTheme =
              NeumorphicTheme.isUsingDark(context)
                  ? UsedTheme.LIGHT
                  : UsedTheme.DARK;
        },
        icon: Icon(
          NeumorphicTheme.isUsingDark(context)
              ? CupertinoIcons.brightness
              : CupertinoIcons.brightness_solid,
        ),
        color: NeumorphicTheme.defaultTextColor(context),
      ),
    );
  }
}

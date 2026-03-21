import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ThemeSwitchButton extends StatelessWidget {
  const ThemeSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: IconButton(
        padding: const EdgeInsets.only(bottom: 2),
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        onPressed: () {},
        icon: const Icon(
          CupertinoIcons.brightness_solid,
        ),
        color: Colors.black,
      ),
    );
  }
}

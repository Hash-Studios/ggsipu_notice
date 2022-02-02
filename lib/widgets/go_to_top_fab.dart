import 'package:flutter/cupertino.dart';

class GoToTopFAB extends StatelessWidget {
  const GoToTopFAB({
    Key? key,
    required this.showFab,
    required this.onFABPressed,
  }) : super(key: key);

  final bool showFab;
  final Null Function() onFABPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      curve: Curves.easeOutCubic,
      duration: const Duration(milliseconds: 250),
      bottom: showFab ? 20 : -50,
      right: 20,
      child: CupertinoButton.filled(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(500),
        child: const Icon(
          CupertinoIcons.up_arrow,
        ),
        onPressed: onFABPressed,
      ),
    );
  }
}

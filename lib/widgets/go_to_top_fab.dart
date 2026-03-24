import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GoToTopFAB extends StatelessWidget {
  const GoToTopFAB({
    super.key,
    required this.showFab,
    required this.onFABPressed,
  });

  final bool showFab;
  final VoidCallback onFABPressed;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: 20 + bottomPadding,
      right: 20,
      child: AnimatedOpacity(
        opacity: showFab ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: showFab ? 1.0 : 0.75,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: IgnorePointer(
            ignoring: !showFab,
            child: Semantics(
              label: 'Back to top',
              button: true,
              child: CupertinoButton.filled(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(500),
                onPressed: onFABPressed,
                child: const Icon(
                  CupertinoIcons.up_arrow,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

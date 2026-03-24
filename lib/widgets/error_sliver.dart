import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ErrorSliver extends StatelessWidget {
  const ErrorSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.multiply_circle,
                  color: Theme.of(context).colorScheme.error,
                  size: 32,
                ),
                SizedBox(height: 12),
                Text(
                  "Couldn't load notices",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4),
                Text(
                  "Pull down to try again",
                  style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

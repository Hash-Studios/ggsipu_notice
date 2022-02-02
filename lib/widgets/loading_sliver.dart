import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadingSliver extends StatelessWidget {
  const LoadingSliver({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Material(
            color: Colors.transparent,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width,
              child: const Center(
                child: CupertinoActivityIndicator(
                  animating: true,
                  radius: 20,
                ),
              ),
            ),
          );
        },
        childCount: 1,
      ),
    );
  }
}

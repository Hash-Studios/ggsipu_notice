import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ErrorSliver extends StatelessWidget {
  const ErrorSliver({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          width: MediaQuery.of(context).size.width,
          child: const Center(
            child: Icon(
              CupertinoIcons.multiply_circle,
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }
}

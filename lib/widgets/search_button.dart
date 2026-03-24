import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ip_notices/services/locator.dart';
import 'package:ip_notices/services/theme_service.dart';

class SearchButton extends StatelessWidget {
  const SearchButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final themeService = locator<ThemeService>();
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: IconButton(
        padding: const EdgeInsets.only(bottom: 2),
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        tooltip: 'Search',
        onPressed: onPressed,
        icon: const Icon(
          CupertinoIcons.search,
        ),
        color: themeService.onBackground(context),
        iconSize: 20,
      ),
    );
  }
}

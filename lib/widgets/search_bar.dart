import 'package:flutter/cupertino.dart';
import 'package:ip_notices/services/locator.dart';
import 'package:ip_notices/services/theme_service.dart';

class SearchBar extends StatelessWidget {
  const SearchBar({
    Key? key,
    required this.searchController,
    required this.searchFocusNode,
    required this.onChanged,
  }) : super(key: key);

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Null Function(dynamic value) onChanged;

  @override
  Widget build(BuildContext context) {
    final _themeService = locator<ThemeService>();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: CupertinoSearchTextField(
          controller: searchController,
          focusNode: searchFocusNode,
          onChanged: onChanged,
          onSubmitted: onChanged,
          autocorrect: true,
          style: TextStyle(
            color: _themeService.onBackground(context),
          ),
        ),
      ),
    );
  }
}

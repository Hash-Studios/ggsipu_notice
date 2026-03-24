import 'package:flutter/material.dart';

class ThemeService {
  Color backgroundL = const Color(0xFFFAFAFA);
  Color backgroundD = const Color(0xFF000000);
  Color accentL = Colors.indigo;
  Color accentD = Colors.indigo.shade400;

  Color accent(context) =>
      Theme.of(context).brightness == Brightness.dark
          ? accentD
          : accentL;
  Color onAccent(context) =>
      Theme.of(context).brightness == Brightness.dark
          ? accentD.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white
          : accentL.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white;

  Color onBackground(context) =>
      Theme.of(context).brightness == Brightness.dark
          ? backgroundD.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white
          : backgroundL.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white;

  Color background(context) =>
      Theme.of(context).brightness == Brightness.dark
          ? backgroundD
          : backgroundL;
  Color backgroundHighContrast(context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF181818)
          : Colors.white;

  ThemeData get themeData {
    ThemeData lightTheme = ThemeData.light().copyWith(
      textTheme: ThemeData.light().textTheme.apply(
            fontFamily: 'Pragmatica',
          ),
      primaryTextTheme: ThemeData.light().textTheme.apply(
            fontFamily: 'Pragmatica',
          ),
    );
    TextTheme txtTheme = lightTheme.textTheme;
    Color txtColor = txtTheme.bodyLarge?.color ?? Colors.black;
    ColorScheme colorScheme = ColorScheme(
        brightness: Brightness.light,
        primary: accentL,
        secondary: accentL,
        surface: backgroundL,
        onSurface: txtColor,
        onError: Colors.white,
        onPrimary:
            accentL.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        onSecondary:
            accentL.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        error: Colors.red.shade400);

    final ThemeData t =
        ThemeData.from(textTheme: txtTheme, colorScheme: colorScheme).copyWith(
      textSelectionTheme: TextSelectionThemeData(cursorColor: accentL),
      highlightColor: accentL.withValues(alpha: 0.2),
      scaffoldBackgroundColor: backgroundL,
    );
    return t;
  }

  ThemeData get darkThemeData {
    ThemeData darkTheme = ThemeData.dark().copyWith(
      textTheme: ThemeData.dark().textTheme.apply(
            fontFamily: 'Pragmatica',
          ),
      primaryTextTheme: ThemeData.dark().textTheme.apply(
            fontFamily: 'Pragmatica',
          ),
    );
    TextTheme txtTheme = darkTheme.textTheme;
    Color txtColor = txtTheme.bodyLarge?.color ?? Colors.white;
    ColorScheme colorScheme = ColorScheme(
        brightness: Brightness.dark,
        primary: accentD,
        secondary: accentD,
        surface: backgroundD,
        onSurface: txtColor,
        onError: Colors.white,
        onPrimary:
            accentD.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        onSecondary:
            accentD.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        error: Colors.red.shade400);

    final ThemeData t =
        ThemeData.from(textTheme: txtTheme, colorScheme: colorScheme).copyWith(
      textSelectionTheme: TextSelectionThemeData(cursorColor: accentD),
      highlightColor: accentD.withValues(alpha: 0.2),
      scaffoldBackgroundColor: backgroundD,
    );
    return t;
  }
}

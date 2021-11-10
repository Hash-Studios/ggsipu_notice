import 'package:flutter/material.dart';

class ThemeService {
  Color backgroundL = const Color(0xFFFAFAFA);
  Color backgroundD = const Color(0xFF000000);
  Color accentL = const Color(0xFF0C54BE);
  Color accentD = const Color(0xFF303F60);

  Color accent(context) =>
      MediaQuery.of(context).platformBrightness == Brightness.dark
          ? accentD
          : accentL;
  Color onAccent(context) =>
      MediaQuery.of(context).platformBrightness == Brightness.dark
          ? accentD.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white
          : accentL.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white;

  Color onBackground(context) =>
      MediaQuery.of(context).platformBrightness == Brightness.dark
          ? backgroundD.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white
          : backgroundL.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white;

  Color background(context) =>
      MediaQuery.of(context).platformBrightness == Brightness.dark
          ? backgroundD
          : backgroundL;
  Color backgroundHighContrast(context) =>
      MediaQuery.of(context).platformBrightness == Brightness.dark
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
    Color txtColor = txtTheme.bodyText1?.color ?? (Colors.black);
    ColorScheme colorScheme = ColorScheme(
        brightness: Brightness.light,
        primary: accentL,
        primaryVariant: accentL,
        secondary: accentL,
        secondaryVariant: accentL,
        background: backgroundL,
        surface: backgroundL,
        onBackground: txtColor,
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
      highlightColor: accentL,
      scaffoldBackgroundColor: backgroundL,
      toggleableActiveColor: accentL,
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
    Color txtColor = txtTheme.bodyText1?.color ?? (Colors.white);
    ColorScheme colorScheme = ColorScheme(
        brightness: Brightness.dark,
        primary: accentD,
        primaryVariant: accentD,
        secondary: accentD,
        secondaryVariant: accentD,
        background: backgroundD,
        surface: backgroundD,
        onBackground: txtColor,
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
      highlightColor: accentD,
      scaffoldBackgroundColor: backgroundD,
      toggleableActiveColor: accentD,
    );
    return t;
  }
}

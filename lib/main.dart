import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:ip_notices/keys.dart';
import 'package:ip_notices/notifiers/firestore_notifier.dart';
import 'package:ip_notices/pages/home_page.dart';
import 'package:ip_notices/services/locator.dart';
import 'package:ip_notices/services/logger.dart';
import 'package:ip_notices/services/theme_service.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences prefs;

void main() async {
  await setupLocator();
  await Firebase.initializeApp();
  await setRefreshRate();
  prefs = await SharedPreferences.getInstance();
  await FlutterDownloader.initialize();
  oneSignalSetup();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<FirestoreNotifier>(
        create: (_) => FirestoreNotifier()),
  ], child: const MyApp()));
}

void oneSignalSetup() {
  OneSignal.shared.setLogLevel(OSLogLevel.fatal, OSLogLevel.none);
  OneSignal.shared.setAppId(oneSignalAppID);
}

Future<void> setRefreshRate() async {
  await FlutterDisplayMode.setHighRefreshRate().then((value) =>
      FlutterDisplayMode.active.then((mode) => logger.i(
          "Refresh rate set to - ${mode.width}x${mode.height} @ ${mode.refreshRate}")));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      title: 'GGSIPU Notices',
      home: Builder(builder: (context) {
        final Brightness brightnessValue =
            MediaQuery.of(context).platformBrightness;
        bool isDark = brightnessValue == Brightness.dark;
        return Theme(
          data: isDark
              ? locator<ThemeService>().darkThemeData
              : locator<ThemeService>().themeData,
          child: const HomePage(),
        );
      }),
    );
  }
}

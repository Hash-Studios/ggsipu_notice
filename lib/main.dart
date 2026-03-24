import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:ip_notices/keys.dart';
import 'package:ip_notices/notifiers/algolia_notifier.dart';
import 'package:ip_notices/notifiers/firestore_notifier.dart';
import 'package:ip_notices/pages/home_page.dart';
import 'package:ip_notices/services/locator.dart';
import 'package:ip_notices/services/logger.dart';
import 'package:ip_notices/services/theme_service.dart';
import 'package:oktoast/oktoast.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

late SharedPreferences prefs;

// Must be top-level for Firebase Messaging background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

// Must be top-level for FlutterDownloader isolate callback
@pragma('vm:entry-point')
void _downloadCallback(String id, int status, int progress) {
  // System notification handles download progress display
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await setRefreshRate();
  prefs = await SharedPreferences.getInstance();
  await FlutterDownloader.initialize();
  FlutterDownloader.registerCallback(_downloadCallback);
  oneSignalSetup();
  await setupFirebaseMessaging();
  runApp(OKToast(
    child: MultiProvider(providers: [
      ChangeNotifierProvider<FirestoreNotifier>(
          create: (_) => FirestoreNotifier()),
      ChangeNotifierProvider<AlgoliaNotifier>(
          create: (_) => AlgoliaNotifier()),
    ], child: const MyApp()),
  ));
}

void oneSignalSetup() {
  OneSignal.Debug.setLogLevel(OSLogLevel.fatal);
  OneSignal.initialize(oneSignalAppID);
}

Future<void> setupFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission();

  // App opened from a notification while terminated
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    _openNoticeUrl(initialMessage.data['url']);
  }

  // App opened from a notification while backgrounded
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _openNoticeUrl(message.data['url']);
  });

  // Notification received in foreground — show a toast; don't interrupt the user
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final title = message.notification?.title
        ?? message.data['title'] as String?
        ?? 'New notice';
    showToast(
      title,
      duration: const Duration(seconds: 4),
      position: ToastPosition.top,
    );
  });

  // Register FCM token with Firestore so the backend can send notifications
  await _registerFcmToken(messaging);
  messaging.onTokenRefresh.listen(_registerFcmToken);
}

Future<void> _registerFcmToken(dynamic tokenOrMessaging) async {
  final String? token = tokenOrMessaging is String
      ? tokenOrMessaging
      : await (tokenOrMessaging as FirebaseMessaging).getToken();
  if (token == null) return;
  await FirebaseFirestore.instance
      .collection('fcm_tokens')
      .doc(token)
      .set({'active': true, 'updatedAt': FieldValue.serverTimestamp()});
  logger.i('FCM token registered: $token');
}

void _openNoticeUrl(String? url) async {
  if (url == null || url.isEmpty) return;
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    logger.e('Could not open notice URL: $url');
  }
}

Future<void> setRefreshRate() async {
  try {
    await FlutterDisplayMode.setHighRefreshRate();
    final mode = await FlutterDisplayMode.active;
    logger.i("Refresh rate: ${mode.width}x${mode.height} @ ${mode.refreshRate}Hz");
  } catch (e) {
    logger.w("Could not set high refresh rate: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

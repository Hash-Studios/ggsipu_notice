import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:ip_notices/notifiers/firestore_notifier.dart';
import 'package:ip_notices/services/firestore_service.dart';
import 'package:ip_notices/services/theme_service.dart';

import 'logger.dart';

GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stopwatch stopwatch = Stopwatch()..start();
  locator.registerFactory<FirestoreNotifier>(() => FirestoreNotifier());
  locator.registerLazySingleton<ThemeService>(() => ThemeService());
  locator.registerLazySingleton<FirestoreService>(() => FirestoreService());
  logger.d('SETUP LOCATOR EXECUTED IN ${stopwatch.elapsed}');
  stopwatch.stop();
}

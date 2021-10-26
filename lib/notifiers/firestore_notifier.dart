import 'package:flutter/material.dart';
import 'package:ip_notices/models/notice.dart';
import 'package:ip_notices/services/firestore_service.dart';
import 'package:ip_notices/services/locator.dart';

class FirestoreNotifier with ChangeNotifier {
  final FirestoreService _firestoreService = locator<FirestoreService>();
  Stream<List<Notice>>? get noticesStream => _firestoreService.noticesStream;
  int get limit => _firestoreService.limit;

  set limit(int value) {
    _firestoreService.limit = value;
    notifyListeners();
  }
}

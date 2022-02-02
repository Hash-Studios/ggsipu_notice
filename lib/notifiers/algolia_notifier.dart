import 'package:algolia/algolia.dart';
import 'package:flutter/material.dart';
import 'package:ip_notices/services/algolia_service.dart';
import 'package:ip_notices/services/locator.dart';

class AlgoliaNotifier with ChangeNotifier {
  final _algoliaService = locator<AlgoliaService>();
  AlgoliaQuerySnapshot? get snapshot => _algoliaService.snapshot;

  Future<void> getNoticeSearch(String queryString) async {
    await _algoliaService.getNoticeSearch(queryString);
    notifyListeners();
  }
}

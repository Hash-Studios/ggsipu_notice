import 'package:algolia/algolia.dart';
import 'package:ip_notices/keys.dart';
import 'package:ip_notices/services/logger.dart';

class AlgoliaApplication {
  static Algolia algolia = const Algolia.init(
    applicationId: algoliaApplicationId,
    apiKey: algoliaApiKey,
  );
}

class AlgoliaService {
  final Algolia algolia = AlgoliaApplication.algolia;
  AlgoliaQuerySnapshot? snapshot;
  Future<void> getNoticeSearch(String queryString) async {
    final AlgoliaQuery query =
        algolia.instance.index('notices').query(queryString);
    snapshot = await query.getObjects();
    logger.d('Hits count: ${snapshot?.nbHits}');
  }
}

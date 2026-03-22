import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ip_notices/models/notice.dart';
import 'package:ip_notices/services/logger.dart';

class FirestoreService {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Stream<List<Notice>>? noticesStream;
  int limit = 10;
  bool priorityCheck = false;

  void initNoticeStream(bool more) {
    logger.i("Init");
    if (!more) {
      limit = 10;
    }
    noticesStream = priorityCheck
        ? FirebaseFirestore.instance
            .collection('notices')
            .where('isArchived', isEqualTo: false)
            .where('priority', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .snapshots()
            .map((event) =>
                event.docs.map((doc) => Notice.fromJson(doc.data())).toList())
        : FirebaseFirestore.instance
            .collection('notices')
            .where('isArchived', isEqualTo: false)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .snapshots()
            .map((event) =>
                event.docs.map((doc) => Notice.fromJson(doc.data())).toList());
  }

  void loadMore() {
    limit = limit + 10;
    initNoticeStream(true);
  }

  void togglePriorityCheck() {
    priorityCheck = !priorityCheck;
    initNoticeStream(false);
  }
}

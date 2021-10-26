import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ip_notices/models/notice.dart';

class FirestoreService {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Stream<List<Notice>>? noticesStream;
  int limit = 10;

  FirestoreService() {
    initNoticeStream();
  }

  void initNoticeStream() {
    noticesStream = FirebaseFirestore.instance
        .collection('notices')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((event) =>
            event.docs.map((doc) => Notice.fromJson(doc.data())).toList());
  }
}

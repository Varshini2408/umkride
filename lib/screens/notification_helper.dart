import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHelper {
  static final _db = FirebaseFirestore.instance;

  static Future<void> send({
    required String toUid,
    required String title,
    required String message,
  }) async {
    await _db.collection('notifications').add({
      'toUid':     toUid,
      'title':     title,
      'message':   message,
      'createdAt': FieldValue.serverTimestamp(),
      'read':      false,
    });
  }
}

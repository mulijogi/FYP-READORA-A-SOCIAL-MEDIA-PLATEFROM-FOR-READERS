import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:readora/utils/custom_snackbar.dart';

class NotificationController extends GetxController {
  final notifications = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
  }

  void _setupListeners() {
    final user = _auth.currentUser;
    if (user == null) return;

    final baseRef = _firestore.collection('notifications').doc(user.uid);

    final Map<String, List<Map<String, dynamic>>> dataMap = {
      'friend_request': [],
      'comment': [],
      'like': [],
      'friend_post': [],
    };

    void updateCombinedList() {
      final combined = dataMap.values.expand((e) => e).toList();
      combined.sort((a, b) {
        final t1 = a['data']['timestamp'] as Timestamp?;
        final t2 = b['data']['timestamp'] as Timestamp?;
        if (t1 == null) return 1;
        if (t2 == null) return -1;
        return t2.compareTo(t1); // Descending
      });
      notifications.value = combined;
      isLoading.value = false;
    }

    // Friend Request Notifications
    baseRef.collection('friendRequestNotifications').snapshots().listen((snap) {
      dataMap['friend_request'] = snap.docs.map((doc) => {
        'type': 'friend_request',
        'data': doc.data(),
        'id': doc.id,
      }).toList();
      updateCombinedList();
    }, onError: (e) => print("Error in friendRequestNotifications: $e"));

    // Comment Notifications
    baseRef.collection('commentNotifications').snapshots().listen((snap) {
      dataMap['comment'] = snap.docs.map((doc) => {
        'type': 'comment',
        'data': doc.data(),
        'id': doc.id,
      }).toList();
      updateCombinedList();
    }, onError: (e) => print("Error in commentNotifications: $e"));

    // Like Notifications
    baseRef.collection('likeNotifications').snapshots().listen((snap) {
      dataMap['like'] = snap.docs.map((doc) => {
        'type': 'like',
        'data': doc.data(),
        'id': doc.id,
      }).toList();
      updateCombinedList();
    }, onError: (e) => print("Error in likeNotifications: $e"));

    // Friend Post Notifications
    baseRef.collection('friendPostNotifications').snapshots().listen((snap) {
      dataMap['friend_post'] = snap.docs.map((doc) => {
        'type': 'friend_post',
        'data': doc.data(),
        'id': doc.id,
      }).toList();
      updateCombinedList();
    }, onError: (e) => print("Error in friendPostNotifications: $e"));
  }

  Future<void> deleteFriendRequestNotification(String notificationId, String userId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('friendRequestNotifications')
          .doc(notificationId)
          .delete();
      customSnackbar(title: 'Success', message: 'Friend request notification deleted.');
    } catch (e) {
      customSnackbar(title: 'Error', message: 'Failed to delete notification: $e');
    }
  }

  Future<void> deleteCommentNotification(String notificationId, String userId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('commentNotifications')
          .doc(notificationId)
          .delete();
      customSnackbar(title: 'Success', message: 'Comment notification deleted.');
    } catch (e) {
      customSnackbar(title: 'Error', message: 'Failed to delete notification: $e');
    }
  }

  Future<void> deleteLikeNotification(String notificationId, String userId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('likeNotifications')
          .doc(notificationId)
          .delete();
      customSnackbar(title: 'Success', message: 'Like notification deleted.');
    } catch (e) {
      customSnackbar(title: 'Error', message: 'Failed to delete notification: $e');
    }
  }

  Future<void> deleteFriendPostNotification(String notificationId, String userId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('friendPostNotifications')
          .doc(notificationId)
          .delete();
      customSnackbar(title: 'Success', message: 'Friend post notification deleted.');
    } catch (e) {
      customSnackbar(title: 'Error', message: 'Failed to delete notification: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final baseRef = _firestore.collection('notifications').doc(user.uid);
      final collections = [
        'friendRequestNotifications',
        'commentNotifications',
        'likeNotifications',
        'friendPostNotifications'
      ];

      for (var coll in collections) {
        final snap = await baseRef.collection(coll).get();
        for (var doc in snap.docs) {
          await doc.reference.delete();
        }
      }
      customSnackbar(title: 'Success', message: 'All notifications deleted.');
    } catch (e) {
      customSnackbar(title: 'Error', message: 'Failed to delete all notifications: $e');
    }
  }
}

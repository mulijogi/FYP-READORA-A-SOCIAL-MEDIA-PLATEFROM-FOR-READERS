import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:readora/screens/Reminders/service/reminder_service.dart';
import 'package:readora/utils/custom_snackbar.dart';

class ReminderController extends GetxController {
  final _box = GetStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Storage keys ─────────────────────────────────────────────
  static const _kReadingEnabled = 'reminder_reading_enabled';
  static const _kReadingHour = 'reminder_reading_hour';
  static const _kReadingMin = 'reminder_reading_min';
  static const _kGoalEnabled = 'reminder_goal_enabled';
  static const _kFriendPostEnabled = 'reminder_friendpost_enabled';

  // ── Reactive state ───────────────────────────────────────────
  var readingReminderEnabled = false.obs;
  var readingGoalReminderEnabled = false.obs;
  var friendPostReminderEnabled = false.obs;
  var readingReminderTime = const TimeOfDay(hour: 20, minute: 0).obs;

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
    _listenForFriendPosts();
  }

  // ─────────────────────────────────────────────────────────────
  //  LOAD / SAVE PREFERENCES
  // ─────────────────────────────────────────────────────────────
  void _loadPreferences() {
    readingReminderEnabled.value = _box.read(_kReadingEnabled) ?? false;
    readingGoalReminderEnabled.value = _box.read(_kGoalEnabled) ?? false;
    friendPostReminderEnabled.value = _box.read(_kFriendPostEnabled) ?? true;

    final hour = _box.read(_kReadingHour) ?? 20;
    final min = _box.read(_kReadingMin) ?? 0;
    readingReminderTime.value = TimeOfDay(hour: hour, minute: min);

    // Re-apply scheduled reminders on app restart
    if (readingReminderEnabled.value) {
      ReminderService.instance
          .scheduleReadingTimeReminder(readingReminderTime.value);
    }
    if (readingGoalReminderEnabled.value) {
      ReminderService.instance.scheduleReadingGoalReminder(readingReminderTime.value);
    }
  }

  void _savePreferences() {
    _box.write(_kReadingEnabled, readingReminderEnabled.value);
    _box.write(_kGoalEnabled, readingGoalReminderEnabled.value);
    _box.write(_kFriendPostEnabled, friendPostReminderEnabled.value);
    _box.write(_kReadingHour, readingReminderTime.value.hour);
    _box.write(_kReadingMin, readingReminderTime.value.minute);
  }

  void saveAndRescheduleAll() {
    _savePreferences();
    if (readingReminderEnabled.value) {
      ReminderService.instance
          .scheduleReadingTimeReminder(readingReminderTime.value);
    } else {
      ReminderService.instance.cancelReadingTimeReminder();
    }
    if (readingGoalReminderEnabled.value) {
      ReminderService.instance
          .scheduleReadingGoalReminder(readingReminderTime.value);
    } else {
      ReminderService.instance.cancelReadingGoalReminder();
    }
  }

  Future<bool> _requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      status = await Permission.notification.request();
    }
    if (!status.isGranted) {
      customSnackbar(
        title: 'Permission Required',
        message: 'Please grant notification permission in settings to receive reminders.',
      );
      return false;
    }

    // On Android 13+ (SDK 33+), exact alarms require permission
    try {
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    } catch (e) {
      print("Exact alarm permission check failed: $e");
    }

    return true;
  }

  // ─────────────────────────────────────────────────────────────
  //  READING TIME REMINDER
  // ─────────────────────────────────────────────────────────────
  void toggleReadingReminder(bool value) async {
    if (value) {
      final granted = await _requestNotificationPermission();
      if (!granted) return;
    }
    readingReminderEnabled.value = value;
    _savePreferences();
    if (value) {
      try {
        await ReminderService.instance
            .scheduleReadingTimeReminder(readingReminderTime.value);
      } catch (e) {
        print("Failed to schedule reading time reminder: $e");
        customSnackbar(
          title: 'Schedule Error',
          message: 'Could not schedule reminder. Please check app alarm permissions.',
        );
        readingReminderEnabled.value = false;
        _savePreferences();
      }
    } else {
      ReminderService.instance.cancelReadingTimeReminder();
    }
  }

  void setReadingReminderTime(TimeOfDay time) async {
    readingReminderTime.value = time;
    _savePreferences();
    if (readingReminderEnabled.value) {
      try {
        await ReminderService.instance.scheduleReadingTimeReminder(time);
      } catch (e) {
        print("Failed to schedule reading time reminder on time change: $e");
      }
    }
    if (readingGoalReminderEnabled.value) {
      try {
        await ReminderService.instance.scheduleReadingGoalReminder(time);
      } catch (e) {
        print("Failed to schedule goal reminder on time change: $e");
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  READING GOAL REMINDER
  // ─────────────────────────────────────────────────────────────
  void toggleGoalReminder(bool value) async {
    if (value) {
      final granted = await _requestNotificationPermission();
      if (!granted) return;
    }
    readingGoalReminderEnabled.value = value;
    _savePreferences();
    if (value) {
      try {
        await ReminderService.instance.scheduleReadingGoalReminder(readingReminderTime.value);
      } catch (e) {
        print("Failed to schedule goal reminder: $e");
        customSnackbar(
          title: 'Schedule Error',
          message: 'Could not schedule reminder. Please check app alarm permissions.',
        );
        readingGoalReminderEnabled.value = false;
        _savePreferences();
      }
    } else {
      ReminderService.instance.cancelReadingGoalReminder();
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  FRIEND POST REMINDER
  // ─────────────────────────────────────────────────────────────
  void toggleFriendPostReminder(bool value) async {
    if (value) {
      final granted = await _requestNotificationPermission();
      if (!granted) return;
    }
    friendPostReminderEnabled.value = value;
    _savePreferences();
  }

  /// Called by PostsController after a new post is saved to Firestore.
  /// Fetches the poster's friends list and writes a notification document
  /// to each friend's `friendPostNotifications` sub-collection.
  static Future<void> notifyFriendsOfNewPost({
    required String posterId,
    required String posterName,
    required String posterPicUrl,
    required String postPreview,
    required String postId,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Get all users who have this poster as a friend
      final allUsersSnap = await firestore.collection('users').get();

      for (final userDoc in allUsersSnap.docs) {
        if (userDoc.id == posterId) continue; // skip poster themselves

        // Check if this user has the poster as a friend
        final friendDoc = await firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('friends')
            .where('friendId', isEqualTo: posterId)
            .limit(1)
            .get();

        if (friendDoc.docs.isEmpty) continue;

        // Write to friendPostNotifications sub-collection
        await firestore
            .collection('notifications')
            .doc(userDoc.id)
            .collection('friendPostNotifications')
            .add({
          'senderId': posterId,
          'receiverId': userDoc.id,
          'posterName': posterName,
          'profilePicUrl': posterPicUrl,
          'message': '$posterName shared a new post',
          'postPreview': postPreview,
          'postId': postId,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    } catch (e) {
      print('Error notifying friends of new post: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  LISTEN FOR FRIEND POSTS (real-time → local notification)
  // ─────────────────────────────────────────────────────────────
  void _listenForFriendPosts() {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore
        .collection('notifications')
        .doc(user.uid)
        .collection('friendPostNotifications')
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
      if (!friendPostReminderEnabled.value) return;
      for (int i = 0; i < snap.docChanges.length; i++) {
        final change = snap.docChanges[i];
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          final name = data['posterName'] as String? ?? 'A friend';
          final preview = data['postPreview'] as String? ?? '';
          ReminderService.instance.showFriendPostNotification(
            friendName: name,
            postPreview: preview,
            index: i,
          );
        }
      }
    });
  }

  String formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

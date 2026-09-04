import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Reminders/controller/reminder_controller.dart';

void main() {
  late ReminderController reminderController;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    Get.reset();
    reminderController = ReminderController();
  });

  group('ReminderController Unit Tests', () {
    test('Adding a reminder creates document in Firestore', () async {
      // Call add reminder method
      // await reminderController.addReminder('Read Book', DateTime.now());

      // Check if it was added
      // final reminders = await fakeFirestore.collection('reminders').get();
      // expect(reminders.docs.isNotEmpty, true);
    });

    test('updateReminderStatus toggles reminder state', () async {
      // Mock an existing reminder
      // Test toggling status
    });

    test('deleteReminder removes from list and DB', () async {
      // Test deletion functionality
    });
  });
}

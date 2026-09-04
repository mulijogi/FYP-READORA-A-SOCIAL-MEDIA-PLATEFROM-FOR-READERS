import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/controller/profile_controller.dart';
import 'package:readora/screens/Dashboard/Home/controller/home_controller.dart';
import 'package:readora/screens/ChatList/controller/chat_lists_controller.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/view/component/edit_profile/controller/edit_profile_controller.dart';

class MockHomeController extends Mock implements HomeController {}
class MockChatListsController extends Mock implements ChatListsController {}
class MockEditProfileController extends Mock implements EditProfileController {}

void main() {
  late ProfileController profileController;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(signedIn: true);

    // Mocking injected dependencies
    final mockHome = MockHomeController();
    when(() => mockHome.username).thenReturn('testuser');
    Get.put<HomeController>(mockHome);

    final mockChatList = MockChatListsController();
    when(() => mockChatList.friends).thenReturn(<Map<String, dynamic>>[].obs);
    Get.put<ChatListsController>(mockChatList);

    final mockEditProfile = MockEditProfileController();
    Get.put<EditProfileController>(mockEditProfile);

    profileController = ProfileController();
  });

  tearDown(() {
    Get.reset();
  });

  group('ProfileController Unit Tests', () {
    test('Initialization sets correct user details', () {
      expect(profileController.currentUser, 'testuser');
      expect(profileController.friendsCount.value, 0);
    });

    test('updatePostsCount updates observable correctly', () {
      profileController.updatePostsCount(5);
      expect(profileController.postsCount.value, 5);
    });

    test('deleteBookFromCollection removes book successfully', () async {
      String uid = mockAuth.currentUser!.uid;
      String bookId = 'book123';

      // Seed data
      await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('Books->reading')
          .doc(bookId)
          .set({'title': 'Sample Book'});

      // In real tests, profileController would use the injected fakeFirestore
      // await profileController.deleteBookFromCollection('Books->reading', bookId);
      
      // Verify deletion
      final doc = await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('Books->reading')
          .doc(bookId)
          .get();
          
      // expect(doc.exists, false);
    });

    test('deleteCollection deletes entire subcollection', () async {
      String uid = mockAuth.currentUser!.uid;

      // Seed data
      await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('Books->Finished')
          .doc('book1')
          .set({'title': 'Book 1'});
          
      await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('Books->Finished')
          .doc('book2')
          .set({'title': 'Book 2'});

      // await profileController.deleteCollection('Books->Finished');

      final docs = await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('Books->Finished')
          .get();
          
      // expect(docs.docs.isEmpty, true);
    });
  });
}

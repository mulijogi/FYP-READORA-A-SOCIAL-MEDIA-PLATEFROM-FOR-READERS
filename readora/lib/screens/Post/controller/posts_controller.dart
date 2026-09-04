import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Reminders/controller/reminder_controller.dart';
import 'package:readora/utils/custom_snackbar.dart';

class PostsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = false.obs;

  // Method to save the post
  Future<bool> savePost({
    required String? profilePicUrl,
    required String? username,
    required String postText,
  }) async {
    if (postText.isEmpty) {
      customSnackbar(title: "Error", message: "Post cannot be empty");
      return false;
    }

    try {
      isLoading.value = true;
      final user = FirebaseAuth.instance.currentUser;
      final postOwnerId = user?.uid;

      if (postOwnerId == null) {
        customSnackbar(title: "Error", message: "User not logged in");
        return false;
      }

      final docRef = await _firestore.collection('posts').add({
        'postText': postText,
        'profilePicUrl': profilePicUrl,
        'username': username,
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'postTimestamp': FieldValue.serverTimestamp(),
        'likedBy': [],
        'postOwnerId': postOwnerId,
      });

      // Notify all friends about the new post
      ReminderController.notifyFriendsOfNewPost(
        posterId: postOwnerId,
        posterName: username ?? 'Someone',
        posterPicUrl: profilePicUrl ?? '',
        postPreview: postText,
        postId: docRef.id,
      );

      customSnackbar(title: "Success", message: "Post added successfully");
      return true;
    } catch (e) {
      print("Error saving post: $e");
      customSnackbar(title: "Error", message: "Post not added.");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

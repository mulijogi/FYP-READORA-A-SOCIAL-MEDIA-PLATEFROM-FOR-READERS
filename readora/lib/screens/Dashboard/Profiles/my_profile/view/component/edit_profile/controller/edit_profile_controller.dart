import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:readora/screens/Dashboard/Home/controller/home_controller.dart';
import 'package:readora/screens/Dashboard/Home/view/home.dart';
import 'package:readora/utils/custom_snackbar.dart';

class EditProfileController extends GetxController {
  // Controllers for form fields
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final picker = ImagePicker();
  var profilePicUrl = ''.obs; // Observable for profile picture URL
  var isLoading = false.obs; // Observable loading state for image picking
  String initialFullName = '';
  String initialEmail = '';
  String initialAbout = '';

  final usernameError = RxString('');

  final List<String> availableGenres = [
    'Romance',
    'Fantasy',
    'History',
    'Mystery',
    'Drama',
    'Adventure',
    'Classic',
    'Sci-Fi',
    'Thriller',
    'Biography'
  ];

  var selectedGenres = <String>[].obs;

  bool isUsernameValid(String username) {
    return !(username.startsWith('-') || RegExp(r'^\d').hasMatch(username));
  }

  void setInitialValues(String fullName, String email, String about, List<String> genres) {
    initialFullName = fullName;
    initialEmail = email;
    initialAbout = about;
    selectedGenres.value = List<String>.from(genres);
  }

  // Method to check for changes
  bool hasChanges() {
    return fullNameController.text != initialFullName ||
        emailController.text != initialEmail ||
        aboutController.text != initialAbout ||
        !_areListsEqual(selectedGenres, Get.find<HomeController>().genres);
  }

  bool _areListsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    return a.toSet().difference(b.toSet()).isEmpty;
  }

  // Method to update user data
  Future<void> updateUserData() async {
    isLoading.value = true;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      final updatedusername = fullNameController.text.trim();
      final updatedabout = aboutController.text.trim();

      try {
        if (!isUsernameValid(updatedusername)) {
          customSnackbar(
              title: 'Error',
              message:
                  'Invalid username. It cannot start with a number or negative sign.');
          isLoading.value = false;
          return;
        }
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final currentUsername = userDoc.data()?['username'] ?? '';
        final currentuserabout = userDoc.data()?['about'] ?? '';

        final isUsernameChanged = currentUsername != updatedusername;
        final isAboutChanged = currentuserabout != updatedabout;

        if (updatedusername.isEmpty) {
          customSnackbar(title: 'Error', message: 'Full name cannot be empty.');
          isLoading.value = false;
          return;
        }

        if (isUsernameChanged) {
          final usernameExists = await _checkUsernameExists(updatedusername);
          if (usernameExists) {
            customSnackbar(
                title: 'Error',
                message: 'Username is already taken. Please choose another one.');
            isLoading.value = false;
            return;
          }
        }

        // Prepare fields to set
        Map<String, dynamic> updateData = {
          'about': updatedabout,
          'genres': selectedGenres.toList(),
        };

        if (isUsernameChanged) {
          updateData['username'] = updatedusername;
        }

        await FirebaseFirestore.instance.collection('users').doc(uid).set(
          updateData,
          SetOptions(merge: true),
        );

        if (isAboutChanged) {
          final friendsSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('friends')
              .get();

          for (var friendDoc in friendsSnapshot.docs) {
            final friendId = friendDoc['friendId'];
            await FirebaseFirestore.instance
                .collection('users')
                .doc(friendId)
                .collection('friends')
                .where('friendId', isEqualTo: uid)
                .get()
                .then((friendQuery) {
              for (var doc in friendQuery.docs) {
                doc.reference.update({
                  'about': updatedabout,
                });
              }
            });
          }
        }

        if (isUsernameChanged) {
          final friendsSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('friends')
              .get();

          for (var friendDoc in friendsSnapshot.docs) {
            final friendId = friendDoc['friendId'];

            await FirebaseFirestore.instance
                .collection('users')
                .doc(friendId)
                .collection('friends')
                .where('friendId', isEqualTo: uid)
                .get()
                .then((friendQuery) {
              for (var doc in friendQuery.docs) {
                doc.reference.update({
                  'friendName': updatedusername,
                });
              }
            });
          }

          final postsSnapshot = await FirebaseFirestore.instance
              .collection('posts')
              .where('postOwnerId', isEqualTo: uid)
              .get();

          for (var postDoc in postsSnapshot.docs) {
            await postDoc.reference.update({
              'username': updatedusername,
            });

            final likedBy = postDoc['likedBy'] ?? [];
            for (int i = 0; i < likedBy.length; i++) {
              if (likedBy[i] == initialFullName) {
                likedBy[i] = updatedusername;
              }
            }

            await postDoc.reference.update({
              'likedBy': likedBy,
            });
          }

          final postsLikedByUserSnapshot = await FirebaseFirestore.instance
              .collection('posts')
              .where('likedBy', arrayContains: initialFullName)
              .get();

          for (var postDoc in postsLikedByUserSnapshot.docs) {
            final likedBy = postDoc['likedBy'] ?? [];
            for (int i = 0; i < likedBy.length; i++) {
              if (likedBy[i] == initialFullName) {
                likedBy[i] = updatedusername;
              }
            }

            await postDoc.reference.update({
              'likedBy': likedBy,
            });
          }

          final groupChatsSnapshot =
              await FirebaseFirestore.instance.collection('group_chats').get();

          for (var groupChatDoc in groupChatsSnapshot.docs) {
            final members = groupChatDoc['members'] as List<dynamic>;
            for (int i = 0; i < members.length; i++) {
              if (members[i]['userName'] == initialFullName) {
                members[i]['userName'] = updatedusername;
              }
            }
            await groupChatDoc.reference.update({'members': members});

            final messagesSnapshot = await groupChatDoc.reference
                .collection('messages')
                .where('senderName', isEqualTo: initialFullName)
                .get();

            for (var messageDoc in messagesSnapshot.docs) {
              await messageDoc.reference
                  .update({'senderName': updatedusername});
            }
          }

          final friendssSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('friends')
              .get();

          List<String> friendIds = [];
          for (var friendDoc in friendssSnapshot.docs) {
            friendIds.add(friendDoc.id);
          }

          List<String> friendPostIds = [];
          for (var friendId in friendIds) {
            final postsSnapshot = await FirebaseFirestore.instance
                .collection('posts')
                .where('postOwnerId', isEqualTo: friendId)
                .get();

            for (var postDoc in postsSnapshot.docs) {
              friendPostIds.add(postDoc.id);
            }
          }

          for (var postId in friendPostIds) {
            final postCommentsSnapshot = await FirebaseFirestore.instance
                .collection('comments')
                .doc(postId)
                .collection('postComments')
                .get();

            for (var postCommentDoc in postCommentsSnapshot.docs) {
              final senderName = postCommentDoc['username'];
              if (senderName == initialFullName) {
                if (postCommentDoc['username'] != updatedusername) {
                  await postCommentDoc.reference.update({
                    'username': updatedusername,
                  });
                }
              }
            }
          }

          final chatRoomsSnapshot =
              await FirebaseFirestore.instance.collection('chat_rooms').get();

          for (var chatRoomDoc in chatRoomsSnapshot.docs) {
            final postsSnapshot = await chatRoomDoc.reference
                .collection('posts')
                .where('postOwnerId', isEqualTo: uid)
                .get();

            for (var postDoc in postsSnapshot.docs) {
              await postDoc.reference.update({
                'username': updatedusername,
              });
            }
          }
        }

        customSnackbar(title: "Success", message: 'Profile updated!');
        Get.to(() => const Home());
      } catch (e) {
        customSnackbar(title: 'Error', message: 'Failed to update profile: $e');
      } finally {
        isLoading.value = false;
      }
    } else {
      customSnackbar(title: 'Error', message: 'User not found');
      isLoading.value = false;
    }
  }

// Check if the username already exists
  Future<bool> _checkUsernameExists(String username) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      return querySnapshot
          .docs.isNotEmpty; // Returns true if the username exists
    } catch (e) {
      customSnackbar(
          title: 'Error', message: 'Error checking username availability: $e');
      return false;
    }
  }

  Future<void> pickImage() async {
    try {
      isLoading.value = true;

      // Request storage/photos permission first
      PermissionStatus status = await Permission.photos.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        customSnackbar(
            title: 'Permission',
            message:
                'Please grant storage permission to upload a profile picture.');
        isLoading.value = false;
        return;
      }

      final pickedFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

      if (pickedFile != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          print("[EditProfileController] Error: No user signed in");
          return;
        }

        final uid = user.uid;
        print("[EditProfileController] Starting profile pic upload for $uid");

        final storageRef =
            FirebaseStorage.instance.ref().child('profile_pics/$uid');
        final uploadTask = storageRef.putFile(File(pickedFile.path));

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print("[EditProfileController] Upload success: $downloadUrl");

        // 1. Update primary User doc
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'profilePicUrl': downloadUrl,
        });
        profilePicUrl.value = downloadUrl;
        print("[EditProfileController] Firestore user doc updated");

        // Background updates (fire and forget or wrap in separate try-catches)
        _updateRelatedCollections(uid, downloadUrl);

        customSnackbar(title: "Success", message: 'Profile picture updated!');
      }
    } catch (e) {
      print("[EditProfileController] Error picking/uploading image: $e");
      customSnackbar(
          title: 'Error', message: 'Failed to update profile picture: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateRelatedCollections(String uid, String downloadUrl) async {
    try {
      // Step 1: Update posts where user is owner
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('postOwnerId', isEqualTo: uid)
          .get();
      for (var postDoc in postsSnapshot.docs) {
        postDoc.reference.update({'profilePicUrl': downloadUrl}).catchError(
            (e) => print("Error updating post pic: $e"));
      }

      // Step 2: Update friends' collections
      final friendsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('friends')
          .get();
      for (var friendDoc in friendsSnapshot.docs) {
        final friendId = friendDoc.id;
        // Update the friend's record of this user
        FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .collection('friends')
            .where('friendId', isEqualTo: uid)
            .get()
            .then((q) {
          for (var d in q.docs) {
            d.reference.update({'friendProfilePicUrl': downloadUrl});
          }
        }).catchError((e) => print("Error updating friend record: $e"));
      }

      // Step 3: Update group chats
      final groupChatsSnapshot =
          await FirebaseFirestore.instance.collection('group_chats').get();
      for (var groupChatDoc in groupChatsSnapshot.docs) {
        final membersList = List.from(groupChatDoc['members']);
        bool changed = false;
        for (int i = 0; i < membersList.length; i++) {
          if (membersList[i]['userId'] == uid) {
            membersList[i]['profilePicUrl'] = downloadUrl;
            changed = true;
          }
        }
        if (changed) {
          groupChatDoc.reference.update({'members': membersList}).catchError(
              (e) => print("Error updating group member pic: $e"));
        }
      }
      print("[EditProfileController] Related collections update triggered");
    } catch (e) {
      print("[EditProfileController] Error in background updates: $e");
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    aboutController.dispose();
    super.onClose();
  }
}

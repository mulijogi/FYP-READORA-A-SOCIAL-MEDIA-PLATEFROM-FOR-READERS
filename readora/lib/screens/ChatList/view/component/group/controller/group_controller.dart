import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:readora/utils/custom_snackbar.dart';

class GroupController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;



RxList<String> groupIds = <String>[].obs;

Future<void> checkUserInGroupChat() async {
  try {
    String currentUserId = _auth.currentUser!.uid;

    // Listen for real-time updates where the current user is a member
    _firestore
        .collection('group_chats')
        .where('memberIds', arrayContains: currentUserId)
        .snapshots() // Real-time listener
        .listen((groupSnapshot) {
      // Clear previous data and add new group IDs when there are changes
      groupIds.clear();
      for (var doc in groupSnapshot.docs) {
        groupIds.add(doc.id); // Add group ID to the observable list
      }
    });
  } catch (e) {
    print("Error checking group membership: $e");
  }
}

  Future<void> createGroupChat(String groupName, List<Map<String, dynamic>> selectedFriends) async {
  try {
    // Get the current user's ID and user data
    String currentUserId = _auth.currentUser!.uid;
    DocumentSnapshot currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
    
    Map<String, dynamic>? userData = currentUserDoc.data() as Map<String, dynamic>?;
    String currentUserName = userData?['username'] ?? 'Unknown';
    String currentUserProfilePic = userData?['profilePicUrl'] ?? '';

    // Prepare a flat list of user IDs for querying
    List<String> memberIds = [currentUserId];
    for (var friend in selectedFriends) {
      if (friend['friendId'] != null) {
        memberIds.add(friend['friendId']);
      }
    }

    // Prepare the list of members with profile data
    List<Map<String, dynamic>> members = [
      {
        'userId': currentUserId,
        'userName': currentUserName,
        'profilePicUrl': currentUserProfilePic,
      },
      ...selectedFriends.map((friend) => {
        'userId': friend['friendId'] ?? '',
        'userName': friend['friendName'] ?? 'Unknown',
        'profilePicUrl': friend['profilePicUrl'] ?? '',
      }),
    ];

    // Create a new document in the 'group_chats' collection
    final groupDoc = _firestore.collection('group_chats').doc();

    // Set group data with the list of members and memberIds
    await groupDoc.set({
      'groupId': groupDoc.id,
      'groupName': groupName,
      'members': members,
      'memberIds': memberIds, // Added for efficient array-contains queries
      'createdAt': FieldValue.serverTimestamp(),
    });

    customSnackbar(title: "Success", message: "Group created successfully");
  } catch (e) {
    print("Error creating group: $e");
    customSnackbar(title: "Error", message: "Failed to create group: $e");
  }
}

  Future<void> deleteGroupChat(String groupId) async {
    try {
      // First, delete all messages in the group
      final messagesSnapshot = await _firestore
          .collection('group_chats')
          .doc(groupId)
          .collection('messages')
          .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Then delete the group document itself
      await _firestore.collection('group_chats').doc(groupId).delete();

      customSnackbar(title: "Success", message: "Group chat deleted successfully");
    } catch (e) {
      customSnackbar(title: "Error", message: "Failed to delete group chat: $e");
    }
  }
}

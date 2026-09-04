import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:readora/utils/custom_snackbar.dart';

class ShareController extends GetxController {
  final String postId;
  final RxList<Map<String, dynamic>> friends = <Map<String, dynamic>>[].obs;
  final RxList<String> selectedFriends = <String>[].obs;
  RxInt sharesCount = 0.obs;
  RxBool isLoadingFriends = false.obs;

  ShareController(this.postId);

  @override
  void onInit() {
    super.onInit();
    fetchFriends();
    listenToSharesCount();
  }

  Future<void> fetchFriends() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    isLoadingFriends.value = true;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('friends')
        .snapshots()
        .listen((snap) {
      print("[ShareController] Listener found ${snap.docs.length} friends.");
      _processFriendsSnapshot(snap.docs);
    }, onError: (e) {
      print("[ShareController] Error fetching friends: $e");
      isLoadingFriends.value = false;
    });
  }

  void _processFriendsSnapshot(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    List<Map<String, dynamic>> friendsList = [];
    for (var doc in docs) {
      final data = doc.data();
      // Support both field name variants
      final picUrl = data['friendProfilePicUrl'] ?? data['profilePicUrl'] ?? '';
      final name = data['friendName'] ?? data['username'] ?? 'Unknown';
      friendsList.add({
        'id': doc.id,
        'username': name,
        'profilePicUrl': picUrl,
      });
    }
    friends.assignAll(friendsList);
    isLoadingFriends.value = false; // Set false after data is loaded
    print("[ShareController] Assigned ${friendsList.length} friends.");
  }

  void toggleFriendSelection(String friendId) {
    print("[ShareController] Toggling selection for friend: $friendId");
    if (selectedFriends.contains(friendId)) {
      selectedFriends.remove(friendId);
      print("[ShareController] Removed $friendId from selectedFriends.");
    } else {
      selectedFriends.add(friendId);
      print("[ShareController] Added $friendId to selectedFriends.");
    }
    selectedFriends.refresh(); // Ensure UI updates
  }

  Future<void> sendPost() async {
    if (selectedFriends.isEmpty) {
      customSnackbar(title: "Info", message: "Please select at least one friend.");
      return;
    }

    try {
      final postDoc = await FirebaseFirestore.instance.collection('posts').doc(postId).get();

      if (!postDoc.exists) {
        customSnackbar(title: "Error", message: "Post no longer exists.");
        return;
      }

      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      int incrementBy = selectedFriends.length;
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'shares': FieldValue.increment(incrementBy),
      });

      final updatedPostData = postDoc.data()!;
      await sendToSelectedFriends(updatedPostData, currentUserId);
      
      customSnackbar(title: "Success", message: "Post shared with ${selectedFriends.length} friends!");
      selectedFriends.clear();
    } catch (e) {
      print('[ShareController] Error sending post: $e');
      customSnackbar(title: "Error", message: "Failed to share post.");
    }
  }

  Future<void> sendToSelectedFriends(Map<String, dynamic> postDetails, String currentUserId) async {
    final timestamp = DateTime.now();
    for (String friendId in selectedFriends) {
      // Create a message in the chat room instead of a generic 'postToSend' document
      await sendPostToChatRoom(postDetails, friendId, currentUserId);
    }
  }

  Future<void> sendPostToChatRoom(Map<String, dynamic> postDetails, String friendId, String currentUserId) async {
    String chatRoomId = getChatRoomId(currentUserId, friendId);
    
    final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId);
    final chatRoomSnapshot = await chatRoomRef.get();

    if (!chatRoomSnapshot.exists) {
      await chatRoomRef.set({
        'users': [currentUserId, friendId],
        'lastMessage': 'Shared a post',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    }

    await chatRoomRef.collection('posts').add({
      'senderId': currentUserId,
      'receiverId': friendId,
      'isRead': false,
      'type': 'post_share',
      'postId': postId,
      'postDetails': postDetails,
      'timesstamp': FieldValue.serverTimestamp(),
    });

    await chatRoomRef.update({
      'lastMessage': 'Shared a post',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });
  }

  String getChatRoomId(String u1, String u2) {
    List<String> ids = [u1, u2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  void listenToSharesCount() {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .snapshots()
        .listen((document) {
      if (document.exists) {
        sharesCount.value = document.data()?['shares'] ?? 0;
      }
    });
  }
}

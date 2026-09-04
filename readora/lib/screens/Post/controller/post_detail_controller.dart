import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class PostDetailController extends GetxController {
  final String postId;
  final RxMap<String, dynamic> postData = <String, dynamic>{}.obs;
  final RxBool isLoading = true.obs;
  final RxBool isLiked = false.obs;
  final RxInt likesCount = 0.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PostDetailController(this.postId);

  @override
  void onInit() {
    super.onInit();
    listenToPost();
    checkIfLiked();
  }

  void listenToPost() {
    if (postId.isEmpty) {
      isLoading.value = false;
      print("[PostDetailController] Error: postId is empty");
      return;
    }
    
    print("[PostDetailController] Listening to post: $postId");
    _firestore.collection('posts').doc(postId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        postData.value = snapshot.data() as Map<String, dynamic>;
        likesCount.value = postData['likes'] ?? 0;
        isLoading.value = false;
        print("[PostDetailController] Post data loaded successfully");
      } else {
        isLoading.value = false;
        print("[PostDetailController] Post document does not exist for ID: $postId");
        // Get.snackbar("Error", "Post not found.");
      }
    }, onError: (error) {
      print("[PostDetailController] Listener error: $error");
      isLoading.value = false;
    });
  }

  void checkIfLiked() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final likeDoc = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('likedBy')
        .doc(user.uid)
        .get();

    isLiked.value = likeDoc.exists;
  }

  Future<void> toggleLike() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final postRef = _firestore.collection('posts').doc(postId);
    final likeRef = postRef.collection('likedBy').doc(user.uid);

    if (isLiked.value) {
      // Unlike
      isLiked.value = false;
      likesCount.value--;
      await postRef.update({'likes': FieldValue.increment(-1)});
      await likeRef.delete();
    } else {
      // Like
      isLiked.value = true;
      likesCount.value++;
      await postRef.update({'likes': FieldValue.increment(1)});
      await likeRef.set({'likedAt': FieldValue.serverTimestamp()});

      // Send notification
      final postOwnerId = postData['postOwnerId'];
      if (postOwnerId != null && postOwnerId != user.uid) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final username = userDoc.data()?['username'] ?? 'Someone';
        final profilePicUrl = userDoc.data()?['profilePicUrl'] ?? '';

        await _firestore
            .collection('notifications')
            .doc(postOwnerId)
            .collection('likeNotifications')
            .add({
          'senderId': user.uid,
          'receiverId': postOwnerId,
          'postId': postId,
          'message': "$username liked your post",
          'profilePicUrl': profilePicUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }
}

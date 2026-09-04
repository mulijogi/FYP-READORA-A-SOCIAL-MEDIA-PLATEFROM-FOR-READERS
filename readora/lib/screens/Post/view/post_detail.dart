import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Post/controller/post_detail_controller.dart';
import 'package:readora/utils/app_assets.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/comments_section.dart';
import 'package:readora/utils/glass_box.dart';
import 'package:readora/utils/post_time.dart';
import 'package:readora/utils/share_section.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:readora/screens/Dashboard/Profiles/user_profile/view/user_profile.dart';
import 'package:readora/screens/Dashboard/Profiles/user_profile/controller/user_profile_controller.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/view/profile.dart';

class PostDetail extends StatefulWidget {
  final String postId;

  const PostDetail({super.key, required this.postId});

  @override
  State<PostDetail> createState() => _PostDetailState();
}

class _PostDetailState extends State<PostDetail> {
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _openUserProfile(BuildContext context, String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == currentUserId) {
      Get.to(() => const Profile());
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      
      // Dismiss loader
      if (mounted) Navigator.of(context).pop();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        final friendsSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('friends')
            .doc(userId)
            .get();
        final bool isFriend = friendsSnap.exists;

        Get.delete<UserProfileController>();
        Get.to(() => UserProfile(
              friendName: userData['username'] ?? 'Unknown',
              friendAbout: userData['about'] ?? '',
              friendProfilepic: userData['profilePicUrl'] ?? '',
              friendId: userId,
              friendrole: userData['role'] ?? '',
              isFriend: isFriend,
              requestid: '',
            ));
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      print("Error opening user profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final PostDetailController controller =
        Get.put(PostDetailController(widget.postId), tag: widget.postId);

    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Post Details", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.postData.isEmpty) {
          return const Center(
            child: Text("This post is no longer available.",
                style: TextStyle(color: Colors.white70)),
          );
        }

        final post = controller.postData;
        String postText = post['postText'] ?? post['text'] ?? '';
        String imageUrl = post['imageUrl'] ?? '';
        String audioUrl = post['audioUrl'] ?? '';
        String profilePicUrl = post['profilePicUrl'] ?? '';
        String friendName = post['friendName'] ?? post['username'] ?? 'Unknown';
        dynamic timestampValue = post['postTimestamp'] ?? post['timestamp'];
        final String ownerId = post['postOwnerId'] ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: GlassBox(
            borderRadius: 20,
            opacity: 0.12,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (ownerId.isNotEmpty) {
                        _openUserProfile(context, ownerId);
                      }
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColor.unselected,
                          backgroundImage: profilePicUrl.isNotEmpty
                              ? NetworkImage(profilePicUrl)
                              : null,
                          child: profilePicUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.white70)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friendName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              Text(
                                PostTime.timeAgo(timestampValue ?? 0),
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (postText.isNotEmpty)
                    Text(
                      postText,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  if (imageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, color: Colors.white24),
                        ),
                      ),
                    ),
                  if (audioUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                  _isPlaying ? Icons.pause_circle : Icons.play_circle,
                                  color: AppColor.clickedbutton,
                                  size: 32),
                              onPressed: () async {
                                if (_isPlaying) {
                                  await _audioPlayer.pause();
                                } else {
                                  await _audioPlayer.play(UrlSource(audioUrl));
                                }
                              },
                            ),
                            const Expanded(
                              child: Text("Voice Message",
                                  style: TextStyle(color: Colors.white70)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: SvgPicture.asset(
                              AppAssets.likeHeart,
                              colorFilter: ColorFilter.mode(
                                controller.isLiked.value
                                    ? AppColor.heartRed
                                    : Colors.white70,
                                BlendMode.srcIn,
                              ),
                              width: 22,
                              height: 22,
                            ),
                            onPressed: () => controller.toggleLike(),
                          ),
                          Text(
                            '${post['likes'] ?? 0} Likes',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      CommentSection(postId: widget.postId),
                      ShareSection(postId: widget.postId),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

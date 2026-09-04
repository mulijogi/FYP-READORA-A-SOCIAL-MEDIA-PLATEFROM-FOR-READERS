import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:readora/screens/ChatList/controller/chat_lists_controller.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/controller/profile_controller.dart';
import 'package:readora/screens/Recommendations/controller/recommendation_controller.dart';
import 'package:readora/screens/Post/view/post_detail.dart';
import 'package:readora/utils/app_assets.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/comments_section.dart';
import 'package:readora/utils/glass_box.dart';
import 'package:readora/utils/audio_player_widget.dart';
import 'package:readora/utils/post_time.dart';
import 'package:readora/utils/share_section.dart';
import 'package:readora/screens/Dashboard/Profiles/user_profile/view/user_profile.dart';
import 'package:readora/screens/Dashboard/Profiles/user_profile/controller/user_profile_controller.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/view/profile.dart';

class PostsList extends StatefulWidget {
  final Widget? header;
  const PostsList({
    super.key,
    this.header,
  });

  @override
  _PostsListState createState() => _PostsListState();
}

class _PostsListState extends State<PostsList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatListsController controller = Get.put(ChatListsController());
  final ProfileController profileController = Get.put(ProfileController());
  late final RecommendationController _recController;
  List<Map<String, dynamic>> friendsWithPosts = [];
  Set<String> likedPosts = {}; // Track liked posts using their IDs
  String currentUser = ''; // Variable to store the current user's username
  String profilePicUrl = '';
  bool isLoading = true; // Add loading state
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _recController = Get.put(RecommendationController());
    _recController.fetchRecommendedPosts();
    _recController.fetchRecommendedUsers();
    _getCurrentUser(); // Fetch current user detail
  }

  void _getCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser; // Get current user
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;
          if (mounted) {
            setState(() {
              currentUser = data != null && data.containsKey('username')
                  ? data['username']
                  : '';
              profilePicUrl = data != null && data.containsKey('profilePicUrl')
                  ? data['profilePicUrl']
                  : '';
            });
          }
          print("Current user: $currentUser");
          print("Current user: $profilePicUrl");

          // Fetch all registered users' posts in real-time
          _listenForAllPosts();
        } else {
          // User document missing (e.g. database cleared but auth remains)
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error in _getCurrentUser: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _listenForAllPosts() {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      var postsSubscription =
          _firestore.collection('posts').snapshots().listen((postsSnapshot) {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        List<Map<String, dynamic>> updatedPosts = [];

        for (final postDoc in postsSnapshot.docs) {
          var postId = postDoc.id;
          final data = postDoc.data();

          // Exclude logged-in user's own posts from main feed (Instagram behavior)
          final postOwnerId = data['postOwnerId'];
          final postUsername = data['username'] as String?;
          if ((currentUserId != null && postOwnerId == currentUserId) ||
              (currentUser.isNotEmpty && postUsername == currentUser)) {
            continue;
          }

          var likedBy = data.containsKey('likedBy') ? data['likedBy'] : [];
          bool isLikedByCurrentUser = likedBy.contains(currentUser);

          var rawTimestamp = data['postTimestamp'] ?? data['timestamp'];

          if (isLikedByCurrentUser) {
            likedPosts.add(postId);
          } else {
            likedPosts.remove(postId);
          }

          updatedPosts.add({
            'postId': postId,
            'friendName': data['username'] ?? 'Unknown',
            'profilePicUrl': data['profilePicUrl'] ?? '',
            'postDoc': postDoc,
            'postText': data['postText'] ?? data['text'] ?? '',
            'postTimestamp': rawTimestamp,
            'imageUrl': data['imageUrl'] ?? '',
            'audioUrl': data['audioUrl'] ?? '',
            'likes': data['likes'] ?? 0,
            'comments': data['comments'] ?? 0,
            'shares': data['shares'] ?? 0,
            'likedBy': likedBy,
            'isLikedByCurrentUser': isLikedByCurrentUser,
          });
        }

        // Sort posts by timestamp descending so latest post is at the top
        updatedPosts.sort((a, b) {
          var timeA = a['postTimestamp'];
          var timeB = b['postTimestamp'];

          if (timeA is Timestamp && timeB is Timestamp) {
            return timeB.compareTo(timeA);
          }
          if (timeA is Timestamp && timeB == null)
            return -1; // Newer post without server timestamp yet goes top
          if (timeA == null && timeB is Timestamp) return 1;
          return 0;
        });

        if (mounted) {
          setState(() {
            friendsWithPosts = updatedPosts;
            isLoading = false;
          });
        }
      }, onError: (e) {
        print("Error fetching all posts: $e");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      });

      _subscriptions.add(postsSubscription);
    } catch (e) {
      print("Error setting up posts listener: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleLike(
      String postId, int index, String? profilePicUrl) async {
    int currentLikes = friendsWithPosts[index]['likes'];
    final postDoc =
        await FirebaseFirestore.instance.collection('posts').doc(postId).get();
    final postOwnerId = postDoc.data()?['postOwnerId'];

    if (likedPosts.contains(postId)) {
      likedPosts.remove(postId);
      currentLikes--;
      friendsWithPosts[index]['likes'] = currentLikes;

      postDoc.reference.update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([currentUser]),
      }).then((_) {
        print("Post unliked.");
      }).catchError((error) {
        print("Error unliking post: $error");
      });
    } else {
      likedPosts.add(postId);
      currentLikes++;
      friendsWithPosts[index]['likes'] = currentLikes;

      postDoc.reference.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([currentUser]),
      }).then((_) async {
        print("Post liked.");

        // Log post content for recommendation learning
        final postText = friendsWithPosts[index]['postText'] as String? ?? '';
        _recController.logPostLikeInteraction(postText);
        _recController.fetchRecommendedPosts();

        // Send like notification
        final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

        if (postOwnerId != currentUserId) {
          final notificationData = {
            'senderId': currentUserId,
            'receiverId': postOwnerId,
            'postId': postId,
            'message': "$currentUser liked your post",
            'profilePicUrl': profilePicUrl,
            'timestamp': FieldValue.serverTimestamp(),
          };

          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(postOwnerId)
              .collection('likeNotifications')
              .add(notificationData)
              .then((_) {
            print("Like notification sent to $postOwnerId");
          }).catchError((error) {
            print("Error sending like notification: $error");
          });
        }
      }).catchError((error) {
        print("Error liking post: $error");
      });
    }

    // Update local state for UI
    if (mounted) {
      setState(() {
        // Update liked state
        friendsWithPosts[index]['isLikedByCurrentUser'] =
            likedPosts.contains(postId);
      });
    }
  }

  @override
  void dispose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
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

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

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
    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  if (widget.header != null)
                    SliverToBoxAdapter(child: widget.header),
                  // ── Suggested for You strip ──────────────────────────
                  Obx(() {
                    final allSuggested = _recController.recommendedPosts;
                    // Filter out hidden posts
                    final suggested = allSuggested
                        .where((p) => !_recController.hiddenSuggestedPostIds
                            .contains(p['id']))
                        .toList();

                    if (suggested.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    return SliverToBoxAdapter(
                      child: _buildSuggestedPostsStrip(suggested),
                    );
                  }),
                  // ── Friend posts list ────────────────────────────────
                  if (friendsWithPosts.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No posts available.',
                          style: TextStyle(color: AppColor.iconstext),
                        ),
                      ),
                    )
                  else
                    _buildFriendPostsSliver(),
                ],
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Suggested for You — horizontal strip of non-friend posts
  // ─────────────────────────────────────────────────────────────
  Widget _buildSuggestedPostsStrip(List<Map<String, dynamic>> posts) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: const [
                Icon(Icons.auto_awesome,
                    color: AppColor.clickedbutton, size: 18),
                SizedBox(width: 8),
                Text(
                  'Suggested for You',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: posts.length,
              itemBuilder: (context, i) {
                final p = posts[i];
                final picUrl = p['profilePicUrl'] as String? ?? '';
                final username = p['username'] as String? ?? 'Unknown';
                final text = p['text'] as String? ?? '';
                final likes = p['likes'] ?? 0;
                return GestureDetector(
                  onTap: () {
                    if (p['id'] != null) {
                      Get.to(() => PostDetail(postId: p['id']));
                    }
                  },
                  child: Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 12),
                    child: GlassBox(
                      borderRadius: 16,
                      opacity: 0.15,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      final String ownerId =
                                          p['postOwnerId'] ?? '';
                                      if (ownerId.isNotEmpty) {
                                        _openUserProfile(context, ownerId);
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.transparent,
                                          backgroundImage:
                                              (picUrl.trim().isNotEmpty)
                                                  ? NetworkImage(picUrl)
                                                      as ImageProvider
                                                  : const AssetImage(
                                                      AppAssets.defaultAvatar),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            username,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _recController
                                      .dismissSuggestedPost(p['id']),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.favorite,
                                    size: 12, color: AppColor.heartRed),
                                const SizedBox(width: 4),
                                Text(
                                  '$likes',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          const Divider(color: AppColor.unselected, height: 1),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Friend posts list (Sliver version)
  // ─────────────────────────────────────────────────────────────
  Widget _buildFriendPostsSliver() {
    friendsWithPosts.sort((a, b) {
      var timeA = a['postTimestamp'];
      var timeB = b['postTimestamp'];
      if (timeA is Timestamp && timeB is Timestamp) {
        return timeB.compareTo(timeA);
      }
      if (timeA is Timestamp && timeB == null) return -1;
      if (timeA == null && timeB is Timestamp) return 1;
      return 0;
    });

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 100), // Space for nav bar
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final post = friendsWithPosts[index];
            final postDoc = post['postDoc'] as DocumentSnapshot;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: GlassBox(
                borderRadius: 20,
                opacity: 0.15,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post header
                      GestureDetector(
                        onTap: () {
                          final postData =
                              postDoc.data() as Map<String, dynamic>?;
                          final String ownerId = postData?['postOwnerId'] ?? '';
                          if (ownerId.isNotEmpty) {
                            _openUserProfile(context, ownerId);
                          }
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22.0,
                              backgroundColor: Colors.transparent,
                              backgroundImage: (post['profilePicUrl'] != null &&
                                      post['profilePicUrl'].trim().isNotEmpty)
                                  ? NetworkImage(post['profilePicUrl'])
                                      as ImageProvider
                                  : const AssetImage(AppAssets.defaultAvatar),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post['friendName'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    PostTime.timeAgo(
                                        post['postTimestamp'] ?? 0),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      // Post content
                      Text(
                        post['postText'],
                        style:
                            const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      if (post['imageUrl'] != null &&
                          post['imageUrl'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: (post['imageUrl'] != null &&
                                    post['imageUrl'].toString().isNotEmpty &&
                                    post['imageUrl']
                                        .toString()
                                        .startsWith('http'))
                                ? Image.network(
                                    post['imageUrl'],
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: Colors.grey.withOpacity(0.2),
                                      height: 200,
                                      width: double.infinity,
                                      child: const Icon(Icons.broken_image,
                                          color: Colors.white30),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      if (post['audioUrl'] != null &&
                          post['audioUrl'].isNotEmpty)
                        AudioPlayerWidget(url: post['audioUrl']),
                      const SizedBox(height: 12.0),
                      // Post actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: SvgPicture.asset(
                                  AppAssets.likeHeart,
                                  colorFilter: ColorFilter.mode(
                                    likedPosts.contains(postDoc.id)
                                        ? AppColor.heartRed
                                        : Colors.white70,
                                    BlendMode.srcIn,
                                  ),
                                  width: 22,
                                  height: 22,
                                ),
                                onPressed: () => _toggleLike(
                                    friendsWithPosts[index]['postId'],
                                    index,
                                    post['profilePicUrl']),
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                '${post['likes']} Likes',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          CommentSection(postId: postDoc.id),
                          ShareSection(postId: postDoc.id),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: friendsWithPosts.length,
        ),
      ),
    );
  }
}

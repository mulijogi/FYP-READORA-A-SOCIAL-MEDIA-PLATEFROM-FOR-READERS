import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Friendreq/view/friendreq.dart';
import 'package:readora/screens/Dashboard/Notifications/controller/notification_controller.dart';
import 'package:readora/screens/Post/view/post_detail.dart';
import 'package:readora/screens/Reminders/view/reminder_settings.dart';
import 'package:readora/utils/app_assets.dart';
import 'package:readora/utils/appbar.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/glass_box.dart';

class Notifications extends StatelessWidget {
  const Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController notificationController =
        Get.put(NotificationController());

    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      appBar: CustomAppBar(
        title: "Notifications",
        showBackButton: true,
        role: '',
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: AppColor.iconstext),
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  backgroundColor: AppColor.bgcolor,
                  title: const Text("Delete All",
                      style: TextStyle(color: AppColor.white)),
                  content: const Text(
                      "Are you sure you want to delete all notifications?",
                      style: TextStyle(color: AppColor.iconstext)),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text("Cancel",
                          style: TextStyle(color: AppColor.iconstext)),
                    ),
                    TextButton(
                      onPressed: () {
                        notificationController.deleteAllNotifications();
                        Get.back();
                      },
                      child: const Text("Delete All",
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColor.iconstext),
            onPressed: () => Get.to(() => const ReminderSettings()),
          ),
        ],
      ),
      body: Obx(() {
        if (notificationController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (notificationController.notifications.isEmpty) {
          return const Center(
            child: Text("No notifications.",
                style: TextStyle(color: AppColor.iconstext)),
          );
        }

        // Grouping notifications by type
        final Map<String, List<Map<String, dynamic>>> grouped = {
          'Friend Requests': notificationController.notifications
              .where((n) => n['type'] == 'friend_request')
              .toList(),
          'Comments': notificationController.notifications
              .where((n) => n['type'] == 'comment')
              .toList(),
          'Likes': notificationController.notifications
              .where((n) => n['type'] == 'like')
              .toList(),
          'Posts': notificationController.notifications
              .where((n) => n['type'] == 'friend_post')
              .toList(),
        };

        // Remove empty categories
        grouped.removeWhere((key, value) => value.isEmpty);

        return ListView.builder(
          itemCount: grouped.length,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemBuilder: (context, catIndex) {
            String category = grouped.keys.elementAt(catIndex);
            List<Map<String, dynamic>> items = grouped[category]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      color: AppColor.clickedbutton,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                ...items.map((notification) {
                  var message =
                      notification['data']?['message'] ?? 'No message';
                  var senderId = notification['data']?['senderId'];
                  var messageId = notification['id'] ??
                      'unknown_${items.indexOf(notification)}';
                  var receiverId = notification['data']?['receiverId'] ?? '';
                  var type = notification['type'] ?? 'unknown';
                  var postId = notification['data']?['postId'];

                  return Dismissible(
                    key: Key(messageId),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      if (type == 'friend_request') {
                        notificationController.deleteFriendRequestNotification(
                            messageId, receiverId);
                      } else if (type == 'comment') {
                        notificationController.deleteCommentNotification(
                            messageId, receiverId);
                      } else if (type == 'like') {
                        notificationController.deleteLikeNotification(
                            messageId, receiverId);
                      } else if (type == 'friend_post') {
                        notificationController.deleteFriendPostNotification(
                            messageId, receiverId);
                      }
                    },
                    background: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: FutureBuilder<DocumentSnapshot>(
                      future: senderId != null
                          ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(senderId)
                              .get()
                          : Future.value(null),
                      builder: (context, userSnapshot) {
                        String profilePicUrl = '';
                        String username = 'User';
                        String about = '';
                        String role = '';

                        if (userSnapshot.hasData &&
                            userSnapshot.data != null &&
                            userSnapshot.data!.exists) {
                          var userData =
                              userSnapshot.data!.data() as Map<String, dynamic>;
                          profilePicUrl = userData['profilePicUrl'] ?? '';
                          username = userData['username'] ?? 'User';
                          about = userData['about'] ?? '';
                          role = userData['role'] ?? '';
                        }

                        var timestamp =
                            notification['data']['timestamp'] as Timestamp?;
                        String timeText = '';
                        if (timestamp != null) {
                          final diff =
                              DateTime.now().difference(timestamp.toDate());
                          if (diff.inMinutes < 1) {
                            timeText = 'just now';
                          } else if (diff.inHours < 1) {
                            timeText = '${diff.inMinutes}m';
                          } else if (diff.inDays < 1) {
                            timeText = '${diff.inHours}h';
                          } else {
                            timeText = '${diff.inDays}d';
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 6.0),
                          child: GlassBox(
                            borderRadius: 16,
                            opacity: 0.1,
                            child: InkWell(
                              onTap: () {
                                if (type == 'like' ||
                                    type == 'comment' ||
                                    type == 'friend_post') {
                                  if (postId != null) {
                                    Get.to(() => PostDetail(postId: postId));
                                  } else {
                                    Get.snackbar("Info",
                                        "This post is no longer available.");
                                  }
                                } else if (type == 'friend_request') {
                                  Get.to(() => const Friendreq());
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.transparent,
                                      backgroundImage: profilePicUrl.isNotEmpty
                                          ? NetworkImage(profilePicUrl)
                                              as ImageProvider
                                          : const AssetImage(
                                              AppAssets.defaultAvatar),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14.5),
                                              children: [
                                                TextSpan(
                                                  text: '$username ',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                TextSpan(
                                                  text: _formatMessage(
                                                      message, username),
                                                  style: const TextStyle(
                                                      color: Colors.white70),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            timeText,
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.5),
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      _getIconForType(type),
                                      color: _getIconColorForType(type),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            );
          },
        );
      }),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'friend_request':
        return Icons.person_add;
      case 'friend_post':
        return Icons.post_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColorForType(String type) {
    switch (type) {
      case 'like':
        return AppColor.heartRed;
      case 'comment':
        return AppColor.clickedbutton;
      default:
        return AppColor.clickedbutton;
    }
  }

  String _formatMessage(String message, String username) {
    if (message.startsWith(username)) {
      return message.replaceFirst(username, '').trim();
    }
    return message;
  }
}

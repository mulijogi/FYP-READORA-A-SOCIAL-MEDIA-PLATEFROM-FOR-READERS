import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Dashboard/Profiles/user_profile/controller/user_profile_controller.dart';
import 'package:readora/screens/Dashboard/Profiles/user_profile/view/user_profile.dart';
import 'package:readora/utils/appbar.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/glass_box.dart';

class UserFriendList extends StatefulWidget {
  final List<Map<String, dynamic>> friendsList;
  const UserFriendList({super.key, required this.friendsList});

  @override
  State<UserFriendList> createState() => _UserFriendListState();
}

class _UserFriendListState extends State<UserFriendList> {
  late final UserProfileController userprofileController;

  @override
  void initState() {
    super.initState();
    userprofileController = Get.put(UserProfileController(''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      appBar: const CustomAppBar(
        title: "Friends",
        showBackButton: true,
        role: '',
      ),
      body: Obx(() {
        if (widget.friendsList.isEmpty) {
          return const Center(
            child: Text('No friends found.',
                style: TextStyle(color: Colors.white70)),
          );
        } else {
          return ListView.builder(
            itemCount: widget.friendsList.length,
            padding: const EdgeInsets.all(12.0),
            itemBuilder: (context, index) {
              final friend = widget.friendsList[index];
              final picUrl = friend['friendProfilePicUrl'] ?? '';
              final friendName = friend['friendName'] ?? 'Unknown';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GlassBox(
                  borderRadius: 15,
                  opacity: 0.12,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: GestureDetector(
                      onTap: () {
                        // Logic to navigate to profile if needed
                      },
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: picUrl.isEmpty ? AppColor.iconstext : Colors.transparent,
                        backgroundImage: picUrl.isNotEmpty ? NetworkImage(picUrl) : null,
                        child: picUrl.isEmpty
                            ? const Icon(Icons.person, size: 24, color: AppColor.unselected)
                            : null,
                      ),
                    ),
                    title: Text(
                      friendName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      // Navigate to friend's profile
                      Get.to(() => UserProfile(
                        isFriend: true,
                        friendName: friendName,
                        friendAbout: friend['friendsabout'] ?? '',
                        friendProfilepic: picUrl,
                        friendId: friend['id'] ?? friend['friendId'] ?? '',
                        requestid: '',
                        friendrole: friend['role'] ?? 'user',
                      ));
                    },
                  ),
                ),
              );
            },
          );
        }
      }),
    );
  }
}

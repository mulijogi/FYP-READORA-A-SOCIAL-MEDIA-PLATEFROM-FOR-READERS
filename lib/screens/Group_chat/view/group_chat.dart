import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:readora/screens/ChatList/controller/chat_lists_controller.dart';
import 'package:readora/screens/Dashboard/Home/controller/home_controller.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/view/profile.dart';
import 'package:readora/screens/Dashboard/Profiles/user_profile/controller/user_profile_controller.dart';
import 'package:readora/screens/Dashboard/Profiles/user_profile/view/user_profile.dart';
import 'package:readora/screens/Group_chat/controller/group_chat_controller.dart';
import 'package:readora/utils/app_assets.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/glass_box.dart';

class GroupChat extends StatefulWidget {
  final List<dynamic> members;
  final String groupId;
  final String currentUserId;

  const GroupChat(
      {super.key,
      required this.members,
      required this.groupId,
      required this.currentUserId});

  @override
  State<GroupChat> createState() => _GroupChatState();
}

class _GroupChatState extends State<GroupChat> {
  late final GroupChatController groupChatController;
  final HomeController homeController = Get.find<HomeController>();

  String currentUser = '';

  @override
  void initState() {
    super.initState();
    groupChatController = Get.put(GroupChatController(groupId: widget.groupId));
    groupChatController.fetchGroupMembers();

    currentUser = homeController.username;
    print("current suer $currentUser");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      appBar: AppBar(
        backgroundColor: AppColor.bgcolor,
        iconTheme: const IconThemeData(color: AppColor.iconstext),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.members.map((member) {
              return GestureDetector(
                onTap: () async {
                  //   print("Group Members: ${groupChatController.groupMembers}");
                  // print("Clicked Member UserId: ${member['userId']}");
                  // Get.delete<UserProfileController>();
                  // Get full details from `membersfullydetails`
                  final memberFullyDetails =
                      groupChatController.groupMembers.firstWhere(
                    (m) => m['id'] == member['userId'], // Match userId
                    orElse: () => {}, // Default empty map if not found
                  );

                  final currentUserId =
                      FirebaseAuth.instance.currentUser?.uid ??
                          "defaultUserId"; // Provide a fallback ID
                  bool isFriend = await groupChatController.checkIfFriend(
                      currentUserId, member['userId']);

                  if (memberFullyDetails['id'] == currentUserId) {
                    Get.delete<ChatListsController>(); // Remove the controller
                    Get.to(() => const Profile());
                  } else {
                    Get.delete<
                        UserProfileController>(); // Remove the controller

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfile(
                          friendId: memberFullyDetails['id'],
                          friendName: memberFullyDetails['name'],
                          friendAbout: memberFullyDetails['about'],
                          friendProfilepic:
                              memberFullyDetails['profilePicUrl'] ?? '',
                          friendrole: memberFullyDetails['role'],
                          isFriend: isFriend,
                          requestid: '',
                        ),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: (member['profilePicUrl'] == null ||
                                member['profilePicUrl'].isEmpty)
                            ? AppColor
                                .iconstext // Replace with your desired background color
                            : Colors.transparent,
                        backgroundImage: (member['profilePicUrl'] != null &&
                                member['profilePicUrl']
                                    .toString()
                                    .trim()
                                    .isNotEmpty)
                            ? NetworkImage(member['profilePicUrl'])
                            : const AssetImage(AppAssets.defaultAvatar)
                                as ImageProvider,
                        child: (member['profilePicUrl'] == null ||
                                member['profilePicUrl'].trim().isEmpty)
                            ? const Icon(Icons.account_circle,
                                size: 20, color: AppColor.bgcolor)
                            : null,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        member['userName'] ?? member['name'] ?? 'Unknown',
                        style: const TextStyle(
                            color: AppColor.white, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(AppAssets.callicon,
                colorFilter: const ColorFilter.mode(
                    AppColor.iconstext, BlendMode.srcIn)),
            onPressed: () {
              // Handle call action
            },
          ),
          IconButton(
            icon: SvgPicture.asset(AppAssets.videoicon,
                colorFilter: const ColorFilter.mode(
                    AppColor.iconstext, BlendMode.srcIn)),
            onPressed: () {
              // Handle video call action
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Message List Section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: groupChatController.getMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text(
                    "No messages yet",
                    style: TextStyle(
                      color: AppColor.iconstext,
                    ),
                  ));
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var messageDoc = snapshot.data!.docs[index];
                    var messageData = messageDoc.data() as Map<String, dynamic>;
                    String messageId = messageDoc.id;
                    bool isCurrentUser =
                        messageData['senderId'] == widget.currentUserId;

                    return Align(
                      alignment: isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: isCurrentUser
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: AppColor.bgcolor,
                                    title: const Text("Delete Message",
                                        style: TextStyle(color: Colors.white)),
                                    content: const Text(
                                        "Are you sure you want to unsend this message?",
                                        style:
                                            TextStyle(color: Colors.white70)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel",
                                            style: TextStyle(
                                                color: AppColor.iconstext)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          groupChatController
                                              .deleteMessage(messageId);
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Unsend",
                                            style: TextStyle(
                                                color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: GlassBox(
                            borderRadius: 15,
                            opacity: isCurrentUser ? 0.2 : 0.1,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Display the sender's name
                                  Text(
                                    messageData['senderName'] ?? 'Unknown',
                                    style: TextStyle(
                                        color: isCurrentUser
                                            ? AppColor.clickedbutton
                                            : Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    messageData['message'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColor.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Section
          Container(
            margin: const EdgeInsets.only(
                left: 4,
                right: 4,
                bottom: 5), // Add horizontal margin and bottom margin
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8), // Padding inside the container
            decoration: const BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20), // Rounded top corners
                bottom: Radius.circular(20), // Rounded bottom corners
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: groupChatController.messageController,
                    style: const TextStyle(color: AppColor.bgcolor),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: AppColor.hinttextcolor),
                      filled: true,
                      fillColor: AppColor.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: SvgPicture.asset(AppAssets.sendicon,
                      colorFilter: const ColorFilter.mode(
                          AppColor.bgcolor, BlendMode.srcIn)),
                  onPressed: () {
                    final message =
                        groupChatController.messageController.text.trim();
                    if (message.isNotEmpty) {
                      groupChatController.sendMessage(
                          widget.currentUserId, currentUser, message);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

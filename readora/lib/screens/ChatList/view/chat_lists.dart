import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:readora/screens/ChatList/controller/chat_lists_controller.dart';
import 'package:readora/screens/ChatList/view/component/group/controller/group_controller.dart';
import 'package:readora/screens/Chats/controller/chat_controller.dart';
import 'package:readora/screens/Chats/view/Chatting.dart';
import 'package:readora/screens/Dashboard/Profiles/user_profile/controller/user_profile_controller.dart';
import 'package:readora/screens/Dashboard/Profiles/user_profile/view/user_profile.dart';
import 'package:readora/utils/app_assets.dart';
import 'package:readora/utils/appbar.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/glass_box.dart';
import 'package:readora/screens/Group_chat/view/group_chat.dart';

class ChatLists extends StatefulWidget {
  final String friendId;

  const ChatLists({super.key, required this.friendId});

  @override
  _ChatListsState createState() => _ChatListsState();
}

class _ChatListsState extends State<ChatLists> {
  final ChatListsController chatlistcontroller = Get.put(ChatListsController());
  final GroupController groupController = Get.put(GroupController());
  @override
  void initState() {
    super.initState();
    // Call the function to check group membership when the widget is initialized
    groupController.checkUserInGroupChat();
    chatlistcontroller.fetchGroupChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      body: Column(
        children: [
          const CustomAppBar(
            title: "Friends",
            groupicon: true,
            role: '',
          ),
          // ── Readers / Authors Toggle Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Obx(() {
              final isReaders = chatlistcontroller.selectedChatTab.value == 'readers';
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => chatlistcontroller.selectedChatTab.value = 'readers',
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isReaders ? AppColor.clickedbutton : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              "Readers Chats (${chatlistcontroller.readerFriends.length})",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isReaders ? Colors.white : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => chatlistcontroller.selectedChatTab.value = 'authors',
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !isReaders ? AppColor.clickedbutton : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              "Authors Chats (${chatlistcontroller.authorFriends.length})",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: !isReaders ? Colors.white : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          Expanded(
            child: Obx(() {
              if (chatlistcontroller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // Filter group chats where the current user is a member
              var userId = FirebaseAuth.instance.currentUser?.uid ?? '';
              var filteredGroupChats = chatlistcontroller.group_chats
                  .where((group) => group['members']
                      .any((member) => member['userId'] == userId))
                  .toList();

              final currentFriendsList = chatlistcontroller.selectedChatTab.value == 'readers'
                  ? chatlistcontroller.readerFriends
                  : chatlistcontroller.authorFriends;

              final showGroups = chatlistcontroller.selectedChatTab.value == 'readers';
              final groupCount = showGroups ? filteredGroupChats.length : 0;

              if (currentFriendsList.isEmpty && groupCount == 0) {
                return Center(
                    child: Text('No ${chatlistcontroller.selectedChatTab.value} chats found.',
                        style: const TextStyle(color: AppColor.iconstext)));
              }

              return ListView.builder(
                itemCount: groupCount + currentFriendsList.length,
                padding: const EdgeInsets.only(top: 4.0, bottom: 80),
                itemBuilder: (context, index) {
                  if (index < groupCount) {
                    // Show group chat cards
                    var group = filteredGroupChats[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 6.0),
                      child: GlassBox(
                        borderRadius: 15,
                        opacity: 0.15,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group Name
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    group['groupName'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.white,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: SvgPicture.asset(
                                          AppAssets.chat,
                                          colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                                          width: 20,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => GroupChat(
                                                members: group['members'],
                                                groupId: group['groupId'],
                                                currentUserId: userId,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: AppColor.bgcolor,
                                              title: const Text("Delete Group", style: TextStyle(color: Colors.white)),
                                              content: const Text("Are you sure you want to delete this group? This will remove it for everyone.", style: TextStyle(color: Colors.white70)),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text("Cancel", style: TextStyle(color: AppColor.iconstext)),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    groupController.deleteGroupChat(group['groupId']);
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              // Members Row
                              Row(
                                children: [
                                  // Profile Pictures
                                  Flexible(
                                    flex: 2,
                                    child: SizedBox(
                                      height: 40,
                                      child: Stack(
                                        children: [
                                          for (var i = 0;
                                              i < group['members'].length;
                                              i++)
                                            Positioned(
                                              left: i *
                                                  10.0, // Adjust overlap as needed
                                              child: CircleAvatar(
                                                radius: 20,
                                                backgroundColor: (group['members'][i]['profilePicUrl'] == null ||
                                                        group['members'][i]['profilePicUrl'].isEmpty)
                                                    ? AppColor
                                                        .iconstext // Replace with your desired background color
                                                    : Colors.transparent,
                                                backgroundImage: (group[
                                                                    'members'][i]
                                                                [
                                                                'profilePicUrl'] !=
                                                            null &&
                                                        group['members'][i][
                                                                'profilePicUrl']
                                                            .toString()
                                                            .isNotEmpty)
                                                    ? NetworkImage(group[
                                                                'members'][i]
                                                            ['profilePicUrl']
                                                        .toString())
                                                    : null,
                                                child: (group['members'][i][
                                                                'profilePicUrl'] ==
                                                            null ||
                                                        group['members'][i][
                                                                'profilePicUrl']
                                                            .toString()
                                                            .isEmpty)
                                                    ? const Icon(
                                                        Icons.account_circle,
                                                        size: 30,
                                                        color: AppColor.bgcolor,
                                                      )
                                                    : null,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // const SizedBox(width: 8),
                                  // Member Names
                                  Expanded(
                                    flex: 8,
                                    child: Text(
                                      group['members']
                                          .map((member) =>
                                              member['userName'] ??
                                              member['username'] ??
                                              'User')
                                          .join(", "),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Show individual friend cards
                    var adjustedIndex = index - groupCount;
                    var friend = currentFriendsList[adjustedIndex];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 3.0),
                      child: GlassBox(
                        borderRadius: 15,
                        opacity: 0.1,
                        child: Stack(
                          children: [
                            ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              leading: GestureDetector(
                                onTap: () {
                                  Get.delete<UserProfileController>();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserProfile(
                                        friendName: friend['friendName'],
                                        friendAbout: friend['about'],
                                        friendProfilepic:
                                            friend['profilePicUrl'],
                                        friendId: friend['friendId'],
                                        friendrole: friend['role'],
                                        isFriend: true,
                                        requestid: '',
                                      ),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: (friend['profilePicUrl'] != null &&
                                          friend['profilePicUrl'].trim().isNotEmpty)
                                      ? NetworkImage(friend['profilePicUrl'])
                                          as ImageProvider
                                      : const AssetImage(AppAssets.defaultAvatar),
                                ),
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    friend['friendName'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (friend['unreadPostsCount'] > 0)
                                    Text(
                                      friend['unreadPostsCount'] > 3
                                          ? '3+ New Posts'
                                          : '${friend['unreadPostsCount']} New Post${friend['unreadPostsCount'] > 1 ? 's' : ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.clickedbutton,
                                        fontSize: 14,
                                      ),
                                    ),
                                  if (friend['unreadPostsCount'] == 0 &&
                                      friend['unreadMessageCount'] > 0)
                                    Text(
                                      friend['unreadMessageCount'] > 3
                                          ? '3+ New Messages'
                                          : '${friend['unreadMessageCount']} New Message${friend['unreadMessageCount'] > 1 ? 's' : ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.clickedbutton,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: SvgPicture.asset(
                                      AppAssets.chat,
                                      colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                                    ),
                                    onPressed: () async {
                                      var currentUser =
                                          FirebaseAuth.instance.currentUser;

                                      String chatRoomId =
                                          chatlistcontroller.generateChatRoomId(
                                              currentUser!.uid,
                                              friend['friendId'] ?? '');

                                      bool chatRoomExists =
                                          await chatlistcontroller
                                              .checkChatRoomExists(chatRoomId);
                                      if (!chatRoomExists) {
                                        // await
                                        chatlistcontroller.createChatRoom(
                                            chatRoomId,
                                            currentUser.uid,
                                            friend['friendId'] ?? '');
                                      }
                                      //  await
                                      chatlistcontroller.markMessagesAsRead(
                                          friend['friendId'] ?? '');
                                      // await
                                      chatlistcontroller.markPostsAsRead(
                                          friend['friendId'] ?? '');

                                      chatlistcontroller.updateFriendList(
                                          friend['friendId'], 0,
                                          isMessage: true);
                                      chatlistcontroller.updateFriendList(
                                          friend['friendId'], 0,
                                          isMessage: false);

                                      Get.delete<ChatController>();

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Chatting(
                                            friendId: friend['friendId'] ?? '',
                                            friendName: friend['friendName'] ??
                                                'Unknown',
                                            profilePicUrl:
                                                friend['profilePicUrl'] ?? '',
                                            chatRoomId: chatRoomId,
                                            status:
                                                friend['status'] ?? 'offline',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 35,
                              left: 42,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (friend['status'] == 'online')
                                      ? AppColor.clickedbutton
                                      : AppColor.unselected,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              );
            }),
          )
        ],
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Chats/controller/chat_controller.dart';
import 'package:readora/utils/app_assets.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/glass_box.dart';
import 'package:readora/utils/audio_player_widget.dart';
import 'package:readora/screens/Post/view/post_detail.dart';
import 'package:url_launcher/url_launcher.dart';

class Chatting extends StatefulWidget {
  final String friendId;
  final String friendName;
  final String profilePicUrl;
  final String chatRoomId;
  final String status;

  const Chatting({
    super.key,
    required this.friendId,
    required this.friendName,
    required this.profilePicUrl,
    required this.chatRoomId,
    required this.status,
  });

  @override
  State<Chatting> createState() => _ChattingState();
}

class _ChattingState extends State<Chatting> {
  late final ChatController chatController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final RxBool _showOptions = false.obs;
  final RxBool _isRecording = false.obs;

  @override
  void initState() {
    super.initState();
    chatController = Get.put(ChatController(widget.chatRoomId));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.transparent,
              backgroundImage: widget.profilePicUrl.trim().isNotEmpty
                  ? NetworkImage(widget.profilePicUrl) as ImageProvider
                  : const AssetImage(AppAssets.defaultAvatar),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.friendName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text(widget.status,
                    style: TextStyle(
                        color: widget.status == 'online'
                            ? Colors.greenAccent
                            : Colors.white60,
                        fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColor.bgcolor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Obx(() {
                  var messages = chatController.allMessages;
                  if (messages.isEmpty && chatController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (messages.isEmpty) {
                    return const Center(
                        child: Text("No messages yet",
                            style: TextStyle(color: Colors.white38)));
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(messages[index]);
                    },
                  );
                }),
              ),
              _buildInputSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data) {
    String? messageId = data['id'];
    bool isMe = data['senderId'] == FirebaseAuth.instance.currentUser!.uid;
    String type = data['type'] ?? 'messages';

    if (type == 'post_share') {
      return _buildPostShareBubble(data, isMe);
    }

    String text = data['text'] ?? '';
    bool isImage = text.startsWith('image:');
    bool isAudio = text.startsWith('audio:');
    bool isFile = text.startsWith('file:');

    Widget content;
    if (isImage) {
      String imageUrl = text.substring(6).trim();
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    color: Colors.white24,
                    size: 50),
              )
            : const Icon(Icons.image_not_supported,
                color: Colors.white24, size: 50),
      );
    } else if (isAudio) {
      String audioUrl = text.substring(6).trim();
      content = AudioPlayerWidget(url: audioUrl);
    } else if (isFile) {
      String fileUrl = text.substring(5).trim();
      String fileName = data['fileName'] ?? 'File';
      content = InkWell(
        onTap: () => launchUrl(Uri.parse(fileUrl)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.white70),
            const SizedBox(width: 8),
            Flexible(
              child: Text(fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline)),
            ),
          ],
        ),
      );
    } else {
      content = Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 14.5));
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe && messageId != null
            ? () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColor.bgcolor,
                    title: const Text("Delete Message",
                        style: TextStyle(color: Colors.white)),
                    content: const Text(
                        "Are you sure you want to unsend this message?",
                        style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel",
                            style: TextStyle(color: AppColor.iconstext)),
                      ),
                      TextButton(
                        onPressed: () {
                          chatController.deleteMessage(messageId);
                          Navigator.pop(context);
                        },
                        child: const Text("Unsend",
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              }
            : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: GlassBox(
            borderRadius: 16,
            opacity: isMe ? 0.2 : 0.1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: Get.width * 0.75),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostShareBubble(Map<String, dynamic> data, bool isMe) {
    final postDetails = data['postDetails'] as Map<String, dynamic>?;
    if (postDetails == null) return const SizedBox.shrink();

    String? messageId = data['id'];
    String username = postDetails['username'] ?? 'Unknown';
    String postText = postDetails['postText'] ?? '';
    String imageUrl = postDetails['imageUrl'] ?? '';
    String profilePicUrl = postDetails['profilePicUrl'] ?? '';
    String postId = data['postId'] ?? '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe && messageId != null
            ? () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColor.bgcolor,
                    title: const Text("Delete Shared Post",
                        style: TextStyle(color: Colors.white)),
                    content: const Text(
                        "Are you sure you want to unsend this shared post?",
                        style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel",
                            style: TextStyle(color: AppColor.iconstext)),
                      ),
                      TextButton(
                        onPressed: () {
                          // For shared posts, we might need to know if it's in 'messages' or 'posts' collection
                          // But ChatController.deleteMessage currently only looks in 'messages'
                          // In _updateCombinedList, 'posts' are also added to allMessages.
                          // If it's a post share, it's likely in the 'posts' subcollection.
                          chatController.deleteMessage(messageId); 
                          Navigator.pop(context);
                        },
                        child: const Text("Unsend",
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              }
            : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          constraints: BoxConstraints(maxWidth: Get.width * 0.75),
          child: InkWell(
            onTap: () {
              if (postId.isNotEmpty) {
                Get.to(() => PostDetail(postId: postId));
              }
            },
            child: GlassBox(
              borderRadius: 20,
              opacity: isMe ? 0.2 : 0.1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.transparent,
                          backgroundImage: profilePicUrl.isNotEmpty
                              ? NetworkImage(profilePicUrl) as ImageProvider
                              : const AssetImage(AppAssets.defaultAvatar),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            username,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (imageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(imageUrl,
                            fit: BoxFit.cover, width: double.infinity),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      postText,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20)),
                    ),
                    child: const Center(
                      child: Text("View Post",
                          style: TextStyle(
                              color: AppColor.clickedbutton,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        Obx(() =>
            _showOptions.value ? _buildOptions() : const SizedBox.shrink()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: GlassBox(
            borderRadius: 30,
            opacity: 0.1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_circle,
                        color: _showOptions.value
                            ? AppColor.clickedbutton
                            : Colors.white70),
                    onPressed: () => _showOptions.toggle(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        hintStyle:
                            TextStyle(color: Colors.white38, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onLongPressStart: (_) async {
                      _isRecording.value = true;
                      await chatController.startRecording();
                    },
                    onLongPressEnd: (_) async {
                      _isRecording.value = false;
                      await chatController.stopRecording();
                    },
                    child: Obx(() => Icon(
                          _isRecording.value ? Icons.mic : Icons.mic_none,
                          color: _isRecording.value
                              ? Colors.redAccent
                              : Colors.white70,
                        )),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColor.clickedbutton),
                    onPressed: () {
                      if (_messageController.text.trim().isNotEmpty) {
                        chatController
                            .sendMessage(_messageController.text.trim());
                        _messageController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassBox(
        borderRadius: 20,
        opacity: 0.15,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _optionIcon(
                  Icons.image, "Gallery", () => chatController.pickImage()),
              _optionIcon(Icons.insert_drive_file, "File",
                  () => chatController.pickFile()),
              _optionIcon(Icons.camera_alt, "Camera",
                  () => chatController.pickImageFromCamera()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        onTap();
        _showOptions.value = false;
      },
      child: Column(
        children: [
          CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.1),
              child: Icon(icon, color: Colors.white)),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

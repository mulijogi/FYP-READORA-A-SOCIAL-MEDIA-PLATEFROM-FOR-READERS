import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:readora/screens/Dashboard/Home/view/component/comments/controller/comments_controller.dart';
import 'package:readora/utils/app_assets.dart';
import 'package:readora/utils/colors.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  late TextEditingController commentController;
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    commentController = TextEditingController();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    commentController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CommentsController controller =
        Get.put(CommentsController(widget.postId));

    return GestureDetector(
      onTap: () {
        FocusScope.of(context)
            .unfocus(); // Close the keyboard when tapping outside
      },
      child: WillPopScope(
        onWillPop: () async {
          if (focusNode.hasFocus) {
            focusNode.unfocus();
            return false; // Prevent back action if the keyboard is open
          }
          return true; // Allow back action if the keyboard is closed
        },
        child: Material(
          color: AppColor.wholescreencolor,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Color(0xFF131A22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColor.white,
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.close, color: AppColor.iconstext),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.comments.isEmpty) {
                      return const Center(
                        child: Text(
                          'No comments yet.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: controller.comments.length,
                      itemBuilder: (context, index) {
                        final comment = controller.comments[index];
                        final isMe = comment['userId'] ==
                            FirebaseAuth.instance.currentUser?.uid;

                        return GestureDetector(
                          onLongPress: isMe
                              ? () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: AppColor.bgcolor,
                                      title: const Text("Delete Comment",
                                          style:
                                              TextStyle(color: Colors.white)),
                                      content: const Text(
                                          "Are you sure you want to delete your comment?",
                                          style:
                                              TextStyle(color: Colors.white70)),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Cancel",
                                              style: TextStyle(
                                                  color: AppColor.iconstext)),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            controller.deleteComment(
                                                comment['commentId']);
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Delete",
                                              style: TextStyle(
                                                  color: Colors.redAccent)),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  (comment['profilePicUrl'] == null ||
                                          comment['profilePicUrl'].isEmpty)
                                      ? AppColor.iconstext
                                      : Colors.transparent,
                              backgroundImage:
                                  (comment['profilePicUrl'] != null &&
                                          comment['profilePicUrl'] != '')
                                      ? NetworkImage(comment['profilePicUrl'])
                                      : null,
                              child: (comment['profilePicUrl'] == null ||
                                      comment['profilePicUrl'] == '')
                                  ? const Icon(Icons.person,
                                      size: 30, color: AppColor.unselected)
                                  : null,
                            ),
                            title: Text(
                              comment['username'] ?? 'Anonymous',
                              style: const TextStyle(
                                  color: AppColor.textwhitecolor),
                            ),
                            subtitle: Text(
                              comment['commentText'] ?? '',
                              style: const TextStyle(
                                  color: AppColor.textwhitecolor),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                    left: 8.0,
                    right: 8.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          focusNode: focusNode,
                          style: const TextStyle(color: AppColor.white),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle:
                                const TextStyle(color: AppColor.hinttextcolor),
                            filled: true,
                            fillColor: AppColor.cardcolor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 20.0),
                            suffixIcon: IconButton(
                              icon: SvgPicture.asset(AppAssets.sendicon,
                                  colorFilter: const ColorFilter.mode(AppColor.iconstext, BlendMode.srcIn)),
                              onPressed: () {
                                if (commentController.text.trim().isNotEmpty) {
                                  controller
                                      .postComment(commentController.text);
                                  commentController.clear();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Post/controller/posts_controller.dart';
import 'package:readora/utils/colors.dart';

class Posts extends StatefulWidget {
  final String? profilePicUrl;
  final String? username;

  const Posts({super.key, this.profilePicUrl, this.username});

  @override
  _PostsState createState() => _PostsState();
}

class _PostsState extends State<Posts> {
  final TextEditingController _postController = TextEditingController();
  final PostsController _postsController = Get.put(PostsController());
  
  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: Get.height * 0.8,
          decoration: const BoxDecoration(
            color: AppColor.bgcolor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColor.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColor.iconstext),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25.0,
                            backgroundColor: (widget.profilePicUrl == null || widget.profilePicUrl!.isEmpty)
                                ? AppColor.iconstext
                                : Colors.transparent,
                            backgroundImage: (widget.profilePicUrl != null && widget.profilePicUrl!.isNotEmpty)
                                ? NetworkImage(widget.profilePicUrl!)
                                : null,
                            child: (widget.profilePicUrl == null || widget.profilePicUrl!.isEmpty)
                                ? const Icon(Icons.person, size: 25, color: AppColor.unselected)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.username ?? 'User',
                            style: const TextStyle(color: AppColor.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _postController,
                        decoration: const InputDecoration(
                          hintText: "What's on your mind?",
                          hintStyle: TextStyle(color: AppColor.hinttextcolor),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: AppColor.white, fontSize: 18),
                        maxLines: null,
                        autofocus: true,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Obx(() => ElevatedButton(
                  onPressed: () async {
                    bool success = await _postsController.savePost(
                      profilePicUrl: widget.profilePicUrl,
                      username: widget.username,
                      postText: _postController.text,
                    );
                    if (success) {
                      Future.delayed(const Duration(seconds: 1), () {
                        Get.back();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.clickedbutton,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _postsController.isLoading.value
                      ? const CircularProgressIndicator(color: AppColor.white)
                      : const Text("Post", style: TextStyle(color: AppColor.white, fontSize: 16, fontWeight: FontWeight.bold)),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

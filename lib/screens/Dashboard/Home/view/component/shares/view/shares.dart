import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Dashboard/Home/view/component/shares/controller/share_controller.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/glass_box.dart';

class ShareScreen extends StatefulWidget {
  final String postId;

  const ShareScreen({super.key, required this.postId});

  @override
  _ShareScreenState createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  late final ShareController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ShareController>(tag: widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Material(
        color: Colors.transparent,
        child: GlassBox(
          borderRadius: 20,
          opacity: 0.15,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.35,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Share with Friends',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoadingFriends.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (controller.friends.isEmpty) {
                      return const Center(
                        child: Text('No friends found.', 
                          style: TextStyle(color: Colors.white60)),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.friends.length,
                      itemBuilder: (context, index) {
                        final friend = controller.friends[index];
                        final isSelected = controller.selectedFriends.contains(friend['id']);
                        return GestureDetector(
                          onTap: () {
                            controller.toggleFriendSelection(friend['id']);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? AppColor.clickedbutton : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.white10,
                                        backgroundImage: friend['profilePicUrl'].isNotEmpty
                                            ? NetworkImage(friend['profilePicUrl'])
                                            : null,
                                        child: friend['profilePicUrl'].isEmpty
                                            ? const Icon(Icons.person, color: Colors.white24, size: 30)
                                            : null,
                                      ),
                                    ),
                                    if (isSelected)
                                      const CircleAvatar(
                                        radius: 10,
                                        backgroundColor: AppColor.clickedbutton,
                                        child: Icon(Icons.check, size: 12, color: Colors.white),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    friend['username'],
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.clickedbutton,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      await controller.sendPost();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Send Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

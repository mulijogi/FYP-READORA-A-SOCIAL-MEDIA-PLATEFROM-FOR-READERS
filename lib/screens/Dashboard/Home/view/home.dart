import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Books/view/books.dart';
import 'package:readora/screens/ChatList/controller/chat_lists_controller.dart';
import 'package:readora/screens/ChatList/view/chat_lists.dart';
import 'package:readora/screens/Dashboard/Home/controller/home_controller.dart';
import 'package:readora/screens/Dashboard/Home/view/component/postsList.dart';
import 'package:readora/screens/Dashboard/Notifications/view/notifications.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/view/component/edit_profile/controller/edit_profile_controller.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/view/profile.dart';
import 'package:readora/screens/Dashboard/Searchfriend/view/searchfriend.dart';
import 'package:readora/screens/Friendreq/view/friendreq.dart';
import 'package:readora/screens/Post/view/posts.dart';
import 'package:readora/utils/app_assets.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/readora_logo.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final HomeController homeController = Get.put(HomeController());
  final ChatListsController chatListController = Get.put(ChatListsController());
  final EditProfileController editProfileController =
      Get.put(EditProfileController());

  final RxInt selectedIndex = 0.obs;
  // Hide-on-scroll state
  final RxBool _isNavBarVisible = true.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            final delta = notification.scrollDelta ?? 0;
            if (delta > 3) {
              // scrolling down → hide
              _isNavBarVisible.value = false;
            } else if (delta < -3) {
              // scrolling up → show
              _isNavBarVisible.value = true;
            }
          }
          return false;
        },
        child: Stack(
          children: [
            // The content behind the navigation bar
            Obx(() {
              return _getSelectedPage(selectedIndex.value, homeController);
            }),

            // Positioned CurvedNavigationBar at the bottom
            Obx(() {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                bottom: _isNavBarVisible.value ? 0 : -80,
                left: 0,
                right: 0,
                child: Obx(() {
                  return CurvedNavigationBar(
                    index: selectedIndex.value,
                    backgroundColor: Colors
                        .transparent, // Transparent background behind navigation bar
                    color: AppColor.unselected, // Dark bar color
                    buttonBackgroundColor:
                        AppColor.clickedbutton, // Button background color
                    items: <Widget>[
                      SvgPicture.asset(
                        AppAssets.home,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        colorFilter: const ColorFilter.mode(AppColor.iconstext, BlendMode.srcIn),
                      ),
                      SvgPicture.asset(
                        AppAssets.book,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        colorFilter: const ColorFilter.mode(AppColor.iconstext, BlendMode.srcIn),
                      ),
                      Image.asset(
                        AppAssets.searchicon,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        color: AppColor.iconstext,
                      ),
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          SvgPicture.asset(
                            AppAssets.people,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            colorFilter: const ColorFilter.mode(AppColor.iconstext, BlendMode.srcIn),
                          ),
                          Obx(() => homeController.pendingFriendRequests > 0
                              ? Positioned(
                                  right: 2,
                                  top: -4,
                                  left: 9,
                                  child: CircleAvatar(
                                    backgroundColor: AppColor.clickedbutton,
                                    radius:
                                        10, // Increased radius for better visibility
                                    child: Text(
                                      homeController.pendingFriendRequests
                                          .toString(),
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.white),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink()), // Hide if no requests
                        ],
                      ),
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          SvgPicture.asset(AppAssets.chat,
                              colorFilter: const ColorFilter.mode(AppColor.iconstext, BlendMode.srcIn)),
                          Obx(() => chatListController.totalUnreadCount > 0
                              ? Positioned(
                                  right: 0,
                                  top: 0,
                                  child: CircleAvatar(
                                    backgroundColor: AppColor.clickedbutton,
                                    radius: 7,
                                    child: Text(
                                      chatListController.totalUnreadCount
                                          .toString(),
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.white),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink()),
                        ],
                      ),
                    ],
                    onTap: (index) {
                      selectedIndex.value = index;
                      // Always show nav bar when tapping tabs
                      _isNavBarVisible.value = true;
                    },
                  );
                }),
              );
            }),
          ],
        ),
      ),

      // Floating action button for posts
      floatingActionButton: Obx(() {
        // Only show the FloatingActionButton on Home (index 0) or Profile (index 1) pages
        if (selectedIndex.value == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 80, left: 20),
            child: FloatingActionButton(
              backgroundColor: AppColor.unselected
                  .withOpacity(1), // Semi-transparent background
              onPressed: () {
                // Show modal bottom sheet instead of navigating to a new page
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, // Allows control over height
                  backgroundColor: Colors.transparent, // Fix white screen glitch

                  builder: (context) {
                    return FractionallySizedBox(
                      child: Posts(
                        profilePicUrl: homeController.profilePicUrl,
                        username: homeController.username,
                      ),
                    );
                  },
                ).then((value) {
                  homeController.fetchPendingRequests();
                });
              },
              child: const Icon(
                Icons.add,
                color: AppColor.iconstext,
              ),
            ),
          );
        } else {
          return const SizedBox
              .shrink(); // Do not display the button on other screens
        }
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

// For the Profile Avatar and Notification Bar
  Widget _buildProfileAvatar(HomeController homeController) {
    return Padding(
      padding: const EdgeInsets.only(top: 60.0, left: 10.0, right: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Get.to(() => const Profile());
            },
            child: Obx(() {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundImage: homeController.profilePicUrl.isNotEmpty
                        ? NetworkImage(homeController.profilePicUrl)
                            as ImageProvider
                        : const AssetImage(AppAssets.defaultAvatar),
                    radius: 25,
                    backgroundColor: Colors.transparent,
                  ),
                ],
              );
            }),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: const Offset(
                    -7, 0), // Move the image 20 pixels down (adjust as needed)
                child: const ReadoraLogo(fontSize: 28),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Get.to(() => const Notifications());
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    SvgPicture.asset(
                      AppAssets.bell,
                      width: 35,
                      height: 35,
                      colorFilter: const ColorFilter.mode(AppColor.iconstext, BlendMode.srcIn),
                    ),
                    Obx(() {
                      if (homeController.totalNotificationsCount > 0) {
                        return Positioned(
                          right: 0,
                          top: 0,
                          child: CircleAvatar(
                            backgroundColor: AppColor.clickedbutton,
                            radius: 8,
                            child: Text(
                              homeController.totalNotificationsCount.toString(),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSelectedPage(int index, HomeController homeController) {
    switch (index) {
      case 0:
        return PostsList(
          header: _buildProfileAvatar(homeController),
        );
      case 1:
        return const Books();
      case 2:
        return const SearchFriend();
      case 3:
        return const Friendreq();
      case 4:
        return ChatLists(
            friendId: 'your_friend_id_here'); // Pass the actual friend ID
      default:
        return const Center(
          child: Text(
            'Page not found!',
            style: TextStyle(fontSize: 20, color: Colors.black),
          ),
        );
    }
  }
}

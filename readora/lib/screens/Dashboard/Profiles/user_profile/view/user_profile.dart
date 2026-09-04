import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Dashboard/Profiles/user_profile/controller/user_profile_controller.dart';
import 'package:readora/screens/Dashboard/Profiles/user_profile/view/component/respond.dart';
import 'package:readora/screens/Dashboard/Profiles/user_profile/view/component/user_friend_list.dart';
import 'package:readora/utils/app_assets.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/comments_section.dart';
import 'package:readora/utils/glass_box.dart';
import 'package:readora/utils/on_screen_picture.dart';
import 'package:readora/utils/post_time.dart';
import 'package:readora/utils/share_section.dart';
import 'package:readora/utils/audio_player_widget.dart';
import 'package:readora/screens/Books/view/component/books-details/view/books_details.dart';

class UserProfile extends StatefulWidget {
  final bool isFriend;
  final String friendName;
  final String friendAbout;
  final String friendProfilepic;
  final String friendId;
  final String requestid;
  final String friendrole;

  const UserProfile(
      {super.key,
      required this.isFriend,
      required this.friendName,
      required this.friendAbout,
      required this.friendProfilepic,
      required this.friendId,
      required this.requestid,
      required this.friendrole});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  int selectedTabIndex = 0;
  late final UserProfileController userprofileController;

  @override
  void initState() {
    super.initState();
    userprofileController =
        Get.put(UserProfileController(widget.friendId), tag: widget.friendId);
    userprofileController.listenToFriendRequestStatus(widget.friendId);
    userprofileController.listenToFriendshipStatus(widget.friendId);
    userprofileController.friendsBooks(widget.friendId);
  }

  void _showUnfollowDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColor.bgcolor,
        title: const Text("Unfollow", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to unfollow ${widget.friendName}?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              userprofileController.unfriendUser(widget.friendId);
              Get.back();
            },
            child: const Text("Unfollow", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      appBar: AppBar(
        title: const Text("User Profile",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Row(
              children: [
                GestureDetector(
                  onTap: () => Get.to(() =>
                      OnScreenPicture(profilePicUrl: widget.friendProfilepic)),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.transparent,
                    backgroundImage: widget.friendProfilepic.isNotEmpty
                        ? NetworkImage(widget.friendProfilepic) as ImageProvider
                        : const AssetImage(AppAssets.defaultAvatar),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Obx(() {
                    final totalBooks =
                        userprofileController.readingBooks.length +
                            userprofileController.planToReadBooks.length +
                            userprofileController.finishedBooks.length;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(
                            'Posts', userprofileController.friendPosts.length),
                        _buildStatColumn('Books', totalBooks),
                        GestureDetector(
                          onTap: () => Get.to(() => UserFriendList(
                              friendsList:
                                  userprofileController.friendsoffreindsList)),
                          child: _buildStatColumn(
                              'Friends',
                              userprofileController
                                  .friendsoffreindsList.length),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(widget.friendName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            if (widget.friendrole.isNotEmpty)
              Text(widget.friendrole,
                  style: const TextStyle(
                      color: AppColor.clickedbutton, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
                widget.friendAbout.isNotEmpty
                    ? widget.friendAbout
                    : "No bio available",
                style: const TextStyle(color: Colors.white70, fontSize: 14)),

            const SizedBox(height: 16),

            // Interaction Buttons
            Obx(() {
              if (userprofileController.isFriend.value) {
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        onPressed: () {}, // Already friends
                        child: const Text("Friends",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        onPressed: () => _showUnfollowDialog(),
                        child: const Text("Unfollow",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                );
              } else if (userprofileController.friendRequestReceived.value) {
                return RespondToRequest(
                    requestid: userprofileController.incomingRequestId.value,
                    friendId: widget.friendId);
              } else if (userprofileController.friendRequestSent.value) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: () => userprofileController
                        .cancelFriendRequest(widget.friendId),
                    child: const Text("Cancel Request",
                        style: TextStyle(color: Colors.white70)),
                  ),
                );
              } else {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.clickedbutton,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: () => userprofileController
                        .sendFriendRequest(widget.friendId),
                    child: const Text("Add Friend",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                );
              }
            }),

            const SizedBox(height: 30),

            // Posts, Books, and Genres Selection Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTabIndex = 0;
                    });
                  },
                  child: Column(
                    children: [
                      SvgPicture.asset(AppAssets.texticon,
                          width: 30,
                          height: 30,
                          colorFilter: ColorFilter.mode(
                            selectedTabIndex == 0
                                ? AppColor.clickedbutton
                                : AppColor.iconstext,
                            BlendMode.srcIn,
                          )),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 2,
                        width: 60,
                        color: selectedTabIndex == 0
                            ? AppColor.clickedbutton
                            : Colors.transparent,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTabIndex = 1;
                    });
                  },
                  child: Column(
                    children: [
                      SvgPicture.asset(AppAssets.library,
                          width: 30,
                          height: 30,
                          colorFilter: ColorFilter.mode(
                            selectedTabIndex == 1
                                ? AppColor.clickedbutton
                                : AppColor.iconstext,
                            BlendMode.srcIn,
                          )),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 2,
                        width: 60,
                        color: selectedTabIndex == 1
                            ? AppColor.clickedbutton
                            : Colors.transparent,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTabIndex = 2;
                    });
                  },
                  child: Column(
                    children: [
                      Icon(Icons.interests_outlined,
                          size: 30,
                          color: selectedTabIndex == 2
                              ? AppColor.clickedbutton
                              : AppColor.iconstext),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 2,
                        width: 60,
                        color: selectedTabIndex == 2
                            ? AppColor.clickedbutton
                            : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Content
            Obx(() {
              if (selectedTabIndex == 0) {
                if (!userprofileController.isFriend.value &&
                    widget.friendId != userprofileController.currentUserId) {
                  return const Center(
                      child: Text("Add friend to see posts",
                          style: TextStyle(color: Colors.white38)));
                }
                if (userprofileController.friendPosts.isEmpty) {
                  return const Center(
                      child: Text("No posts yet",
                          style: TextStyle(color: Colors.white38)));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userprofileController.friendPosts.length,
                  itemBuilder: (context, index) {
                    final post = userprofileController.friendPosts[index];
                    return _buildPostCard(post);
                  },
                );
              } else if (selectedTabIndex == 1) {
                // Books content logic
                if (userprofileController.readingBooks.isEmpty &&
                    userprofileController.planToReadBooks.isEmpty &&
                    userprofileController.finishedBooks.isEmpty) {
                  return const Center(
                      child: Text("No books found",
                          style: TextStyle(color: Colors.white38)));
                }
                return _buildBooksSection();
              } else {
                return _buildFriendGenresTab(context);
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text('$count',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassBox(
        borderRadius: 20,
        opacity: 0.12,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.transparent,
                    backgroundImage: widget.friendProfilepic.isNotEmpty
                        ? NetworkImage(widget.friendProfilepic) as ImageProvider
                        : const AssetImage(AppAssets.defaultAvatar),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.friendName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text(PostTime.timeAgo(post['postTimestamp']),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Builder(builder: (context) {
                final text =
                    (post['postText'] ?? post['text'] ?? '').toString().trim();
                if (text.isEmpty) return const SizedBox.shrink();
                return Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                );
              }),
              if (post['imageUrl'] != null && post['imageUrl'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post['imageUrl'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.white10,
                          child: const Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.white30, size: 40),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (post['audioUrl'] != null && post['audioUrl'].isNotEmpty)
                AudioPlayerWidget(url: post['audioUrl']),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => userprofileController
                                .onLikeButtonPressed(post['postId']),
                            child: SvgPicture.asset(
                              AppAssets.likeHeart,
                              colorFilter: ColorFilter.mode(
                                userprofileController.likedPosts
                                        .contains(post['postId'])
                                    ? AppColor.heartRed
                                    : Colors.white70,
                                BlendMode.srcIn,
                              ),
                              width: 22,
                              height: 22,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post['likes'] ?? 0} Likes',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      )),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CommentSection(postId: post['postId']),
                      const SizedBox(width: 8),
                      ShareSection(postId: post['postId']),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBooksSection() {
    return Column(
      children: [
        _buildBookCategory("Reading", userprofileController.readingBooks,
            userprofileController.readingBooksCount.value),
        _buildBookCategory(
            "Plan to Read",
            userprofileController.planToReadBooks,
            userprofileController.planToReadBooksCount.value),
        _buildBookCategory("Finished", userprofileController.finishedBooks,
            userprofileController.finishedBooksCount.value),
        if (userprofileController.uploadedbooks.isNotEmpty)
          _buildBookCategory(
              "Uploaded Books",
              userprofileController.uploadedbooks,
              userprofileController.uploadedbooksCount.value),
      ],
    );
  }

  Widget _buildBookCategory(
      String title, List<Map<String, dynamic>> books, int count) {
    if (books.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            TextButton(
                onPressed: () {},
                child: const Text("View All",
                    style: TextStyle(color: AppColor.clickedbutton))),
          ],
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            itemBuilder: (context, i) {
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                child: GlassBox(
                  borderRadius: 12,
                  opacity: 0.1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: books[i]['img'] != null
                        ? Image.network(books[i]['img'], fit: BoxFit.cover)
                        : const Center(
                            child: Icon(Icons.book, color: Colors.white24)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFriendGenresTab(BuildContext context) {
    final List<String> friendGenres = userprofileController.genres;

    if (friendGenres.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'No preferred genres selected.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final allFriendBooks = [
      ...userprofileController.readingBooks,
      ...userprofileController.planToReadBooks,
      ...userprofileController.finishedBooks,
    ];

    return SingleChildScrollView(
      child: Column(
        children: friendGenres.map((genre) {
          // Filter books for this genre (case insensitive comparison)
          final genreBooks = allFriendBooks.where((book) {
            final String bookGenre =
                book['genre']?.toString().toLowerCase().trim() ?? '';
            return bookGenre == genre.toLowerCase().trim();
          }).toList();

          return Container(
            margin: const EdgeInsets.only(bottom: 12.0, left: 8.0, right: 8.0),
            width: double.infinity,
            child: GlassBox(
              borderRadius: 20,
              opacity: 0.1,
              child: Padding(
                padding:
                    EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          genre,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${genreBooks.length} books',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    genreBooks.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              'No books in this genre added to collection.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: genreBooks.map((book) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      Get.to(() => BooksDetails(
                                            bookId: book['id'] ?? '',
                                            title: book['title'] ??
                                                'Unknown Title',
                                            author: book['author'] ??
                                                'Unknown Author',
                                            img: book['img'] ?? '',
                                            description: book['desc'] ??
                                                'No description available',
                                            rating: double.tryParse(
                                                    book['rating']
                                                            ?.toString() ??
                                                        '') ??
                                                0.0,
                                            pages: (double.tryParse(
                                                        book['pages']
                                                                ?.toString() ??
                                                            '') ??
                                                    0.0)
                                                .toInt(),
                                            isbn: book['isbn'] ?? 'No isbn',
                                            bookFormate: book['bookformat'] ??
                                                'No bookformat',
                                            isPaid: book['isPaid'] ?? false,
                                            isApproved:
                                                book['isApproved'] ?? true,
                                            pdfUrl: book['pdfUrl'] ?? '',
                                          ));
                                    },
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: (book['img'] != null &&
                                                  book['img']
                                                      .toString()
                                                      .isNotEmpty)
                                              ? Image.network(
                                                  book['img'],
                                                  width: 70,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Container(
                                                    width: 70,
                                                    height: 100,
                                                    color: Colors.grey,
                                                    child: const Icon(
                                                        Icons.book,
                                                        size: 36,
                                                        color: Colors.white),
                                                  ),
                                                )
                                              : Container(
                                                  width: 70,
                                                  height: 100,
                                                  color: Colors.grey,
                                                  child: const Icon(Icons.book,
                                                      size: 36,
                                                      color: Colors.white),
                                                ),
                                        ),
                                        const SizedBox(height: 6),
                                        SizedBox(
                                          width: 70,
                                          child: Text(
                                            book['title'] ?? 'Unknown',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Books/view/component/books-details/controller/books_details_controller.dart';
import 'package:readora/screens/Books/view/component/books-details/view/books_details.dart';
import 'package:readora/screens/ChatList/controller/chat_lists_controller.dart';
import 'package:readora/screens/Dashboard/Home/controller/home_controller.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/controller/profile_controller.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/view/component/all_books/view/all_book.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/view/component/edit_profile/controller/edit_profile_controller.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/view/component/edit_profile/view/edit_proifle.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/view/component/friend_list/view/friend_list.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/view/component/uploaded_book/view/uploaded_books.dart';
import 'package:readora/utils/app_assets.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/comments_section.dart';
import 'package:readora/utils/on_screen_picture.dart';
import 'package:readora/utils/glass_box.dart';
import 'package:readora/utils/post_time.dart';
import 'package:readora/utils/db_seeder.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HomeController homecontroller = Get.put(HomeController());
  final ProfileController profileController = Get.put(ProfileController());
  final EditProfileController editprofileController =
      Get.put(EditProfileController());
  final ChatListsController friendListController =
      Get.put(ChatListsController());

  List<Map<String, dynamic>> userPosts = [];
  Set<String> likedPosts = {};
  String currentUser = '';
  String role = '';
  bool isLoading = true;
  String aboutText = '';
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    currentUser = homecontroller.username;
    role = homecontroller.role;
    aboutText = homecontroller.about;
    friendListController.fetchFriends();
    _listenForUserPosts();
  }

  // Listen for real-time changes in user's posts
  void _listenForUserPosts() {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    // Listen to real-time changes in posts made by the current user
    var postsSubscription = _firestore
        .collection('posts')
        .where('postOwnerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .snapshots()
        .listen((postsSnapshot) {
      // Update the posts count in ProfileController — reacts to add/delete
      profileController.updatePostsCount(postsSnapshot.docs.length);

      List<Map<String, dynamic>> fetchedPosts = [];

      for (final postDoc in postsSnapshot.docs) {
        final data = postDoc.data();

        // Support both old field names (text/timestamp) and new (postText/postTimestamp)
        final postText = data['postText'] ?? data['text'] ?? '';
        final postTimestamp = data['postTimestamp'] ?? data['timestamp'];
        final imageUrl = data['imageUrl'] ?? '';
        final audioUrl = data['audioUrl'] ?? '';

        List<dynamic> likedBy =
            data.containsKey('likedBy') ? data['likedBy'] : [];

        if (likedBy.contains(currentUser)) {
          likedPosts.add(postDoc.id);
        } else {
          likedPosts.remove(postDoc.id);
        }

        fetchedPosts.add({
          'postId': postDoc.id,
          'postDoc': postDoc,
          'postText': postText,
          'postTimestamp': postTimestamp,
          'imageUrl': imageUrl,
          'audioUrl': audioUrl,
          'likes': data['likes'] ?? 0,
          'comments': data['comments'] ?? 0,
          'shares': data['shares'] ?? 0,
          'likedBy': likedBy,
        });
      }

      // Sort posts by timestamp descending (newest first)
      fetchedPosts.sort((a, b) {
        final tA = a['postTimestamp'];
        final tB = b['postTimestamp'];
        if (tA is Timestamp && tB is Timestamp) return tB.compareTo(tA);
        if (tA is Timestamp) return -1;
        if (tB is Timestamp) return 1;
        return 0;
      });

      setState(() {
        userPosts = fetchedPosts;
        isLoading = false;
      });
    }, onError: (e) {
      setState(() {
        isLoading = false;
      });
    });

    // Add the posts subscription to the list
    _subscriptions.add(postsSubscription);
  }


  // Toggle like function remains unchanged
  void _toggleLike(String postId, DocumentSnapshot postDoc, int index) {
    int currentLikes = userPosts[index]['likes'];

    if (likedPosts.contains(postId)) {
      setState(() {
        likedPosts.remove(postId);
        currentLikes--;
        postDoc.reference.update({
          'likes': currentLikes,
          'likedBy': FieldValue.arrayRemove([currentUser])
        });
        userPosts[index]['likes'] = currentLikes;
      });
    } else {
      setState(() {
        likedPosts.add(postId);
        currentLikes++;
        postDoc.reference.update({
          'likes': currentLikes,
          'likedBy': FieldValue.arrayUnion([currentUser])
        });
        userPosts[index]['likes'] = currentLikes;
      });
    }
  }

  @override
  void dispose() {
    // Cancel all subscriptions when the widget is disposed
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColor.iconstext),
        ),
      ],
    );
  }

  int selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(
            color: AppColor.iconstext,
            fontSize: 20,
            fontWeight: FontWeight.normal,
          ),
        ),
        backgroundColor: AppColor.bgcolor,
        iconTheme: const IconThemeData(
          color: AppColor.iconstext,
        ),
        actions: [
          IconButton(
            tooltip: "Seed/Refresh Books",
            icon: const Icon(Icons.cloud_sync, color: AppColor.clickedbutton),
            onPressed: () => DatabaseSeeder.seedBooks(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColor.iconstext),
            onPressed: () {
              profileController.logoutUser(context); // Call the logout method
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row for Profile Picture and Stats
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture with left padding
                Padding(
                  padding: const EdgeInsets.only(
                      left: 10.0), // Add left padding here
                  child: Obx(
                    () => GestureDetector(
                        onTap: () {
                          // Navigate to the Profile Picture Screen when the avatar is clicked
                          Get.to(() => OnScreenPicture(
                              profilePicUrl:
                                  editprofileController.profilePicUrl.value));
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.transparent,
                          backgroundImage: editprofileController
                                  .profilePicUrl.value.isNotEmpty
                              ? NetworkImage(
                                      editprofileController.profilePicUrl.value)
                                  as ImageProvider
                              : const AssetImage(AppAssets.defaultAvatar),
                        )),
                  ),
                ),
                const SizedBox(
                    width: 16), // Spacing between profile picture and stats
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Obx(() => _buildStatColumn(
                          'Posts', profileController.postsCount.value)),
                      GestureDetector(
                        onTap: () {
                          // Navigate to the FriendList screen
                          Get.to(() => const FriendList());
                        },
                        child: Obx(() => _buildStatColumn(
                            'Friends', profileController.friendsCount.value)),
                      ),
                      if (role == 'auth')
                        GestureDetector(
                          onTap: () {
                            final String userId =
                                FirebaseAuth.instance.currentUser!.uid;

                            // Navigate to the FriendList screen
                            Get.to(() => UploadedBooks(
                                userid: userId, isOwnProfile: true));
                          },
                          // Uncomment the following line if you want to include Followers
                          child: Obx(() => _buildStatColumn('Books',
                              profileController.uploadedbooksCount.value)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2), // Spacing between stats and username

            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0), // Add padding here
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Align text to the start (left)
                children: [
                  // Username
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Distribute space between elements
                    children: [
                      Expanded(
                        // Allows the text to take the available width
                        child: Text(
                          currentUser,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColor.white,
                            fontSize:
                                18, // You can adjust the font size as needed
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                      height: 2), // Spacing between username and about
                  // About Text
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.start, // Align to the start
                    children: [
                      Expanded(
                        // Allows the text to take the available width
                        child: Text(
                          aboutText,
                          style: const TextStyle(
                            color: AppColor.iconstext,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8.0), // Add padding around the row
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      // ElevatedButton(
                      //   onPressed: () {},
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: AppColor.cardcolor,
                      //   ),
                      //   child: const Text("Share profile",
                      //       style: TextStyle(color: AppColor.textwhitecolor)),
                      // ),

                      child: ElevatedButton(
                        onPressed: () async {
                          // Await the fetchUserData to complete before navigation
                          // await homecontroller.fetchUserData();

                          // // Navigate to EditProfile screen once data is fetched
                          Get.to(() => const EditProfile());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.unselected,
                          minimumSize: const Size(
                              350, 40), // Set the width to 200 and height to 50
                        ),
                        child: const Text("Edit profile",
                            style: TextStyle(color: AppColor.iconstext)),
                      ),
                    )
                  ],
                )),
            const SizedBox(height: 16),
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
                      SvgPicture.asset(
                          AppAssets.texticon,
                          width: 30,
                          height: 30,
                          colorFilter: ColorFilter.mode(
                            selectedTabIndex == 0 ? AppColor.clickedbutton : AppColor.iconstext,
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
                      SvgPicture.asset(
                          AppAssets.library,
                          width: 30,
                          height: 30,
                          colorFilter: ColorFilter.mode(
                            selectedTabIndex == 1 ? AppColor.clickedbutton : AppColor.iconstext,
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
            const SizedBox(height: 16),
            // Posts List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : selectedTabIndex == 0
                      ? userPosts.isEmpty
                          ? const Center(
                              child: Text(
                                'Nothing posted yet.',
                                style: TextStyle(
                                  color: AppColor.iconstext,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: userPosts.length,
                              itemBuilder: (context, index) {
                                // Display each user post in a card
                                final post = userPosts[index];
                                final postDoc =
                                    post['postDoc'] as DocumentSnapshot;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 8.0),
                                  child: GlassBox(
                                    borderRadius: 20,
                                    opacity: 0.15,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Header Row for Profile Picture, User Name, and Options
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 22,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    backgroundImage: editprofileController
                                                            .profilePicUrl
                                                            .value
                                                            .isNotEmpty
                                                        ? NetworkImage(
                                                                editprofileController
                                                                    .profilePicUrl
                                                                    .value)
                                                            as ImageProvider
                                                        : const AssetImage(
                                                            AppAssets
                                                                .defaultAvatar),
                                                  ),
                                                  const SizedBox(width: 12.0),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        currentUser,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      Text(
                                                        PostTime.timeAgo(post[
                                                            'postTimestamp']),
                                                        style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(0.7),
                                                          fontSize: 12.0,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              PopupMenuButton<String>(
                                                icon: const Icon(
                                                  Icons.more_vert,
                                                  color: Colors.white70,
                                                ),
                                                onSelected:
                                                    (String value) async {
                                                  if (value == 'delete') {
                                                    await profileController
                                                        .deletePostAndComments(
                                                            postDoc.id);
                                                  }
                                                },
                                                itemBuilder:
                                                    (BuildContext context) {
                                                  return [
                                                    const PopupMenuItem<String>(
                                                      value: 'delete',
                                                      child: Center(
                                                        child: Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: AppColor
                                                                  .iconstext),
                                                        ),
                                                      ),
                                                    ),
                                                  ];
                                                },
                                                color: AppColor.unselected,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12.0),
                                          Text(
                                            post['postText'],
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15),
                                          ),
                                          const SizedBox(height: 12.0),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: SvgPicture.asset(
                                                      AppAssets.likeHeart,
                                                      colorFilter: ColorFilter.mode(
                                                        likedPosts.contains(postDoc.id)
                                                            ? AppColor.heartRed
                                                            : Colors.white70,
                                                        BlendMode.srcIn,
                                                      ),
                                                      width: 22,
                                                      height: 22,
                                                    ),
                                                    onPressed: () =>
                                                        _toggleLike(postDoc.id,
                                                            postDoc, index),
                                                  ),
                                                  Text(
                                                    '${post['likes']} Likes',
                                                    style: const TextStyle(
                                                        color: Colors.white70),
                                                  ),
                                                ],
                                              ),
                                              CommentSection(
                                                  postId: postDoc.id),
                                              Flexible(
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SvgPicture.asset(
                                                      AppAssets.share,
                                                      colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                                                      width: 20,
                                                      height: 20,
                                                    ),
                                                    const SizedBox(width: 4.0),
                                                    Flexible(
                                                      child: Text(
                                                        '${post['shares']} Shares',
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 14.0,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                      : selectedTabIndex == 1
                          ? Obx(
                              () => SingleChildScrollView(
                                  // This makes the entire Column scrollable
                                  child: Column(
                                children: [
                                  // Show "No books available" if both lists are empty
                                  if (profileController.readingBooks.isEmpty &&
                                      profileController
                                          .planToReadBooks.isEmpty &&
                                      profileController.finishedBooks.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 195),
                                      child: Text(
                                        'No books Added...',
                                        style: TextStyle(
                                          color: AppColor.iconstext,
                                        ),
                                      ),
                                    ),

                                  // "Reading" Books Section
                                  profileController.readingBooks.isNotEmpty
                                      ? Dismissible(
                                          key: const Key('collection_reading'),
                                          direction:
                                              DismissDirection.endToStart,
                                          background: Container(
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(
                                                right: 20),
                                            color: Colors.red.withOpacity(0.8),
                                            child: const Icon(Icons.delete,
                                                color: Colors.white),
                                          ),
                                          confirmDismiss: (direction) async {
                                            return await showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      "Delete Collection"),
                                                  content: const Text(
                                                      "Are you sure you want to delete this entire collection?"),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(false),
                                                        child: const Text(
                                                            "CANCEL")),
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true),
                                                        child: const Text(
                                                            "DELETE",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .red))),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          onDismissed: (direction) {
                                            profileController.deleteCollection(
                                                'Books->reading');
                                          },
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: GlassBox(
                                              borderRadius: 20,
                                              opacity: 0.1,
                                              child: Padding(
                                                padding: EdgeInsets.all(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.05),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        const Text(
                                                          'Reading',
                                                          style: TextStyle(
                                                            fontSize: 24,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            Get.to(() =>
                                                                const ViewAllBooks(
                                                                  sectionTitle:
                                                                      'Reading',
                                                                  isOwnProfile:
                                                                      true,
                                                                ));
                                                          },
                                                          child: const Text(
                                                            'View All',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white70),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      '${profileController.readingBooks.length} books',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        height: 12.0),
                                                    SingleChildScrollView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      child: Row(
                                                        children:
                                                            profileController
                                                                .readingBooks
                                                                .map((book) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    right: 8.0),
                                                            child: Dismissible(
                                                              key: Key(
                                                                  'book_${book['id']}'),
                                                              direction:
                                                                  DismissDirection
                                                                      .down,
                                                              onDismissed:
                                                                  (direction) {
                                                                profileController
                                                                    .deleteBookFromCollection(
                                                                        'Books->reading',
                                                                        book[
                                                                            'id']);
                                                              },
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  Get.to(() =>
                                                                      BooksDetails(
                                                                        bookId:
                                                                            book['id'],
                                                                        title: book['title'] ??
                                                                            'Unknown Title',
                                                                        author: book['author'] ??
                                                                            'Unknown Author',
                                                                        img: book['img'] ??
                                                                            '',
                                                                        description:
                                                                            book['desc'] ??
                                                                                'No description available',
                                                                        rating: double.tryParse(book['rating'].toString()) ??
                                                                            0.0,
                                                                        pages: (double.tryParse(book['pages'].toString()) ??
                                                                                0.0)
                                                                            .toInt(),
                                                                        isbn: book['isbn'] ??
                                                                            'No isbn',
                                                                        bookFormate:
                                                                            book['bookformat'] ??
                                                                                'No bookformat',
                                                                        isPaid: book['isPaid'] ??
                                                                            false,
                                                                        isApproved:
                                                                            book['isApproved'] ??
                                                                                true,
                                                                        pdfUrl:
                                                                            book['pdfUrl'] ??
                                                                                '',
                                                                      ));
                                                                },
                                                                child:
                                                                    ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              4.0),
                                                                  child: (book['img'] !=
                                                                              null &&
                                                                          book['img']
                                                                              .toString()
                                                                              .isNotEmpty)
                                                                      ? Image
                                                                          .network(
                                                                          book[
                                                                              'img'],
                                                                          width:
                                                                              40,
                                                                          height:
                                                                              60,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                          errorBuilder: (context, error, stackTrace) =>
                                                                              Container(
                                                                            width:
                                                                                40,
                                                                            height:
                                                                                60,
                                                                            color:
                                                                                Colors.grey,
                                                                            child: const Icon(Icons.book,
                                                                                size: 24,
                                                                                color: Colors.white),
                                                                          ),
                                                                        )
                                                                      : Container(
                                                                          width:
                                                                              40,
                                                                          height:
                                                                              60,
                                                                          color:
                                                                              Colors.grey,
                                                                          child:
                                                                              const Icon(
                                                                            Icons.book,
                                                                            size:
                                                                                24,
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                        ),
                                                                ),
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
                                          ),
                                        )
                                      : Container(),
                                  const SizedBox(height: 6),
                                  // "Plan to Read" Books Section
                                  profileController.planToReadBooks.isNotEmpty
                                      ? Dismissible(
                                          key: const Key('collection_plan'),
                                          direction:
                                              DismissDirection.endToStart,
                                          background: Container(
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(
                                                right: 20),
                                            color: Colors.red.withOpacity(0.8),
                                            child: const Icon(Icons.delete,
                                                color: Colors.white),
                                          ),
                                          confirmDismiss: (direction) async {
                                            return await showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      "Delete Collection"),
                                                  content: const Text(
                                                      "Are you sure you want to delete this entire collection?"),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(false),
                                                        child: const Text(
                                                            "CANCEL")),
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true),
                                                        child: const Text(
                                                            "DELETE",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .red))),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          onDismissed: (direction) {
                                            profileController.deleteCollection(
                                                'Books->PlanToRead');
                                          },
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: GlassBox(
                                              borderRadius: 20,
                                              opacity: 0.1,
                                              child: Padding(
                                                padding: EdgeInsets.all(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.05),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        const Text(
                                                          'Plan to Read',
                                                          style: TextStyle(
                                                            fontSize: 24,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            Get.to(() =>
                                                                const ViewAllBooks(
                                                                  sectionTitle:
                                                                      'Plan to Read',
                                                                  isOwnProfile:
                                                                      true,
                                                                ));
                                                          },
                                                          child: const Text(
                                                            'View All',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white70),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4.0),
                                                    Text(
                                                      '${profileController.planToReadBooks.length} books',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        height: 12.0),
                                                    SingleChildScrollView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      child: Row(
                                                        children:
                                                            profileController
                                                                .planToReadBooks
                                                                .map((book) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    right: 8.0),
                                                            child: Dismissible(
                                                              key: Key(
                                                                  'book_${book['id']}'),
                                                              direction:
                                                                  DismissDirection
                                                                      .down,
                                                              onDismissed:
                                                                  (direction) {
                                                                profileController
                                                                    .deleteBookFromCollection(
                                                                        'Books->PlanToRead',
                                                                        book[
                                                                            'id']);
                                                              },
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  // Navigate to Book Details screen
                                                                  Get.to(() =>
                                                                      BooksDetails(
                                                                        bookId:
                                                                            book['id'],
                                                                        title: book['title'] ??
                                                                            'Unknown Title',
                                                                        author: book['author'] ??
                                                                            'Unknown Author',
                                                                        img: book['img'] ??
                                                                            '',
                                                                        description:
                                                                            book['desc'] ??
                                                                                'No description available',
                                                                        rating: double.tryParse(book['rating'].toString()) ??
                                                                            0.0,
                                                                        pages: (double.tryParse(book['pages'].toString()) ??
                                                                                0.0)
                                                                            .toInt(),
                                                                        isbn: book['isbn'] ??
                                                                            'No isbn',
                                                                        bookFormate:
                                                                            book['bookformat'] ??
                                                                                'No bookformat',
                                                                        isPaid: book['isPaid'] ??
                                                                            false,
                                                                        isApproved:
                                                                            book['isApproved'] ??
                                                                                true,
                                                                      ));
                                                                },
                                                                child:
                                                                    ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              4.0),
                                                                  child: (book['img'] !=
                                                                              null &&
                                                                          book['img']
                                                                              .toString()
                                                                              .isNotEmpty)
                                                                      ? Image
                                                                          .network(
                                                                          book[
                                                                              'img'],
                                                                          width:
                                                                              40,
                                                                          height:
                                                                              60,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                          errorBuilder: (context, error, stackTrace) =>
                                                                              Container(
                                                                            width:
                                                                                40,
                                                                            height:
                                                                                60,
                                                                            color:
                                                                                Colors.grey,
                                                                            child: const Icon(Icons.book,
                                                                                size: 24,
                                                                                color: Colors.white),
                                                                          ),
                                                                        )
                                                                      : Container(
                                                                          width:
                                                                              40,
                                                                          height:
                                                                              60,
                                                                          color:
                                                                              Colors.grey,
                                                                          child:
                                                                              const Icon(
                                                                            Icons.book,
                                                                            size:
                                                                                24,
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                        ),
                                                                ),
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
                                          ),
                                        )
                                      : Container(),
                                  const SizedBox(height: 6),
                                  // "Finished" Books Section
                                  profileController.finishedBooks.isNotEmpty
                                      ? Dismissible(
                                          key: const Key('collection_finished'),
                                          direction:
                                              DismissDirection.endToStart,
                                          background: Container(
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(
                                                right: 20),
                                            color: Colors.red.withOpacity(0.8),
                                            child: const Icon(Icons.delete,
                                                color: Colors.white),
                                          ),
                                          confirmDismiss: (direction) async {
                                            return await showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      "Delete Collection"),
                                                  content: const Text(
                                                      "Are you sure you want to delete this entire collection?"),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(false),
                                                        child: const Text(
                                                            "CANCEL")),
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true),
                                                        child: const Text(
                                                            "DELETE",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .red))),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          onDismissed: (direction) {
                                            profileController.deleteCollection(
                                                'Books->Finished');
                                          },
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: GlassBox(
                                              borderRadius: 20,
                                              opacity: 0.1,
                                              child: Padding(
                                                padding: EdgeInsets.all(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.05),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        const Text(
                                                          'Finished',
                                                          style: TextStyle(
                                                            fontSize: 24,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            Get.to(() =>
                                                                const ViewAllBooks(
                                                                  sectionTitle:
                                                                      'Finished',
                                                                  isOwnProfile:
                                                                      true,
                                                                ));
                                                          },
                                                          child: const Text(
                                                            'View All',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white70),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4.0),
                                                    Text(
                                                      '${profileController.finishedBooks.length} books',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        height: 12.0),
                                                    SingleChildScrollView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      child: Row(
                                                        children:
                                                            profileController
                                                                .finishedBooks
                                                                .map((book) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    right: 8.0),
                                                            child: Dismissible(
                                                              key: Key(
                                                                  'book_${book['id']}'),
                                                              direction:
                                                                  DismissDirection
                                                                      .down,
                                                              onDismissed:
                                                                  (direction) {
                                                                profileController
                                                                    .deleteBookFromCollection(
                                                                        'Books->Finished',
                                                                        book[
                                                                            'id']);
                                                              },
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  Get.delete<
                                                                      BookDetailsController>(); // Remove the controller
                                                                  // Navigate to Book Details screen
                                                                  Get.to(() =>
                                                                      BooksDetails(
                                                                        bookId:
                                                                            book['id'],
                                                                        title: book['title'] ??
                                                                            'Unknown Title',
                                                                        author: book['author'] ??
                                                                            'Unknown Author',
                                                                        img: book['img'] ??
                                                                            '',
                                                                        description:
                                                                            book['desc'] ??
                                                                                'No description available',
                                                                        rating: double.tryParse(book['rating'].toString()) ??
                                                                            0.0,
                                                                        pages: (double.tryParse(book['pages'].toString()) ??
                                                                                0.0)
                                                                            .toInt(),
                                                                        isbn: book['isbn'] ??
                                                                            'No isbn',
                                                                        bookFormate:
                                                                            book['bookformat'] ??
                                                                                'No bookformat',
                                                                        isPaid: book['isPaid'] ??
                                                                            false,
                                                                        isApproved:
                                                                            book['isApproved'] ??
                                                                                true,
                                                                      ));
                                                                },
                                                                child:
                                                                    ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              4.0),
                                                                  child: (book['img'] !=
                                                                              null &&
                                                                          book['img']
                                                                              .toString()
                                                                              .isNotEmpty)
                                                                      ? Image
                                                                          .network(
                                                                          book[
                                                                              'img'],
                                                                          width:
                                                                              40,
                                                                          height:
                                                                              60,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                          errorBuilder: (context, error, stackTrace) =>
                                                                              Container(
                                                                            width:
                                                                                40,
                                                                            height:
                                                                                60,
                                                                            color:
                                                                                Colors.grey,
                                                                            child: const Icon(Icons.book,
                                                                                size: 24,
                                                                                color: Colors.white),
                                                                          ),
                                                                        )
                                                                      : Container(
                                                                          width:
                                                                              40,
                                                                          height:
                                                                              60,
                                                                          color:
                                                                              Colors.grey,
                                                                          child:
                                                                              const Icon(
                                                                            Icons.book,
                                                                            size:
                                                                                24,
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                        ),
                                                                ),
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
                                          ),
                                        )
                                      : Container(),
                                ],
                              )),
                            )
                          : Obx(() => _buildGenresTab(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenresTab(BuildContext context) {
    final List<String> myGenres = homecontroller.genres;

    if (myGenres.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'No preferred genres selected. Edit your profile to choose genres!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColor.iconstext,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final allMyBooks = [
      ...profileController.readingBooks,
      ...profileController.planToReadBooks,
      ...profileController.finishedBooks,
    ];

    return SingleChildScrollView(
      child: Column(
        children: myGenres.map((genre) {
          // Filter books for this genre (case insensitive comparison)
          final genreBooks = allMyBooks.where((book) {
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
                              'No books in this genre added to your collection.',
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

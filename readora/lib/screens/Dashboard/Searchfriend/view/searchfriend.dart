import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/view/profile.dart';
import 'package:readora/screens/Dashboard/Profiles/user_profile/controller/user_profile_controller.dart';
import 'package:readora/screens/Dashboard/Profiles/user_profile/view/user_profile.dart';
import 'package:readora/screens/Dashboard/Searchfriend/controller/searchfriend_controller.dart';
import 'package:readora/utils/appbar.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/app_assets.dart';
import 'package:readora/utils/custom_snackbar.dart';

class SearchFriend extends StatefulWidget {
  const SearchFriend({super.key});

  @override
  State<SearchFriend> createState() => _SearchFriendState();
}

class _SearchFriendState extends State<SearchFriend> {
  final TextEditingController _searchController = TextEditingController();
  late SearchFriendController _controller;
  bool _nearYouExpanded = false;
  bool _genreExpanded = false;

  @override
  void initState() {
    super.initState();
    // Delete stale instance and create a fresh one
    Get.delete<SearchFriendController>(force: true);
    _controller = Get.put(SearchFriendController());
  }

  @override
  void dispose() {
    _searchController.dispose();
    Get.delete<SearchFriendController>(force: true);
    super.dispose();
  }

  Widget _buildUserTile(DocumentSnapshot doc, BuildContext context, {bool showOnlyMatchingGenres = false, bool hideGenres = false}) {
    var user = doc.data() as Map<String, dynamic>;
    String receiverId = doc.id;
    String? profilePicUrl = user['profilePicUrl'];
    String username = user['username'] ?? 'Unknown';
    String? role = user['role'];

    bool friendRequestSent = _controller.checkIfFriendRequestSent(receiverId);
    bool isFriend = _controller.friendsMap.containsKey(receiverId);

    // Extract and parse genres
    final List<dynamic> rawGenres = user['genres'] ?? [];
    final List<String> userGenres = rawGenres.map((g) => g.toString()).toList();
    
    // Filter to only matching genres if showOnlyMatchingGenres is true
    List<String> displayGenres = userGenres;
    if (showOnlyMatchingGenres) {
      displayGenres = userGenres.where((genre) => 
        _controller.currentUserGenres.any((myGenre) => myGenre.toLowerCase().trim() == genre.toLowerCase().trim())
      ).toList();
    }

    Widget? subtitleWidget;
    if (!hideGenres && displayGenres.isNotEmpty) {
      subtitleWidget = Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Wrap(
          spacing: 6.0,
          runSpacing: 6.0,
          children: displayGenres.map((genre) {
            bool isMatching = _controller.currentUserGenres.any(
              (myGenre) => myGenre.toLowerCase().trim() == genre.toLowerCase().trim()
            );
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: isMatching
                    ? const Color(0xFF1A9EFF).withOpacity(0.15) // Highlighted match
                    : Colors.white.withOpacity(0.05), // Soft neutral glass background
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isMatching
                      ? const Color(0xFF1A9EFF)
                      : Colors.white.withOpacity(0.1),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMatching) ...[
                    const Icon(
                      Icons.star,
                      size: 11,
                      color: Color(0xFF1A9EFF),
                    ),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    genre,
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: isMatching ? FontWeight.bold : FontWeight.normal,
                      color: isMatching
                          ? const Color(0xFF1A9EFF) // Accent blue for matches
                          : Colors.white70, // Neutral white/grey for others
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
      child: Card(
        elevation: 0.0, // Transparent glass style cards do not need heavy shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
          side: BorderSide(
            color: Colors.white.withOpacity(0.08), // Subtle glass border
            width: 1.0,
          ),
        ),
        color: Colors.white.withOpacity(0.05), // Semi-transparent glass background
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            leading: GestureDetector(
              onTap: () {
                String currentUserId = FirebaseAuth.instance.currentUser!.uid;
                if (receiverId == currentUserId) {
                  Get.to(() => const Profile());
                } else {
                  Get.delete<UserProfileController>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfile(
                        friendName: username,
                        friendAbout: user['about'] ?? '',
                        friendProfilepic: profilePicUrl ?? '',
                        friendId: receiverId,
                        friendrole: role ?? '',
                        isFriend: isFriend,
                        requestid: '',
                      ),
                    ),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1A9EFF).withOpacity(0.5),
                    width: 2.0,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: (profilePicUrl == null || profilePicUrl.isEmpty)
                      ? AppColor.iconstext
                      : Colors.transparent,
                  backgroundImage: (profilePicUrl != null &&
                          profilePicUrl.isNotEmpty)
                      ? NetworkImage(profilePicUrl) as ImageProvider
                      : const AssetImage(AppAssets.defaultAvatar) as ImageProvider,
                ),
              ),
            ),
            title: Text(
              username,
              style: const TextStyle(
                color: Colors.white, // Highly visible text color
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            subtitle: subtitleWidget,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFriend)
                  Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: AppColor.hinttextcolor, size: 20),
                  ),
                if (!isFriend)
                  Container(
                    decoration: BoxDecoration(
                      color: friendRequestSent
                          ? const Color(0xFF1A9EFF).withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: friendRequestSent
                            ? const Color(0xFF1A9EFF).withOpacity(0.5)
                            : Colors.white.withOpacity(0.1),
                        width: 1.0,
                      ),
                    ),
                    child: IconButton(
                      icon: friendRequestSent
                          ? const Icon(Icons.done, color: Color(0xFF1A9EFF), size: 20)
                          : const Icon(Icons.person_add, color: Colors.white, size: 20),
                      onPressed: () {
                        if (_controller.isFriendRequestReceived(receiverId)) {
                          customSnackbar(
                            title: "Notice",
                            message: "This user has already sent you a friend request.",
                          );
                        } else if (!friendRequestSent) {
                          _controller.sendFriendRequest(receiverId);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    List<Marker> markers = [];

    // Add current user marker
    if (_controller.currentLocation.value != null) {
      markers.add(Marker(
          point: _controller.currentLocation.value!,
          width: 80,
          height: 80,
          child: Column(
            children: [
              const Icon(Icons.location_on, color: Colors.blue, size: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4)),
                child: const Text('You',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
              )
            ],
          )));
    }

    void addMarkers(List<DocumentSnapshot> docs, Color color) {
      for (var doc in docs) {
        var data = doc.data() as Map<String, dynamic>?;
        if (data != null &&
            data.containsKey('latitude') &&
            data.containsKey('longitude')) {
          double lat = data['latitude'] + 0.0;
          double lon = data['longitude'] + 0.0;
          markers.add(Marker(
              point: LatLng(lat, lon),
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () {
                  bool isFriend = _controller.friendsMap.containsKey(doc.id);
                  Get.to(() => UserProfile(
                        isFriend: isFriend,
                        friendName: data['username'] ?? 'Unknown',
                        friendAbout: data['about'] ?? 'No info available',
                        friendProfilepic: data['profilePicUrl'] ?? '',
                        friendId: doc.id,
                        requestid: '',
                        friendrole: data['role'] ?? 'user',
                      ));
                },
                child: Column(children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      backgroundImage: data['profilePicUrl'] != null && data['profilePicUrl'].toString().isNotEmpty
                          ? NetworkImage(data['profilePicUrl'])
                          : const AssetImage(AppAssets.defaultAvatar) as ImageProvider,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(data['username'] ?? '',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                  )
                ]),
              )));
        }
      }
    }

    // Recommended users (red pins)
    addMarkers(_controller.recommendedUsers, Colors.red);

    // Friends outside recommended (green pins)
    List<DocumentSnapshot> friendDocs = _controller.otherUsers
        .where((doc) => _controller.friendsMap.containsKey(doc.id))
        .toList();
    addMarkers(friendDocs, Colors.green);

    return FlutterMap(
      options: MapOptions(
        initialCenter: _controller.currentLocation.value ?? const LatLng(0, 0),
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.readora',
        ),
        MarkerLayer(
          markers: markers,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(Get.height * .12),
        child: CustomAppBar(
          hintText: "Search by username...",
          searchController: _searchController,
          onSearchChanged: _controller.performSearch,
          role: '',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Text(
                    _controller.isMapVisible.value ? "Map View" : "List View",
                    style: const TextStyle(
                        color: AppColor.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold))),
                Obx(() => IconButton(
                    icon: Icon(
                        _controller.isMapVisible.value ? Icons.list : Icons.map,
                        color: AppColor.white,
                        size: 28),
                    onPressed: () {
                      if (_controller.currentLocation.value == null) {
                        customSnackbar(
                            title: "Location missing",
                            message: "We haven't received your location yet.");
                      } else {
                        _controller.isMapVisible.value =
                            !_controller.isMapVisible.value;
                      }
                    }))
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_controller.isMapVisible.value &&
                  _controller.currentLocation.value != null) {
                return _buildMap(context);
              }

              if (_controller.searchQuery.value.isNotEmpty) {
                if (_controller.searchResults.isEmpty) {
                  return const Center(
                      child: Text("No users found.",
                          style: TextStyle(color: AppColor.white)));
                }
                return ListView.builder(
                  itemCount: _controller.searchResults.length,
                  padding: const EdgeInsets.only(top: 4.0),
                  itemBuilder: (context, index) =>
                      _buildUserTile(_controller.searchResults[index], context, hideGenres: true),
                );
              } else {
                return CustomScrollView(
                  slivers: [
                    if (_controller.nearYouUsers.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFF1A9EFF), size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                "Near to you",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColor.white),
                              ),
                              const Spacer(),
                              Text(
                                "${_controller.nearYouUsers.length} users",
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildUserTile(
                              _controller.nearYouUsers[index], context, hideGenres: true),
                          childCount: _nearYouExpanded
                              ? _controller.nearYouUsers.length
                              : (_controller.nearYouUsers.length > 3 ? 3 : _controller.nearYouUsers.length),
                        ),
                      ),
                      if (_controller.nearYouUsers.length > 3)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: GestureDetector(
                              onTap: () => setState(() => _nearYouExpanded = !_nearYouExpanded),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _nearYouExpanded
                                          ? "Show Less"
                                          : "See More (${_controller.nearYouUsers.length - 3} more)",
                                      style: const TextStyle(
                                        color: Color(0xFF1A9EFF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _nearYouExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      color: const Color(0xFF1A9EFF),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                    if (_controller.genreSuggestedUsers.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              const Icon(Icons.style, color: Color(0xFF1A9EFF), size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                "Suggested by Genre",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColor.white),
                              ),
                              const Spacer(),
                              Text(
                                "${_controller.genreSuggestedUsers.length} users",
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildUserTile(
                              _controller.genreSuggestedUsers[index], context, showOnlyMatchingGenres: true),
                          childCount: _genreExpanded
                              ? _controller.genreSuggestedUsers.length
                              : (_controller.genreSuggestedUsers.length > 3 ? 3 : _controller.genreSuggestedUsers.length),
                        ),
                      ),
                      if (_controller.genreSuggestedUsers.length > 3)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: GestureDetector(
                              onTap: () => setState(() => _genreExpanded = !_genreExpanded),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _genreExpanded
                                          ? "Show Less"
                                          : "See More (${_controller.genreSuggestedUsers.length - 3} more)",
                                      style: const TextStyle(
                                        color: Color(0xFF1A9EFF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _genreExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      color: const Color(0xFF1A9EFF),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                    // ── Readers / Authors Toggle Section ──────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.people, color: Color(0xFF1A9EFF), size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "Browse",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColor.white),
                            ),
                            const Spacer(),
                            Obx(() {
                              final isReaders = _controller.selectedUserType.value == 'readers';
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                padding: const EdgeInsets.all(3),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _controller.selectedUserType.value = 'readers',
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isReaders ? AppColor.clickedbutton : Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          "Readers (${_controller.readersUsers.length})",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isReaders ? Colors.white : Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _controller.selectedUserType.value = 'authors',
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: !isReaders ? AppColor.clickedbutton : Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          "Authors (${_controller.authorsUsers.length})",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: !isReaders ? Colors.white : Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    Obx(() {
                      final currentList = _controller.selectedUserType.value == 'readers'
                          ? _controller.readersUsers
                          : _controller.authorsUsers;
                      if (currentList.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                "No ${_controller.selectedUserType.value} found.",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        );
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildUserTile(
                              currentList[index], context, hideGenres: true),
                          childCount: currentList.length,
                        ),
                      );
                    }),
                    if (_controller.nearYouUsers.isEmpty &&
                        _controller.genreSuggestedUsers.isEmpty &&
                        _controller.readersUsers.isEmpty &&
                        _controller.authorsUsers.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                            child: Text("No users available.",
                                style: TextStyle(color: AppColor.white))),
                      ),
                  ],
                );
              }
            }),
          ),
        ],
      ),
    );
  }
}

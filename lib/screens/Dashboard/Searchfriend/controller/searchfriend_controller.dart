import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:readora/screens/Dashboard/Home/controller/home_controller.dart';
import 'package:readora/utils/custom_snackbar.dart';

class SearchFriendController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var searchResults = <DocumentSnapshot>[].obs;
  var nearYouUsers = <DocumentSnapshot>[].obs;
  var genreSuggestedUsers = <DocumentSnapshot>[].obs;
  var otherUsers = <DocumentSnapshot>[].obs;
  var readersUsers = <DocumentSnapshot>[].obs;
  var authorsUsers = <DocumentSnapshot>[].obs;
  var selectedUserType = 'readers'.obs; // 'readers' or 'authors'
  var friendRequests = <DocumentSnapshot>[].obs;
  var isLoading = false.obs;
  var searchQuery = ''.obs;
  var isMapVisible = false.obs;
  var currentLocation = Rxn<LatLng>();
  late String _currentUserId;
  var friendsList = <String>[].obs;
  var friendsMap = <String, String>{}; // friendId -> friendName
  var currentUserGenres = <String>[].obs;
  var _allUsersCache = <DocumentSnapshot>[];

  List<DocumentSnapshot> get recommendedUsers => nearYouUsers;

  @override
  void onInit() {
    super.onInit();
    _currentUserId = _auth.currentUser!.uid;
    fetchFriends(); // Fetch friends on initialization
    fetchIncomingFriendRequests();
    fetchCurrentUserGenres();
    updateAndFetchLocationAndUsers();
  }

  void fetchCurrentUserGenres() {
    // Use HomeController genres (already loaded and kept in sync)
    try {
      final homeController = Get.find<HomeController>();
      currentUserGenres.value = List<String>.from(homeController.genres);
      print('[SearchFriend] Genres from HomeController: $currentUserGenres');
    } catch (e) {
      print('[SearchFriend] HomeController not found, fetching directly: $e');
      // Fallback: fetch directly from Firestore
      _firestore.collection('users').doc(_currentUserId).get().then((snapshot) {
        if (snapshot.exists) {
          final List<dynamic> fetchedGenres = snapshot.data()?['genres'] ?? [];
          currentUserGenres.value = List<String>.from(fetchedGenres);
          print('[SearchFriend] Genres from Firestore: $currentUserGenres');
          categorizeUsers(_allUsersCache);
        }
      });
    }
  }

  Future<void> updateAndFetchLocationAndUsers() async {
    isLoading.value = true;
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        fetchAllUsers();
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          fetchAllUsers();
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        fetchAllUsers();
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      currentLocation.value = LatLng(position.latitude, position.longitude);
      
      // Update Firestore
      await _firestore.collection('users').doc(_currentUserId).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      fetchAllUsers();

    } catch (e) {
      print("Location error: $e");
      fetchAllUsers();
    }
  }

  void fetchAllUsers() {
    _firestore.collection('users').snapshots().listen((snapshot) {
      print('[SearchFriend] All users fetched: ${snapshot.docs.length} users');
      categorizeUsers(snapshot.docs);
      isLoading.value = false;
    });
  }

  void categorizeUsers(List<DocumentSnapshot> allUsersDocs) {
    if (allUsersDocs.isEmpty) return; // Nothing to categorize yet
    _allUsersCache = allUsersDocs;
    nearYouUsers.clear();
    genreSuggestedUsers.clear();
    otherUsers.clear();
    readersUsers.clear();
    authorsUsers.clear();

    final myGenres = currentUserGenres.map((g) => g.toLowerCase().trim()).toSet();
    final myLocation = currentLocation.value;

    print('[SearchFriend] Categorizing ${allUsersDocs.length} users | myGenres: $myGenres | hasLocation: ${myLocation != null}');

    for (var doc in allUsersDocs) {
      if (doc.id == _currentUserId) continue;

      var data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      // Proximity check
      bool isNear = false;
      if (myLocation != null && data.containsKey('latitude') && data.containsKey('longitude')) {
        double lat = (data['latitude'] ?? 0.0) + 0.0;
        double lon = (data['longitude'] ?? 0.0) + 0.0;
        double distanceInMeters = Geolocator.distanceBetween(
          myLocation.latitude,
          myLocation.longitude,
          lat,
          lon,
        );
        if (distanceInMeters <= 50000) { // 50 km
          isNear = true;
        }
      }

      // Exact Genre Match check: Every preferred genre of the current user must be present in target user's genres
      final List<dynamic> rawGenres = data['genres'] ?? [];
      final userGenres = rawGenres.map((g) => g.toString().toLowerCase().trim()).toSet();
      
      bool hasExactGenreMatch = myGenres.isNotEmpty && 
          myGenres.every((g) => userGenres.contains(g));

      print('[SearchFriend] User: ${data['username']} | genres: $userGenres | isNear: $isNear | exactGenreMatch: $hasExactGenreMatch');

      if (hasExactGenreMatch) {
        genreSuggestedUsers.add(doc);
      }

      if (isNear) {
        nearYouUsers.add(doc);
      }

      final String userRole = data['role'] ?? 'user';
      if (userRole == 'auth') {
        authorsUsers.add(doc);
      } else {
        readersUsers.add(doc);
      }
      otherUsers.add(doc);
    }

    print('[SearchFriend] Result -> nearYou: ${nearYouUsers.length} | genreSuggested: ${genreSuggestedUsers.length} | readers: ${readersUsers.length} | authors: ${authorsUsers.length}');
  }

  // Fetch friends of the current user
  void fetchFriends() {
    try {
      _firestore.collection('users').doc(_currentUserId).snapshots().listen((currentUserDoc) {
        final friendsCollectionRef = currentUserDoc.reference.collection('friends');
        friendsCollectionRef.snapshots().listen((friendsSnapshot) {
          friendsMap.clear();
          for (final friendDoc in friendsSnapshot.docs) {
            String friendId = friendDoc['friendId'];
            String friendName = friendDoc['friendName'];
            friendsMap[friendId] = friendName;
          }
        });
      });
    } catch (e) {
      customSnackbar(title: "Error", message: "Error fetching friends: $e");
    }
  }

void fetchIncomingFriendRequests() {
  try {
    _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      friendRequests.clear();
      friendRequests.addAll(snapshot.docs);
    });
  } catch (e) {
    customSnackbar(title: "Error",message:  "Error fetching incoming friend requests: $e");
  }
}
bool isFriendRequestReceived(String senderId) {
  return friendRequests.any((request) =>
      request['senderId'] == senderId && request['status'] == 'pending');
}

  // Perform search for users by username
  void performSearch(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    try {
      _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: '$query\uf8ff')
          .snapshots()
          .listen((snapshot) {
            searchResults.clear();
            for (var doc in snapshot.docs) {
              if (doc.id != _currentUserId) {
                String receiverId = doc.id;
                friendsMap.containsKey(receiverId);
                checkIfFriendRequestSent(receiverId);
                isFriendRequestReceived(receiverId);
                searchResults.add(doc); 
              }
            }
          });
    } catch (e) {
      customSnackbar(title: "Error", message: "Error while searching. Please try again.");
    }
  }

  // Check if a friend request has already been sent
  bool checkIfFriendRequestSent(String receiverId) {
    return friendRequests.any((request) => request['receiverId'] == receiverId && request['status'] == 'pending');
  }

  // Send friend request to the specified user
Future<void> sendFriendRequest(String receiverId) async {
  final currentUser = _auth.currentUser;

  if (currentUser == null) {
    customSnackbar(title: "Error", message: "You must be logged in to send friend requests.");
    return;
  }

  if (receiverId == _currentUserId) {
    customSnackbar(title: "Error", message: "You cannot send a friend request to yourself.");
    return;
  }

  try {
    // Listen for existing friend requests to check if there's already a pending one
    final querySnapshot = await _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: currentUser.uid)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .get();

    // If a pending request exists, show a message and return
    if (querySnapshot.docs.isNotEmpty) {
      customSnackbar(title: "Error", message: "You have already sent a friend request to this user.");
      return;
    }

    // Send the friend request if no pending request exists
    await _firestore.collection('friend_requests').add({
      'senderId': currentUser.uid,
      'receiverId': receiverId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    customSnackbar(title: "Success",message:  "Friend request sent!");
  } catch (e) {
    customSnackbar(title: "Error",message:  "Failed to send friend request. Try again.");
  }
}
}

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class RecommendationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var recommendedBooks = <Map<String, dynamic>>[].obs;
  var recommendedPosts = <Map<String, dynamic>>[].obs;
  var recommendedUsers = <Map<String, dynamic>>[].obs;
  var isLoadingBooks = false.obs;
  var isLoadingPosts = false.obs;
  var isLoadingUsers = false.obs;

  /// True when the user has no genre preferences set in their profile
  var hasNoGenres = false.obs;

  // Track dismissed suggested posts/users locally
  var hiddenSuggestedPostIds = <String>{}.obs;
  var hiddenSuggestedUserIds = <String>{}.obs;

  String get _uid => _auth.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    fetchRecommendedBooks();
    fetchRecommendedPosts();
    fetchRecommendedUsers();
  }

  @override
  void onClose() {
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────
  //  BOOK RECOMMENDATIONS
  // ─────────────────────────────────────────────────────────────

  /// Call this whenever the user opens a book detail page.
  /// [genre] — the genre string from the book document.
  /// [boost] — extra score for explicit interactions (add to list).
  Future<void> logBookGenreInteraction(String genre, {int boost = 1}) async {
    if (_uid.isEmpty || genre.isEmpty) return;
    try {
      final ref = _firestore
          .collection('users')
          .doc(_uid)
          .collection('genreInteractions')
          .doc(genre.toLowerCase().trim());

      await ref.set(
        {'score': FieldValue.increment(boost), 'genre': genre},
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error logging genre interaction: $e');
    }
  }

  /// Normalise a raw genre value from Firestore into a flat list of genre strings.
  /// The field can be:
  ///   - a String          → ["Romance"]
  ///   - a List<dynamic>   → ["Romance", "History"]
  ///   - null / other      → []
  List<String> _normalizeGenreField(dynamic raw) {
    if (raw == null) return [];
    if (raw is String) {
      return raw
          .split(RegExp(r'[,/|;]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (raw is List) {
      final result = <String>[];
      for (final item in raw) {
        result.addAll(_normalizeGenreField(item));
      }
      return result;
    }
    return [raw.toString().trim()];
  }

  /// Fetch books recommended based on the user's selected genre preferences.
  /// Fetches ALL books from Firestore and filters in-memory so that every
  /// possible genre-field format (String, List, comma-separated, etc.) is
  /// handled without hitting Firestore query limitations.
  /// ONLY books whose genre matches (case-insensitively) at least one of the
  /// user's profile genres will appear in "Suggested for You".
  Future<void> fetchRecommendedBooks() async {
    if (_uid.isEmpty) return;
    isLoadingBooks.value = true;
    hasNoGenres.value = false;

    try {
      // 1. Read the user's saved genre preferences from their profile
      final userDoc = await _firestore.collection('users').doc(_uid).get();
      final List<dynamic> rawUserGenres = userDoc.data()?['genres'] ?? [];
      // Normalise user genres using the same helper to handle strings, lists, etc.
      final Set<String> userGenresLower = _normalizeGenreField(rawUserGenres)
          .map((g) => g.trim().toLowerCase())
          .where((g) => g.isNotEmpty)
          .toSet();

      // 2. Fetch books from Firestore
      final booksSnap = await _firestore.collection('books').get();
      final List<Map<String, dynamic>> matched = [];

      for (final doc in booksSnap.docs) {
        final String bookId = doc.id.trim();
        final data = doc.data();
        final List<String> bookGenres = _normalizeGenreField(data['genre']);

        final bool isMatch = userGenresLower.isEmpty || bookGenres.any(
          (g) => userGenresLower.contains(g.toLowerCase().trim()),
        );

        if (isMatch) {
          final String genreDisplay = (data['genre']?.toString() ?? '');
          matched.add({
            ...data,
            'id': bookId,
            'genre': genreDisplay,
          });
        }
      }

      // Sort by rating descending
      matched.sort((a, b) {
        final double rA = double.tryParse(a['rating']?.toString() ?? '0') ?? 0;
        final double rB = double.tryParse(b['rating']?.toString() ?? '0') ?? 0;
        return rB.compareTo(rA);
      });

      final top = matched.take(40).toList()..shuffle();
      recommendedBooks.value = top.take(20).toList();
    } catch (e) {
      print('Error fetching recommended books: $e');
      recommendedBooks.clear();
    } finally {
      isLoadingBooks.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  POST RECOMMENDATIONS
  // ─────────────────────────────────────────────────────────────

  /// Call this when the user likes a post to score keywords.
  Future<void> logPostLikeInteraction(String postText) async {
    if (_uid.isEmpty || postText.isEmpty) return;
    try {
      // Extract simple keywords (words > 4 chars, ignore common stop words)
      final keywords = _extractKeywords(postText);
      for (final kw in keywords.take(5)) {
        final ref = _firestore
            .collection('users')
            .doc(_uid)
            .collection('postInterests')
            .doc(kw);
        await ref.set(
          {'score': FieldValue.increment(1), 'keyword': kw},
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      print('Error logging post like interaction: $e');
    }
  }

  /// Fetch trending posts from non-friends as suggestions.
  Future<void> fetchRecommendedPosts() async {
    if (_uid.isEmpty) return;
    isLoadingPosts.value = true;

    try {
      // 1. Get current user's username
      final userDoc = await _firestore.collection('users').doc(_uid).get();
      final currentUsername =
          (userDoc.data()?['username'] as String? ?? '').toLowerCase();

      // 2. Get friends' usernames to exclude
      final friendsSnap = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('friends')
          .get();
      final friendUsernames = friendsSnap.docs
          .map((d) => (d.data()['friendName'] as String? ?? '').toLowerCase())
          .toSet();
      friendUsernames.add(currentUsername); // exclude own posts too

      // 3. Fetch trending posts (by likes desc), filter out friends/self
      final postsSnap = await _firestore
          .collection('posts')
          .orderBy('likes', descending: true)
          .limit(50)
          .get();

      final List<Map<String, dynamic>> suggestions = [];
      for (final doc in postsSnap.docs) {
        final data = doc.data();
        final poster = (data['username'] as String? ?? '').toLowerCase();
        if (!friendUsernames.contains(poster)) {
          suggestions.add({...data, 'id': doc.id});
          if (suggestions.length >= 10) break;
        }
      }

      recommendedPosts.value = suggestions;
    } catch (e) {
      print('Error fetching recommended posts: $e');
    } finally {
      isLoadingPosts.value = false;
    }
  }

  void dismissSuggestedPost(String postId) {
    hiddenSuggestedPostIds.add(postId);
  }

  void dismissSuggestedUser(String userId) {
    hiddenSuggestedUserIds.add(userId);
  }

  Future<void> fetchRecommendedUsers() async {
    if (_uid.isEmpty) return;
    isLoadingUsers.value = true;

    try {
      // 1. Get current user's genres
      final userDoc = await _firestore.collection('users').doc(_uid).get();
      if (!userDoc.exists) return;
      final List<dynamic> currentGenres = userDoc.data()?['genres'] ?? [];
      if (currentGenres.isEmpty) {
        recommendedUsers.clear();
        return;
      }
      final currentGenresSet =
          currentGenres.map((g) => g.toString().toLowerCase()).toSet();

      // 2. Get friends' user IDs to exclude them from suggestions
      final friendsSnap = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('friends')
          .get();
      final friendIds = friendsSnap.docs
          .map((d) => d.data()['friendId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      friendIds.add(_uid); // Exclude self

      // 3. Fetch all users and find those with matching genres
      final usersSnap = await _firestore.collection('users').get();
      final List<Map<String, dynamic>> matchedUsers = [];

      for (var doc in usersSnap.docs) {
        if (friendIds.contains(doc.id)) continue;

        final data = doc.data();
        final List<dynamic> userGenres = data['genres'] ?? [];
        final userGenresLower =
            userGenres.map((g) => g.toString().toLowerCase()).toSet();

        // Check intersection of genres
        final common = currentGenresSet.intersection(userGenresLower);
        if (common.isNotEmpty) {
          matchedUsers.add({
            ...data,
            'id': doc.id,
            'commonGenres': common.toList(),
          });
        }
      }

      // Sort matched users by number of common genres (most matches first)
      matchedUsers.sort((a, b) {
        final lenA = (a['commonGenres'] as List).length;
        final lenB = (b['commonGenres'] as List).length;
        return lenB.compareTo(lenA);
      });

      recommendedUsers.value = matchedUsers;
    } catch (e) {
      print('Error fetching recommended users: $e');
    } finally {
      isLoadingUsers.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────

  static const _stopWords = {
    'that',
    'this',
    'with',
    'from',
    'have',
    'been',
    'were',
    'they',
    'their',
    'there',
    'what',
    'will',
    'just',
    'your',
    'about',
    'more',
    'some',
    'when',
    'into',
    'than',
    'then',
    'only',
    'also',
    'very',
  };

  List<String> _extractKeywords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 4 && !_stopWords.contains(w))
        .toSet()
        .toList();
  }
}

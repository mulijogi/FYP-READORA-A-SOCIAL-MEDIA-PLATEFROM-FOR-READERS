import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Recommendations/controller/recommendation_controller.dart';
import 'package:readora/utils/custom_snackbar.dart';

class BookDetailsController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  RxBool isLoading = false.obs;
  // Genre of the currently opened book (set from the detail view)
  String _currentGenre = '';

  // Variable to hold the current user's name
  var userName = ''.obs;
  var isBookInReadingList =
      false.obs; // Observable for real-time updates on the reading status
  var isBookInPlanToReadList = false.obs;
  var isBookInFinishedList = false.obs;
  RxDouble currentRating =
      0.0.obs; // This will hold the calculated average rating
  RxBool hasUserRated = false.obs;
  String? bookId;
  @override
  void onInit() {
    super.onInit();
    _listenToUserName();
  }

  Future<void> checkUserRating(String bookId) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final querySnapshot = await firestore
          .collection('user_ratings')
          .where('bookId', isEqualTo: bookId)
          .where('userId', isEqualTo: userId)
          .get();
      print("CheckRating: Found ${querySnapshot.docs.length} docs for book $bookId and user $userId");
      hasUserRated.value = querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking user rating: $e");
    }
  }

  Future<void> rateBook(String bookId, double userRating) async {
    final userId = auth.currentUser?.uid;

    if (userId == null) {
      print("User not logged in");
      return;
    }

    // Reference to the user's rating for this book in the 'userratings' collection
    final ratingRef = firestore
        .collection('user_ratings')
        .where('bookId', isEqualTo: bookId)
        .where('userId', isEqualTo: userId);

    try {
      // Check if the user has already rated this book
      final querySnapshot = await ratingRef.get();
      print("RateBook: Found ${querySnapshot.docs.length} existing ratings for book $bookId and user $userId");
      if (querySnapshot.docs.isNotEmpty) {
        hasUserRated.value = true;
        customSnackbar(
            title: "Error", message: "You have already rated this book");
        return;
      }
      isLoading.value = true;

      // If the document doesn't exist, save the user's rating
      await firestore.collection('user_ratings').add({
        'bookId': bookId,
        'userId': userId,
        'userrating': userRating,
        'timestamp': FieldValue.serverTimestamp(),
      });
      hasUserRated.value = true;

      // Now update the book's total rating and average rating
      final bookRef = firestore.collection('books').doc(bookId);

      await firestore.runTransaction((transaction) async {
        final bookSnapshot = await transaction.get(bookRef);

        if (bookSnapshot.exists) {
          // Retrieve the current rating and rating count from the book document
          final currentAverageRating =
              double.tryParse(bookSnapshot['rating']?.toString() ?? '') ?? 0.0;
          final currentRatingCount = bookSnapshot['totalratings'] ?? 0;

          // Calculate the current total rating sum
          final currentTotalRatingSum =
              currentAverageRating * currentRatingCount;

          // Update total rating sum and rating count with the new user rating
          final newTotalRatingSum = currentTotalRatingSum + userRating;
          final newRatingCount = currentRatingCount + 1;
          final newAverageRating =
              (newTotalRatingSum / newRatingCount * 100).round() / 100;

          print("AVG $newAverageRating");

          // Update the book document with new rating values
          transaction.update(bookRef, {
            'rating':
                newAverageRating, // Update the average rating, rounded to 2 decimal places
            'totalratings': newRatingCount, // Update the rating count
          });

          //   // Check all users' books collections for this bookId
          // final allUsersSnapshot =
          //     await firestore.collection('users').get(); // Get all users
          // for (final userDoc in allUsersSnapshot.docs) {
          //   final userBooksRef =
          //       firestore.collection('users').doc(userDoc.id).collection('books');
          //   final userBookDoc = await userBooksRef.doc(bookId).get();

          //   if (userBookDoc.exists) {
          //     // Update the rating and totalratings fields for the matching book
          //     transaction.update(userBookDoc.reference, {
          //       'rating': newAverageRating,
          //       'totalratings': newRatingCount,

          //     });
          //   }
          // }
        } else {
          print("Book not found in global collection.gjhgj");
        }
      });

      customSnackbar(title: "Success", message: "Thank you for rating!");
      isLoading.value = false;
    } catch (e) {
      print("Error updating rating: $e");
    }
  }

  // Method to listen to the real-time changes of the current user's username
  void _listenToUserName() {
    User? user = auth.currentUser;
    if (user != null) {
      // Listen to the user's data from the Firestore "users" collection
      firestore.collection('users').doc(user.uid).snapshots().listen((userDoc) {
        if (userDoc.exists) {
          // Update the username with real-time data
          userName.value = userDoc['username'] ?? 'UserNamePlaceholder';
          listenToBookInReadingList(bookId!);
          listenToPlantoReading(bookId!);
          listenToFinished(bookId!);
        } else {
          userName.value =
              'UserNamePlaceholder'; // Default value if user document doesn't exist
        }
      });
    }
  }

  // Method to set the bookId and optional genre (for recommendation tracking)
  void setBookId(String id, {String genre = ''}) {
    bookId = id;
    _currentGenre = genre;

    // Log this genre view so recommendations improve over time
    if (genre.isNotEmpty) {
      try {
        final recCtrl = Get.find<RecommendationController>();
        recCtrl.logBookGenreInteraction(genre);
      } catch (_) {
        // RecommendationController not yet registered — safe to ignore
      }
    }

    if (userName.isNotEmpty) {
      listenToBookInReadingList(bookId!);
      listenToPlantoReading(bookId!);
      listenToFinished(bookId!);
    }
  }

  void listenToBookInReadingList(String bookId) {
    String currentUserName = userName.value;

    if (currentUserName.isNotEmpty) {
      User? user = auth.currentUser;
      if (user != null) {
        firestore
            .collection('users') // Correct collection for users
            .doc(user.uid) // The user's document
            .collection(
                'Books->reading') // The reading subcollection for the user
            .where('bookId', isEqualTo: bookId) // Filter by bookId
            .where('userName',
                isEqualTo:
                    currentUserName) // Ensure the current user's username matches
            .snapshots() // Listen to real-time changes
            .listen((snapshot) {
          // Update the 'isBookInReadingList' observable when a change is detected
          isBookInReadingList.value = snapshot.docs.isNotEmpty;
        });
      }
    }
  }

  Future<void> addBookToReading({
    required String bookId,
    required String title,
    required String author,
    required String img,
    required String description,
    required double rating,
    required int pages,
    required String isbn,
    required String bookFormate,
    String genre = '',
    String pdfUrl = '',
  }) async {
    try {
      String currentUserName = userName.value;

      if (currentUserName.isEmpty) {
        customSnackbar(
            title: 'Error', message: 'User not logged in or no username found');
        return;
      }

      User? user = auth.currentUser;
      if (user == null) return;

      // Check if the book is already in the user's reading list inside the "Books" subcollection
      QuerySnapshot existingBooks = await firestore
          .collection('users') // Get the users collection
          .doc(user.uid) // Get the specific user document
          .collection('Books->reading') // Check the Books subcollection
          .where('bookId',
              isEqualTo: bookId) // Ensure the bookId is not already added
          .get();

      if (existingBooks.docs.isNotEmpty) {
        customSnackbar(
            title: 'Already Added',
            message: 'This book is already in your Reading');
        return;
      }

      // Check if the book is in the "PlanToRead" collection and delete it if it exists
      QuerySnapshot planToReadBooks = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('Books->PlanToRead')
          .where('bookId', isEqualTo: bookId)
          .get();

      if (planToReadBooks.docs.isNotEmpty) {
        // Remove from "PlanToRead"
        await firestore
            .collection('users')
            .doc(user.uid)
            .collection('Books->PlanToRead')
            .doc(bookId)
            .delete();

        // Update the observable to indicate the book is no longer in "PlanToRead"
        isBookInPlanToReadList.value = false;
      }

      // Check if the book is in the "Finished" collection and delete it if it exists
      QuerySnapshot finishedBooks = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('Books->Finished')
          .where('bookId', isEqualTo: bookId)
          .get();

      if (finishedBooks.docs.isNotEmpty) {
        // Remove from "PlanToRead"
        await firestore
            .collection('users')
            .doc(user.uid)
            .collection('Books->Finished')
            .doc(bookId)
            .delete();

        // Update the observable to indicate the book is no longer in "PlanToRead"
        isBookInFinishedList.value = false;
      }

      // Add the book to the Books subcollection under the current user's document
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('Books->reading')
          .doc(bookId)
          .set({
        'bookId': bookId,
        'title': title,
        'author': author,
        'img': img,
        'description': description,
        'rating': rating,
        'pages': pages,
        'isbn': isbn,
        'bookFormate': bookFormate,
        'genre': genre,
        'pdfUrl': pdfUrl,
        'userName': currentUserName,
        'addedAt': FieldValue.serverTimestamp(),
      });

      customSnackbar(title: 'Success', message: 'Book added to Reading');

      // Boost genre score when user explicitly adds a book
      if (_currentGenre.isNotEmpty) {
        try {
          final recCtrl = Get.find<RecommendationController>();
          recCtrl.logBookGenreInteraction(_currentGenre, boost: 2);
        } catch (_) {}
      }
    } catch (e) {
      print("Error adding book to Reading: $e");
      customSnackbar(title: 'Error', message: 'Failed to add book to Reading');
    }
  }

  // Method to listen to real-time changes in the "Plan to Read" collection
  void listenToPlantoReading(String bookId) {
    String currentUserName = userName.value;

    if (currentUserName.isNotEmpty) {
      User? user = auth.currentUser;
      if (user != null) {
        firestore
            .collection('users') // Correct collection for users
            .doc(user.uid) // The user's document
            .collection(
                'Books->PlanToRead') // The reading subcollection for the user
            .where('bookId', isEqualTo: bookId) // Filter by bookId
            .where('userName',
                isEqualTo:
                    currentUserName) // Ensure the current user's username matches
            .snapshots() // Listen to real-time changes
            .listen((snapshot) {
          // Update the 'isBookInReadingList' observable when a change is detected
          isBookInPlanToReadList.value = snapshot.docs.isNotEmpty;
        });
      }
    }
  }

  Future<void> addBookToPlantoReading({
    required String bookId,
    required String title,
    required String author,
    required String img,
    required String description,
    required double rating,
    required int pages,
    required String isbn,
    required String bookFormate,
    String genre = '',
    String pdfUrl = '',
  }) async {
    try {
      String currentUserName = userName.value;

      if (currentUserName.isEmpty) {
        customSnackbar(
            title: 'Error', message: 'User not logged in or no username found');
        return;
      }

      User? user = auth.currentUser;
      if (user == null) return;

      // Check if the book is already in the user's reading list inside the "Books" subcollection
      QuerySnapshot existingBooks = await firestore
          .collection('users') // Get the users collection
          .doc(user.uid) // Get the specific user document
          .collection('Books->PlanToRead') // Check the Books subcollection
          .where('bookId',
              isEqualTo: bookId) // Ensure the bookId is not already added
          .get();

      if (existingBooks.docs.isNotEmpty) {
        customSnackbar(
            title: 'Already Added',
            message: 'This book is already in your PlanToRead');
        return;
      }

      // Check if the book is in the "Reading" collection and delete it if it exists
      QuerySnapshot readingBooks = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('Books->reading')
          .where('bookId', isEqualTo: bookId)
          .get();

      if (readingBooks.docs.isNotEmpty) {
        // Remove from "PlanToRead"
        await firestore
            .collection('users')
            .doc(user.uid)
            .collection('Books->reading')
            .doc(bookId)
            .delete();

        // Update the observable to indicate the book is no longer in "Reading"
        isBookInReadingList.value = false;
      }

      // Check if the book is in the "finishedBooks" collection and delete it if it exists
      QuerySnapshot finishedBooks = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('Books->Finished')
          .where('bookId', isEqualTo: bookId)
          .get();

      if (finishedBooks.docs.isNotEmpty) {
        // Remove from "finishedBooks"
        await firestore
            .collection('users')
            .doc(user.uid)
            .collection('Books->Finished')
            .doc(bookId)
            .delete();

        // Update the observable to indicate the book is no longer in "finishedBooks"
        isBookInFinishedList.value = false;
      }

      // If the book doesn't exist, add it to the collection
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('Books->PlanToRead')
          .doc(bookId)
          .set({
        'bookId': bookId,
        'title': title,
        'author': author,
        'img': img,
        'description': description,
        'rating': rating,
        'pages': pages,
        'isbn': isbn,
        'bookFormate': bookFormate,
        'genre': genre,
        'pdfUrl': pdfUrl,
        'userName': currentUserName,
        'addedAt': FieldValue.serverTimestamp(),
      });

      customSnackbar(title: 'Success', message: 'Book added to PlanToRead');

      // Boost genre score
      if (_currentGenre.isNotEmpty) {
        try {
          final recCtrl = Get.find<RecommendationController>();
          recCtrl.logBookGenreInteraction(_currentGenre, boost: 2);
        } catch (_) {}
      }
    } catch (e) {
      print("Error adding book to Reading: $e");
      customSnackbar(
          title: 'Error', message: 'Failed to add book to PlanToRead');
    }
  }

  // Method to listen to real-time changes in the "Finished collection
  void listenToFinished(String bookId) {
    String currentUserName = userName.value;

    if (currentUserName.isNotEmpty) {
      User? user = auth.currentUser;
      if (user != null) {
        firestore
            .collection('users') // Correct collection for users
            .doc(user.uid) // The user's document
            .collection(
                'Books->Finished') // The reading subcollection for the user
            .where('bookId', isEqualTo: bookId) // Filter by bookId
            .where('userName',
                isEqualTo:
                    currentUserName) // Ensure the current user's username matches
            .snapshots() // Listen to real-time changes
            .listen((snapshot) {
          // Update the 'isBookInReadingList' observable when a change is detected
          isBookInFinishedList.value = snapshot.docs.isNotEmpty;
        });
      }
    }
  }

  Future<void> addBookToFinished({
    required String bookId,
    required String title,
    required String author,
    required String img,
    required String description,
    required double rating,
    required int pages,
    required String isbn,
    required String bookFormate,
    String genre = '',
    String pdfUrl = '',
  }) async {
    try {
      String currentUserName = userName.value;

      if (currentUserName.isEmpty) {
        customSnackbar(
            title: 'Error', message: 'User not logged in or no username found');
        return;
      }

      User? user = auth.currentUser;
      if (user == null) return;

      // Check if the book is already in the user's reading list inside the "Books" subcollection
      QuerySnapshot existingBooks = await firestore
          .collection('users') // Get the users collection
          .doc(user.uid) // Get the specific user document
          .collection('Books->Finished') // Check the Books subcollection
          .where('bookId',
              isEqualTo: bookId) // Ensure the bookId is not already added
          .get();

      if (existingBooks.docs.isNotEmpty) {
        customSnackbar(
            title: 'Already Added',
            message: 'This book is already in your Finished list');
        return;
      }

      // Check if the book is in the "Reading" collection and delete it if it exists
      QuerySnapshot readingBooks = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('Books->reading')
          .where('bookId', isEqualTo: bookId)
          .get();

      if (readingBooks.docs.isNotEmpty) {
        // Remove from "PlanToRead"
        await firestore
            .collection('users')
            .doc(user.uid)
            .collection('Books->reading')
            .doc(bookId)
            .delete();

        // Update the observable to indicate the book is no longer in "Reading"
        isBookInReadingList.value = false;
      }

      // Check if the book is in the "PlanToRead" collection and delete it if it exists
      QuerySnapshot planToReadBooks = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('Books->PlanToRead')
          .where('bookId', isEqualTo: bookId)
          .get();

      if (planToReadBooks.docs.isNotEmpty) {
        // Remove from "PlanToRead"
        await firestore
            .collection('users')
            .doc(user.uid)
            .collection('Books->PlanToRead')
            .doc(bookId)
            .delete();

        // Update the observable to indicate the book is no longer in "PlanToRead"
        isBookInPlanToReadList.value = false;
      }

      // If the book doesn't exist, add it to the collection
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('Books->Finished')
          .doc(bookId)
          .set({
        'bookId': bookId,
        'title': title,
        'author': author,
        'img': img,
        'description': description,
        'rating': rating,
        'pages': pages,
        'isbn': isbn,
        'bookFormate': bookFormate,
        'genre': genre,
        'pdfUrl': pdfUrl,
        'userName': currentUserName,
        'addedAt': FieldValue.serverTimestamp(),
      });

      customSnackbar(title: 'Success', message: 'Book added to Finished');

      // Boost genre score
      if (_currentGenre.isNotEmpty) {
        try {
          final recCtrl = Get.find<RecommendationController>();
          recCtrl.logBookGenreInteraction(_currentGenre, boost: 2);
        } catch (_) {}
      }
    } catch (e) {
      print("Error adding book to Reading: $e");
      customSnackbar(title: 'Error', message: 'Failed to add book to Finished');
    }
  }

  // ─── Book Comments ─────────────────────────────────────────────────────────

  /// Observable list of comments for the currently viewed book.
  var comments = <Map<String, dynamic>>[].obs;
  var isCommentsLoading = false.obs;
  String? _commentsBookId;

  /// Start listening to real-time comments for [bookId].
  void listenToComments(String bookId) {
    _commentsBookId = bookId;
    isCommentsLoading.value = true;
    firestore
        .collection('book_comments')
        .where('bookId', isEqualTo: bookId)
        .snapshots()
        .listen((snap) {
      List<Map<String, dynamic>> list = snap.docs.map((d) {
        final data = d.data();
        return {
          'commentId': d.id,
          'userId': data['userId'] ?? '',
          'username': data['username'] ?? 'Anonymous',
          'comment': data['comment'] ?? '',
          'timestamp': data['timestamp'],
        };
      }).toList();

      // Sort in memory (newest first) to avoid requiring Firestore composite index
      list.sort((a, b) {
        final tA = a['timestamp'];
        final tB = b['timestamp'];
        if (tA is Timestamp && tB is Timestamp) return tB.compareTo(tA);
        if (tA is Timestamp) return -1;
        if (tB is Timestamp) return 1;
        return 0;
      });

      comments.value = list;
      isCommentsLoading.value = false;
    }, onError: (e) {
      print("Error fetching comments: $e");
      isCommentsLoading.value = false;
    });
  }

  /// Add a new comment for [bookId].
  Future<void> addComment(String bookId, String commentText) async {
    final user = auth.currentUser;
    if (user == null) return;
    final trimmed = commentText.trim();
    if (trimmed.isEmpty) {
      customSnackbar(title: 'Error', message: 'Comment cannot be empty');
      return;
    }
    try {
      await firestore.collection('book_comments').add({
        'bookId': bookId,
        'userId': user.uid,
        'username': userName.value.isNotEmpty ? userName.value : 'Anonymous',
        'comment': trimmed,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      customSnackbar(title: 'Error', message: 'Failed to post comment');
    }
  }

  /// Delete a comment by [commentId]. Only allowed for the comment owner.
  Future<void> deleteComment(String commentId) async {
    try {
      await firestore.collection('book_comments').doc(commentId).delete();
    } catch (e) {
      customSnackbar(title: 'Error', message: 'Failed to delete comment');
    }
  }
}

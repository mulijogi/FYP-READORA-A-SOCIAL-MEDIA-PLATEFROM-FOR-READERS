import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class BooksController extends GetxController {
  var books = [].obs;
  var selectedGenre = 'All'.obs;
  var searchTerm = ''.obs;
  var filteredBooks = [].obs;
  late FirebaseFirestore firestore;
  late FirebaseAuth auth;

  // Debounce timer for search — avoids filtering on every keystroke
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    firestore = FirebaseFirestore.instance;
    auth = FirebaseAuth.instance;
    fetchBooks();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  // Fetch books from Firestore — real-time listener
  void fetchBooks() {
    firestore
        .collection('books')
        .limit(200) // Cap at 200 to avoid over-fetching
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      final fetchedBooks = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Shuffle only once when first loaded, not on every change
      if (books.isEmpty) fetchedBooks.shuffle();

      books.value = fetchedBooks;
      filterBooks();
    }, onError: (error) {
      print("Error fetching books: $error");
    });
  }

  void filterBooks() {
    // Step 1: Filter by genre
    final List genreFiltered = selectedGenre.value == 'All'
        ? List.from(books)
        : books.where((book) {
            final genre =
                book['genre']?.toString().toLowerCase() ?? '';
            return genre.contains(selectedGenre.value.toLowerCase());
          }).toList();

    // Step 2: Filter by search term
    final List result = searchTerm.value.isEmpty
        ? genreFiltered
        : genreFiltered.where((book) {
            final q = searchTerm.value.toLowerCase();
            final title = book['title']?.toString().toLowerCase() ?? '';
            final author = book['author']?.toString().toLowerCase() ?? '';
            final isbn = book['isbn']?.toString().toLowerCase() ?? '';
            return title.contains(q) ||
                author.contains(q) ||
                isbn.contains(q);
          }).toList();

    // Step 3: Sort — books with PDF (readable) first
    result.sort((a, b) {
      final hasPdfA =
          a['pdfUrl'] != null && a['pdfUrl'].toString().isNotEmpty;
      final hasPdfB =
          b['pdfUrl'] != null && b['pdfUrl'].toString().isNotEmpty;
      if (hasPdfA && !hasPdfB) return -1;
      if (!hasPdfA && hasPdfB) return 1;
      return 0;
    });

    filteredBooks.value = result;
  }

  // Genre selection — instant response
  void selectGenre(String genre) {
    selectedGenre.value = genre;
    filterBooks();
  }

  // Search — debounced 300ms to avoid filtering on every single keystroke
  void setSearchTerm(String term) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      searchTerm.value = term;
      filterBooks();
    });
  }

  void reshuffleBooks() {
    final list = List.from(books);
    list.shuffle();
    books.value = list;
    filterBooks();
  }
}

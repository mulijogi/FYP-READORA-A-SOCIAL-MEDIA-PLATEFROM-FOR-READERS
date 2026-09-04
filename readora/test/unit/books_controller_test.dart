import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Books/controller/books_controller.dart';

void main() {
  late BooksController booksController;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();

    // Reset GetX before each test
    Get.reset();

    // Inject the controller
    booksController = BooksController();
    // Replace the instances inside the controller with our mocks/fakes
    booksController.firestore = fakeFirestore;
    booksController.auth = mockAuth;
  });

  group('BooksController Tests', () {
    test('fetchBooks updates books and filteredBooks', () async {
      // Add fake data to Firestore
      await fakeFirestore.collection('books').add({
        'title': 'Test Book 1',
        'author': 'Test Author 1',
        'genre': 'Fiction',
        'isbn': '123456789',
        'pdfUrl': 'http://example.com/book1.pdf',
      });
      await fakeFirestore.collection('books').add({
        'title': 'Test Book 2',
        'author': 'Test Author 2',
        'genre': 'Science',
        'isbn': '987654321',
        'pdfUrl': '',
      });

      // Call the method
      booksController.fetchBooks();

      // Wait a small amount for streams to emit
      await Future.delayed(const Duration(milliseconds: 100));

      // Assertions
      expect(booksController.books.length, 2);
      expect(booksController.filteredBooks.length, 2);

      // Ensure free books (with pdfUrl) are sorted to the top
      expect(booksController.filteredBooks.first['title'], 'Test Book 1');
    });

    test('filterBooks by genre', () async {
      // Add fake data
      await fakeFirestore.collection('books').add({
        'title': 'Test Book 1',
        'author': 'Test Author 1',
        'genre': 'Fiction',
      });
      await fakeFirestore.collection('books').add({
        'title': 'Test Book 2',
        'author': 'Test Author 2',
        'genre': 'Science',
      });

      booksController.fetchBooks();
      await Future.delayed(const Duration(milliseconds: 100));

      booksController.selectGenre('Fiction');

      expect(booksController.filteredBooks.length, 1);
      expect(booksController.filteredBooks.first['genre'], 'Fiction');
    });

    test('filterBooks by search term', () async {
      // Add fake data
      await fakeFirestore.collection('books').add({
        'title': 'The Great Gatsby',
        'author': 'F. Scott Fitzgerald',
        'isbn': '1111',
      });
      await fakeFirestore.collection('books').add({
        'title': '1984',
        'author': 'George Orwell',
        'isbn': '2222',
      });

      booksController.fetchBooks();
      await Future.delayed(const Duration(milliseconds: 100));

      // Search by title
      booksController.setSearchTerm('1984');
      expect(booksController.filteredBooks.length, 1);
      expect(booksController.filteredBooks.first['title'], '1984');

      // Search by author
      booksController.setSearchTerm('f. scott');
      expect(booksController.filteredBooks.length, 1);
      expect(
          booksController.filteredBooks.first['author'], 'F. Scott Fitzgerald');
    });
  });
}

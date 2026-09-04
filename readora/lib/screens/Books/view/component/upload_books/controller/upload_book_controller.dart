import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:readora/utils/custom_snackbar.dart';

class UploadBooksController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final authorController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final ratingController = TextEditingController();
  final pagesController = TextEditingController();
  final isbnController = TextEditingController();
  final bookFormatController = TextEditingController();
  final genresController = TextEditingController();
  final totalRatingController = TextEditingController();
  final pdfUrlController = TextEditingController();

  final isLoading = false.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);
  String? selectedGenre;

  bool validateISBN(String isbn) {
    // Remove any non-numeric characters (except 'X' for ISBN-10 check digit)
    isbn = isbn.replaceAll(RegExp(r'[^0-9X]'), '');

    // Check if the ISBN length is valid for either ISBN-10 (10 digits) or ISBN-13 (13 digits)
    if (isbn.length == 10) {
      return _validateISBN10(isbn); // Validate ISBN-10
    } else if (isbn.length == 13) {
      return _validateISBN13(isbn); // Validate ISBN-13
    }
    return false; // Invalid length
  }

// ISBN-10 validation
  bool _validateISBN10(String isbn) {
    int sum = 0;

    // Sum the first 9 digits with their respective weights (10 to 2)
    for (int i = 0; i < 9; i++) {
      final digit = int.tryParse(isbn[i]);
      if (digit == null) return false; // If it's not a number, return false
      sum += (10 - i) * digit; // Multiply by the weight (10 to 2)
    }

    // Check the last character (either a digit or 'X')
    final lastChar = isbn[9];
    sum += lastChar == 'X' ? 10 : int.tryParse(lastChar) ?? 0;

    return sum % 11 == 0; // Valid ISBN if sum is divisible by 11
  }

// ISBN-13 validation
  bool _validateISBN13(String isbn) {
    int sum = 0;

    // Sum the first 12 digits, alternating between weights of 1 and 3
    for (int i = 0; i < 12; i++) {
      final digit = int.tryParse(isbn[i]);
      if (digit == null) return false; // If it's not a number, return false
      sum += (i % 2 == 0 ? 1 : 3) *
          digit; // Multiply by 1 for even indices, 3 for odd indices
    }

    // Check the last digit (check digit)
    final checkDigit = int.tryParse(isbn[12]);
    if (checkDigit == null) return false;

    sum += checkDigit;

    return sum % 10 == 0; // Valid ISBN-13 if sum is divisible by 10
  }

  var errors = <String, String?>{}.obs;

  void validateField(String label, String value) {
    String? error;
    if (label == "PDF / Book Link" || label.contains("Optional")) {
      // Optional field - no error if empty
      error = null;
    } else if (value.isEmpty) {
      error = 'Please enter $label';
    } else if (label == "Author Name" && RegExp(r'^-?\d+$').hasMatch(value)) {
      error = 'Author name cannot start with a number';
    } else if (label == "Rating (out of 5)" &&
        (double.tryParse(value) == null ||
            double.parse(value) < 1 ||
            double.parse(value) > 5)) {
      error = 'Please enter a valid rating (1-5)';
    } else if (label == "Total Pages" &&
        (int.tryParse(value) == null || int.tryParse(value)! <= 0)) {
      error = 'Please enter a valid number of pages (must be positive)';
    } else if (label == "ISBN" && !validateISBN(value)) {
      error = 'Please enter a valid ISBN number';
    } else if (label == "Book Format" && RegExp(r'^-?\d+$').hasMatch(value)) {
      error = 'Book format cannot contain numbers';
    } else if (label == "Total Ratings" &&
        (int.tryParse(value) == null || int.tryParse(value)! <= 0)) {
      error = 'Please enter a valid total rating';
    }
    errors[label] = error;
  }

  bool validateAllFields() {
    validateField("Author Name", authorController.text.trim());
    validateField("Title", titleController.text.trim());
    validateField("Description", descriptionController.text.trim());
    validateField("Rating (out of 5)", ratingController.text.trim());
    validateField("Total Pages", pagesController.text.trim());
    validateField("ISBN", isbnController.text.trim());
    validateField("Book Format", bookFormatController.text.trim());
    validateField("Total Ratings", totalRatingController.text.trim());
    validateField("PDF / Book Link", pdfUrlController.text.trim());

    return errors.values.every((e) => e == null);
  }

  // Function to pick an image from the gallery
  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      selectedImage.value = File(pickedFile.path);
    } else {
      customSnackbar(
          title: 'No Image Selected',
          message: 'Please select an image to upload.see thos off');
    }
  }

  // Function to upload book details
  Future<bool> uploadBookDetails(String currentuserId) async {
    try {
      isLoading.value = true;
      String isbn = isbnController.text.trim();
      final querySnapshot = await _firestore
          .collection('books')
          .where('isbn', isEqualTo: isbn)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        customSnackbar(
            title: 'Duplicate ISBN',
            message: 'A book with this ISBN already exists.');
        isLoading.value = false;
        return false;
      }

      String imageUrl = 'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=400';

      Map<String, dynamic> bookData = {
        'author': authorController.text.trim(),
        'title': titleController.text.trim(),
        'desc': descriptionController.text.trim(),
        'rating': double.tryParse(ratingController.text.trim()) ?? 0,
        'pages': int.tryParse(pagesController.text.trim()) ?? 0,
        'isbn': isbnController.text.trim(),
        'bookformat': bookFormatController.text.trim(),
        'genre': selectedGenre ?? genresController.text.trim(),
        'totalratings': int.tryParse(totalRatingController.text.trim()) ?? 0,
        'img': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': currentuserId,
        'isPaid': false, // Default to free
        'isApproved': true, // Default to approved
        'pdfUrl': pdfUrlController.text.trim().isNotEmpty
            ? pdfUrlController.text.trim()
            : 'https://www.gutenberg.org/files/1232/1232-pdf.pdf',
      };

      await _firestore.collection('books').add(bookData);

      customSnackbar(title: 'Success', message: 'Book uploaded successfully.');
      return true;
    } catch (e) {
      customSnackbar(title: 'Error', message: 'Failed to upload book: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

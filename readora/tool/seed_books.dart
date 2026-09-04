// Script to seed 20 free public-domain books into Firestore
// Run with: dart run tool/seed_books.dart
// Uses Firestore REST API — no auth needed since rules allow open write for dev

import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── CONFIG ─────────────────────────────────────────────────────────────────
const String projectId = 'readora-8cc74';
const String apiKey = 'AIzaSyB0YgvCrlBJqrgob8b_0d89wM9amZt0d24';
const String firestoreBase =
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/books';

// ─── 20 FREE PUBLIC-DOMAIN BOOKS ─────────────────────────────────────────────
// All PDFs are from Project Gutenberg — direct download links, no CORS issues on web
// Cover images are from Open Library (free API)
final List<Map<String, dynamic>> books = [
  // ─── ROMANCE ───────────────────────────────────────────────────────────────
  {
    'title': 'Pride and Prejudice',
    'author': 'Jane Austen',
    'desc':
        'The story of the Bennet family and the romantic entanglement between the witty Elizabeth Bennet and the proud Mr. Darcy. A timeless exploration of love, class, and character.',
    'genre': 'Romance',
    'pages': 432,
    'isbn': '978-0-14-143951-8',
    'bookformat': 'PDF',
    'rating': 4.8,
    'totalratings': 12500,
    'img': 'https://covers.openlibrary.org/b/id/8739161-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/1342/1342-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  {
    'title': 'Sense and Sensibility',
    'author': 'Jane Austen',
    'desc':
        'Two sisters, Elinor and Marianne Dashwood, navigate the complex world of love and heartbreak in 19th century England. A beautiful tale of reason versus emotion.',
    'genre': 'Romance',
    'pages': 374,
    'isbn': '978-0-14-143966-2',
    'bookformat': 'PDF',
    'rating': 4.6,
    'totalratings': 8700,
    'img': 'https://covers.openlibrary.org/b/id/8739521-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/161/161-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  {
    'title': 'Jane Eyre',
    'author': 'Charlotte Brontë',
    'desc':
        'An orphaned girl grows up to become a governess and falls in love with her mysterious employer, Mr. Rochester, uncovering dark secrets in Thornfield Hall.',
    'genre': 'Romance',
    'pages': 507,
    'isbn': '978-0-14-144114-6',
    'bookformat': 'PDF',
    'rating': 4.7,
    'totalratings': 11200,
    'img': 'https://covers.openlibrary.org/b/id/8739420-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/1260/1260-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  {
    'title': 'Wuthering Heights',
    'author': 'Emily Brontë',
    'desc':
        'A tale of passionate and destructive love set against the wild Yorkshire moors. The story of Heathcliff and Catherine Earnshaw is one of literature\'s most intense romances.',
    'genre': 'Romance',
    'pages': 352,
    'isbn': '978-0-14-143955-6',
    'bookformat': 'PDF',
    'rating': 4.5,
    'totalratings': 9800,
    'img': 'https://covers.openlibrary.org/b/id/8739536-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/768/768-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  // ─── HISTORY ───────────────────────────────────────────────────────────────
  {
    'title': 'The Art of War',
    'author': 'Sun Tzu',
    'desc':
        'An ancient Chinese military treatise dating from the 5th century BC. It has remained the most influential strategy text in East Asia for the past two thousand years.',
    'genre': 'History',
    'pages': 98,
    'isbn': '978-1-59030-350-0',
    'bookformat': 'PDF',
    'rating': 4.7,
    'totalratings': 18000,
    'img': 'https://covers.openlibrary.org/b/id/8089889-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/132/132-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  {
    'title': 'The Histories',
    'author': 'Herodotus',
    'desc':
        'Written in 440 BC, this is the world\'s first major work of history. Herodotus chronicles the Greco-Persian Wars and explores the cultures and peoples of the ancient world.',
    'genre': 'History',
    'pages': 592,
    'isbn': '978-0-14-044908-2',
    'bookformat': 'PDF',
    'rating': 4.4,
    'totalratings': 5200,
    'img': 'https://covers.openlibrary.org/b/id/8261227-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/2456/2456-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  {
    'title': 'The Prince',
    'author': 'Niccolò Machiavelli',
    'desc':
        'A 16th-century political treatise on how rulers maintain power. Machiavelli\'s ruthlessly pragmatic observations on statecraft have made this one of the most controversial books ever written.',
    'genre': 'History',
    'pages': 140,
    'isbn': '978-0-14-044915-0',
    'bookformat': 'PDF',
    'rating': 4.5,
    'totalratings': 14500,
    'img': 'https://covers.openlibrary.org/b/id/8231990-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/1232/1232-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  {
    'title': 'Caesar\'s Gallic Wars',
    'author': 'Julius Caesar',
    'desc':
        'Julius Caesar\'s first-hand account of the Gallic Wars (58–50 BC), one of the most remarkable pieces of military history ever written. A vivid record of Roman expansion and ancient warfare.',
    'genre': 'History',
    'pages': 224,
    'isbn': '978-0-14-044433-9',
    'bookformat': 'PDF',
    'rating': 4.2,
    'totalratings': 3800,
    'img': 'https://covers.openlibrary.org/b/id/8218462-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/10657/10657-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  // ─── BIOGRAPHY ─────────────────────────────────────────────────────────────
  {
    'title': 'Autobiography of Benjamin Franklin',
    'author': 'Benjamin Franklin',
    'desc':
        'Benjamin Franklin\'s own account of his remarkable life — from his humble beginnings in Boston to his rise as a scientist, inventor, statesman, and Founding Father of the United States.',
    'genre': 'Biography',
    'pages': 256,
    'isbn': '978-0-486-29073-0',
    'bookformat': 'PDF',
    'rating': 4.5,
    'totalratings': 7600,
    'img': 'https://covers.openlibrary.org/b/id/8261011-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/20203/20203-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  {
    'title': 'Up From Slavery',
    'author': 'Booker T. Washington',
    'desc':
        'The inspiring autobiography of Booker T. Washington, who was born into slavery and went on to become one of the most influential African-American educators and leaders of the 19th century.',
    'genre': 'Biography',
    'pages': 268,
    'isbn': '978-0-14-018706-7',
    'bookformat': 'PDF',
    'rating': 4.6,
    'totalratings': 5500,
    'img': 'https://covers.openlibrary.org/b/id/8093712-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/2376/2376-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  {
    'title': 'Personal Memoirs of Ulysses S. Grant',
    'author': 'Ulysses S. Grant',
    'desc':
        'The acclaimed memoirs of the 18th President of the United States and Union Army commander, written in the final year of his life. Widely considered the greatest military memoir ever written.',
    'genre': 'Biography',
    'pages': 633,
    'isbn': '978-0-14-043701-0',
    'bookformat': 'PDF',
    'rating': 4.4,
    'totalratings': 4100,
    'img': 'https://covers.openlibrary.org/b/id/8258027-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/4367/4367-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  // ─── FANTASY ───────────────────────────────────────────────────────────────
  {
    'title': 'Alice\'s Adventures in Wonderland',
    'author': 'Lewis Carroll',
    'desc':
        'Young Alice falls down a rabbit hole into a fantastical world populated with peculiar creatures. A classic of imaginative literature that has fascinated children and adults alike for over 150 years.',
    'genre': 'Fantasy',
    'pages': 130,
    'isbn': '978-0-14-143976-1',
    'bookformat': 'PDF',
    'rating': 4.6,
    'totalratings': 15000,
    'img': 'https://covers.openlibrary.org/b/id/8739389-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/11/11-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  {
    'title': 'The Wonderful Wizard of Oz',
    'author': 'L. Frank Baum',
    'desc':
        'A Kansas girl named Dorothy is swept away by a tornado to the magical land of Oz, where she embarks on an adventure with a Scarecrow, Tin Man, and Cowardly Lion to find the great Wizard.',
    'genre': 'Fantasy',
    'pages': 260,
    'isbn': '978-0-14-036143-7',
    'bookformat': 'PDF',
    'rating': 4.5,
    'totalratings': 13500,
    'img': 'https://covers.openlibrary.org/b/id/8231743-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/55/55-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  {
    'title': 'A Princess of Mars',
    'author': 'Edgar Rice Burroughs',
    'desc':
        'John Carter, a Civil War veteran, is mysteriously transported to Mars, where he becomes embroiled in an epic adventure involving alien races, a beautiful princess, and interplanetary warfare.',
    'genre': 'Fantasy',
    'pages': 286,
    'isbn': '978-1-59308-225-7',
    'bookformat': 'PDF',
    'rating': 4.3,
    'totalratings': 6800,
    'img': 'https://covers.openlibrary.org/b/id/8218347-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/62/62-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  {
    'title': 'Peter Pan',
    'author': 'J.M. Barrie',
    'desc':
        'The story of the boy who never grows up. Peter Pan leads Wendy and her brothers to the magical Neverland, filled with pirates, mermaids, fairies, and lost boys.',
    'genre': 'Fantasy',
    'pages': 192,
    'isbn': '978-0-14-036202-1',
    'bookformat': 'PDF',
    'rating': 4.5,
    'totalratings': 11000,
    'img': 'https://covers.openlibrary.org/b/id/8739462-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/16/16-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  // ─── ART ───────────────────────────────────────────────────────────────────
  {
    'title': 'The Picture of Dorian Gray',
    'author': 'Oscar Wilde',
    'desc':
        'A beautiful young man makes a Faustian bargain — his portrait ages while he remains forever young. A stunning exploration of art, beauty, morality, and corruption.',
    'genre': 'Art',
    'pages': 272,
    'isbn': '978-0-14-143957-0',
    'bookformat': 'PDF',
    'rating': 4.7,
    'totalratings': 12000,
    'img': 'https://covers.openlibrary.org/b/id/8739499-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/174/174-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  {
    'title': 'The Importance of Being Earnest',
    'author': 'Oscar Wilde',
    'desc':
        'A masterful comedy of manners that skewers the hypocrisy of Victorian upper-class society. Considered one of the greatest plays in English literature, full of wit and brilliant dialogue.',
    'genre': 'Art',
    'pages': 95,
    'isbn': '978-0-14-048209-7',
    'bookformat': 'PDF',
    'rating': 4.6,
    'totalratings': 9900,
    'img': 'https://covers.openlibrary.org/b/id/8231880-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/844/844-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  // ─── POLITICS ──────────────────────────────────────────────────────────────
  {
    'title': 'Common Sense',
    'author': 'Thomas Paine',
    'desc':
        'Published in 1776, this pamphlet by Thomas Paine challenged the authority of the British government and the royal monarchy. It is credited as one of the most influential works that inspired the American Revolution.',
    'genre': 'Politics',
    'pages': 64,
    'isbn': '978-0-14-039016-1',
    'bookformat': 'PDF',
    'rating': 4.5,
    'totalratings': 7200,
    'img': 'https://covers.openlibrary.org/b/id/8261119-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/147/147-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  {
    'title': 'The Federalist Papers',
    'author': 'Alexander Hamilton, James Madison, John Jay',
    'desc':
        'A collection of 85 essays written to promote the ratification of the United States Constitution. These papers remain one of the most important works in the history of American political thought.',
    'genre': 'Politics',
    'pages': 528,
    'isbn': '978-0-14-024495-8',
    'bookformat': 'PDF',
    'rating': 4.4,
    'totalratings': 6100,
    'img': 'https://covers.openlibrary.org/b/id/8254668-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/1404/1404-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
  {
    'title': 'Democracy in America',
    'author': 'Alexis de Tocqueville',
    'desc':
        'Written after Tocqueville\'s travels in the United States, this landmark work analyzes the unique political and social nature of American democracy and its influence on the world.',
    'genre': 'Politics',
    'pages': 800,
    'isbn': '978-0-14-043442-2',
    'bookformat': 'PDF',
    'rating': 4.3,
    'totalratings': 4900,
    'img': 'https://covers.openlibrary.org/b/id/8094169-L.jpg',
    'pdfUrl': 'https://www.gutenberg.org/files/815/815-pdf.pdf',
    'isPaid': false,
    'isApproved': true,
  },
];

// ─── FIRESTORE REST API HELPER ────────────────────────────────────────────────

Map<String, dynamic> toFirestoreValue(dynamic value) {
  if (value is String) return {'stringValue': value};
  if (value is int) return {'integerValue': value.toString()};
  if (value is double) return {'doubleValue': value};
  if (value is bool) return {'booleanValue': value};
  return {'stringValue': value.toString()};
}

Map<String, dynamic> toFirestoreFields(Map<String, dynamic> data) {
  final fields = <String, dynamic>{};
  data.forEach((key, value) {
    fields[key] = toFirestoreValue(value);
  });
  return fields;
}

Future<bool> addBook(Map<String, dynamic> book, int index) async {
  final fields = toFirestoreFields({
    ...book,
    'userId': 'system',
    'userName': 'Readora Team',
  });

  final url = Uri.parse('$firestoreBase?key=$apiKey');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'fields': fields}),
  );

  if (response.statusCode == 200) {
    print('[${index + 1}/20] ✅ Added: ${book['title']} (${book['genre']})');
    return true;
  } else {
    print(
        '[${index + 1}/20] ❌ Failed: ${book['title']} — ${response.statusCode}: ${response.body}');
    return false;
  }
}

void main() async {
  print('🚀 Seeding 20 free books into Firestore...\n');

  int success = 0;
  for (int i = 0; i < books.length; i++) {
    final ok = await addBook(books[i], i);
    if (ok) success++;
    // Small delay to avoid rate limits
    await Future.delayed(const Duration(milliseconds: 500));
  }

  print('\n✅ Done! $success/${books.length} books added successfully.');
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String projectId = 'readora-8cc74';
const String apiKey = 'AIzaSyB0YgvCrlBJqrgob8b_0d89wM9amZt0d24';
const String firestoreBase =
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/books';

void main() async {
  print("Fetching all books from Firestore...\n");

  String? pageToken;
  int totalCount = 0;
  int pageNum = 1;
  final allBooks = <Map<String, String>>[];

  do {
    String fetchUrl = '$firestoreBase?key=$apiKey&pageSize=300';
    if (pageToken != null && pageToken.isNotEmpty) {
      fetchUrl += '&pageToken=${Uri.encodeComponent(pageToken)}';
    }

    final res = await http.get(Uri.parse(fetchUrl));
    if (res.statusCode != 200) break;

    final data = jsonDecode(res.body);
    final List docs = data['documents'] ?? [];
    pageToken = data['nextPageToken'];

    for (final doc in docs) {
      final fields = doc['fields'] ?? {};
      final title = fields['title']?['stringValue'] ?? 'Unknown Title';
      final author = fields['author']?['stringValue'] ?? 'Unknown Author';
      final genre = fields['genre']?['stringValue'] ?? 'Unknown Genre';
      allBooks.add({'title': title, 'author': author, 'genre': genre});
      totalCount++;
    }

    pageNum++;
  } while (pageToken != null && pageToken.isNotEmpty);

  // Sort by genre then title
  allBooks.sort((a, b) {
    final genreCompare = (a['genre'] ?? '').compareTo(b['genre'] ?? '');
    if (genreCompare != 0) return genreCompare;
    return (a['title'] ?? '').compareTo(b['title'] ?? '');
  });

  // Write to CSV file for easy reference
  final csvFile = File('tool/books_list.csv');
  final csvBuffer = StringBuffer();
  csvBuffer.writeln('No,Genre,Title,Author,PDF Download Link (Open in Browser)');

  int no = 1;
  String currentGenre = '';
  for (final book in allBooks) {
    final genre = book['genre'] ?? '';
    final title = book['title'] ?? '';
    final author = book['author'] ?? '';

    // Generate a Gutenberg search link (open in browser to find & download PDF)
    final searchQuery = Uri.encodeComponent('${title.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim()} $author filetype:pdf');
    final gutenbergSearch = 'https://www.gutenberg.org/ebooks/search/?query=${Uri.encodeComponent(title.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim())}&submit_search=Go';

    csvBuffer.writeln('$no,$genre,"$title","$author","$gutenbergSearch"');

    if (genre != currentGenre) {
      print('\n=== $genre ===');
      currentGenre = genre;
    }
    print('$no. $title — $author');
    no++;
  }

  await csvFile.writeAsString(csvBuffer.toString());

  print('\n===========================================');
  print('Total Books in Database: $totalCount');
  print('Book list saved to: tool/books_list.csv');
  print('===========================================');
  print('\nINSTRUCTION: Open books_list.csv and use the "PDF Download Link" column');
  print('to find each book on Gutenberg, download PDF, upload to Google Drive,');
  print('and share the link back.');
}

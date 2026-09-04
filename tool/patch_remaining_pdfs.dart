import 'dart:convert';
import 'package:http/http.dart' as http;

const String projectId = 'readora-8cc74';
const String apiKey = 'AIzaSyB0YgvCrlBJqrgob8b_0d89wW9amZt0d24';
const String firestoreBase =
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/books';

// Project Gutenberg direct PDF file URLs (format: /files/[ID]/[ID]-pdf.pdf)
// Plus alternative sources for non-Gutenberg books
final List<Map<String, String>> candidateUrls = [
  // Drama – Shakespeare (Gutenberg)
  {
    'title': 'Hamlet',
    'pdfUrl': 'https://www.gutenberg.org/files/1524/1524-pdf.pdf',
  },
  {
    'title': 'Romeo and Juliet',
    'pdfUrl': 'https://www.gutenberg.org/files/1112/1112-pdf.pdf',
  },
  {
    'title': 'Macbeth',
    'pdfUrl': 'https://www.gutenberg.org/files/1533/1533-pdf.pdf',
  },
  {
    'title': 'Othello',
    'pdfUrl': 'https://www.gutenberg.org/files/1531/1531-pdf.pdf',
  },
  {
    'title': 'King Lear',
    'pdfUrl': 'https://www.gutenberg.org/files/1532/1532-pdf.pdf',
  },
  // History / Politics
  {
    'title': 'The Art of War',
    'pdfUrl': 'https://www.gutenberg.org/files/132/132-pdf.pdf',
  },
  {
    'title': 'Common Sense',
    'pdfUrl': 'https://www.gutenberg.org/files/147/147-pdf.pdf',
  },
  {
    'title': 'The Communist Manifesto',
    'pdfUrl': 'https://www.gutenberg.org/files/61/61-pdf.pdf',
  },
  // Biography
  {
    'title': 'Narrative of the Life of Frederick Douglass',
    'pdfUrl': 'https://www.gutenberg.org/files/23/23-pdf.pdf',
  },
  {
    'title': 'Twelve Years a Slave',
    'pdfUrl': 'https://www.gutenberg.org/files/11624/11624-pdf.pdf',
  },
  // Fantasy
  {
    'title': 'The Wonderful Wizard of Oz',
    'pdfUrl': 'https://www.gutenberg.org/files/55/55-pdf.pdf',
  },
  {
    'title': 'Peter and Wendy',
    'pdfUrl': 'https://www.gutenberg.org/files/16/16-pdf.pdf',
  },
  {
    'title': 'A Princess of Mars',
    'pdfUrl': 'https://www.gutenberg.org/files/62/62-pdf.pdf',
  },
];

void main() async {
  print('🔍 Testing ${candidateUrls.length} Gutenberg direct PDF URLs...\n');

  final List<Map<String, String>> working = [];

  for (final book in candidateUrls) {
    try {
      final res = await http.head(
        Uri.parse(book['pdfUrl']!),
        headers: {'User-Agent': 'ReadoraApp/1.0'},
      );
      final ct = res.headers['content-type'] ?? '';
      if (res.statusCode == 200 && ct.contains('pdf')) {
        print('  ✅ ${book['title']} — 200 OK');
        working.add(book);
      } else if (res.statusCode == 302 || res.statusCode == 301) {
        // Follow redirect
        final location = res.headers['location'] ?? '';
        print('  🔀 ${book['title']} — redirect to $location');
        final res2 = await http.head(Uri.parse(location),
            headers: {'User-Agent': 'ReadoraApp/1.0'});
        final ct2 = res2.headers['content-type'] ?? '';
        if (res2.statusCode == 200 && ct2.contains('pdf')) {
          print('     ✅ Redirect OK! Using: $location');
          working.add({'title': book['title']!, 'pdfUrl': location});
        } else {
          print('     ❌ Redirect failed: ${res2.statusCode} $ct2');
        }
      } else {
        final preview = ct.length > 40 ? ct.substring(0, 40) : ct;
        print('  ❌ ${book['title']} — ${res.statusCode} ($preview)');
      }
    } catch (e) {
      print('  ❌ ${book['title']} — Error: $e');
    }
  }

  print('\n✅ ${working.length} working PDFs found.\n');

  if (working.isEmpty) {
    print('No working PDFs to update. Exiting.');
    return;
  }

  print('🚀 Fetching Firestore books and patching pdfUrl...\n');

  final fetchUrl = '$firestoreBase?key=$apiKey&pageSize=100';
  final res = await http.get(Uri.parse(fetchUrl));
  if (res.statusCode != 200) {
    print('❌ Failed to fetch Firestore books: ${res.statusCode}');
    return;
  }

  final data = jsonDecode(res.body);
  final List docs = data['documents'] ?? [];

  int updated = 0;
  int notFound = 0;

  for (final wBook in working) {
    Map<String, dynamic>? matchedDoc;
    for (final doc in docs) {
      final fields = doc['fields'] as Map<String, dynamic>;
      final docTitle = fields['title']?['stringValue'] ?? '';
      if (docTitle.toLowerCase().trim() ==
          wBook['title']!.toLowerCase().trim()) {
        matchedDoc = doc;
        break;
      }
    }

    if (matchedDoc == null) {
      print('  ⚠️  Not found in Firestore: ${wBook['title']}');
      notFound++;
      continue;
    }

    final docName = matchedDoc['name'];
    final patchUrl =
        'https://firestore.googleapis.com/v1/$docName?key=$apiKey&updateMask.fieldPaths=pdfUrl';
    final body = jsonEncode({
      'fields': {
        'pdfUrl': {'stringValue': wBook['pdfUrl']},
      }
    });

    final patchRes = await http.patch(
      Uri.parse(patchUrl),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (patchRes.statusCode == 200) {
      print('  ✅ Updated: ${wBook['title']}');
      updated++;
    } else {
      print(
          '  ❌ Failed to update ${wBook['title']}: ${patchRes.statusCode}');
    }
  }

  print('\n=================================================');
  print('🎉 DONE! Updated $updated more books with Gutenberg PDF links.');
  if (notFound > 0) print('⚠️  $notFound not found in Firestore.');
  print('=================================================');
}

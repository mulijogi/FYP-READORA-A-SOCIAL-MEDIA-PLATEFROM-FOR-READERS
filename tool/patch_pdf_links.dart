import 'dart:convert';
import 'package:http/http.dart' as http;

const String projectId = 'readora-8cc74';
const String apiKey = 'AIzaSyB0YgvCrlBJqrgob8b_0d89wW9amZt0d24';
const String firestoreBase =
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/books';

// Only books with VERIFIED working PDF links (200 OK, Content-Type: application/pdf)
// planetebook.com = legit free PDF hosting for public domain books
final List<Map<String, String>> verifiedPdfs = [
  // Classic
  {
    'title': 'Pride and Prejudice',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/pride-and-prejudice.pdf',
  },
  {
    'title': 'Great Expectations',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/great-expectations.pdf',
  },
  {
    'title': 'Frankenstein',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/frankenstein.pdf',
  },
  {
    'title': 'Dracula',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/dracula.pdf',
  },
  {
    'title': 'Jane Eyre',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/jane-eyre.pdf',
  },
  {
    'title': 'Wuthering Heights',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/wuthering-heights.pdf',
  },
  {
    'title': 'The Picture of Dorian Gray',
    'pdfUrl':
        'https://www.planetebook.com/free-ebooks/the-picture-of-dorian-gray.pdf',
  },
  {
    'title': 'Crime and Punishment',
    'pdfUrl':
        'https://www.planetebook.com/free-ebooks/crime-and-punishment.pdf',
  },
  {
    'title': 'The Great Gatsby',
    'pdfUrl':
        'https://pressbooks.library.torontomu.ca/thegreatgatsby/open/download?type=pdf',
  },
  {
    'title': 'Moby-Dick',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/moby-dick.pdf',
  },
  // Drama
  {
    'title': 'Hamlet',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/hamlet.pdf',
  },
  {
    'title': 'Romeo and Juliet',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/romeo-and-juliet.pdf',
  },
  {
    'title': 'Macbeth',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/macbeth.pdf',
  },
  {
    'title': 'Othello',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/othello.pdf',
  },
  {
    'title': 'King Lear',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/king-lear.pdf',
  },
  // History
  {
    'title': 'The Art of War',
    'pdfUrl':
        'https://www.planetebook.com/free-ebooks/the-art-of-war.pdf',
  },
  // Politics
  {
    'title': 'The Prince',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/the-prince.pdf',
  },
  {
    'title': 'Common Sense',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/common-sense.pdf',
  },
  {
    'title': 'The Communist Manifesto',
    'pdfUrl':
        'https://www.planetebook.com/free-ebooks/the-communist-manifesto.pdf',
  },
  // Romance
  {
    'title': 'Sense and Sensibility',
    'pdfUrl':
        'https://www.planetebook.com/free-ebooks/sense-and-sensibility.pdf',
  },
  {
    'title': 'Emma',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/emma.pdf',
  },
  {
    'title': 'Little Women',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/little-women.pdf',
  },
  {
    'title': 'Anna Karenina',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/anna-karenina.pdf',
  },
  // Biography
  {
    'title': 'Narrative of the Life of Frederick Douglass',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/narrative-of-the-life-of-frederick-douglass.pdf',
  },
  {
    'title': 'Twelve Years a Slave',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/twelve-years-a-slave.pdf',
  },
  // Fantasy
  {
    'title': "Alice's Adventures in Wonderland",
    'pdfUrl':
        'https://www.planetebook.com/free-ebooks/alices-adventures-in-wonderland.pdf',
  },
  {
    'title': 'The Wonderful Wizard of Oz',
    'pdfUrl':
        'https://www.planetebook.com/free-ebooks/the-wonderful-wizard-of-oz.pdf',
  },
  {
    'title': 'Peter and Wendy',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/peter-and-wendy.pdf',
  },
  {
    'title': 'A Princess of Mars',
    'pdfUrl':
        'https://www.planetebook.com/free-ebooks/a-princess-of-mars.pdf',
  },
  {
    'title': 'Tarzan of the Apes',
    'pdfUrl':
        'https://www.planetebook.com/free-ebooks/tarzan-of-the-apes.pdf',
  },
];

void main() async {
  print('🔍 Step 1: Testing all PDF URLs first...\n');

  final List<Map<String, String>> working = [];

  for (final book in verifiedPdfs) {
    try {
      final res = await http.head(Uri.parse(book['pdfUrl']!));
      final ct = res.headers['content-type'] ?? '';
      if (res.statusCode == 200 && ct.contains('pdf')) {
        print('  ✅ ${book['title']} — ${res.statusCode} OK');
        working.add(book);
      } else {
        print('  ⚠️  ${book['title']} — ${res.statusCode} (${ct.substring(0, ct.length > 30 ? 30 : ct.length)}) SKIP');
      }
    } catch (e) {
      print('  ❌ ${book['title']} — Error: $e');
    }
  }

  print('\n✅ ${working.length} working PDFs found out of ${verifiedPdfs.length} tested.\n');
  print('🚀 Step 2: Fetching all books from Firestore and updating pdfUrl fields...\n');

  // Fetch all documents
  final fetchUrl = '$firestoreBase?key=$apiKey&pageSize=100';
  final res = await http.get(Uri.parse(fetchUrl));
  if (res.statusCode != 200) {
    print('❌ Failed to fetch books: ${res.statusCode}');
    return;
  }

  final data = jsonDecode(res.body);
  final List docs = data['documents'] ?? [];

  int updated = 0;
  int notFound = 0;

  for (final wBook in working) {
    // Find the matching Firestore doc by title
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
      print('  ✅ Updated pdfUrl for: ${wBook['title']}');
      updated++;
    } else {
      print('  ❌ Failed to update ${wBook['title']}: ${patchRes.statusCode}');
    }
  }

  print('\n=================================================');
  print('🎉 DONE! Updated $updated books with real PDF links.');
  if (notFound > 0) print('⚠️  $notFound books not found in Firestore.');
  print('=================================================');
}

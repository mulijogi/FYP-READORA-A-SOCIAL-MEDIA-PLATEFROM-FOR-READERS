import 'dart:convert';
import 'package:http/http.dart' as http;

// Reliable, tested, direct public PDF links for famous books
final List<Map<String, String>> realPdfBooks = [
  {
    'title': 'Pride and Prejudice',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/pride-and-prejudice.pdf',
  },
  {
    'title': 'The Great Gatsby',
    'pdfUrl': 'https://pressbooks.library.torontomu.ca/thegreatgatsby/open/download?type=pdf',
  },
  {
    'title': 'The Art of War',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/the-art-of-war.pdf',
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
    'title': 'Moby-Dick',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/moby-dick.pdf',
  },
  {
    'title': 'The Picture of Dorian Gray',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/the-picture-of-dorian-gray.pdf',
  },
  {
    'title': 'Crime and Punishment',
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/crime-and-punishment.pdf',
  },
  {
    'title': "Alice's Adventures in Wonderland",
    'pdfUrl': 'https://www.planetebook.com/free-ebooks/alices-adventures-in-wonderland.pdf',
  },
];

void main() async {
  print('Testing PDF URLs...');
  for (final b in realPdfBooks) {
    try {
      final res = await http.head(Uri.parse(b['pdfUrl']!));
      print('${b['title']}: ${res.statusCode} (Content-Type: ${res.headers['content-type']})');
    } catch (e) {
      print('${b['title']}: Error $e');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print("Finding 100% verified working PDF URLs...\n");

  final candidateUrls = [
    // Syncfusion official sample PDFs
    'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
    // Internet Archive / GitHub raw PDFs of real public domain books
    'https://raw.githubusercontent.com/mozilla/pdf.js/master/examples/learning/helloworld.pdf',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    // Gutenberg cache PDF structure (pg{id}.pdf)
    'https://www.gutenberg.org/cache/epub/1342/pg1342-images.pdf',
    'https://www.gutenberg.org/cache/epub/1232/pg1232-images.pdf',
    'https://www.gutenberg.org/cache/epub/11/pg11-images.pdf',
    'https://www.gutenberg.org/cache/epub/768/pg768-images.pdf',
    'https://www.gutenberg.org/cache/epub/161/pg161-images.pdf',
    'https://www.gutenberg.org/cache/epub/1260/pg1260-images.pdf',
    'https://www.gutenberg.org/cache/epub/174/pg174-images.pdf',
    'https://www.gutenberg.org/cache/epub/844/pg844-images.pdf',
    'https://www.gutenberg.org/cache/epub/147/pg147-images.pdf',
    'https://www.gutenberg.org/cache/epub/815/pg815-images.pdf',
  ];

  for (final url in candidateUrls) {
    try {
      final res = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      });
      final len = res.bodyBytes.length;
      final header = len >= 4 ? String.fromCharCodes(res.bodyBytes.sublist(0, 4)) : '';
      final isPdf = header == '%PDF' && res.statusCode == 200;

      if (isPdf) {
        print("✅ VERIFIED WORKING PDF ($len bytes): $url");
      } else {
        print("❌ FAILED (${res.statusCode}, header: $header): $url");
      }
    } catch (e) {
      print("❌ ERROR: $url - $e");
    }
  }
}

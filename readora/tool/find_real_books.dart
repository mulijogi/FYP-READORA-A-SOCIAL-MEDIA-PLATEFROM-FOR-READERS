import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print("Testing various public PDF hosts...\n");

  final candidateUrls = [
    // Standard public domain PDF hosting
    'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    'https://unec.edu.az/application/uploads/2014/12/pdf-sample.pdf',
    'https://ncss.gov.sg/docs/default-source/default-document-library/sample-pdf-download-10mb.pdf',
    'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pypdf.pdf',
    'https://raw.githubusercontent.com/pdf-association/pdf20-examples/master/pdf20-utf8-labels.pdf',
    'https://archive.org/download/TheGreatGatsby_201304/TheGreatGatsby.pdf',
    'https://archive.org/download/prideandprejudic0000aust_n7n6/prideandprejudic0000aust_n7n6.pdf',
    'https://archive.org/download/artofwar0000sunt_h8u3/artofwar0000sunt_h8u3.pdf',
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
        print("✅ 100% VALID PDF ($len bytes): $url");
      } else {
        print("❌ INVALID (${res.statusCode}, header: '$header'): $url");
      }
    } catch (e) {
      print("❌ ERROR: $url - $e");
    }
  }
}

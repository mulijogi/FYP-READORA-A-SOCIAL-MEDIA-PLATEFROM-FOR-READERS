import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print("Testing Project Gutenberg PDF URL accessibility...");

  final urls = [
    'https://www.gutenberg.org/files/1232/1232-pdf.pdf', // The Prince
    'https://www.gutenberg.org/files/1342/1342-pdf.pdf', // Pride & Prejudice
    'https://www.gutenberg.org/files/11/11-pdf.pdf',     // Alice
    'https://raw.githubusercontent.com/mozilla/pdf.js/master/web/compressed.tracemonkey-pypdf.pdf',
    'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
  ];

  for (final url in urls) {
    try {
      final res = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      });
      print("\nURL: $url");
      print("Status: ${res.statusCode}");
      print("Content-Type: ${res.headers['content-type']}");
      print("Access-Control-Allow-Origin: ${res.headers['access-control-allow-origin']}");
      print("Content-Length: ${res.bodyBytes.length} bytes");
      if (res.bodyBytes.length > 4) {
        final header = String.fromCharCodes(res.bodyBytes.sublist(0, 4));
        print("Header Signature: $header (PDF signature is %PDF)");
      }
    } catch (e) {
      print("Error testing $url: $e");
    }
  }
}

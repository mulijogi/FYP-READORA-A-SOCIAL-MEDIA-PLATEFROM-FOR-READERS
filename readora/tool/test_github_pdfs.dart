import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print("Testing GitHub raw and Archive.org book PDF URLs...\n");

  final testUrls = [
    'https://raw.githubusercontent.com/Anand-G/Book-Bot/master/books/Pride%20and%20Prejudice.pdf',
    'https://raw.githubusercontent.com/Anand-G/Book-Bot/master/books/The%20Prince.pdf',
    'https://raw.githubusercontent.com/Anand-G/Book-Bot/master/books/The%20Art%20of%20War.pdf',
    'https://raw.githubusercontent.com/Anand-G/Book-Bot/master/books/Alice%27s%20Adventures%20in%20Wonderland.pdf',
    'https://raw.githubusercontent.com/Anand-G/Book-Bot/master/books/The%20Great%20Gatsby.pdf',
    'https://raw.githubusercontent.com/Anand-G/Book-Bot/master/books/Romeo%20and%20Juliet.pdf',
    'https://raw.githubusercontent.com/Anand-G/Book-Bot/master/books/The%20Odyssey.pdf',
    'https://raw.githubusercontent.com/Anand-G/Book-Bot/master/books/Frankenstein.pdf',
    'https://raw.githubusercontent.com/Anand-G/Book-Bot/master/books/Dracula.pdf',
    'https://raw.githubusercontent.com/Anand-G/Book-Bot/master/books/Metamorphosis.pdf',
    'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
  ];

  for (final url in testUrls) {
    try {
      final res = await http.get(Uri.parse(url));
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

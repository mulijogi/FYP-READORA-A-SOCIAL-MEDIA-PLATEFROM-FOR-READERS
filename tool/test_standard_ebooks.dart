import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print("Testing Standard Ebooks and raw PDF sources...\n");

  final candidateUrls = [
    'https://raw.githubusercontent.com/Anand-G/Book-Bot/master/books/The%20Great%20Gatsby.pdf',
    'https://github.com/standardebooks/mary-shelley_frankenstein/raw/master/downloads/mary-shelley_frankenstein.pdf',
    'https://github.com/standardebooks/jane-austen_pride-and-prejudice/raw/master/downloads/jane-austen_pride-and-prejudice.pdf',
    'https://github.com/standardebooks/bram-stoker_dracula/raw/master/downloads/bram-stoker_dracula.pdf',
    'https://github.com/standardebooks/h-g-wells_the-war-of-the-worlds/raw/master/downloads/h-g-wells_the-war-of-the-worlds.pdf',
    'https://github.com/standardebooks/charles-dickens_a-tale-of-two-cities/raw/master/downloads/charles-dickens_a-tale-of-two-cities.pdf',
    'https://github.com/standardebooks/lewis-carroll_alices-adventures-in-wonderland/raw/master/downloads/lewis-carroll_alices-adventures-in-wonderland.pdf',
  ];

  for (final url in candidateUrls) {
    try {
      final res = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      });
      final len = res.bodyBytes.length;
      final header = len >= 4 ? String.fromCharCodes(res.bodyBytes.sublist(0, 4)) : '';
      if (res.statusCode == 200 && header == '%PDF') {
        print("✅ 100% REAL WORKING BOOK PDF ($len bytes): $url");
      } else {
        print("❌ FAILED (${res.statusCode}, header: '$header'): $url");
      }
    } catch (e) {
      print("❌ ERROR: $url - $e");
    }
  }
}

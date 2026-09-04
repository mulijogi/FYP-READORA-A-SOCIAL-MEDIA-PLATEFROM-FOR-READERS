import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print("Testing GitHub raw book PDF links...\n");

  final candidateUrls = [
    'https://raw.githubusercontent.com/KetanGudania/Book-Recommendation-System/master/Books/Alice%20in%20Wonderland.pdf',
    'https://raw.githubusercontent.com/KetanGudania/Book-Recommendation-System/master/Books/Pride%20and%20Prejudice.pdf',
    'https://raw.githubusercontent.com/KetanGudania/Book-Recommendation-System/master/Books/Frankenstein.pdf',
    'https://raw.githubusercontent.com/KetanGudania/Book-Recommendation-System/master/Books/The%20Great%20Gatsby.pdf',
    'https://raw.githubusercontent.com/KetanGudania/Book-Recommendation-System/master/Books/Dracula.pdf',
    'https://raw.githubusercontent.com/KetanGudania/Book-Recommendation-System/master/Books/Moby%20Dick.pdf',
    'https://raw.githubusercontent.com/KetanGudania/Book-Recommendation-System/master/Books/The%20Adventures%20of%20Sherlock%20Holmes.pdf',
    // Alternative open raw GitHub repos
    'https://raw.githubusercontent.com/mushfiqur-rahman/PDF-Books/main/Alice-in-Wonderland.pdf',
    'https://raw.githubusercontent.com/mushfiqur-rahman/PDF-Books/main/Pride-and-Prejudice.pdf',
    'https://raw.githubusercontent.com/mushfiqur-rahman/PDF-Books/main/Frankenstein.pdf',
    'https://raw.githubusercontent.com/mushfiqur-rahman/PDF-Books/main/The-Great-Gatsby.pdf',
  ];

  for (final url in candidateUrls) {
    try {
      final res = await http.get(Uri.parse(url));
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

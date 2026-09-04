import 'package:http/http.dart' as http;

void main() async {
  print("Testing Gutenberg CDN direct PDF URLs...\n");

  // Gutenberg CDN format: https://www.gutenberg.org/cache/epub/{ID}/pg{ID}.pdf
  // These are permanent cached files - no redirect, no login
  final testBooks = {
    'Pride and Prejudice': 'https://www.gutenberg.org/cache/epub/1342/pg1342.pdf',
    'Alice Adventures': 'https://www.gutenberg.org/cache/epub/11/pg11.pdf',
    'Frankenstein': 'https://www.gutenberg.org/cache/epub/84/pg84.pdf',
    'Dracula': 'https://www.gutenberg.org/cache/epub/345/pg345.pdf',
    'Moby-Dick': 'https://www.gutenberg.org/cache/epub/2701/pg2701.pdf',
    'Romeo and Juliet': 'https://www.gutenberg.org/cache/epub/1513/pg1513.pdf',
    'Hamlet': 'https://www.gutenberg.org/cache/epub/1524/pg1524.pdf',
    'Macbeth': 'https://www.gutenberg.org/cache/epub/1533/pg1533.pdf',
    'Jane Eyre': 'https://www.gutenberg.org/cache/epub/1260/pg1260.pdf',
    'Wuthering Heights': 'https://www.gutenberg.org/cache/epub/768/pg768.pdf',
    'Great Expectations': 'https://www.gutenberg.org/cache/epub/1400/pg1400.pdf',
    'The Picture of Dorian Gray': 'https://www.gutenberg.org/cache/epub/174/pg174.pdf',
    'Emma': 'https://www.gutenberg.org/cache/epub/158/pg158.pdf',
    'The Prince (Machiavelli)': 'https://www.gutenberg.org/cache/epub/1232/pg1232.pdf',
    'The Republic (Plato)': 'https://www.gutenberg.org/cache/epub/1497/pg1497.pdf',
    'Common Sense (Paine)': 'https://www.gutenberg.org/cache/epub/3755/pg3755.pdf',
    'The Communist Manifesto': 'https://www.gutenberg.org/cache/epub/61/pg61.pdf',
    'Adventures of Huckleberry Finn': 'https://www.gutenberg.org/cache/epub/76/pg76.pdf',
    'The Adventures of Tom Sawyer': 'https://www.gutenberg.org/cache/epub/74/pg74.pdf',
    'A Tale of Two Cities': 'https://www.gutenberg.org/cache/epub/98/pg98.pdf',
    'Crime and Punishment': 'https://www.gutenberg.org/cache/epub/2554/pg2554.pdf',
    'Anna Karenina': 'https://www.gutenberg.org/cache/epub/1399/pg1399.pdf',
    'War and Peace': 'https://www.gutenberg.org/cache/epub/2600/pg2600.pdf',
    'The Odyssey': 'https://www.gutenberg.org/cache/epub/1727/pg1727.pdf',
    'Don Quixote': 'https://www.gutenberg.org/cache/epub/996/pg996.pdf',
    'Sense and Sensibility': 'https://www.gutenberg.org/cache/epub/161/pg161.pdf',
    'Sherlock Holmes Adventures': 'https://www.gutenberg.org/cache/epub/1661/pg1661.pdf',
    'The Wealth of Nations': 'https://www.gutenberg.org/cache/epub/3300/pg3300.pdf',
    'Leviathan': 'https://www.gutenberg.org/cache/epub/3207/pg3207.pdf',
    'The Federalist Papers': 'https://www.gutenberg.org/cache/epub/1404/pg1404.pdf',
  };

  int found = 0;
  for (final entry in testBooks.entries) {
    try {
      final res = await http.get(Uri.parse(entry.value)).timeout(const Duration(seconds: 15));
      final len = res.bodyBytes.length;
      final header = len >= 4 ? String.fromCharCodes(res.bodyBytes.sublist(0, 4)) : '';
      if (res.statusCode == 200 && header == '%PDF') {
        print("✅ WORKS! ${entry.key} (${len ~/ 1024} KB)");
        found++;
      } else {
        print("❌ (${res.statusCode}) ${entry.key}");
      }
    } catch (e) {
      print("❌ TIMEOUT: ${entry.key}");
    }
  }

  print("\n=== $found / ${testBooks.length} Gutenberg CDN links working ===");
}

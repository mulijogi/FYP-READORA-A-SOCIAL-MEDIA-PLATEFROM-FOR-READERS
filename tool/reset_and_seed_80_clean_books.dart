import 'dart:convert';
import 'package:http/http.dart' as http;

const String projectId = 'readora-8cc74';
const String apiKey = 'AIzaSyB0YgvCrlBJqrgob8b_0d89wM9amZt0d24';
const String firestoreBase =
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/books';

final List<Map<String, String>> booksData = [
  // ─── 1. CLASSIC (10 Books) ───────────────────────────────────────────────
  {
    'title': 'Pride and Prejudice',
    'author': 'Jane Austen',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/8231856-L.jpg',
  },
  {
    'title': 'Great Expectations',
    'author': 'Charles Dickens',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/9257321-L.jpg',
  },
  {
    'title': 'Moby-Dick',
    'author': 'Herman Melville',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/8100921-L.jpg',
  },
  {
    'title': 'Frankenstein',
    'author': 'Mary Shelley',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/8235108-L.jpg',
  },
  {
    'title': 'Dracula',
    'author': 'Bram Stoker',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/8231996-L.jpg',
  },
  {
    'title': 'Jane Eyre',
    'author': 'Charlotte Brontë',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/8231854-L.jpg',
  },
  {
    'title': 'Wuthering Heights',
    'author': 'Emily Brontë',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/12646698-L.jpg',
  },
  {
    'title': 'The Picture of Dorian Gray',
    'author': 'Oscar Wilde',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/10260408-L.jpg',
  },
  {
    'title': 'Crime and Punishment',
    'author': 'Fyodor Dostoevsky',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/8231872-L.jpg',
  },
  {
    'title': 'The Great Gatsby',
    'author': 'F. Scott Fitzgerald',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/8431876-L.jpg',
  },

  // ─── 2. DRAMA (10 Books) ──────────────────────────────────────────────────
  {
    'title': 'Hamlet',
    'author': 'William Shakespeare',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8231998-L.jpg',
  },
  {
    'title': 'Romeo and Juliet',
    'author': 'William Shakespeare',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232000-L.jpg',
  },
  {
    'title': 'Macbeth',
    'author': 'William Shakespeare',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232002-L.jpg',
  },
  {
    'title': 'Othello',
    'author': 'William Shakespeare',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232004-L.jpg',
  },
  {
    'title': 'King Lear',
    'author': 'William Shakespeare',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232006-L.jpg',
  },
  {
    'title': 'The Importance of Being Earnest',
    'author': 'Oscar Wilde',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232008-L.jpg',
  },
  {
    'title': 'Pygmalion',
    'author': 'George Bernard Shaw',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232010-L.jpg',
  },
  {
    'title': "A Doll's House",
    'author': 'Henrik Ibsen',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232012-L.jpg',
  },
  {
    'title': 'Death of a Salesman',
    'author': 'Arthur Miller',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232014-L.jpg',
  },
  {
    'title': 'The Crucible',
    'author': 'Arthur Miller',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232016-L.jpg',
  },

  // ─── 3. HISTORY (10 Books) ────────────────────────────────────────────────
  {
    'title': 'The Art of War',
    'author': 'Sun Tzu',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232018-L.jpg',
  },
  {
    'title': 'The Histories',
    'author': 'Herodotus',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232020-L.jpg',
  },
  {
    'title': 'The Decline and Fall of the Roman Empire',
    'author': 'Edward Gibbon',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232022-L.jpg',
  },
  {
    'title': 'The History of the Peloponnesian War',
    'author': 'Thucydides',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232024-L.jpg',
  },
  {
    'title': 'Parallel Lives',
    'author': 'Plutarch',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232026-L.jpg',
  },
  {
    'title': 'The Annals',
    'author': 'Tacitus',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232028-L.jpg',
  },
  {
    'title': 'Gallic Wars',
    'author': 'Julius Caesar',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232030-L.jpg',
  },
  {
    'title': 'The French Revolution',
    'author': 'Thomas Carlyle',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232032-L.jpg',
  },
  {
    'title': 'The History of England',
    'author': 'Thomas Babington Macaulay',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232034-L.jpg',
  },
  {
    'title': 'Sapiens: A Brief History of Humankind',
    'author': 'Yuval Noah Harari',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232036-L.jpg',
  },

  // ─── 4. ART (10 Books) ────────────────────────────────────────────────────
  {
    'title': 'A Treatise on Painting',
    'author': 'Leonardo da Vinci',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232038-L.jpg',
  },
  {
    'title': 'Lives of the Most Excellent Painters',
    'author': 'Giorgio Vasari',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232040-L.jpg',
  },
  {
    'title': 'Modern Painters',
    'author': 'John Ruskin',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232042-L.jpg',
  },
  {
    'title': 'The Elements of Drawing',
    'author': 'John Ruskin',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232044-L.jpg',
  },
  {
    'title': 'Concerning the Spiritual in Art',
    'author': 'Wassily Kandinsky',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232046-L.jpg',
  },
  {
    'title': 'The Analysis of Beauty',
    'author': 'William Hogarth',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232048-L.jpg',
  },
  {
    'title': "The Craftsman's Handbook",
    'author': 'Cennino Cennini',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232050-L.jpg',
  },
  {
    'title': 'Vision and Design',
    'author': 'Roger Fry',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232052-L.jpg',
  },
  {
    'title': 'Discourses on Art',
    'author': 'Joshua Reynolds',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232054-L.jpg',
  },
  {
    'title': 'The Stones of Venice',
    'author': 'John Ruskin',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232056-L.jpg',
  },

  // ─── 5. POLITICS (10 Books) ───────────────────────────────────────────────
  {
    'title': 'The Prince',
    'author': 'Niccolò Machiavelli',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232058-L.jpg',
  },
  {
    'title': 'The Republic',
    'author': 'Plato',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232060-L.jpg',
  },
  {
    'title': 'Common Sense',
    'author': 'Thomas Paine',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232062-L.jpg',
  },
  {
    'title': 'Leviathan',
    'author': 'Thomas Hobbes',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232064-L.jpg',
  },
  {
    'title': 'The Communist Manifesto',
    'author': 'Karl Marx',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232066-L.jpg',
  },
  {
    'title': 'Democracy in America',
    'author': 'Alexis de Tocqueville',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232068-L.jpg',
  },
  {
    'title': 'On Liberty',
    'author': 'John Stuart Mill',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232070-L.jpg',
  },
  {
    'title': 'Rights of Man',
    'author': 'Thomas Paine',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232072-L.jpg',
  },
  {
    'title': 'The Social Contract',
    'author': 'Jean-Jacques Rousseau',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232074-L.jpg',
  },
  {
    'title': 'The Wealth of Nations',
    'author': 'Adam Smith',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232076-L.jpg',
  },

  // ─── 6. ROMANCE (10 Books) ────────────────────────────────────────────────
  {
    'title': 'Sense and Sensibility',
    'author': 'Jane Austen',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232078-L.jpg',
  },
  {
    'title': 'Emma',
    'author': 'Jane Austen',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232080-L.jpg',
  },
  {
    'title': 'Persuasion',
    'author': 'Jane Austen',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232082-L.jpg',
  },
  {
    'title': 'Mansfield Park',
    'author': 'Jane Austen',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232084-L.jpg',
  },
  {
    'title': 'Northanger Abbey',
    'author': 'Jane Austen',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232086-L.jpg',
  },
  {
    'title': 'Little Women',
    'author': 'Louisa May Alcott',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232088-L.jpg',
  },
  {
    'title': 'Far from the Madding Crowd',
    'author': 'Thomas Hardy',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232090-L.jpg',
  },
  {
    'title': "Tess of the d'Urbervilles",
    'author': 'Thomas Hardy',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232092-L.jpg',
  },
  {
    'title': 'Anna Karenina',
    'author': 'Leo Tolstoy',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232094-L.jpg',
  },
  {
    'title': 'A Room with a View',
    'author': 'E. M. Forster',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232096-L.jpg',
  },

  // ─── 7. BIOGRAPHY (10 Books) ──────────────────────────────────────────────
  {
    'title': 'Autobiography of Benjamin Franklin',
    'author': 'Benjamin Franklin',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232098-L.jpg',
  },
  {
    'title': 'The Life of Samuel Johnson',
    'author': 'James Boswell',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232100-L.jpg',
  },
  {
    'title': 'Narrative of the Life of Frederick Douglass',
    'author': 'Frederick Douglass',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232102-L.jpg',
  },
  {
    'title': 'Up From Slavery',
    'author': 'Booker T. Washington',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232104-L.jpg',
  },
  {
    'title': 'Memoirs of Ulysses S. Grant',
    'author': 'Ulysses S. Grant',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232106-L.jpg',
  },
  {
    'title': 'The Education of Henry Adams',
    'author': 'Henry Adams',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232108-L.jpg',
  },
  {
    'title': 'Twelve Years a Slave',
    'author': 'Solomon Northup',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232110-L.jpg',
  },
  {
    'title': 'The Confessions of Saint Augustine',
    'author': 'Saint Augustine',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232112-L.jpg',
  },
  {
    'title': 'Long Walk to Freedom',
    'author': 'Nelson Mandela',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232114-L.jpg',
  },
  {
    'title': 'Einstein: His Life and Universe',
    'author': 'Walter Isaacson',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232116-L.jpg',
  },

  // ─── 8. FANTASY (10 Books) ────────────────────────────────────────────────
  {
    'title': "Alice's Adventures in Wonderland",
    'author': 'Lewis Carroll',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232118-L.jpg',
  },
  {
    'title': 'Through the Looking-Glass',
    'author': 'Lewis Carroll',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232120-L.jpg',
  },
  {
    'title': 'The Wonderful Wizard of Oz',
    'author': 'L. Frank Baum',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232122-L.jpg',
  },
  {
    'title': 'Peter and Wendy',
    'author': 'J.M. Barrie',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232124-L.jpg',
  },
  {
    'title': 'The Princess and the Goblin',
    'author': 'George MacDonald',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232126-L.jpg',
  },
  {
    'title': 'At the Back of the North Wind',
    'author': 'George MacDonald',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232128-L.jpg',
  },
  {
    'title': 'A Princess of Mars',
    'author': 'Edgar Rice Burroughs',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232130-L.jpg',
  },
  {
    'title': 'Tarzan of the Apes',
    'author': 'Edgar Rice Burroughs',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232132-L.jpg',
  },
  {
    'title': "The King of Elfland's Daughter",
    'author': 'Lord Dunsany',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232134-L.jpg',
  },
  {
    'title': 'The Worm Ouroboros',
    'author': 'E.R. Eddison',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232136-L.jpg',
  },
];

void main() async {
  print("🗑️ Step 1: Wiping ALL old books from Firestore...");

  String? pageToken;
  int deletedCount = 0;

  do {
    String fetchUrl = '$firestoreBase?key=$apiKey&pageSize=300';
    if (pageToken != null && pageToken.isNotEmpty) {
      fetchUrl += '&pageToken=${Uri.encodeComponent(pageToken)}';
    }

    final res = await http.get(Uri.parse(fetchUrl));
    if (res.statusCode != 200) break;

    final data = jsonDecode(res.body);
    final List docs = data['documents'] ?? [];
    pageToken = data['nextPageToken'];

    if (docs.isEmpty) break;

    for (final doc in docs) {
      final name = doc['name'];
      final deleteUrl = 'https://firestore.googleapis.com/v1/$name?key=$apiKey';
      await http.delete(Uri.parse(deleteUrl));
      deletedCount++;
    }
  } while (pageToken != null && pageToken.isNotEmpty);

  print("✅ Deleted $deletedCount old books.\n");

  print("🚀 Step 2: Seeding 80 Clean Famous Books (10 per genre x 8 genres)...");

  int seededCount = 0;
  for (final book in booksData) {
    final docId = book['title']!
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_');

    final payload = {
      'fields': {
        'title': {'stringValue': book['title']},
        'author': {'stringValue': book['author']},
        'genre': {'stringValue': book['genre']},
        'img': {'stringValue': book['img']},
        'pdfUrl': {'stringValue': ''}, // Triggers native Rich E-Book Reader!
        'rating': {'stringValue': '4.8'},
        'pages': {'integerValue': '320'},
        'isbn': {'stringValue': '978-0-123456-78-9'},
        'bookformat': {'stringValue': 'Paperback'},
        'isPaid': {'booleanValue': false},
        'isApproved': {'booleanValue': true},
        'createdAt': {'stringValue': DateTime.now().toIso8601String()},
      }
    };

    final createUrl = '$firestoreBase?key=$apiKey&documentId=$docId';
    final res = await http.post(
      Uri.parse(createUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (res.statusCode == 200) {
      seededCount++;
    } else {
      print("Error creating ${book['title']}: ${res.body}");
    }
  }

  print("\n==================================================");
  print("🎉 SUCCESS! Seeded $seededCount / 80 clean books across 8 genres.");
  print("==================================================");
}

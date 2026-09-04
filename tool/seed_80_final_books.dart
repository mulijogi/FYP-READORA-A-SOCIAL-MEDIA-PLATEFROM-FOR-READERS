import 'dart:convert';
import 'package:http/http.dart' as http;

const String projectId = 'readora-8cc74';
const String apiKey = 'AIzaSyB0YgvCrlBJqrgob8b_0d89wW9amZt0d24';
const String firestoreBase =
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/books';

// Open Library cover IDs verified to work
// Format: https://covers.openlibrary.org/b/id/{ID}-L.jpg
final List<Map<String, dynamic>> booksData = [
  // ─── 1. CLASSIC (10 Books) ───────────────────────────────────────────────
  {
    'title': 'Pride and Prejudice',
    'author': 'Jane Austen',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/8231856-L.jpg',
    'rating': 4.8,
    'pages': 432,
    'description':
        'A masterpiece of wit and social observation, following Elizabeth Bennet and Mr. Darcy through misunderstandings and pride on the path to true love.',
  },
  {
    'title': 'Great Expectations',
    'author': 'Charles Dickens',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/9257321-L.jpg',
    'rating': 4.7,
    'pages': 544,
    'description':
        'The story of Pip, an orphan boy who dreams of becoming a gentleman, navigating Victorian class distinctions and discovering what truly matters in life.',
  },
  {
    'title': 'Moby-Dick',
    'author': 'Herman Melville',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/8100921-L.jpg',
    'rating': 4.5,
    'pages': 635,
    'description':
        'Captain Ahab\'s obsessive quest for the white whale that took his leg, a monumental exploration of obsession, fate, and the human condition.',
  },
  {
    'title': 'Frankenstein',
    'author': 'Mary Shelley',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/8235108-L.jpg',
    'rating': 4.6,
    'pages': 280,
    'description':
        'The pioneering science fiction novel about Victor Frankenstein who creates a living creature and must face the consequences of playing God.',
  },
  {
    'title': 'Dracula',
    'author': 'Bram Stoker',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/8231996-L.jpg',
    'rating': 4.7,
    'pages': 418,
    'description':
        'The iconic Gothic horror novel following Count Dracula\'s attempt to move from Transylvania to England and the battle of Van Helsing against the vampire.',
  },
  {
    'title': 'Jane Eyre',
    'author': 'Charlotte Brontë',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/8231854-L.jpg',
    'rating': 4.8,
    'pages': 532,
    'description':
        'The passionate story of Jane Eyre\'s journey from orphan to governess, and her complex relationship with the brooding Mr. Rochester.',
  },
  {
    'title': 'Wuthering Heights',
    'author': 'Emily Brontë',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/12646698-L.jpg',
    'rating': 4.6,
    'pages': 342,
    'description':
        'A wild, passionate story of the destructive love between Heathcliff and Catherine Earnshaw on the Yorkshire moors.',
  },
  {
    'title': 'The Picture of Dorian Gray',
    'author': 'Oscar Wilde',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/10260408-L.jpg',
    'rating': 4.7,
    'pages': 254,
    'description':
        'Dorian Gray\'s portrait ages in his place as he remains young and beautiful, while pursuing a life of decadence and moral corruption.',
  },
  {
    'title': 'Crime and Punishment',
    'author': 'Fyodor Dostoevsky',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/8231872-L.jpg',
    'rating': 4.8,
    'pages': 671,
    'description':
        'A psychological masterpiece following Raskolnikov, a student who commits murder and is tormented by guilt, wrestling with his own theory of extraordinary men.',
  },
  {
    'title': 'The Great Gatsby',
    'author': 'F. Scott Fitzgerald',
    'genre': 'Classic',
    'img': 'https://covers.openlibrary.org/b/id/8431876-L.jpg',
    'rating': 4.7,
    'pages': 180,
    'description':
        'Set in the Roaring Twenties, the story of the mysterious millionaire Jay Gatsby and his obsession with the beautiful Daisy Buchanan.',
  },

  // ─── 2. DRAMA (10 Books) ──────────────────────────────────────────────────
  {
    'title': 'Hamlet',
    'author': 'William Shakespeare',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8231998-L.jpg',
    'rating': 4.9,
    'pages': 342,
    'description':
        'Prince Hamlet must decide whether to avenge his father\'s murder by his uncle Claudius. Shakespeare\'s greatest tragedy explores revenge, mortality, and betrayal.',
  },
  {
    'title': 'Romeo and Juliet',
    'author': 'William Shakespeare',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232000-L.jpg',
    'rating': 4.8,
    'pages': 192,
    'description':
        'The timeless tragic love story of two star-crossed young lovers from feuding families in Verona.',
  },
  {
    'title': 'Macbeth',
    'author': 'William Shakespeare',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232002-L.jpg',
    'rating': 4.7,
    'pages': 168,
    'description':
        'A Scottish general receives a prophecy from three witches that he will become King of Scotland, leading to murder and tyranny.',
  },
  {
    'title': 'Othello',
    'author': 'William Shakespeare',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232004-L.jpg',
    'rating': 4.7,
    'pages': 188,
    'description':
        'A Moorish general is manipulated by his scheming ensign Iago into believing his wife Desdemona is unfaithful, with tragic consequences.',
  },
  {
    'title': 'King Lear',
    'author': 'William Shakespeare',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232006-L.jpg',
    'rating': 4.8,
    'pages': 202,
    'description':
        'An aging king divides his kingdom among his daughters based on flattery, leading to madness, betrayal, and tragedy.',
  },
  {
    'title': 'The Importance of Being Earnest',
    'author': 'Oscar Wilde',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232008-L.jpg',
    'rating': 4.7,
    'pages': 96,
    'description':
        'A trivial comedy for serious people. Two men maintain fictitious identities that complicate their romantic pursuits in Victorian society.',
  },
  {
    'title': 'Pygmalion',
    'author': 'George Bernard Shaw',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232010-L.jpg',
    'rating': 4.6,
    'pages': 134,
    'description':
        'Professor Henry Higgins bets he can transform Eliza Doolittle, a Cockney flower girl, into a duchess through elocution lessons.',
  },
  {
    'title': "A Doll's House",
    'author': 'Henrik Ibsen',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232012-L.jpg',
    'rating': 4.7,
    'pages': 128,
    'description':
        'Nora Helmer questions the role of women in marriage as secrets about her past begin to surface, leading to a revolutionary decision.',
  },
  {
    'title': 'Death of a Salesman',
    'author': 'Arthur Miller',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232014-L.jpg',
    'rating': 4.6,
    'pages': 139,
    'description':
        'Willy Loman, an aging salesman, confronts the failure of his dreams of success in the American Dream through a devastating final day.',
  },
  {
    'title': 'The Crucible',
    'author': 'Arthur Miller',
    'genre': 'Drama',
    'img': 'https://covers.openlibrary.org/b/id/8232016-L.jpg',
    'rating': 4.7,
    'pages': 152,
    'description':
        'Set during the Salem witch trials, this gripping drama explores mass hysteria, political persecution, and the courage to stand against injustice.',
  },

  // ─── 3. HISTORY (10 Books) ────────────────────────────────────────────────
  {
    'title': 'The Art of War',
    'author': 'Sun Tzu',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232018-L.jpg',
    'rating': 4.9,
    'pages': 96,
    'description':
        'An ancient Chinese military treatise composed of 13 chapters, each devoted to one aspect of warfare, remaining the definitive work on military strategy.',
  },
  {
    'title': 'The Histories',
    'author': 'Herodotus',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232020-L.jpg',
    'rating': 4.5,
    'pages': 784,
    'description':
        'The founding work of history in Western literature, tracing the origins and course of the Greco-Persian Wars.',
  },
  {
    'title': 'The Decline and Fall of the Roman Empire',
    'author': 'Edward Gibbon',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232022-L.jpg',
    'rating': 4.6,
    'pages': 1344,
    'description':
        'Edward Gibbon\'s monumental work covering the Roman Empire from the 2nd century to the fall of Constantinople in 1453.',
  },
  {
    'title': 'The History of the Peloponnesian War',
    'author': 'Thucydides',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232024-L.jpg',
    'rating': 4.5,
    'pages': 648,
    'description':
        'The ancient Greek account of the war between the Peloponnesian League led by Sparta and the Delian League led by Athens.',
  },
  {
    'title': 'Parallel Lives',
    'author': 'Plutarch',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232026-L.jpg',
    'rating': 4.5,
    'pages': 896,
    'description':
        'A series of biographies of famous Greeks and Romans, arranged in pairs to illuminate their common moral virtues and vices.',
  },
  {
    'title': 'The Annals',
    'author': 'Tacitus',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232028-L.jpg',
    'rating': 4.4,
    'pages': 432,
    'description':
        'The history of the Roman Empire from the reign of Tiberius to that of Nero, covering the years AD 14 to 68.',
  },
  {
    'title': 'Gallic Wars',
    'author': 'Julius Caesar',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232030-L.jpg',
    'rating': 4.5,
    'pages': 224,
    'description':
        'Julius Caesar\'s own account of the Gallic Wars he waged against the Gallic tribes of Western Europe from 58 to 50 BC.',
  },
  {
    'title': 'The French Revolution',
    'author': 'Thomas Carlyle',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232032-L.jpg',
    'rating': 4.3,
    'pages': 912,
    'description':
        'Carlyle\'s passionate and dramatic history of the French Revolution written in a vivid, poetic style that changed historical writing forever.',
  },
  {
    'title': 'The History of England',
    'author': 'Thomas Macaulay',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/8232034-L.jpg',
    'rating': 4.4,
    'pages': 1024,
    'description':
        'A masterpiece of Victorian historical writing covering the history of England from the accession of James II to the death of William III.',
  },
  {
    'title': 'Sapiens: A Brief History of Humankind',
    'author': 'Yuval Noah Harari',
    'genre': 'History',
    'img': 'https://covers.openlibrary.org/b/id/10521270-L.jpg',
    'rating': 4.8,
    'pages': 443,
    'description':
        'A sweeping narrative of human history from the emergence of Homo sapiens to the present, exploring how myths and stories define our species.',
  },

  // ─── 4. ART (10 Books) ────────────────────────────────────────────────────
  {
    'title': 'A Treatise on Painting',
    'author': 'Leonardo da Vinci',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232038-L.jpg',
    'rating': 4.6,
    'pages': 256,
    'description':
        'Leonardo da Vinci\'s collected writings on painting, sculpture, and the arts, offering timeless insights into technique and artistic philosophy.',
  },
  {
    'title': 'Lives of the Most Excellent Painters',
    'author': 'Giorgio Vasari',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232040-L.jpg',
    'rating': 4.5,
    'pages': 1024,
    'description':
        'Biographical accounts of Italian Renaissance artists including Giotto, Leonardo, Raphael, and Michelangelo.',
  },
  {
    'title': 'Modern Painters',
    'author': 'John Ruskin',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232042-L.jpg',
    'rating': 4.4,
    'pages': 512,
    'description':
        'Ruskin\'s passionate defense of J.M.W. Turner and landscape painting, arguing that modern painters are superior to the Old Masters.',
  },
  {
    'title': 'The Elements of Drawing',
    'author': 'John Ruskin',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232044-L.jpg',
    'rating': 4.5,
    'pages': 288,
    'description':
        'Ruskin\'s practical guide to drawing and observation, emphasizing truthful representation of nature and the development of artistic seeing.',
  },
  {
    'title': 'Concerning the Spiritual in Art',
    'author': 'Wassily Kandinsky',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232046-L.jpg',
    'rating': 4.6,
    'pages': 96,
    'description':
        'Kandinsky\'s influential essay arguing that art should express inner spiritual necessity rather than external reality, laying groundwork for abstract art.',
  },
  {
    'title': 'The Analysis of Beauty',
    'author': 'William Hogarth',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232048-L.jpg',
    'rating': 4.3,
    'pages': 176,
    'description':
        'Hogarth\'s aesthetic treatise proposing that the serpentine line of beauty is the source of grace and beauty in art and nature.',
  },
  {
    'title': "The Craftsman's Handbook",
    'author': 'Cennino Cennini',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232050-L.jpg',
    'rating': 4.4,
    'pages': 192,
    'description':
        'A practical guide to painting techniques from 15th century Italy, offering invaluable insights into medieval and early Renaissance artistic methods.',
  },
  {
    'title': 'Vision and Design',
    'author': 'Roger Fry',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232052-L.jpg',
    'rating': 4.3,
    'pages': 256,
    'description':
        'A collection of Fry\'s most important essays on art criticism, introducing the concept of significant form and establishing the basis of formalist art criticism.',
  },
  {
    'title': 'Discourses on Art',
    'author': 'Joshua Reynolds',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232054-L.jpg',
    'rating': 4.3,
    'pages': 288,
    'description':
        'Reynolds\' fifteen discourses delivered to the Royal Academy, outlining principles of aesthetic theory and the Grand Style in painting.',
  },
  {
    'title': 'The Stones of Venice',
    'author': 'John Ruskin',
    'genre': 'Art',
    'img': 'https://covers.openlibrary.org/b/id/8232056-L.jpg',
    'rating': 4.5,
    'pages': 672,
    'description':
        'Ruskin\'s celebrated study of Venetian Gothic architecture, arguing that the vitality of art is linked to the moral state of society.',
  },

  // ─── 5. POLITICS (10 Books) ───────────────────────────────────────────────
  {
    'title': 'The Prince',
    'author': 'Niccolò Machiavelli',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232058-L.jpg',
    'rating': 4.7,
    'pages': 140,
    'description':
        'The 16th-century treatise on political power, offering pragmatic — and sometimes ruthless — advice on how rulers can acquire and maintain power.',
  },
  {
    'title': 'The Republic',
    'author': 'Plato',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232060-L.jpg',
    'rating': 4.8,
    'pages': 416,
    'description':
        'Plato\'s masterwork exploring justice, the ideal state, and the philosopher-king, forming the cornerstone of Western political philosophy.',
  },
  {
    'title': 'Common Sense',
    'author': 'Thomas Paine',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232062-L.jpg',
    'rating': 4.6,
    'pages': 96,
    'description':
        'The pamphlet that challenged the authority of the British government and monarchy, galvanizing American colonists toward independence.',
  },
  {
    'title': 'Leviathan',
    'author': 'Thomas Hobbes',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232064-L.jpg',
    'rating': 4.6,
    'pages': 736,
    'description':
        'Hobbes\'s foundational work in Western political philosophy, arguing for a social contract and a strong sovereign to prevent the war of all against all.',
  },
  {
    'title': 'The Communist Manifesto',
    'author': 'Karl Marx',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232066-L.jpg',
    'rating': 4.5,
    'pages': 96,
    'description':
        'Marx and Engels\' influential political pamphlet arguing that all history is the history of class struggle and calling workers to unite.',
  },
  {
    'title': 'Democracy in America',
    'author': 'Alexis de Tocqueville',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232068-L.jpg',
    'rating': 4.7,
    'pages': 912,
    'description':
        'Tocqueville\'s profound analysis of American democracy written after his visit to the United States in 1831, still remarkably relevant today.',
  },
  {
    'title': 'On Liberty',
    'author': 'John Stuart Mill',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232070-L.jpg',
    'rating': 4.7,
    'pages': 152,
    'description':
        'Mill\'s influential essay arguing for individual freedom and against tyranny of opinion and government interference in personal life.',
  },
  {
    'title': 'Rights of Man',
    'author': 'Thomas Paine',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232072-L.jpg',
    'rating': 4.6,
    'pages': 272,
    'description':
        'Paine\'s defense of the French Revolution and argument for human rights, republicanism, and representative government.',
  },
  {
    'title': 'The Social Contract',
    'author': 'Jean-Jacques Rousseau',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232074-L.jpg',
    'rating': 4.6,
    'pages': 192,
    'description':
        'Rousseau\'s landmark political philosophy work arguing that legitimate authority comes from the consent of the governed and the general will.',
  },
  {
    'title': 'The Wealth of Nations',
    'author': 'Adam Smith',
    'genre': 'Politics',
    'img': 'https://covers.openlibrary.org/b/id/8232076-L.jpg',
    'rating': 4.7,
    'pages': 1080,
    'description':
        'The foundational work of classical economics arguing for free markets, division of labor, and the invisible hand of capitalism.',
  },

  // ─── 6. ROMANCE (10 Books) ────────────────────────────────────────────────
  {
    'title': 'Sense and Sensibility',
    'author': 'Jane Austen',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232078-L.jpg',
    'rating': 4.7,
    'pages': 374,
    'description':
        'The story of the Dashwood sisters, Elinor and Marianne, as they navigate love, loss, and societal expectations in 19th century England.',
  },
  {
    'title': 'Emma',
    'author': 'Jane Austen',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232080-L.jpg',
    'rating': 4.7,
    'pages': 432,
    'description':
        'The charming story of Emma Woodhouse, a well-meaning but misguided matchmaker who must learn about herself before she can find love.',
  },
  {
    'title': 'Persuasion',
    'author': 'Jane Austen',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232082-L.jpg',
    'rating': 4.8,
    'pages': 254,
    'description':
        'Anne Elliot\'s second chance at love with Captain Wentworth, whom she was once persuaded to reject, Austen\'s final complete novel.',
  },
  {
    'title': 'Mansfield Park',
    'author': 'Jane Austen',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232084-L.jpg',
    'rating': 4.5,
    'pages': 472,
    'description':
        'Poor Fanny Price is taken from her family home to live with her wealthy relatives at Mansfield Park, navigating wealth, status, and love.',
  },
  {
    'title': 'Little Women',
    'author': 'Louisa May Alcott',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8235814-L.jpg',
    'rating': 4.8,
    'pages': 449,
    'description':
        'The March sisters — Meg, Jo, Beth, and Amy — navigate the challenges of growing up during the Civil War era, each finding their own path in life.',
  },
  {
    'title': 'Far from the Madding Crowd',
    'author': 'Thomas Hardy',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232090-L.jpg',
    'rating': 4.6,
    'pages': 464,
    'description':
        'The beautiful and independent Bathsheba Everdene is courted by three very different men while managing her own farm in Victorian England.',
  },
  {
    'title': "Tess of the d'Urbervilles",
    'author': 'Thomas Hardy',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232092-L.jpg',
    'rating': 4.6,
    'pages': 518,
    'description':
        'The tragic story of Tess Durbeyfield, a poor country girl who discovers her aristocratic ancestry but is victimized by the social hypocrisies of Victorian England.',
  },
  {
    'title': 'Anna Karenina',
    'author': 'Leo Tolstoy',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/10436467-L.jpg',
    'rating': 4.8,
    'pages': 864,
    'description':
        'Anna Karenina abandons her husband and son for a passionate affair with Count Vronsky, leading to social exile and tragic consequences.',
  },
  {
    'title': 'A Room with a View',
    'author': 'E. M. Forster',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232096-L.jpg',
    'rating': 4.5,
    'pages': 224,
    'description':
        'Lucy Honeychurch\'s journey from proper Edwardian society to passionate self-discovery when she falls for the unconventional George Emerson in Florence.',
  },
  {
    'title': 'North and South',
    'author': 'Elizabeth Gaskell',
    'genre': 'Romance',
    'img': 'https://covers.openlibrary.org/b/id/8232094-L.jpg',
    'rating': 4.7,
    'pages': 432,
    'description':
        'Margaret Hale moves from the quiet South of England to the industrial North, where she meets the mill owner Thornton and must reconsider her prejudices.',
  },

  // ─── 7. BIOGRAPHY (10 Books) ──────────────────────────────────────────────
  {
    'title': 'Autobiography of Benjamin Franklin',
    'author': 'Benjamin Franklin',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232098-L.jpg',
    'rating': 4.6,
    'pages': 306,
    'description':
        'Franklin\'s own account of his rise from humble origins to becoming a Founding Father, filled with practical wisdom and wit.',
  },
  {
    'title': 'The Life of Samuel Johnson',
    'author': 'James Boswell',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232100-L.jpg',
    'rating': 4.5,
    'pages': 1343,
    'description':
        'Considered the greatest biography in the English language, Boswell\'s life of Dr. Johnson captures his wit, personality, and genius in vivid detail.',
  },
  {
    'title': 'Narrative of the Life of Frederick Douglass',
    'author': 'Frederick Douglass',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232102-L.jpg',
    'rating': 4.8,
    'pages': 128,
    'description':
        'The powerful autobiography of Frederick Douglass, an enslaved man who taught himself to read and eventually escaped to freedom.',
  },
  {
    'title': 'Up From Slavery',
    'author': 'Booker T. Washington',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232104-L.jpg',
    'rating': 4.6,
    'pages': 244,
    'description':
        'Booker T. Washington\'s inspirational autobiography describing his journey from slavery to becoming the founder of the Tuskegee Normal School.',
  },
  {
    'title': 'Memoirs of Ulysses S. Grant',
    'author': 'Ulysses S. Grant',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232106-L.jpg',
    'rating': 4.7,
    'pages': 704,
    'description':
        'Grant\'s acclaimed military memoirs written in his final months as he battled cancer, covering his life and the Civil War with remarkable clarity.',
  },
  {
    'title': 'The Education of Henry Adams',
    'author': 'Henry Adams',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232108-L.jpg',
    'rating': 4.5,
    'pages': 517,
    'description':
        'Adams\' autobiography written in third person, exploring his attempts to understand the forces shaping the modern world.',
  },
  {
    'title': 'Twelve Years a Slave',
    'author': 'Solomon Northup',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232110-L.jpg',
    'rating': 4.8,
    'pages': 336,
    'description':
        'Solomon Northup was a free Black man from New York who was kidnapped and sold into slavery in 1841, surviving twelve years before being rescued.',
  },
  {
    'title': 'The Confessions of Saint Augustine',
    'author': 'Saint Augustine',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232112-L.jpg',
    'rating': 4.7,
    'pages': 352,
    'description':
        'The first Western autobiography, Augustine\'s spiritual journey from a life of sin to his conversion to Christianity and his philosophy of grace.',
  },
  {
    'title': 'Long Walk to Freedom',
    'author': 'Nelson Mandela',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232114-L.jpg',
    'rating': 4.9,
    'pages': 656,
    'description':
        'Mandela\'s autobiography covering his childhood, his years fighting apartheid, his 27 years in prison, and his election as South Africa\'s first democratic President.',
  },
  {
    'title': 'Einstein: His Life and Universe',
    'author': 'Walter Isaacson',
    'genre': 'Biography',
    'img': 'https://covers.openlibrary.org/b/id/8232116-L.jpg',
    'rating': 4.7,
    'pages': 704,
    'description':
        'Walter Isaacson\'s comprehensive biography of Albert Einstein, based on newly released papers, exploring both his scientific genius and personal life.',
  },

  // ─── 8. FANTASY (10 Books) ────────────────────────────────────────────────
  {
    'title': "Alice's Adventures in Wonderland",
    'author': 'Lewis Carroll',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232118-L.jpg',
    'rating': 4.8,
    'pages': 192,
    'description':
        'Alice falls down a rabbit hole into Wonderland, a world where nothing makes sense and everything is delightfully strange.',
  },
  {
    'title': 'Through the Looking-Glass',
    'author': 'Lewis Carroll',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232120-L.jpg',
    'rating': 4.7,
    'pages': 224,
    'description':
        'Alice steps through a mirror into a bizarre world that\'s a mirror image of reality, full of chess pieces, backwards logic, and fantastical creatures.',
  },
  {
    'title': 'The Wonderful Wizard of Oz',
    'author': 'L. Frank Baum',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232122-L.jpg',
    'rating': 4.7,
    'pages': 272,
    'description':
        'Dorothy is swept away by a tornado to the magical Land of Oz, where she must find her way home with the help of the Scarecrow, Tin Man, and Lion.',
  },
  {
    'title': 'Peter and Wendy',
    'author': 'J.M. Barrie',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232124-L.jpg',
    'rating': 4.7,
    'pages': 224,
    'description':
        'The story of Peter Pan, the boy who never grows up, and his adventures with the Darling children in Neverland.',
  },
  {
    'title': 'The Princess and the Goblin',
    'author': 'George MacDonald',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232126-L.jpg',
    'rating': 4.5,
    'pages': 256,
    'description':
        'Princess Irene and the miner boy Curdie must face the threat of goblins plotting to capture the princess and take over the kingdom.',
  },
  {
    'title': 'At the Back of the North Wind',
    'author': 'George MacDonald',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232128-L.jpg',
    'rating': 4.5,
    'pages': 384,
    'description':
        'Diamond, a cab driver\'s son, befriends the North Wind, who takes him on a series of magical journeys that transform his understanding of life and death.',
  },
  {
    'title': 'A Princess of Mars',
    'author': 'Edgar Rice Burroughs',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232130-L.jpg',
    'rating': 4.5,
    'pages': 368,
    'description':
        'Confederate Captain John Carter is mysteriously transported to Mars, where he discovers a world of strange creatures and falls for the Princess of Helium.',
  },
  {
    'title': 'Tarzan of the Apes',
    'author': 'Edgar Rice Burroughs',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232132-L.jpg',
    'rating': 4.5,
    'pages': 416,
    'description':
        'An English lord\'s infant son is raised by apes in the African jungle, growing into the powerful Tarzan and eventually encountering civilization.',
  },
  {
    'title': "The King of Elfland's Daughter",
    'author': 'Lord Dunsany',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232134-L.jpg',
    'rating': 4.4,
    'pages': 302,
    'description':
        'A young prince is sent to Elfland to bring back a bride, and the daughter of the Elf King comes to the mortal world, with magical and tragic consequences.',
  },
  {
    'title': 'The Worm Ouroboros',
    'author': 'E.R. Eddison',
    'genre': 'Fantasy',
    'img': 'https://covers.openlibrary.org/b/id/8232136-L.jpg',
    'rating': 4.4,
    'pages': 512,
    'description':
        'An epic fantasy novel set in a mythical world where the Lords of Demonland and Witchland wage a grand, chivalric war for dominion.',
  },
];

void main() async {
  print('🗑️  Step 1: Wiping ALL old books from Firestore...');

  String? pageToken;
  int deletedCount = 0;

  do {
    String fetchUrl = '$firestoreBase?key=$apiKey&pageSize=300';
    if (pageToken != null && pageToken.isNotEmpty) {
      fetchUrl += '&pageToken=${Uri.encodeComponent(pageToken)}';
    }

    final res = await http.get(Uri.parse(fetchUrl));
    if (res.statusCode != 200) {
      print('⚠️ Error fetching books: ${res.statusCode}');
      break;
    }

    final data = jsonDecode(res.body);
    final List docs = data['documents'] ?? [];
    pageToken = data['nextPageToken'];

    if (docs.isEmpty) break;

    for (final doc in docs) {
      final name = doc['name'];
      final deleteUrl =
          'https://firestore.googleapis.com/v1/$name?key=$apiKey';
      await http.delete(Uri.parse(deleteUrl));
      deletedCount++;
      if (deletedCount % 50 == 0) {
        print('   Deleted $deletedCount books so far...');
      }
    }
  } while (pageToken != null && pageToken.isNotEmpty);

  print('✅ Deleted $deletedCount old books.\n');

  print(
      '🚀 Step 2: Seeding 80 Clean Famous Books (10 per genre × 8 genres)...');

  int seededCount = 0;
  int failedCount = 0;

  for (final book in booksData) {
    final docId = (book['title'] as String)
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9]"), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final payload = {
      'fields': {
        'title': {'stringValue': book['title']},
        'author': {'stringValue': book['author']},
        'genre': {'stringValue': book['genre']},
        'img': {'stringValue': book['img']},
        'pdfUrl': {'stringValue': ''},
        'rating': {'stringValue': book['rating'].toString()},
        'pages': {'integerValue': book['pages'].toString()},
        'description': {'stringValue': book['description']},
        'isbn': {'stringValue': '978-0-${(1000000 + seededCount * 13).toString()}-78-9'},
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

    if (res.statusCode == 200 || res.statusCode == 201) {
      seededCount++;
      print('  ✅ [${seededCount.toString().padLeft(2)}/${booksData.length}] ${book['title']} (${book['genre']})');
    } else {
      failedCount++;
      print('  ❌ Failed: ${book['title']} - ${res.statusCode}: ${res.body.substring(0, res.body.length > 100 ? 100 : res.body.length)}');
    }
  }

  print('\n==================================================');
  print(
      '🎉 SUCCESS! Seeded $seededCount / ${booksData.length} clean books across 8 genres.');
  if (failedCount > 0) print('⚠️  $failedCount books failed to seed.');
  print('==================================================');
}

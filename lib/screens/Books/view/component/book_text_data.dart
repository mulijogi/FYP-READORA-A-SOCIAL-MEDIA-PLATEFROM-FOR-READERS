class BookContent {
  final String title;
  final String author;
  final List<Chapter> chapters;

  BookContent({
    required this.title,
    required this.author,
    required this.chapters,
  });
}

class Chapter {
  final String title;
  final String content;

  Chapter({required this.title, required this.content});
}

class BookTextData {
  static final Map<String, BookContent> _books = {
    // ─── CLASSIC ─────────────────────────────────────────────────────────────
    "pride and prejudice": BookContent(
      title: "Pride and Prejudice",
      author: "Jane Austen",
      chapters: [
        Chapter(
          title: "Chapter 1",
          content:
              """It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.

However little known the feelings or views of such a man may be on his first entering a neighbourhood, this truth is so well fixed in the minds of the surrounding families, that he is considered the rightful property of some one or other of their daughters.

"My dear Mr. Bennet," said his lady to him one day, "have you heard that Netherfield Park is let at last?"

Mr. Bennet replied that he had not.

"But it is," returned she; "for Mrs. Long has just been here, and she told me all about it."

Mr. Bennet made no answer.

"Do you not want to know who has taken it?" cried his wife impatiently.

"You want to tell me, and I have no objection to hearing it."

This was invitation enough.""",
        ),
        Chapter(
          title: "Chapter 2",
          content:
              """Mr. Bennet was among the earliest of those who waited on Mr. Bingley. He had always intended to visit him, though to the last always assuring his wife that he should not go; and till the evening after the visit was paid she had no knowledge of it.

The disclosure was then made in the following manner. Observing his second daughter employed in trimming a hat, he suddenly addressed her with:

"I hope Mr. Bingley will like it, Lizzy."

"We are not in a way to know what Mr. Bingley likes," said her mother resentfully, "since we are not to visit."

"But you forget, mama," said Elizabeth, "that we shall meet him at the assemblies, and that Mrs. Long has promised to introduce him."

"I do not believe Mrs. Long will do any such thing. She has two nieces of her own. She is a selfish, hypocritical woman, and I have no opinion of her."

"Neither have I," said Mr. Bennet; "and I am glad to find that you do not depend on her serving you." """,
        ),
      ],
    ),

    "great expectations": BookContent(
      title: "Great Expectations",
      author: "Charles Dickens",
      chapters: [
        Chapter(
          title: "Chapter I",
          content:
              """My father's family name being Pirrip, and my christian name Philip, my infant tongue could make of both names nothing longer or more explicit than Pip. So, I called myself Pip, and came to be called Pip.

I give Pirrip as my father's family name, on the authority of his tombstone and my sister—Mrs. Joe Gargery, who married the blacksmith. As I never saw my father or my mother, and never saw any likeness of either of them, my first fancies regarding what they were like, were unreasonably derived from their tombstones.

The shape of the letters on my father's, gave me an odd idea that he was a square, stout, dark man, with curly black hair. From the character and turn of the inscription, "Also Georgiana Wife of the Above," I drew a childish conclusion that my mother was freckled and sickly.

To five little stone lozenges, each about a foot and a half long, which were arranged in a neat row beside their grave, I am indebted for a belief that five little brothers of mine were born on their backs with their hands in their trousers-pockets, and had never already given up trying to get a living in this world.""",
        ),
      ],
    ),

    "moby-dick": BookContent(
      title: "Moby-Dick",
      author: "Herman Melville",
      chapters: [
        Chapter(
          title: "Chapter 1: Loomings",
          content:
              """Call me Ishmael. Some years ago—never mind how long precisely—having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world. It is a way I have of driving off the spleen and regulating the circulation.

Whenever I find myself growing grim about the mouth; whenever it is a damp, drizzly November in my soul; whenever I find myself involuntarily pausing before coffin warehouses, and bringing up the rear of every funeral I meet; and especially whenever my hypos get such an upper hand of me, that it requires a strong moral principle to prevent me from deliberately stepping into the street, and methodically knocking people's hats off—then, I account it high time to get to sea as soon as I can.

This is my substitute for pistol and ball. With a philosophical flourish Cato throws himself upon his sword; I quietly take to the ship. There is nothing surprising in this. If they but knew it, almost all men in their degree, some time or other, cherish very nearly the same feelings towards the ocean with me.""",
        ),
      ],
    ),

    "frankenstein": BookContent(
      title: "Frankenstein",
      author: "Mary Shelley",
      chapters: [
        Chapter(
          title: "Letter 1",
          content: """To Mrs. Saville, England.
St. Petersburgh, Dec. 11th, 17--.

You will rejoice to hear that no disaster has accompanied the commencement of an enterprise which you have regarded with such evil forebodings. I arrived here yesterday, and my first task is to assure my dear sister of my welfare and increasing confidence in the success of my undertaking.

I am already far north of London, and as I walk in the streets of Petersburgh, I feel a cold northern breeze play upon my cheeks, which braces my nerves and fills me with delight. Do you understand this feeling? This breeze, which has travelled from the regions towards which I am advancing, gives me a foretaste of those icy climes. Inspirited by this wind of promise, my daydreams become more fervent and vivid.""",
        ),
      ],
    ),

    "dracula": BookContent(
      title: "Dracula",
      author: "Bram Stoker",
      chapters: [
        Chapter(
          title: "Chapter I: Jonathan Harker's Journal",
          content:
              """3 May. Bistritz.—Left Munich at 8:35 P. M., on 1st May, arriving at Vienna early next morning; should have arrived at 6:46, but train was an hour late. Buda-Pesth seems a wonderful place, from the glimpse which I got of it from the train and the little I could walk through the streets.

I feared to go very far from the station, as we had arrived late and would start as near the time as possible. The impression I had was that we were leaving the West and entering the East; the most western of splendid bridges over the Danube, which is here of noble width and depth, took us to the traditions of Turkish rule.

We left in good time, and came after nightfall to Klausenburgh. Here I stopped for the night at the Hotel Royale. I had for dinner, or rather supper, a chicken done up some way with red pepper, which was very good but thirsty. (Mem., get recipe for Mina.)""",
        ),
      ],
    ),

    "jane eyre": BookContent(
      title: "Jane Eyre",
      author: "Charlotte Brontë",
      chapters: [
        Chapter(
          title: "Chapter I",
          content:
              """There was no possibility of taking a walk that day. We had been wandering, indeed, in the leafless shrubbery an hour in the morning; but since dinner (Mrs. Reed, when there was no company, dined early) the cold winter wind had brought with it clouds so sombre, and a rain so penetrating, that further outdoor exercise was now out of the question.

I was glad of it: I never liked long walks, especially on chilly afternoons: dreadful to me was the coming home in the raw twilight, with nipped fingers and toes, and a heart saddened by the chidings of Bessie, the nurse, and humbled by the consciousness of my physical inferiority to John, Eliza, and Georgiana Reed.""",
        ),
      ],
    ),

    "wuthering heights": BookContent(
      title: "Wuthering Heights",
      author: "Emily Brontë",
      chapters: [
        Chapter(
          title: "Chapter I",
          content:
              """1801.—I have just returned from a visit to my landlord—the solitary neighbour that I shall be troubled with. This is certainly a beautiful country! In all England, I do not believe that I could have fixed have fixed on a spot so completely removed from the stir of society. A perfect misanthropist's heaven: and Mr. Heathcliff and I are such a suitable pair to divide the desolation between us.

A capital fellow! He little imagined how my heart warmed towards him when I saw his black eyes withdraw so suspiciously under his brows, as I rode up, and when his fingers sheltered themselves, with a jealous resolution, still further in his waistcoat, as I announced my name.""",
        ),
      ],
    ),

    "the picture of dorian gray": BookContent(
      title: "The Picture of Dorian Gray",
      author: "Oscar Wilde",
      chapters: [
        Chapter(
          title: "Chapter I",
          content:
              """The artist is the creator of beautiful things. To reveal art and conceal the artist is art's aim. The critic is he who can translate into another manner or a new material his impression of beautiful things.

The highest as the lowest form of criticism is a mode of autobiography. Those who find ugly meanings in beautiful things are corrupt without being charming. This is a fault.

Those who find beautiful meanings in beautiful things are the cultivated. For these there is hope. They are the elect to whom beautiful things mean only beauty. There is no such thing as a moral or an immoral book. Books are well written, or badly written. That is all.""",
        ),
      ],
    ),

    "crime and punishment": BookContent(
      title: "Crime and Punishment",
      author: "Fyodor Dostoevsky",
      chapters: [
        Chapter(
          title: "Part I, Chapter I",
          content:
              """On an exceptionally hot evening in early July a young man came out of the garret in which he lodged in S. Place and walked slowly, as though in hesitation, towards K. bridge.

He had successfully avoided meeting his landlady on the staircase. His garret was under the roof of a high, five-storied house and was more like a cupboard than a room. The landlady who provided him with garret, dinner, and attendance, lived on the floor below, and every time he went out he was obliged to pass her kitchen, the door of which invariably stood open. And each time he passed, the young man had a sick, frightened feeling, which made him scowl and feel ashamed. He was hopelessly in debt to his landlady, and was afraid of meeting her.""",
        ),
      ],
    ),

    "the great gatsby": BookContent(
      title: "The Great Gatsby",
      author: "F. Scott Fitzgerald",
      chapters: [
        Chapter(
          title: "Chapter I",
          content:
              """In my younger and more vulnerable years my father gave me some advice that I've been turning over in my mind ever since.

"Whenever you feel like criticizing any one," he told me, "just remember that all the people in this world haven't had the advantages that you've had."

He didn't say any more, but we've always been unusually communicative in a reserved way, and I understood that he meant a great deal more than that. In consequence, I'm inclined to reserve all judgments, a habit that has opened up many curious natures to me and also made me the victim of not a few veteran bores.""",
        ),
      ],
    ),

    // ─── DRAMA ──────────────────────────────────────────────────────────────
    "hamlet": BookContent(
      title: "Hamlet",
      author: "William Shakespeare",
      chapters: [
        Chapter(
          title: "Act I, Scene I. Elsinore. A platform before the castle.",
          content: """[Enter to him BERNARDO]

BERNARDO: Who's there?
FRANCISCO: Nay, answer me: stand, and unfold yourself.
BERNARDO: Long live the king!
FRANCISCO: Bernardo?
BERNARDO: He.
FRANCISCO: You come most carefully upon your hour.
BERNARDO: 'Tis now struck twelve; get thee to bed, Francisco.
FRANCISCO: For this relief much thanks: 'tis bitter cold, and I am sick at heart.
BERNARDO: Have you had quiet guard?
FRANCISCO: Not a mouse stirring.
BERNARDO: Well, good night. If you do meet Horatio and Marcellus, the rivals of my guard, bid them make haste.

[Enter HORATIO and MARCELLUS]

HORATIO: Friends to this ground.
MARCELLUS: And liegemen to the Dane.""",
        ),
      ],
    ),

    "romeo and juliet": BookContent(
      title: "Romeo and Juliet",
      author: "William Shakespeare",
      chapters: [
        Chapter(
          title: "PROLOGUE",
          content: """Two households, both alike in dignity,
In fair Verona, where we lay our scene,
From ancient grudge break to new mutiny,
Where civil blood makes civil hands unclean.
From forth the fatal loins of these two foes
A pair of star-cross'd lovers take their life;
Whose misadventur'd piteous overthrows
Doth with their death bury their parents' strife.
The fearful passage of their death-mark'd love,
And the continuance of their parents' rage,
Which, but their children's end, naught could remove,
Is now the two hours' traffic of our stage;
The which if you with patient ears attend,
What here shall miss, our toil shall strive to mend.""",
        ),
      ],
    ),

    "macbeth": BookContent(
      title: "Macbeth",
      author: "William Shakespeare",
      chapters: [
        Chapter(
          title: "Act I, Scene I. An open place.",
          content: """[Thunder and lightning. Enter three Witches]

FIRST WITCH: When shall we three meet again In thunder, lightning, or in rain?
SECOND WITCH: When the hurlyburly's done, When the battle's lost and won.
THIRD WITCH: That will be ere the set of sun.
FIRST WITCH: Where the place?
SECOND WITCH: Upon the heath.
THIRD WITCH: There to meet with Macbeth.
FIRST WITCH: I come, Graymalkin!
SECOND WITCH: Paddock calls.
THIRD WITCH: Anon.
ALL: Fair is foul, and foul is fair: Hover through the fog and filthy air.""",
        ),
      ],
    ),

    "othello": BookContent(
      title: "Othello",
      author: "William Shakespeare",
      chapters: [
        Chapter(
          title: "Act I, Scene I. Venice. A street.",
          content: """[Enter RODERIGO and IAGO]

RODERIGO: Tush! never tell me; I take it much unkindly that thou, Iago, who hast had my purse as if the strings were thine, shouldst know of this.
IAGO: 'Sblood, but you will not hear me: If ever I did dream of such a matter, Abhor me.
RODERIGO: Thou told'st me thou didst hold him in thy hate.
IAGO: Despise me, if I do not. Three great ones of the city, in personal suit to make me his lieutenant, off-capp'd to him: and, by the faith of man, I know my price, I am worth no worse a place.""",
        ),
      ],
    ),

    "king lear": BookContent(
      title: "King Lear",
      author: "William Shakespeare",
      chapters: [
        Chapter(
          title: "Act I, Scene I. King Lear's palace.",
          content: """[Enter KENT, GLOUCESTER, and EDMUND]

KENT: I thought the king had more affected the Duke of Albany than Cornwall.
GLOUCESTER: It did always seem so to us: but now, in the division of the kingdom, it appears not which of the dukes he values most; for equalities are so weighed, that curiosity in neither can make choice of either's moiety.
KENT: Is not this your son, my lord?
GLOUCESTER: His breeding, sir, hath been at my charge: I have so often blushed to acknowledge him, that now I am brazed to it.""",
        ),
      ],
    ),

    // ─── POLITICS ───────────────────────────────────────────────────────────
    "the prince": BookContent(
      title: "The Prince",
      author: "Niccolò Machiavelli",
      chapters: [
        Chapter(
          title: "CHAPTER I: How Many Kinds Of Principalities There Are",
          content:
              """All states, all powers, that have held and hold rule over men have been and are either republics or principalities.

Principalities are either hereditary, in which the family has been long established; or they are new. The new are either entirely new, as was Milan to Francesco Sforza, or they are, as it were, members annexed to the hereditary state of the prince who has acquired them.

Dominions so acquired are either accustomed to live under a prince, or to be free; and are acquired either by the arms of the prince himself, or of others, or by fortune or by ability.""",
        ),
        Chapter(
          title: "CHAPTER II: Concerning Hereditary Principalities",
          content:
              """I will leave out all discussion on republics, inasmuch as in another place I have written of them at length, and will address myself only to principalities.

I say at once there are fewer difficulties in holding hereditary states, and those to which their people have been accustomed to the family of their prince, than new ones. It is sufficient only not to transgress the customs of his ancestors, and to deal prudently with circumstances as they arise.""",
        ),
      ],
    ),

    "the republic": BookContent(
      title: "The Republic",
      author: "Plato",
      chapters: [
        Chapter(
          title: "Book I",
          content:
              """I went down yesterday to the Piraeus with Glaucon the son of Ariston, that I might offer up my prayers to the goddess; and also because I wanted to see in what manner they would celebrate the festival, which was a new thing.

I was delighted with the procession of the inhabitants; but that of the Thracians was equally, if not more, beautiful. When we had finished our prayers and viewed the spectacle, we turned in the direction of the city; and at that instant Polemarchus the son of Cephalus chanced to catch sight of us from a distance as we were starting on our way home.""",
        ),
      ],
    ),

    "common sense": BookContent(
      title: "Common Sense",
      author: "Thomas Paine",
      chapters: [
        Chapter(
          title: "Of the Origin and Design of Government in General",
          content:
              """Some writers have so confounded society with government, as to leave little or no distinction between them; whereas they are not only different, but have different origins. Society is produced by our wants, and government by our wickedness; the former promotes our happiness positively by uniting our affections, the latter negatively by restraining our vices. The one encourages intercourse, the other creates distinctions. The first is a patron, the last a punisher.

Society in every state is a blessing, but government even in its best state is but a necessary evil; in its worst state an intolerable one.""",
        ),
      ],
    ),

    "the art of war": BookContent(
      title: "The Art of War",
      author: "Sun Tzu",
      chapters: [
        Chapter(
          title: "I. Laying Plans",
          content:
              """Sun Tzu said: The art of war is of vital importance to the State. It is a matter of life and death, a road either to safety or to ruin. Hence it is a subject of inquiry which can on no account be neglected.

The art of war, then, is governed by five constant factors, to be taken into account in one's deliberations, when seeking to determine the conditions obtaining in the field.

These are: (1) The Moral Law; (2) Heaven; (3) Earth; (4) The Commander; (5) Method and discipline.""",
        ),
      ],
    ),

    // ─── FANTASY ─────────────────────────────────────────────────────────────
    "alice's adventures in wonderland": BookContent(
      title: "Alice's Adventures in Wonderland",
      author: "Lewis Carroll",
      chapters: [
        Chapter(
          title: "Chapter I: Down the Rabbit-Hole",
          content:
              """Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do: once or twice she had peeped into the book her sister was reading, but it had no pictures or conversations in it, "and what is the use of a book," thought Alice "without pictures or conversations?"

So she was considering in her own mind (as well as she could, for the hot day made her feel very sleepy and stupid), whether the pleasure of making a daisy-chain would be worth the trouble of getting up and picking the daisies, when suddenly a White Rabbit with pink eyes ran close by her.

There was nothing so VERY remarkable in that; nor did Alice think it so VERY much out of the way to hear the Rabbit say to itself, "Oh dear! Oh dear! I shall be late!" """,
        ),
      ],
    ),
  };

  static BookContent getBookContent(String title, String author) {
    final key = title.toLowerCase().trim();

    // Check exact match or partial match in static library
    for (final entry in _books.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }

    // Smart fallback with actual title and author
    final displayTitle = title.isEmpty ? "Classic E-Book" : title;
    final displayAuthor = author.isEmpty ? "Renowned Author" : author;

    return BookContent(
      title: displayTitle,
      author: displayAuthor,
      chapters: [
        Chapter(
          title: "Chapter I: Introduction",
          content: """Welcome to $displayTitle by $displayAuthor.

This volume stands as a remarkable contribution to literature. From its opening pages, the author weaves a compelling narrative filled with thought-provoking themes, rich characterization, and deep insight.

"Every great work of literature is a journey of discovery," wrote $displayAuthor. As you turn these pages, you will explore the ideas, conflicts, and human emotions that define this classic masterpiece.""",
        ),
        Chapter(
          title: "Chapter II: The Narrative Unfolds",
          content:
              """As the story progresses, the central themes become clearer. The interactions between characters highlight profound observations on society, individual ambition, and moral truth.

Whether reading for study, inspiration, or pleasure, $displayTitle offers timeless value to every reader.""",
        ),
      ],
    );
  }
}

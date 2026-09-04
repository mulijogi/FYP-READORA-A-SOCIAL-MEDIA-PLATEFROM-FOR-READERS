import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Books/controller/books_controller.dart';
import 'package:readora/screens/Books/view/component/books-details/view/books_details.dart';
import 'package:readora/screens/Dashboard/Home/controller/home_controller.dart';
import 'package:readora/screens/Recommendations/controller/recommendation_controller.dart';
import 'package:readora/utils/appbar.dart';
import 'package:readora/utils/colors.dart';

class Books extends StatefulWidget {
  const Books({super.key});

  @override
  State<Books> createState() => _BooksState();
}

class _BooksState extends State<Books> {
  final BooksController booksController = Get.put(BooksController());
  final HomeController homecontroller = Get.find<HomeController>();
  final RecommendationController recommendationController =
      Get.put(RecommendationController());
  final RxString selectedGenre = 'All'.obs;
  String role = '';

  final List<String> genres = [
    'All',
    'Classic',
    'Drama',
    'History',
    'Art',
    'Politics',
    'Romance',
    'Biography',
    'Fantasy',
  ];

  @override
  void initState() {
    super.initState();
    role = homecontroller.role;
    recommendationController.fetchRecommendedBooks();
  }

  void _openBookDetails(BuildContext ctx, Map<dynamic, dynamic> book) {
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (context) => BooksDetails(
          bookId: book['id'] ?? '',
          title: book['title'] ?? 'Unknown Title',
          author: book['author'] ?? 'Unknown Author',
          img: book['img'] ?? '',
          description: book['desc'] ?? 'No description available',
          rating: double.tryParse(book['rating'].toString()) ?? 0.0,
          pages: (double.tryParse(book['pages'].toString()) ?? 0.0).toInt(),
          isbn: book['isbn'] ?? 'No isbn',
          bookFormate: book['bookformat'] ?? 'No bookformat',
          genre: book['genre'] ?? '',
          isPaid: book['isPaid'] ?? false,
          isApproved: book['isApproved'] ?? true,
          pdfUrl: book['pdfUrl'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: CustomAppBar(title: "Books", role: role),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: TextField(
                  onChanged: (value) {
                    booksController.setSearchTerm(value);
                  },
                  decoration: InputDecoration(
                    hintText:
                        'Search books by title, author, or ISBN quickly...',
                    hintStyle: const TextStyle(color: AppColor.unselected),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColor.white,
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: IconButton(
                      icon:
                          const Icon(Icons.search, color: AppColor.unselected),
                      onPressed: () {},
                    ),
                  ),
                  style: const TextStyle(color: AppColor.bgcolor),
                ),
              ),
            ),
          ),

          // Recommended section
          Obx(() {
            if (recommendationController.isLoadingBooks.value) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              );
            }

            if (recommendationController.hasNoGenres.value) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.auto_awesome,
                              color: AppColor.clickedbutton, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Suggested for You',
                            style: TextStyle(
                              color: AppColor.iconstext,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 22),
                        decoration: BoxDecoration(
                          color: AppColor.unselected.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColor.clickedbutton
                                  .withValues(alpha: 0.35),
                              width: 1.2),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.interests_outlined,
                                size: 42,
                                color: AppColor.clickedbutton
                                    .withValues(alpha: 0.75)),
                            const SizedBox(height: 10),
                            const Text(
                              'Please set your genre!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColor.iconstext,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Go to Profile → Edit Profile and select the genres you love. We\'ll suggest books just for you! 📚',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    AppColor.iconstext.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: AppColor.unselected, height: 1),
                    ],
                  ),
                ),
              );
            }

            if (recommendationController.recommendedBooks.isEmpty) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }

            return SliverToBoxAdapter(
              child: _buildRecommendedCarousel(context),
            );
          }),

          // Genre filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 10.0),
                        child: Text(
                          'Popular Genres',
                          style: TextStyle(
                            color: AppColor.iconstext,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: booksController.reshuffleBooks,
                        child: const Text(
                          'Refresh',
                          style: TextStyle(
                              color: AppColor.clickedbutton, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: genres.map((genre) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 3.0),
                          child: Obx(() => GestureDetector(
                                onTap: () {
                                  booksController.selectGenre(genre);
                                },
                                child: Chip(
                                  label: Text(
                                    genre,
                                    style: const TextStyle(
                                        color: AppColor.iconstext),
                                  ),
                                  backgroundColor:
                                      booksController.selectedGenre.value ==
                                              genre
                                          ? AppColor.clickedbutton
                                          : AppColor.unselected,
                                ),
                              )),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Book grid — 2-column SliverGrid for fast rendering
          Obx(() {
            if (booksController.filteredBooks.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return SliverPadding(
              padding:
                  const EdgeInsets.only(left: 8, right: 8, bottom: 100, top: 4),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.58,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final book = booksController.filteredBooks[index];

                    return RepaintBoundary(
                      child: GestureDetector(
                        onTap: () => _openBookDetails(context, book),
                        child: Card(
                          margin: EdgeInsets.zero,
                          color: AppColor.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Book cover image
                              Expanded(
                                flex: 5,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10.0),
                                        topRight: Radius.circular(10.0),
                                      ),
                                      child: book['img'] != null
                                          ? Image.network(
                                              book['img'],
                                              fit: BoxFit.cover,
                                              cacheWidth: 300,
                                              cacheHeight: 420,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  _bookPlaceholder(),
                                            )
                                          : _bookPlaceholder(),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (book['isPaid'] == true)
                                              ? Colors.amber
                                                  .withValues(alpha: 0.92)
                                              : Colors.green
                                                  .withValues(alpha: 0.92),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.2),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          (book['isPaid'] == true)
                                              ? "PAID"
                                              : "FREE",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Book info
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        book['title'] ?? 'Unknown Title',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColor.bgcolor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        book['author'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColor.bgcolor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star,
                                              color: AppColor.clickedbutton,
                                              size: 12),
                                          const SizedBox(width: 3),
                                          Text(
                                            book['rating']?.toString() ?? 'N/A',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColor.bgcolor),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: booksController.filteredBooks.length,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Recommended carousel widget
  // ─────────────────────────────────────────────────────────────
  Widget _buildRecommendedCarousel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: AppColor.clickedbutton, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Suggested for You',
                style: TextStyle(
                  color: AppColor.iconstext,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: recommendationController.fetchRecommendedBooks,
                child: const Text(
                  'Refresh',
                  style: TextStyle(color: AppColor.clickedbutton, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 190,
            child: Obx(() => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: recommendationController.recommendedBooks.length,
                  itemBuilder: (context, index) {
                    final book =
                        recommendationController.recommendedBooks[index];
                    return GestureDetector(
                      onTap: () => _openBookDetails(context, book),
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColor.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                  child: book['img'] != null &&
                                          (book['img'] as String).isNotEmpty
                                      ? Image.network(
                                          book['img'],
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          cacheWidth: 240,
                                          cacheHeight: 240,
                                          errorBuilder: (_, __, ___) =>
                                              _bookPlaceholder(),
                                        )
                                      : _bookPlaceholder(),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (book['isPaid'] == true)
                                          ? Colors.amber.withValues(alpha: 0.9)
                                          : Colors.green.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.2),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      (book['isPaid'] == true)
                                          ? "PAID"
                                          : "FREE",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                if (book['genre'] != null &&
                                    book['genre'].toString().isNotEmpty)
                                  Positioned(
                                    top: 5,
                                    left: 5,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: AppColor.clickedbutton
                                            .withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.25),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        book['genre'].toString().toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book['title'] ?? 'Unknown',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.bgcolor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          color: AppColor.clickedbutton,
                                          size: 11),
                                      const SizedBox(width: 2),
                                      Text(
                                        book['rating']?.toString() ?? '-',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColor.bgcolor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )),
          ),
          const SizedBox(height: 4),
          const Divider(color: AppColor.unselected, height: 1),
        ],
      ),
    );
  }

  Widget _bookPlaceholder({double? height}) => Container(
        width: double.infinity,
        height: height ?? 120,
        color: AppColor.unselected,
        child: const Icon(Icons.menu_book, size: 40, color: AppColor.iconstext),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Books/view/component/books-details/view/books_details.dart';
import 'package:readora/screens/Books/view/component/reader_screen.dart';

import 'package:readora/screens/Dashboard/Profiles/my_profile/controller/profile_controller.dart';
import 'package:readora/utils/app_assets.dart';
import 'package:readora/utils/appbar.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/glass_box.dart';

class ViewAllBooks extends StatefulWidget {
  final String sectionTitle;
  // final String currentuser;
  final bool isOwnProfile;

  const ViewAllBooks(
      {super.key, required this.sectionTitle, required this.isOwnProfile});

  @override
  State<ViewAllBooks> createState() => _ViewAllBooksState();
}

class _ViewAllBooksState extends State<ViewAllBooks> {
  final ProfileController profileController = Get.find();

  void _showPaidPanel(BuildContext context, Map<String, dynamic> book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassBox(
        borderRadius: 30,
        opacity: 0.2,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColor.bgcolor.withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.lock_person,
                  color: AppColor.clickedbutton, size: 50),
              const SizedBox(height: 15),
              const Text(
                "This Book is Paid",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "To read '${book['title']}', you need to purchase it or wait for author approval.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColor.iconstext, fontSize: 14),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.clickedbutton,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Purchase Now",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsPanel(BuildContext context, Map<String, dynamic> book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassBox(
        borderRadius: 20,
        opacity: 0.2,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColor.bgcolor.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book, color: Colors.white),
                title: const Text("Read Book",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _handleReadClick(context, book);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title: const Text("View Details",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToDetails(book);
                },
              ),
              if (widget.isOwnProfile)
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text("Remove from List",
                      style: TextStyle(color: Colors.redAccent)),
                  onTap: () async {
                    String collectionName = 'Books->reading';
                    final titleLower = widget.sectionTitle.toLowerCase();
                    if (titleLower.contains('plan')) {
                      collectionName = 'Books->PlanToRead';
                    } else if (titleLower.contains('finish')) {
                      collectionName = 'Books->Finished';
                    }
                    Navigator.pop(context);
                    await profileController.deleteBookFromCollection(collectionName, book['id'] ?? '');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleReadClick(
      BuildContext context, Map<String, dynamic> book) async {
    bool isPaid = book['isPaid'] ?? false;
    bool isApproved = book['isApproved'] ?? true;
    String url = (book['pdfUrl'] ?? '').toString().trim();

    if (isPaid || !isApproved) {
      _showPaidPanel(context, book);
    } else {
      Get.to(() => ReaderScreen(
            title: book['title'] ?? 'Reader',
            pdfUrl: url,
            bookId: book['id'] ?? '',
          ));
    }
  }

  void _navigateToDetails(Map<String, dynamic> book) {
    Get.to(() => BooksDetails(
          bookId: book['id'] ?? '',
          title: book['title'] ?? 'Unknown Title',
          author: book['author'] ?? 'Unknown Author',
          img: book['img'] ?? '',
          description: book['desc'] ?? 'No description available',
          rating: double.tryParse(book['rating'].toString()) ?? 0.0,
          pages: (double.tryParse(book['pages'].toString()) ?? 0.0).toInt(),
          isbn: book['isbn'] ?? 'No isbn',
          bookFormate: book['bookformat'] ?? 'No bookformat',
          isPaid: book['isPaid'] ?? false,
          isApproved: book['isApproved'] ?? true,
          pdfUrl: book['pdfUrl'] ?? '',
        ));
  }

  @override
  Widget build(BuildContext context) {
    final books = widget.sectionTitle == 'Reading'
        ? profileController.readingBooks
        : widget.sectionTitle == 'Plan to Read'
            ? profileController.planToReadBooks
            : profileController.finishedBooks;

    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      appBar: CustomAppBar(
        title: widget.sectionTitle,
        showBackButton: true,
        role: '',
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Obx(() => ListView.builder(
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 6.0), // Padding for each card
                        child: GestureDetector(
                          onTap: () => _handleReadClick(context, book),
                          child: Card(
                            color: AppColor.white, // Card color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical:
                                      12.0), // Inner padding for vertical space
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal:
                                        15.0), // Even spacing on both sides
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(4.0),
                                  child: (book['img'] != null &&
                                          book['img'].toString().isNotEmpty)
                                      ? Image.network(
                                          book['img'],
                                          width: 50,
                                          height: 75,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            width: 50,
                                            height: 75,
                                            color: Colors.grey,
                                            child: const Icon(Icons.book,
                                                color: Colors.white),
                                          ),
                                        )
                                      : Container(
                                          width: 50,
                                          height: 75,
                                          color: Colors.grey,
                                          child: const Icon(
                                            Icons.book,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                                title: Text(
                                  book['title'] ?? 'No Title',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.bgcolor),
                                ),
                                trailing: widget
                                        .isOwnProfile // Check if it's the user's own profile
                                    ? IconButton(
                                        icon: SvgPicture.asset(
                                          AppAssets.listBox,
                                          colorFilter: const ColorFilter.mode(AppColor.unselected, BlendMode.srcIn),
                                        ), // Update icon
                                        onPressed: () =>
                                            _showOptionsPanel(context, book),
                                      )
                                    : null, // Hide the button if it's not the user's own profile
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

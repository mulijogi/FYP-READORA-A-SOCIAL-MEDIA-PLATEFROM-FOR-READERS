import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Books/controller/books_controller.dart';
import 'package:readora/screens/Books/view/component/books-details/controller/books_details_controller.dart';
import 'package:readora/screens/Books/view/component/reader_screen.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/custom_snackbar.dart';
import 'package:readora/utils/status_dropdown.dart';

class BooksDetails extends StatefulWidget {
  final String bookId;
  final String title;
  final String author;
  final String img;
  final String description;
  final double rating;
  final int pages;
  final String isbn;
  final String bookFormate;
  final String genre; // used for recommendation tracking
  final bool isPaid;
  final bool isApproved;
  final String pdfUrl;

  const BooksDetails({
    super.key,
    required this.bookId,
    required this.title,
    required this.author,
    required this.img,
    required this.description,
    required this.rating,
    required this.pages,
    required this.isbn,
    required this.bookFormate,
    this.genre = '',
    this.isPaid = false,
    this.isApproved = true,
    this.pdfUrl = '',
  });

  @override
  State<BooksDetails> createState() => _BooksDetailsState();
}

class _BooksDetailsState extends State<BooksDetails> {
  bool isBookInReadingList =
      false; // Flag to check if the book is in the reading list
  bool isExpanded = false;
  final RxDouble userRating = 0.0.obs;
  final RxBool showReviewSection = false.obs;
  final TextEditingController _commentController = TextEditingController();
  final BookDetailsController bookDetailsController =
      Get.put(BookDetailsController());
  late final BooksController booksController;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    booksController = Get.isRegistered<BooksController>()
        ? Get.find<BooksController>()
        : Get.put(BooksController());
    bookDetailsController.listenToBookInReadingList(widget.bookId);
    bookDetailsController.listenToPlantoReading(widget.bookId);
    bookDetailsController.setBookId(widget.bookId, genre: widget.genre);
    bookDetailsController.checkUserRating(widget.bookId);
    bookDetailsController.listenToComments(widget.bookId);
  }


  void handleStatusSelection(String value) async {
    // Check if the username is not empty before proceeding with status changes
    if (bookDetailsController.userName.isNotEmpty) {
      if (value == 'Reading') {
        // Call the method to save the book to the "Reading" collection
        await bookDetailsController.addBookToReading(
          bookId: widget.bookId,
          title: widget.title,
          author: widget.author,
          img: widget.img,
          description: widget.description,
          rating: widget.rating,
          pages: widget.pages,
          isbn: widget.isbn,
          bookFormate: widget.bookFormate,
          genre: widget.genre,
          pdfUrl: widget.pdfUrl,
        );
      } else if (value == 'Plan To Read') {
        // Call the method to save the book to the "Plan to Read" collection
        await bookDetailsController.addBookToPlantoReading(
          bookId: widget.bookId,
          title: widget.title,
          author: widget.author,
          img: widget.img,
          description: widget.description,
          rating: widget.rating,
          pages: widget.pages,
          isbn: widget.isbn,
          bookFormate: widget.bookFormate,
          genre: widget.genre,
          pdfUrl: widget.pdfUrl,
        );
      } else if (value == 'Finished') {
        await bookDetailsController.addBookToFinished(
          bookId: widget.bookId,
          title: widget.title,
          author: widget.author,
          img: widget.img,
          description: widget.description,
          rating: widget.rating,
          pages: widget.pages,
          isbn: widget.isbn,
          bookFormate: widget.bookFormate,
          genre: widget.genre,
          pdfUrl: widget.pdfUrl,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      appBar: AppBar(
        backgroundColor: AppColor.bgcolor,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColor.iconstext,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          StatusDropdown(
            onSelected: handleStatusSelection,
            bookId: widget.bookId, // Pass the bookId to the dropdown
          ), // Use StatusDropdown here
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Book Image
                  (widget.img.isNotEmpty && widget.img.startsWith('http'))
                      ? Image.network(
                          widget.img,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.book,
                                  size: 100, color: Colors.grey),
                        )
                      : const Icon(Icons.book, size: 100, color: Colors.grey),

                  const SizedBox(height: 10),

                  // Book Title
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      color: AppColor.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 5),

                  // Book Author
                  Text(
                    widget.author,
                    style: const TextStyle(
                        fontSize: 18, color: AppColor.iconstext),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 5),

                  // Display Rating
                  Obx(() {
                    // Ensure the book exists in the list before accessing it
                    var currentBook = booksController.filteredBooks.isNotEmpty
                        ? booksController.books.firstWhere(
                            (book) => book['id'] == widget.bookId,
                            orElse: () => null,
                          )
                        : null;

                    if (currentBook == null) {
                      return Text(
                        "Rating: ${widget.rating.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: AppColor.clickedbutton,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }

                    double currentRating = double.tryParse(
                            currentBook['rating']?.toString() ?? '') ??
                        widget.rating;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(5, (index) {
                          if (index < currentRating.floor()) {
                            return const Icon(Icons.star,
                                color: AppColor.clickedbutton, size: 20);
                          } else if (index < currentRating) {
                            return const Icon(Icons.star_half,
                                color: AppColor.clickedbutton, size: 20);
                          } else {
                            return const Icon(Icons.star_border,
                                color: AppColor.clickedbutton, size: 20);
                          }
                        }),
                        const SizedBox(width: 4),
                        Text(
                          currentRating.toStringAsFixed(2),
                          style: const TextStyle(
                            color: AppColor.iconstext,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 5),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     // Implement Read button functionality
                  //   },
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: AppColor.cardcolor,
                  //     elevation: 5,
                  //   ),
                  //   child: const Text(
                  //     "Read",
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  // ),

                  const SizedBox(height: 20),

                  // Pages, ISBN, and Book Format with vertical divider
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 15.0, // Space between items
                    runSpacing: 10.0, // Space between rows when wrapping
                    children: [
                      _buildInfoColumn("${widget.pages}", "Pages"),
                      _buildVerticalDivider(),
                      _buildInfoColumn(widget.isbn, "ISBN"),
                      _buildVerticalDivider(),
                      _buildInfoColumn(widget.bookFormate, "Book Format"),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Book Description with Read More/Less functionality
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: isExpanded
                            ? double.infinity
                            : 100, // Adjust height based on expansion
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Text(
                          isExpanded
                              ? widget.description
                              : widget.description.length > 200
                                  ? '${widget.description.substring(0, 200)}...'
                                  : widget
                                      .description, // Show full description if less than 200 characters
                          style: const TextStyle(color: AppColor.iconstext),
                        ),
                      ),
                    ),
                  ),
                  if (widget.description.length >
                      200) // Only show button if necessary
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                        child: Text(
                          isExpanded ? 'Read Less' : 'Read More',
                          style: const TextStyle(
                              color: AppColor.clickedbutton,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Read and Review Options
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (widget.isPaid) {
                              customSnackbar(
                                title: "Paid Book",
                                message:
                                    "This is a paid book. Please purchase to read.",
                              );
                            } else if (!widget.isApproved) {
                              customSnackbar(
                                title: "Approval Pending",
                                message:
                                    "This book is waiting for author approval.",
                              );
                            } else {
                              handleStatusSelection('Reading');
                              String url = widget.pdfUrl.trim();
                              Get.to(() => ReaderScreen(
                                    title: widget.title,
                                    pdfUrl: url,
                                    bookId: widget.bookId,
                                  ));
                            }
                          },
                          icon:
                              const Icon(Icons.menu_book, color: Colors.white),
                          label: const Text("Read",
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.cardcolor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showReviewSection.toggle();
                          },
                          icon: const Icon(Icons.rate_review,
                              color: Colors.white),
                          label: const Text("Book Review",
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.clickedbutton,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Review Section (Stars and Submit)
                  Obx(() => showReviewSection.value
                      ? Column(
                          children: [
                            const Text(
                              "Rate this book",
                              style: TextStyle(
                                  color: AppColor.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Obx(() => Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (index) {
                                    return IconButton(
                                      icon: Icon(
                                        index < userRating.value
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: AppColor.clickedbutton,
                                      ),
                                      onPressed: bookDetailsController
                                              .hasUserRated.value
                                          ? null
                                          : () {
                                              userRating.value = index + 1.0;
                                            },
                                    );
                                  }),
                                )),
                            const SizedBox(height: 10),
                            Obx(() => ElevatedButton(
                                  onPressed: bookDetailsController
                                          .hasUserRated.value
                                      ? null
                                      : () {
                                          if (userRating.value <= 0) {
                                            customSnackbar(
                                                title: "Error",
                                                message:
                                                    "Please select a valid rating");
                                            return;
                                          }
                                          bookDetailsController.rateBook(
                                              widget.bookId, userRating.value);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        bookDetailsController.hasUserRated.value
                                            ? Colors.grey
                                            : AppColor.clickedbutton,
                                    elevation: 5,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 12),
                                  ),
                                  child: Text(
                                    bookDetailsController.hasUserRated.value
                                        ? "Already Reviewed"
                                        : "Submit Review",
                                    style:
                                        const TextStyle(color: AppColor.white),
                                  ),
                                )),
                            const SizedBox(height: 20),
                          ],
                        )
                      : const SizedBox.shrink()),
                   // ── Comments Section ───────────────────────────────────
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.comment, color: Color(0xFF1A9EFF), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Reviews & Comments",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Obx(() => Text(
                        "${bookDetailsController.comments.length}",
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Comment Input Box
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.08),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: const Color(0xFF1A9EFF),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            await bookDetailsController.addComment(
                                widget.bookId, _commentController.text);
                            _commentController.clear();
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.send, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Comments List
                  Obx(() {
                    if (bookDetailsController.isCommentsLoading.value) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    if (bookDetailsController.comments.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'No comments yet. Be the first!',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: bookDetailsController.comments.map((c) {
                        final isOwner = c['userId'] ==
                            bookDetailsController.auth.currentUser?.uid;
                        final ts = c['timestamp'];
                        String timeStr = '';
                        if (ts != null && ts is Timestamp) {
                          final dt = ts.toDate();
                          final diff = DateTime.now().difference(dt);
                          if (diff.inMinutes < 1) timeStr = 'just now';
                          else if (diff.inHours < 1) timeStr = '${diff.inMinutes}m ago';
                          else if (diff.inDays < 1) timeStr = '${diff.inHours}h ago';
                          else timeStr = '${diff.inDays}d ago';
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(0xFF1A9EFF),
                                child: Icon(Icons.person, size: 16, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          c['username'] ?? 'Anonymous',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          timeStr,
                                          style: const TextStyle(
                                              color: Colors.white38, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c['comment'] ?? '',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              if (isOwner)
                                GestureDetector(
                                  onTap: () => bookDetailsController
                                      .deleteComment(c['commentId']),
                                  child: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent, size: 18),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create information columns
  Column _buildInfoColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: AppColor.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColor.iconstext),
        ),
      ],
    );
  }

  // Helper method to create vertical divider
  Container _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColor.textblackcolor,
      margin: const EdgeInsets.symmetric(horizontal: 15),
    );
  }
}

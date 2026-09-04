import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:readora/utils/colors.dart';
import 'ai_agent_panel.dart' as ai;
import 'book_text_data.dart';

class ReaderScreen extends StatefulWidget {
  final String title;
  final String pdfUrl;
  final String bookId; // Used to save/restore reading progress

  const ReaderScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
    this.bookId = '',
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  OverlayEntry? _overlayEntry;
  bool _useNativePdfViewer = false;
  bool _loadingPdf = true;
  String _resolvedUrl = '';

  // E-Book Reader State
  final ScrollController _ebookScrollController = ScrollController();
  double _fontSize = 16.0;
  int _currentChapterIndex = 0;
  late BookContent _bookContent;

  // Progress tracking
  int _savedPage = 1;
  Timer? _saveDebounce;
  bool _hasRestoredPage = false;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _bookContent = BookTextData.getBookContent(widget.title, '');
    _initReader();
  }

  Future<void> _initReader() async {
    _loadSavedProgress();

    final trimmed = widget.pdfUrl.trim();
    // Recognize all known PDF sources (planetebook, pressbooks, drive, dropbox, firebase, direct .pdf)
    final bool isPdfSource = trimmed.isNotEmpty &&
        (trimmed.endsWith('.pdf') ||
            trimmed.contains('planetebook.com') ||
            trimmed.contains('pressbooks') ||
            trimmed.contains('drive.google.com') ||
            trimmed.contains('dropbox.com') ||
            trimmed.contains('firebasestorage'));

    if (isPdfSource) {
      _resolvedUrl = _resolveUrl(trimmed);
      setState(() {
        _useNativePdfViewer = true;
        _loadingPdf = true;
      });
    } else {
      setState(() {
        _useNativePdfViewer = false;
        _loadingPdf = false;
      });
    }
  }

  // ─── PROGRESS: Load saved page from Firestore ────────────────────────────
  Future<void> _loadSavedProgress() async {
    if (widget.bookId.isEmpty) return;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('readingProgress')
          .doc(widget.bookId)
          .get();

      if (doc.exists) {
        final page = (doc.data()?['page'] as num?)?.toInt() ?? 1;
        _savedPage = page > 0 ? page : 1;
        if (!_useNativePdfViewer && _savedPage <= _bookContent.chapters.length) {
          setState(() {
            _currentChapterIndex = _savedPage - 1;
          });
        }
      }
    } catch (_) {}
  }

  // ─── PROGRESS: Save current page to Firestore (debounced 2s) ────────────
  void _saveProgress(int page) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 2), () async {
      if (widget.bookId.isEmpty) return;
      final user = _auth.currentUser;
      if (user == null) return;

      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('readingProgress')
            .doc(widget.bookId)
            .set({
          'page': page,
          'bookId': widget.bookId,
          'title': widget.title,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    });
  }

  // ─── URL Resolution for PDFs ─────────────────────────────────────────────
  String _resolveUrl(String url) {
    String trimmedUrl = url.trim();

    if (trimmedUrl.contains('drive.google.com')) {
      final regExp = RegExp(r'\/d\/([^\/]+)');
      final match = regExp.firstMatch(trimmedUrl);
      if (match != null && match.groupCount >= 1) {
        final fileId = match.group(1);
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    }

    if (trimmedUrl.contains('dropbox.com')) {
      trimmedUrl = trimmedUrl.replaceFirst('dl=0', 'dl=1');
      if (!trimmedUrl.contains('dl=1')) {
        trimmedUrl =
            trimmedUrl.contains('?') ? '$trimmedUrl&dl=1' : '$trimmedUrl?dl=1';
      }
      return trimmedUrl;
    }

    return trimmedUrl;
  }

  // ─── Context Menu (Find Meaning) for PDF Selection ────────────────────────
  void _showContextMenu(
      BuildContext context, PdfTextSelectionChangedDetails details) {
    final OverlayState overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: details.globalSelectedRegion!.topLeft.dy - 55,
        left: details.globalSelectedRegion!.bottomLeft.dx,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.cardcolor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: TextButton.icon(
              icon: const Icon(Icons.smart_toy,
                  color: AppColor.clickedbutton, size: 18),
              label: const Text('Find Meaning',
                  style: TextStyle(
                      color: AppColor.white, fontWeight: FontWeight.w600)),
              onPressed: () {
                final selectedText = details.selectedText;
                _pdfViewerController.clearSelection();
                _hideContextMenu();
                if (selectedText != null) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) =>
                        ai.AiAgentPanel(initialText: selectedText),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
    overlayState.insert(_overlayEntry!);
  }

  void _hideContextMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _pdfViewerController.dispose();
    _ebookScrollController.dispose();
    _hideContextMenu();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColor.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColor.bgcolor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColor.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_useNativePdfViewer) ...[
            IconButton(
              icon: const Icon(Icons.text_decrease, color: AppColor.white),
              onPressed: () {
                if (_fontSize > 12) setState(() => _fontSize -= 2);
              },
            ),
            IconButton(
              icon: const Icon(Icons.text_increase, color: AppColor.white),
              onPressed: () {
                if (_fontSize < 24) setState(() => _fontSize += 2);
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined,
                color: AppColor.clickedbutton, size: 26),
            tooltip: 'AI Assistant',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ai.AiAgentPanel(),
              );
            },
          ),
        ],
      ),
      body: _useNativePdfViewer ? _buildPdfViewer() : _buildEbookReader(),
    );
  }

  Widget _buildPdfViewer() {
    return Stack(
      children: [
        RepaintBoundary(
          child: SfPdfViewer.network(
            _resolvedUrl,
            controller: _pdfViewerController,
            scrollDirection: PdfScrollDirection.vertical,
            pageLayoutMode: PdfPageLayoutMode.continuous,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            canShowPaginationDialog: true,
            onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
              if (details.selectedText == null && _overlayEntry != null) {
                _hideContextMenu();
              } else if (details.selectedText != null) {
                if (_overlayEntry != null) _hideContextMenu();
                _showContextMenu(context, details);
              }
            },
            onPageChanged: (PdfPageChangedDetails details) {
              _saveProgress(details.newPageNumber);
            },
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() => _loadingPdf = false);
              if (!_hasRestoredPage && _savedPage > 1) {
                _hasRestoredPage = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    _pdfViewerController.jumpToPage(_savedPage);
                  } catch (_) {}
                });
              }
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              if (mounted) {
                setState(() {
                  _useNativePdfViewer = false;
                  _loadingPdf = false;
                });
              }
            },
          ),
        ),
        if (_loadingPdf)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColor.clickedbutton),
                SizedBox(height: 16),
                Text('Opening E-Book...',
                    style: TextStyle(color: AppColor.iconstext)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEbookReader() {
    final chapters = _bookContent.chapters;
    final currentChapter = chapters[_currentChapterIndex];

    return Column(
      children: [
        // Chapter Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColor.cardcolor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _bookContent.author,
                style: const TextStyle(
                  color: AppColor.clickedbutton,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                'Chapter ${_currentChapterIndex + 1} of ${chapters.length}',
                style: const TextStyle(
                  color: AppColor.iconstext,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Reader Body
        Expanded(
          child: RepaintBoundary(
            child: SelectionArea(
              child: Scrollbar(
                controller: _ebookScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 6,
                radius: const Radius.circular(10),
                child: SingleChildScrollView(
                  controller: _ebookScrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentChapter.title,
                        style: TextStyle(
                          color: AppColor.white,
                          fontSize: _fontSize + 4,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 16),
                      Text(
                        currentChapter.content,
                        style: TextStyle(
                          color: AppColor.white.withValues(alpha: 0.9),
                          fontSize: _fontSize,
                          height: 1.6,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Navigation Footer
        if (chapters.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColor.cardcolor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: AppColor.white),
                  onPressed: _currentChapterIndex > 0
                      ? () {
                          setState(() {
                            _currentChapterIndex--;
                            _saveProgress(_currentChapterIndex + 1);
                          });
                        }
                      : null,
                ),
                Text(
                  '${_currentChapterIndex + 1} / ${chapters.length}',
                  style: const TextStyle(color: AppColor.white),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.arrow_forward_ios, color: AppColor.white),
                  onPressed: _currentChapterIndex < chapters.length - 1
                      ? () {
                          setState(() {
                            _currentChapterIndex++;
                            _saveProgress(_currentChapterIndex + 1);
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Books/view/component/upload_books/view/upload_book.dart';
import 'package:readora/screens/ChatList/view/component/group/view/group.dart';
import 'package:readora/utils/app_assets.dart';
import 'package:readora/utils/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title; // Title is now nullable
  final String? hintText; // Hint text is also nullable
  final TextEditingController?
      searchController; // Added searchController parameter
  final Function(String)? onSearchChanged; // Added onSearchChanged callback
  final bool showBackButton; // Add parameter to control back button visibility
  final bool groupicon;
  final String role;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.title, // Initialize title as optional
    this.hintText, // Initialize hintText as optional
    this.searchController, // Initialize searchController as optional
    this.onSearchChanged, // Initialize onSearchChanged as optional
    this.showBackButton = false, // Default to false
    this.groupicon = false, // Default to false
    required this.role,
    this.actions,
  }) : assert(
          (title != null && hintText == null) ||
              (title == null && hintText != null),
          'You must provide either a title or a hintText, but not both.',
        );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * .12, // Set the height as required
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF131A22),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          crossAxisAlignment: CrossAxisAlignment.start, // Align to the start
          children: [
            const SizedBox(height: 10), // Add space above the title
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Place title on left, plus on right
              children: [
                Row(
                  children: [
                    if (showBackButton)
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: AppColor.iconstext), // Back button icon
                        onPressed: () {
                          Navigator.pop(
                              context); // Go back to the previous screen
                        },
                      ),
                    const SizedBox(
                        width: 10), // Add space between back button and title
                    if (title != null) // Display title if provided
                      Text(
                        title!,
                        style: const TextStyle(
                          color: AppColor.iconstext,
                          fontSize: 20, // Set font size as required
                          fontWeight: FontWeight.normal, // Non-bold text
                        ),
                      ),
                  ],
                ),
                if (groupicon) // Show plus icon if true
                  IconButton(
                    icon: SvgPicture.asset(AppAssets.groupicon,
                        colorFilter: const ColorFilter.mode(AppColor.iconstext, BlendMode.srcIn)),
                    onPressed: () {
                      // Open a bottom sheet to create a new group
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled:
                            true, // Allows flexible height based on content
                        backgroundColor: Colors
                            .transparent, // Make background transparent for better visual
                        builder: (BuildContext context) {
                          return const Group(); // The screen for creating a group chat
                        },
                      );
                    },
                  ),

                //                Expanded(
                //   child: Container(), // Pushes other content to the right
                // ),
                // Only show the plus icon if role == 'auth'
                if (role == 'auth')
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      size: 24, // Adjust size as needed
                      color: AppColor.iconstext,
                    ),
                    onPressed: () {
                   Get.to(() => const UploadBooks());
                    },
                  ),
                // Alternatively, if you also check for `groupicon`
                if (groupicon && role == 'auth')
                  IconButton(
                    icon: const Icon(
                      Icons.group,
                      size: 24, // Adjust size as needed
                      color: AppColor.iconstext,
                    ),
                    onPressed: () {
                      // Define action for group icon
                    },
                  ),
                if (actions != null) ...actions!,
              ],
            ),
            if (searchController != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05), // Transparent background
                    borderRadius: BorderRadius.circular(30.0), // Rounded pill shape
                    border: Border.all(
                      color: const Color(0xFF1A9EFF).withOpacity(0.6), // Distinct border on sides
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.white54, size: 20),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          textAlignVertical: TextAlignVertical.center, // Center text vertically
                          decoration: InputDecoration(
                            hintText: hintText ?? '',
                            border: InputBorder.none,
                            isDense: true,
                            hintStyle: const TextStyle(color: Colors.white38),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                            suffixIcon: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: searchController!,
                              builder: (context, value, child) {
                                return value.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            color: Colors.white54, size: 18),
                                        onPressed: () {
                                          searchController?.clear();
                                          onSearchChanged?.call('');
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      )
                                    : const SizedBox.shrink();
                              },
                            ),
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                          ),
                          onChanged: onSearchChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(Get.height * .12); // Provide preferred size
}

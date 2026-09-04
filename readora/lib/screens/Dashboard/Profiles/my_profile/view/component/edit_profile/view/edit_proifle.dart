import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Dashboard/Home/controller/home_controller.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/view/component/change_password/view/change_password.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/view/component/edit_profile/controller/edit_profile_controller.dart';
import 'package:readora/utils/app_assets.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/glass_box.dart';
import 'package:readora/utils/custom_loading_indicator.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final EditProfileController editProfileController =
      Get.put(EditProfileController());
  final HomeController homeController = Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      editProfileController.fullNameController.text = homeController.username;
      editProfileController.emailController.text = homeController.email;
      editProfileController.aboutController.text = homeController.about;
      editProfileController.profilePicUrl.value = homeController.profilePicUrl;
      editProfileController.setInitialValues(
          homeController.username, homeController.email, homeController.about, homeController.genres);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      appBar: AppBar(
        title: const Text('Edit Profile',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture Section
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Obx(() {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.transparent,
                          backgroundImage:
                              editProfileController.profilePicUrl.value.isNotEmpty
                                  ? NetworkImage(
                                      editProfileController.profilePicUrl.value)
                                      as ImageProvider
                                  : const AssetImage(AppAssets.defaultAvatar),
                        ),
                      );
                    }),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: editProfileController.pickImage,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColor.clickedbutton,
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    Obx(() => editProfileController.isLoading.value
                        ? const Positioned.fill(
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white)))
                        : const SizedBox.shrink()),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(() => Text(
                      homeController.username,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    )),
                const SizedBox(height: 40),

                // Form Section with Glassmorphism
                GlassBox(
                  borderRadius: 20,
                  opacity: 0.1,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: editProfileController.fullNameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: editProfileController.emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          enabled: false,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: editProfileController.aboutController,
                          label: 'About',
                          icon: Icons.info_outline,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 25),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Preferred Genres",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Obx(() {
                          return Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: editProfileController.availableGenres.map((genre) {
                              final isSelected = editProfileController.selectedGenres.contains(genre);
                              return FilterChip(
                                label: Text(
                                  genre,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppColor.clickedbutton,
                                checkmarkColor: Colors.white,
                                backgroundColor: Colors.white.withOpacity(0.05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected ? AppColor.clickedbutton : Colors.transparent,
                                  ),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    editProfileController.selectedGenres.add(genre);
                                  } else {
                                    editProfileController.selectedGenres.remove(genre);
                                  }
                                },
                              );
                            }).toList(),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.clickedbutton,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => editProfileController.updateUserData(),
                    child: const Text('Save Changes',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Get.to(() => const ChangePassword()),
                  child: const Text('Change Password',
                      style: TextStyle(
                          color: AppColor.clickedbutton,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          Obx(() => editProfileController.isLoading.value
              ? const Center(child: CustomLoadingIndicator())
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white38, size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
        ),
      ],
    );
  }
}

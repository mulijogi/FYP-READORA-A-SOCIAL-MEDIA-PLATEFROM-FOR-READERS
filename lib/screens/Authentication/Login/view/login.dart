import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Authentication/Forget/view/forget.dart';
import 'package:readora/screens/Authentication/Login/controller/login_controller.dart';
import 'package:readora/screens/Authentication/Register/view/register.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/custom_loading_indicator.dart';
import 'package:readora/utils/readora_logo.dart';

class MyLogin extends StatefulWidget {
  const MyLogin({super.key});

  @override
  _MyLoginState createState() => _MyLoginState();
}

class _MyLoginState extends State<MyLogin> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _obscureCurrentPassword = true;
  bool _obscureCurrentPassword1 = true;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // 2 tabs: User and Auth
  }

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.put(LoginController());

    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      body: Stack(
        children: [
          // Background image
          // Container(
          //   decoration: const BoxDecoration(
          //     image: DecorationImage(
          //       image: AssetImage('assets/login.jpg'),
          //       fit: BoxFit.cover,
          //     ),
          //   ),
          // ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width >= 600 ? 100 : 35,
              ),
              child: Form(
                key: loginController.formKeylogin,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // iamge assets
                    const ReadoraLogo(fontSize: 48),

                    const SizedBox(height: 50),

                    // TabBar with "User" and "Auth"
                    Container(
                      decoration: BoxDecoration(
                        // color: const Color.fromARGB(255, 121, 15, 15).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            tabs: const [
                              Tab(text: 'Reader'),
                              Tab(text: 'Author'),
                            ],
                            labelColor: AppColor.clickedbutton,
                            unselectedLabelColor: AppColor.iconstext,
                            indicatorColor: AppColor
                                .white, // Color of the indicator below the selected tab
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 300, // Increased height for both tabs
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // User Tab: Email and Password Fields
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: TextFormField(
                                        controller: loginController.emailController,
                                        style: const TextStyle(color: Colors.black),
                                        decoration: InputDecoration(
                                          focusedBorder: const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: AppColor.clickedbutton,
                                                width:
                                                    2), // Border when focused
                                          ),
                                          hintText: 'Email',
                                          hintStyle: const TextStyle(
                                            color: AppColor
                                                .hinttextcolor, // Change this to your desired color
                                          ),
                                          fillColor: AppColor.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.email,
                                              color: AppColor.bgcolor),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email address';
                            }
                            final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: TextFormField(
                                        controller: loginController.passController,
                                        style: const TextStyle(color: Colors.black),
                                        obscureText: _obscureCurrentPassword,
                                        decoration: InputDecoration(
                                          focusedBorder: const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: AppColor.clickedbutton,
                                                width:
                                                    2), // Border when focused
                                          ),
                                          hintText: 'Password',
                                          hintStyle: const TextStyle(
                                            color: AppColor
                                                .hinttextcolor, // Change this to your desired color
                                          ),
                                          fillColor: AppColor.white,
                                          filled: true,
                                          suffixIcon: IconButton(
          icon: Icon(
            _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
            color: AppColor.dropdown,
          ),
          onPressed: () {
            // Toggle the obscure text value when the icon is clicked
            setState(() {
              _obscureCurrentPassword = !_obscureCurrentPassword;
            });
          },
        ),
                                          prefixIcon: const Icon(Icons.lock,
                                              color: AppColor.bgcolor),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.isEmpty ||
                                              value.length < 8) {
                                            return 'Please enter at least 8 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              loginController.emailController
                                                  .clear();
                                              loginController.passController
                                                  .clear();
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const MyRegister()),
                                              );
                                            },
                                            child: const Text(
                                              'Sign Up',
                                              style: TextStyle(
                                               
                                                fontSize: 16,
                                                color: AppColor.iconstext,
                                              ),
                                            ),
                                          ),
                                          const Spacer(), // Adds space between the buttons
                                          TextButton(
                                            onPressed: () {
                                              loginController.emailController
                                                  .clear();
                                              loginController.passController
                                                  .clear();
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        Forget()),
                                              );
                                            },
                                            child: const Text(
                                              'Forgot Password?',
                                              style: TextStyle(
                                               
                                                fontSize: 16,
                                                color: AppColor.iconstext,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                // Auth Tab: Email and Password Fields with Sign Up and Forgot Password
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: TextFormField(
                                        controller: loginController.emailController,
                                        style: const TextStyle(color: Colors.black),
                                        decoration: InputDecoration(
                                          hintText: 'Email',
                                          hintStyle: const TextStyle(
                                            color: AppColor
                                                .hinttextcolor, // Change this to your desired color
                                          ),
                                          fillColor: AppColor.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.email,
                                              color: AppColor.bgcolor),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                         validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email address';
                            }
                            final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: TextFormField(
                                        controller: loginController.passController,
                                        style: const TextStyle(color: Colors.black),
                                        obscureText: _obscureCurrentPassword1,
                                        decoration: InputDecoration(
                                          focusedBorder:
                                              const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: AppColor.clickedbutton,
                                                width:
                                                    2), // Border when focused
                                          ),
                                          hintText: 'Password',
                                          hintStyle: const TextStyle(
                                            color: AppColor
                                                .hinttextcolor, // Change this to your desired color
                                          ),
                                          fillColor: AppColor.white,
                                          filled: true,
                                          suffixIcon: IconButton(
          icon: Icon(
            _obscureCurrentPassword1 ? Icons.visibility_off : Icons.visibility,
            color: AppColor.dropdown,
          ),
          onPressed: () {
            // Toggle the obscure text value when the icon is clicked
            setState(() {
              _obscureCurrentPassword1 = !_obscureCurrentPassword1;
            });
          },
        ),
                                          prefixIcon: const Icon(Icons.lock,
                                              color: AppColor.bgcolor),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.isEmpty ||
                                              value.length < 8) {
                                            return 'Please enter at least 8 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    // Sign Up and Forgot Password Buttons in Auth Tab
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              loginController.emailController
                                                  .clear();
                                              loginController.passController
                                                  .clear();
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const MyRegister()),
                                              );
                                            },
                                            child: const Text(
                                              'Sign Up',
                                              style: TextStyle(
                                               
                                                fontSize: 16,
                                                color: AppColor.iconstext,
                                              ),
                                            ),
                                          ),
                                          const Spacer(), // Adds space between the buttons
                                          TextButton(
                                            onPressed: () {
                                              loginController.emailController
                                                  .clear();
                                              loginController.passController
                                                  .clear();
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        Forget()),
                                              );
                                            },
                                            child: const Text(
                                              'Forgot Password?',
                                              style: TextStyle(
                                               
                                                fontSize: 16,
                                                color: AppColor.iconstext,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColor.clickedbutton,
                              child: IconButton(
                                onPressed: () {
                                  if (loginController.formKeylogin.currentState!
                                      .validate()) {
                                    loginController.login(
                                        context, _tabController.index);
                                  }
                                },
                                icon: const Icon(Icons.arrow_forward),
                                color: AppColor.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Loading Overlay
          Obx(() {
            return loginController.isLoading.value
                ? Center(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        alignment: Alignment.center,
                        child: const CustomLoadingIndicator(),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}

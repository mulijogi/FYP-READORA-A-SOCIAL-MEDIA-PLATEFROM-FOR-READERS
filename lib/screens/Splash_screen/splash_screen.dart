import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:readora/screens/Authentication/Login/view/login.dart';
import 'package:readora/utils/readora_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    try {
      // Request both notification and location permissions together on startup
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.notification,
        Permission.locationWhenInUse,
      ].request();

      print('[Splash] Notification: ${statuses[Permission.notification]}');
      print('[Splash] Location: ${statuses[Permission.locationWhenInUse]}');
    } catch (e) {
      print("Error requesting permissions in splash screen: $e");
    }

    // Ensure the splash logo stays visible for at least 3.5 seconds total
    final elapsed = DateTime.now().difference(startTime);
    final remainingDelay = const Duration(milliseconds: 3500) - elapsed;
    if (remainingDelay > Duration.zero) {
      await Future.delayed(remainingDelay);
    }

    if (mounted) {
      Get.offAll(() => const MyLogin());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131A22),
      body: Center(
        child: const Center(
          child: ReadoraLogo(fontSize: 60),
        ),
      ),
    );
  }
}

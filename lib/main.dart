import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/screens/Authentication/Forget/view/forget.dart';
import 'package:readora/screens/Authentication/Login/view/login.dart';
import 'package:readora/screens/Authentication/Register/view/register.dart';
import 'package:readora/screens/ChatList/view/chat_lists.dart';
import 'package:readora/screens/Chats/view/Chatting.dart';
import 'package:readora/screens/Dashboard/Home/view/home.dart';
import 'package:readora/screens/Dashboard/Notifications/view/notifications.dart';
import 'package:readora/screens/Dashboard/Profiles/my_profile/view/component/edit_profile/view/edit_proifle.dart';
import 'package:readora/screens/Dashboard/Searchfriend/view/searchfriend.dart';
import 'package:readora/screens/Friendreq/view/friendreq.dart';
import 'package:readora/screens/Post/view/posts.dart';
import 'package:readora/screens/Reminders/service/reminder_service.dart';
import 'package:readora/screens/Splash_screen/splash_screen.dart';
import 'package:readora/screens/firebase_options.dart';

import 'package:readora/screens/Dashboard/Profiles/my_profile/view/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first (required by all other services)
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) rethrow;
  }

  // Run GetStorage + ReminderService in parallel to speed up startup
  await Future.wait([
    GetStorage.init(),
    ReminderService.instance.init().catchError((_) {}),
  ]);

  runApp(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    defaultTransition: Transition.cupertino, // Smooth transitions
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColor.bgcolor,
      primaryColor: AppColor.cardcolor,
      canvasColor: AppColor.bgcolor, // Fix for bottom sheets/drawers
      colorScheme: ColorScheme.dark(
        primary: AppColor.clickedbutton,
        surface: AppColor.cardcolor,
      ),
    ),
    initialRoute: 'SplashScreen',
    routes: {
      'SplashScreen': (context) => const SplashScreen(),
      'login': (context) => const MyLogin(),
      'MyLogin': (context) => const MyLogin(),
      'register': (context) => const MyRegister(),
      'home': (context) => const Home(),
      'forget': (context) => Forget(),
      'friendreq': (context) => const Friendreq(),
      'profile': (context) => const Profile(),
      'searchfriend': (context) => const SearchFriend(),
      'notifications': (context) => const Notifications(),
      'friendlist': (context) => ChatLists(friendId: ''),
      'chatting': (context) => Chatting(
            friendId: '',
            friendName: '',
            profilePicUrl: '',
            chatRoomId: '',
            status: '',
          ),
      'posts': (context) => const Posts(
            username: null,
          ),
      'editprofile': (context) => const EditProfile(),
    },
  ));
}

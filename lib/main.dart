import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/pending_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/post_screen.dart';
import 'screens/map_screen.dart';
import 'screens/item_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/notification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

// must be top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Background message: ${message.messageId}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Back To You',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF22D3EE),
          surface: Color(0xFF1A1A1A),
        ),
      ),
      initialRoute: '/',
      routes: {
       '/admin': (context) => const AdminScreen(),
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/pending': (context) => const PendingScreen(),
        '/feed': (context) => const FeedScreen(),
        '/post': (context) => const PostScreen(),
        '/map': (context) => const MapScreen(),
        '/item-detail': (context) => const ItemDetailScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationScreen(),
      },
    );
  }
}
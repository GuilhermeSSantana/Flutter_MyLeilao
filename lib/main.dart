import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_app/Home/home_Page.dart';
import 'package:my_app/Login/AuthScreen.dart';
import 'package:path_provider/path_provider.dart';

// Function to clear app cache
Future<void> clearAppCache() async {
  try {
    // Clear temporary directory
    final tempDir = await getTemporaryDirectory();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
      await tempDir.create();
    }

    // Clear application support directory
    final appSupportDir = await getApplicationSupportDirectory();
    if (appSupportDir.existsSync()) {
      await appSupportDir.delete(recursive: true);
      await appSupportDir.create();
    }

    // Clear Firebase cache
    await FirebaseAuth.instance.signOut();
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Error clearing cache: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clear cache before initializing Firebase
  await clearAppCache();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC1fdQ6PaN2tegYOzMdijfyhwsgEbf_fCE",
      authDomain: "voltaic-racer-230700.firebaseapp.com",
      projectId: "voltaic-racer-230700",
      storageBucket: "voltaic-racer-230700.appspot.com",
      messagingSenderId: "375462470587",
      appId: "1:375462470587:web:a380d4325684168ff19a9e",
      measurementId: "G-ZQ3GQ9P0VM",
    ),
  );
  runApp(const AuctionApp());
}

class AuctionApp extends StatelessWidget {
  const AuctionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Leilão',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            User? user = snapshot.data;
            if (user == null) {
              return const AuthScreen();
            }
            return const MainNavigationScreen();
          }
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}

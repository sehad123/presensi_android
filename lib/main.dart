import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:presensi_api/firebase_setup.dart';
import 'package:presensi_api/home/home_page.dart';
import 'package:presensi_api/splash_screen.dart';
import 'package:presensi_api/login/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inisialisasi Firebase secara manual dengan mengonfirmasi hasilnya
    final FirebaseApp firebaseApp = await Firebase.initializeApp();

    // Verifikasi inisialisasi
    if (firebaseApp != null) {
      print('Firebase initialized successfully');

      // Jalankan setupFirebase setelah Firebase berhasil diinisialisasi
      await setupFirebase();

      // Tes koneksi Firestore
      await testFirestoreConnection();
    } else {
      print('Failed to initialize Firebase');
    }
  } catch (e) {
    print('Unexpected error during initialization: $e');
  }

  runApp(const MyApp());
}

Future<void> testFirestoreConnection() async {
  try {
    var testDoc = await FirebaseFirestore.instance
        .collection('test')
        .doc('connection')
        .get();
    print(
        'Firestore connection test: ${testDoc.exists ? 'Success' : 'Failed'}');
  } catch (e) {
    print('Error testing Firestore connection: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Presensi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Handling for different routes
        switch (settings.name) {
          case '/home':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => HomePage(
                userId: args?['userId'] ?? '',
              ),
            );
          case '/login':
            return MaterialPageRoute(builder: (context) => LoginPage());
          default:
            return MaterialPageRoute(builder: (context) => SplashScreen());
        }
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('404'),
            ),
            body: Center(
              child: Text('Page not found!'),
            ),
          ),
        );
      },
    );
  }
}

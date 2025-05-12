// In nmain.dart, update the home property to use CarDetailScreen

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'detail.dart'; // Import main.dart to access CarDetailScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Rental App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFFCCFF00), // Neon green color
        fontFamily: 'Roboto',
      ),
      // Use CarDetailScreen as the home screen
      home: const CarDetailScreen(carId: 'TaHKzA6QVnVHUk2t9UFp'),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:consumption/auth_screens/welcome.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screens/home_screen.dart';
import 'auth_screens/login_screen.dart';
import 'auth_screens/signup_screen.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'inner_screens/list_cars.dart';
import 'models/car_entry.dart';

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

String appName = "ConsumptionMeter";
Color appForegroundColor = Colors.grey.shade800;
Color appBackgroundColor = Colors.red.shade400;
final db = FirebaseFirestore.instance;

bool isLoggedIn = false;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Consumption Meter',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red.shade400,
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      initialRoute: HomePage.id,
      routes: {
        HomeScreen.id: (context) => const HomeScreen(),
        LoginScreen.id: (context) => const LoginScreen(),
        SignUpScreen.id: (context) => const SignUpScreen(),
        HomePage.id: (context) => const HomePage(),
        ListCarsScreen.id: (context) => const ListCarsScreen(),
      },
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:consumption/auth_screens/welcome.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
Color appForegroundColor = Colors.grey;
Color appBackgroundColor = Colors.red.shade200;
final db = FirebaseFirestore.instance;

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

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
      title: 'Flutter Demo',
      theme: ThemeData(useMaterial3: true),
      debugShowCheckedModeBanner: true,
      initialRoute: HomeScreen.id,
      routes: {
        HomeScreen.id: (context) => const HomeScreen(),
        LoginScreen.id: (context) => const LoginScreen(),
        SignUpScreen.id: (context) => const SignUpScreen(),
        HomePage.id: (context) => HomePage(),
      },
    );
  }
}

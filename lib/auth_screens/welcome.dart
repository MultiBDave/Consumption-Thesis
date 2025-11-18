import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

// Use lowerCamelCase for variable names
bool backOffice = false;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  static String id = 'welcome_screen';

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(backOffice ? appName : 'Under construction'),
        backgroundColor: appBackgroundColor,
        foregroundColor: appForegroundColor,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(left: 30.0, right: 30, top: 10),
        // WillPopScope is deprecated; ignore the deprecation until migrated to PopScope
        // ignore: deprecated_member_use
        child: WillPopScope(
          onWillPop: () async {
            SystemNavigator.pop();
            return false;
          },
          child: const Center(
              // child: ScreenTitle(
              //   //title: 'Page is under construction',
              // ),
              ),
        ),
      ),
    );
  }
}

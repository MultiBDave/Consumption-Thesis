import 'package:consumption/auth_screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PersistentBottomBarScaffold extends StatefulWidget {
  final List<PersistentTabItem> items;

  const PersistentBottomBarScaffold({super.key, required this.items});
    @override
    State<PersistentBottomBarScaffold> createState() =>
      _PersistentBottomBarScaffoldState();
}

class _PersistentBottomBarScaffoldState
    extends State<PersistentBottomBarScaffold> {
  int _selectedTab = 0;

  bool canSwitchToMyEntries(int index) {
    if (FirebaseAuth.instance.currentUser == null && index == 1) {
      // Navigate to the LoginScreen if no user is logged in
      // Use the root navigator and a direct MaterialPageRoute so the
      // nested tab Navigators (which don't have named routes) don't
      // cause onGenerateRoute null errors.
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ));
      return false;
    } else {
      // Implement your condition here, return true if the user can switch to the tab
      return true;
    } // This is just a placeholder
  }

  void attemptSwitchTab(int index) {
    if (index == 1 && !canSwitchToMyEntries(index)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Login required"),
          content: const Text("You need to be logged in to access this feature."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _selectedTab = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope is deprecated; keep behavior and plan migration to PopScope later.
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (widget.items[_selectedTab].navigatorkey?.currentState?.canPop() ??
            false) {
          widget.items[_selectedTab].navigatorkey?.currentState?.pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedTab,
          children: widget.items
              .map((page) => Navigator(
                    key: page.navigatorkey,
                    onGenerateInitialRoutes: (navigator, initialRoute) {
                      return [
                        MaterialPageRoute(builder: (context) => page.tab)
                      ];
                    },
                  ))
              .toList(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (index) {
            if (index == _selectedTab) {
              widget.items[index].navigatorkey?.currentState
                  ?.popUntil((route) => route.isFirst);
            } else {
              attemptSwitchTab(index);
            }
          },
          items: widget.items
              .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon), label: item.title))
              .toList(),
        ),
      ),
    );
  }
}

/// Model class that holds the tab info for the [PersistentBottomBarScaffold]
class PersistentTabItem {
  final Widget tab;
  final GlobalKey<NavigatorState>? navigatorkey;
  final String title;
  final IconData icon;

  PersistentTabItem(
      {required this.tab,
      this.navigatorkey,
      required this.title,
      required this.icon});
}

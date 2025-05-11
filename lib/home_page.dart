import 'package:flutter/material.dart';
import '../helper/persistent_bottom_bar_scaffold.dart';
import 'inner_screens/my_entries.dart';
import 'inner_screens/list_cars.dart';

class HomePage extends StatefulWidget {
  static String id = 'home_page';

  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _tab1navigatorKey = GlobalKey<NavigatorState>();
  final _tab2navigatorKey = GlobalKey<NavigatorState>();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PersistentBottomBarScaffold(
      items: [
        PersistentTabItem(
          tab: const ListCarsScreen(),
          icon: Icons.search,
          title: 'Search',
          navigatorkey: _tab1navigatorKey,
        ),
        PersistentTabItem(
          tab: MyEntries(),
          icon: Icons.notes,
          title: 'My Entries',
          navigatorkey: _tab2navigatorKey,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:consumption/main.dart';

import '../inner_screens/my_entries.dart';

class AddCarScreen extends StatefulWidget {
  static const routeName = '/patient';
  const AddCarScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddCarScreenState createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(appName),
          backgroundColor: appBackgroundColor,
          foregroundColor: appForegroundColor,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MyEntries(),
              SizedBox(
                height: 10,
              ),
              // TaskBuilder(filter: 'NoGroup'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              //todo
            });
          },
          child: const Icon(Icons.delete),
        ));
  }
}

import 'package:consumption/auth_screens/login_screen.dart';
import 'package:consumption/home_page.dart';
import 'package:consumption/inner_screens/forms/add_car_form.dart';
import 'package:consumption/inner_screens/list_cars.dart';
import 'package:consumption/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '../auth_screens/home_screen.dart';
import '../components/components.dart';
import '../helper/firebase.dart';
import '../helper/flutter_flow/flutter_flow_icon_button.dart';
import '../helper/flutter_flow/flutter_flow_theme.dart';
import '../models/car_entry.dart';

enum Operation { modify, add }

class MyEntries extends StatefulWidget {
  @override
  _MyEntriesState createState() => _MyEntriesState();
}

class _MyEntriesState extends State<MyEntries> {
  int currentFuelValue = 0;
  int currentDistanceValue = 0;
  TextEditingController fuelController = TextEditingController();
  TextEditingController distanceController = TextEditingController();
  List<CarEntry> ownCars = [];

  Future<List<CarEntry>> _loadCarEntryData() async {
    // Load the data asynchronously
    final data = await loadCarEntrysFromFirestore();

    // Return the loaded data
    return data;
  }

  @override
  void initState() {
    // TODO: implement initState
    isLoggedIn = FirebaseAuth.instance.currentUser != null;
    super.initState();
    if (isLoggedIn) {
      _loadCarEntryData().then((value) {
        setState(() {
          //only load where auth.email matches username
          ownCars = value
              .where(
                  (element) => element.ownerUsername == auth.currentUser!.email)
              .toList();
          for (var x in ownCars) {
            x.refreshConsumption();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          title: Text(
            'My vehicles',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 22,
                ),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(isLoggedIn ? Icons.lock_open : Icons.lock),
              color: isLoggedIn ? Colors.black : Colors.white,
              onPressed: () {
                if (isLoggedIn) {
                  // Logout
                  FirebaseAuth.instance.signOut();
                  setState(() {
                    Navigator.of(context).pushNamed(ListCarsScreen.id);
                    isLoggedIn = false;
                  });
                } else {
                  // Navigate to login screen
                  Navigator.of(context).pushNamed(HomeScreen.id);
                }
              },
            ),
          ],
          centerTitle: false,
          elevation: 2,
        ),
        body: ListView.builder(
          itemCount: ownCars.length,
          itemBuilder: (BuildContext context, int index) {
            CarEntry car = ownCars[index];
            return Dismissible(
              key: ValueKey<int>(ownCars[index].id),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 1),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 0,
                        color: Color(0xFFE0E3E7),
                        offset: Offset(0, 1),
                      )
                    ],
                    borderRadius: BorderRadius.circular(0),
                    shape: BoxShape.rectangle,
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                12, 0, 0, 0),
                            child: Text(
                              '${car.make} ${car.model}',
                              style: FlutterFlowTheme.of(context)
                                  .labelLarge
                                  .override(
                                    fontFamily: 'Readex Pro',
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: const AlignmentDirectional(-1.00, 0.00),
                          child: Container(
                            width: 100,
                            height: 30,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                            ),
                            child: Align(
                              alignment:
                                  const AlignmentDirectional(-1.00, 0.00),
                              child: Text(
                                '${car.consumption} L/100km',
                                style: FlutterFlowTheme.of(context).bodyMedium,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(0, 0, 15, 0),
                          child: FlutterFlowIconButton(
                            borderRadius: 10,
                            borderWidth: 1,
                            buttonSize: 30,
                            icon: Icon(
                              Icons.local_gas_station,
                              color: FlutterFlowTheme.of(context).primaryText,
                              size: 20,
                            ),
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Add fuel'),
                                      content: Container(
                                        height: 200,
                                        child: Row(
                                          children: [
                                            const Text('Fuel amount: '),
                                            Expanded(
                                              child: TextField(
                                                controller: fuelController,
                                                keyboardType:
                                                    TextInputType.number,
                                                onChanged: (String newValue) {
                                                  currentFuelValue = int.parse(
                                                      fuelController.text);
                                                },
                                                onTapOutside: (newValue) {
                                                  currentFuelValue = int.parse(
                                                      fuelController.text);
                                                },
                                                onSubmitted: (value) => {
                                                  currentFuelValue = int.parse(
                                                      fuelController.text)
                                                },
                                                decoration:
                                                    const InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        hintText: 'Amount'),
                                              ),
                                            ),
                                            const Text('Current km in car:'),
                                            Expanded(
                                              child: TextField(
                                                controller: distanceController,
                                                keyboardType:
                                                    TextInputType.number,
                                                onChanged: (String newValue) {
                                                  currentDistanceValue =
                                                      int.parse(
                                                          distanceController
                                                              .text);
                                                },
                                                onTapOutside: (newValue) {
                                                  currentDistanceValue =
                                                      int.parse(
                                                          distanceController
                                                              .text);
                                                },
                                                onSubmitted: (value) => {
                                                  currentDistanceValue =
                                                      int.parse(
                                                          distanceController
                                                              .text)
                                                },
                                                decoration:
                                                    const InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        hintText: 'Amount'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Cancel')),
                                        TextButton(
                                            onPressed: () {
                                              setState(() {
                                                ownCars[index].fuelSum +=
                                                    currentFuelValue;
                                                ownCars[index].drivenKm =
                                                    currentDistanceValue;
                                                ownCars[index]
                                                        .drivenKmSincePurchase =
                                                    currentDistanceValue;
                                                ownCars[index]
                                                    .refreshConsumption();
                                                Navigator.of(context).pop();
                                              });
                                            },
                                            child: const Text('Save')),
                                      ],
                                    );
                                  });
                            },
                          ),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => AddCarForm(
                                    car: ownCars[index],
                                    operation: Operation.modify)));
                          },
                          child: Card(
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  4, 4, 4, 4),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => AddCarForm(
                                          car: ownCars[index],
                                          operation: Operation.modify)));
                                },
                                child: Icon(
                                  Icons.keyboard_arrow_right_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              onDismissed: (direction) {
                setState(() {
                  removeEntry(ownCars[index].id);
                });
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: "btn2",
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AddCarForm(
                    car: CarEntry.empty(), operation: Operation.add)));
          },
          backgroundColor: FlutterFlowTheme.of(context).primary,
          elevation: 8,
          child: Icon(
            Icons.add,
            color: FlutterFlowTheme.of(context).info,
            size: 24,
          ),
        ));
  }

  void removeEntry(int id) {
    ownCars.removeWhere((element) => element.id == id);
  }
}

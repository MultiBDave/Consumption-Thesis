import 'package:consumption/auth_screens/home_screen.dart';
import 'package:consumption/auth_screens/login_screen.dart';
import 'package:consumption/home_page.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../helper/firebase.dart';
import '../helper/flutter_flow/flutter_flow_drop_down.dart';
import '../helper/flutter_flow/flutter_flow_theme.dart';
import '../helper/flutter_flow/flutter_flow_util.dart';
import '../helper/flutter_flow/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/car_entry.dart';
import '../models/home_page_model.dart';
import 'forms/add_car_form.dart';
export '../models/home_page_model.dart';

class ListCarsScreen extends StatefulWidget {
  const ListCarsScreen({Key? key}) : super(key: key);
  static String id = 'list_screen';

  @override
  _ListCarsScreenState createState() => _ListCarsScreenState();
}

class _ListCarsScreenState extends State<ListCarsScreen> {
  late ListCarsScreenModel _model;
  List<CarEntry> allCars = [];

  List<String> makes = [];
  List<String> models = [];

  List<String> colorList = ['Red', 'Blue', 'Green', 'Yellow', 'Black', 'White'];
  List<String> carList = [
    'Wagon',
    'Sedan',
    'Hatchback',
    'SUV',
    'Coupe',
    'Convertible',
    'Van',
    'Pickup',
    'Minivan',
    'Bus',
    'Truck',
    'Motorcycle',
    'Other'
  ];

  List<CarEntry> filteredAllCars = [];

  int currentYearMinValue = 1900;
  int currentYearMaxValue = 2023;
  String currentColorTextFormFieldValue = '';
  String currentLocationTextFormFieldValue = '';
  String currentTypeTextFormFieldValue = '';
  int currentKmMaxTextFormFieldValue = 2000000;
  int currentKmMinTextFormFieldValue = 0;

  TextEditingController minKmController = TextEditingController();
  TextEditingController maxKmController = TextEditingController();
  TextEditingController minYearController = TextEditingController();
  TextEditingController maxYearController = TextEditingController();
  TextEditingController colorController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController typeController = TextEditingController();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Future<List<CarEntry>> _loadCarEntryData() async {
    // Load the data asynchronously
    final data = await loadCarEntrysFromFirestore();

    // Return the loaded data
    return data;
  }

  @override
  void initState() {
    isLoggedIn = FirebaseAuth.instance.currentUser != null;
    super.initState();
    _model = createModel(context, () => ListCarsScreenModel());
    _loadCarEntryData().then((value) {
      setState(() {
        allCars = value;
        filteredAllCars = value;
      });
    });
  }

  void filterCars() {
    List<CarEntry> deeperFilteredCars = filteredAllCars;

    // Filter by Min-Max Km
    if (minKmController.text.isNotEmpty) {
      deeperFilteredCars = deeperFilteredCars
          .where((car) => car.drivenKm >= int.parse(minKmController.text))
          .toList();
    }
    if (maxKmController.text.isNotEmpty) {
      deeperFilteredCars = deeperFilteredCars
          .where((car) => car.drivenKm <= int.parse(maxKmController.text))
          .toList();
    }

    // Filter by Car Color
    if (currentColorTextFormFieldValue.isNotEmpty) {
      deeperFilteredCars = deeperFilteredCars
          .where((car) => car.color == currentColorTextFormFieldValue)
          .toList();
    }

    // Filter by Location
    if (locationController.text.isNotEmpty) {
      deeperFilteredCars = deeperFilteredCars
          .where((car) => car.location == locationController.text)
          .toList();
    }

    // Filter by Car Type
    if (typeController.text.isNotEmpty) {
      deeperFilteredCars = deeperFilteredCars
          .where((car) => car.type == typeController.text)
          .toList();
    }

    // Filter by Min-Max Year
    deeperFilteredCars = deeperFilteredCars
        .where((car) => car.year >= currentYearMinValue)
        .toList();
    deeperFilteredCars = deeperFilteredCars
        .where((car) => car.year <= currentYearMaxValue)
        .toList();

    // Now 'deeperFilteredCars' contains the filtered list based on all criteria
    // You can use this filtered list as needed.
    filteredAllCars = deeperFilteredCars;
  }

  void resetFilters() {
    setState(() {
      filteredAllCars = allCars.where((car) {
        return (car.make == _model.dropDownValue1 ||
                _model.dropDownValue1 == 'All') &&
            (car.model == _model.dropDownValue2 ||
                _model.dropDownValue2 == 'All');
      }).toList();
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isiOS) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarBrightness: Theme.of(context).brightness,
          systemStatusBarContrastEnforced: true,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Filter Cars'),
                  content: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        // Add your filter options here
                        TextFormField(
                          keyboardType: TextInputType.number,
                          controller: minKmController,
                          decoration: const InputDecoration(
                            labelText: 'Min KM',
                            // other decoration properties
                          ),
                        ),
                        TextFormField(
                          keyboardType: TextInputType.number,
                          controller: maxKmController,
                          decoration: const InputDecoration(
                            labelText: 'Max KM',
                            // other decoration properties
                          ),
                        ),

                        // Dropdown for Car Color
                        DropdownButtonFormField(
                          value: colorList.firstWhere(
                              (element) =>
                                  element == currentColorTextFormFieldValue,
                              orElse: () => colorList[0]),
                          items: colorList.map((color) {
                            return DropdownMenuItem(
                              value: color,
                              child: Text(color),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              currentColorTextFormFieldValue = value.toString();
                            });
                          },
                          decoration:
                              const InputDecoration(labelText: 'Car Color'),
                        ),
                        // Location Picker
                        ElevatedButton(
                          onPressed: () {
                            showCountryPicker(
                              context: context,
                              onSelect: (Country country) {
                                setState(() {
                                  locationController.text = country.displayName;
                                });
                              },
                            );
                          },
                          child: Text('Pick Location'),
                        ),
                        // TextFormField for Car Type
                        TextFormField(
                          controller: typeController,
                          decoration:
                              const InputDecoration(labelText: 'Car Type'),
                        ),

                        TextFormField(
                          controller: minYearController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Min Year',
                            // other decoration properties
                          ),
                          onTap: () => {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Select year'),
                                    content: Container(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: 100,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          return ListTile(
                                            title: Text(
                                                (DateTime.now().year - index)
                                                    .toString()),
                                            onTap: () {
                                              setState(() {
                                                currentYearMinValue =
                                                    (DateTime.now().year -
                                                        index);
                                              });
                                              Navigator.of(context).pop();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                })
                          },
                          onChanged: (String newValue) {
                            currentYearMinValue = int.parse(newValue);
                            minYearController.text = newValue;
                          },
                        ),
                        TextFormField(
                          controller: maxYearController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max Year',
                            // other decoration properties
                          ),
                          onTap: () => {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Select year'),
                                    content: Container(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: 100,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          return ListTile(
                                            title: Text(
                                                (DateTime.now().year - index)
                                                    .toString()),
                                            onTap: () {
                                              setState(() {
                                                currentYearMaxValue =
                                                    (DateTime.now().year -
                                                        index);
                                              });
                                              Navigator.of(context).pop();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                })
                          },
                          onChanged: (String newValue) {
                            setState(() {
                              maxYearController.text = newValue;
                              currentYearMaxValue = int.parse(newValue);
                            });
                          },
                        ),
                        // Add more TextFormField or DropdownButtonFormField widgets for other fields
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text('Apply'),
                      onPressed: () {
                        setState(() {
                          filterCars();
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
          backgroundColor: FlutterFlowTheme.of(context).primary,
          elevation: 8,
          child: Icon(
            Icons.filter_alt,
            color: FlutterFlowTheme.of(context).info,
            size: 24,
          ),
        ),
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          title: Text(
            'Consumption meter',
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
                    isLoggedIn = false;
                  });
                } else {
                  Navigator.of(context).pushNamed(HomeScreen.id);
                }
              },
            ),
          ],
          centerTitle: false,
          elevation: 2,
        ),
        body: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                FlutterFlowDropDown(
                  controller: _model.dropDownValueController1 ??=
                      FormFieldController<String>(null),
                  options: makes,
                  onChanged: (val) => {
                    setState(() => _model.dropDownValue1 = val),
                    if (val != 'All' || val != null)
                      {
                        filteredAllCars =
                            allCars.where((car) => car.make == val).toList(),
                      },
                    filterCars(),
                  },
                  width: 150,
                  height: 50,
                  textStyle: FlutterFlowTheme.of(context).bodyMedium,
                  hintText: 'Make',
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: FlutterFlowTheme.of(context).secondaryText,
                    size: 24,
                  ),
                  fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                  elevation: 2,
                  borderColor: FlutterFlowTheme.of(context).alternate,
                  borderWidth: 2,
                  borderRadius: 8,
                  margin: EdgeInsetsDirectional.fromSTEB(16, 4, 16, 4),
                  hidesUnderline: true,
                ),
                Flexible(
                  child: Align(
                    alignment: AlignmentDirectional(1.00, 0.00),
                    child: FlutterFlowDropDown(
                      controller: _model.dropDownValueController2 ??=
                          FormFieldController<String>(null),
                      options: models,
                      onChanged: (val) => {
                        setState(() => _model.dropDownValue2 = val),
                        if (val != 'All' || val != null)
                          {
                            filteredAllCars = allCars
                                .where((car) => car.model == val)
                                .toList(),
                          },
                        filterCars(),
                      },
                      width: 150,
                      height: 50,
                      textStyle: FlutterFlowTheme.of(context).bodyMedium,
                      hintText: 'Model',
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: FlutterFlowTheme.of(context).secondaryText,
                        size: 24,
                      ),
                      fillColor:
                          FlutterFlowTheme.of(context).secondaryBackground,
                      elevation: 2,
                      borderColor: FlutterFlowTheme.of(context).alternate,
                      borderWidth: 2,
                      borderRadius: 8,
                      margin: EdgeInsetsDirectional.fromSTEB(16, 4, 16, 4),
                      hidesUnderline: true,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 1),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        boxShadow: [
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
                        padding: EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    EdgeInsetsDirectional.fromSTEB(12, 0, 0, 0),
                                child: Text(
                                  'Vehicle',
                                  style: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .override(
                                        fontFamily: 'Readex Pro',
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional(-1.00, 0.00),
                              child: Container(
                                width: 100,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                ),
                                child: Align(
                                  alignment: AlignmentDirectional(-1.00, 0.00),
                                  child: Text(
                                    'Mileage',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Readex Pro',
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 100,
                              height: 30,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional(-1.00, 0.00),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      12, 0, 0, 0),
                                  child: Text(
                                    'User',
                                    style: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          fontFamily: 'Readex Pro',
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          fontWeight: FontWeight.bold,
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
                  Expanded(
                    child: ListView.builder(
                        itemCount: filteredAllCars.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 0, 0, 1),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
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
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    8, 8, 8, 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(12, 0, 0, 0),
                                        child: Text(
                                          '${filteredAllCars[index].make} ${filteredAllCars[index].model} ${filteredAllCars[index].year}',
                                          style: FlutterFlowTheme.of(context)
                                              .labelLarge
                                              .override(
                                                fontFamily: 'Readex Pro',
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                              ),
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: const AlignmentDirectional(
                                          -1.00, 0.00),
                                      child: Container(
                                        width: 100,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                        ),
                                        child: Align(
                                          alignment: const AlignmentDirectional(
                                              -1.00, 0.00),
                                          child: Text(
                                            '${filteredAllCars[index].consumption} km',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 100,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                      ),
                                      child: Align(
                                        alignment: const AlignmentDirectional(
                                            -1.00, 0.00),
                                        child: Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(12, 0, 0, 0),
                                          child: Text(
                                            '${filteredAllCars[index].ownerUsername} km',
                                            style: FlutterFlowTheme.of(context)
                                                .labelMedium,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

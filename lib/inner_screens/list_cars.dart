import 'package:consumption/auth_screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helper/firebase.dart';
import '../helper/flutter_flow/flutter_flow_theme.dart';
import '../main.dart';
import '../models/car_entry.dart';
import '../models/home_page_model.dart';
export '../models/home_page_model.dart';

class ListCarsScreen extends StatefulWidget {
  const ListCarsScreen({super.key});
  static String id = 'list_screen';

  @override
  _ListCarsScreenState createState() => _ListCarsScreenState();
}

class _ListCarsScreenState extends State<ListCarsScreen> {
  late ListCarsScreenModel _model;
  List<CarEntry> allCars = [];

  List<String> makes = [];
  List<String> models = [];
  late Map<String, List<String>> modelsByMake = {};
  String currentMakeTextFormFieldValue = '';
  String currentModelTextFormFieldValue = '';

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
  int currentYearMaxValue = DateTime.now().year;
  String currentColorTextFormFieldValue = '';
  String currentLocationTextFormFieldValue = '';
  String currentTypeTextFormFieldValue = '';
  int currentKmMaxTextFormFieldValue = 2000000;
  int currentKmMinTextFormFieldValue = 0;

  TextEditingController minKmController = TextEditingController();
  TextEditingController maxKmController = TextEditingController();
  TextEditingController minYearController = TextEditingController(text: "1900");
  TextEditingController maxYearController = TextEditingController(text: DateTime.now().year.toString());
  TextEditingController colorController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController typeController = TextEditingController();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // New state variables for CSV makes/models
  List<String> csvMakes = [];
  Map<String, List<String>> csvModelsByMake = {};
  String currentMakeFilter = '';
  String currentModelFilter = '';

  // Helper function to convert color string to Color
  Color getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      case 'black': return Colors.black;
      case 'white': return Colors.white;
      default: return Colors.grey;
    }
  }

  Future<List<CarEntry>> _loadCarEntryData() async {
    // Load the data asynchronously
    final data = await loadCarEntrysFromFirestore();

    // Update consumption and range for all cars
    for (var car in data) {
      car.refreshConsumption();
    }

    // Return the loaded data
    return data;
  }

  @override
  void initState() {
    super.initState();
    isLoggedIn = FirebaseAuth.instance.currentUser != null;
    loadCsvData();
    _loadCarEntryData().then((value) {
      setState(() {
        filteredAllCars = value;
        allCars = value;
      });
    });
  }

  Future<void> loadCsvData() async {
    final rawData = await rootBundle.loadString('assets/csv/2020.csv');
    final lines = rawData.split('\n');
    final header = lines.first.split(',');
    final int makeIndex = header.indexOf('make');
    final int modelIndex = header.indexOf('model');
    for (var i = 1; i < lines.length; i++) {
      final cols = lines[i].split(',');
      if (cols.length <= modelIndex) continue;
      final make = cols[makeIndex];
      final model = cols[modelIndex];
      if (!makes.contains(make)) makes.add(make);
      modelsByMake.putIfAbsent(make, () => []);
      if (!modelsByMake[make]!.contains(model)) modelsByMake[make]!.add(model);
    }
  }

  void filterCars() {
    List<CarEntry> deeperFilteredCars = allCars;

    // Parse values from controllers, handling null/empty values
    final minKm = minKmController.text.isEmpty ? null : int.tryParse(minKmController.text);
    final maxKm = maxKmController.text.isEmpty ? null : int.tryParse(maxKmController.text);
    final minYear = minYearController.text.isEmpty ? currentYearMinValue : int.tryParse(minYearController.text) ?? currentYearMinValue;
    final maxYear = maxYearController.text.isEmpty ? currentYearMaxValue : int.tryParse(maxYearController.text) ?? currentYearMaxValue;

    // Update the current values
    currentYearMinValue = minYear;
    currentYearMaxValue = maxYear;

    // Filter by Min-Max Km
    if (minKm != null) {
      deeperFilteredCars = deeperFilteredCars
          .where((car) => car.drivenKm >= minKm)
          .toList();
    }

    if (maxKm != null) {
      deeperFilteredCars = deeperFilteredCars
          .where((car) => car.drivenKm <= maxKm)
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
          .where((car) => car.location.toLowerCase().contains(
                locationController.text.toLowerCase(),
              ))
          .toList();
    }

    // Filter by Car Type
    if (typeController.text.isNotEmpty) {
      deeperFilteredCars = deeperFilteredCars
          .where((car) => car.type == typeController.text)
          .toList();
    }
    // Filter by Make
    if (currentMakeTextFormFieldValue.isNotEmpty) {
      deeperFilteredCars = deeperFilteredCars
          .where((car) => car.make == currentMakeTextFormFieldValue)
          .toList();
    }
    // Filter by Model
    if (currentModelTextFormFieldValue.isNotEmpty) {
      deeperFilteredCars = deeperFilteredCars
          .where((car) => car.model == currentModelTextFormFieldValue)
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
      minKmController.clear();
      maxKmController.clear();
      minYearController.text = "1900";
      maxYearController.text = DateTime.now().year.toString();
      currentColorTextFormFieldValue = '';
      locationController.clear();
      typeController.clear();
      currentYearMinValue = 1900;
      currentYearMaxValue = DateTime.now().year;
      currentMakeTextFormFieldValue = '';
      currentModelTextFormFieldValue = '';
      filteredAllCars = allCars;
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        automaticallyImplyLeading: false,
        title: Text(
          'Vehicle search',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 22,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            color: Colors.white,
            onPressed: () {
              showFilterDialog(context);
            },
          ),
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
      body: filteredAllCars.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No vehicles found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try adjusting your search filters',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                final cars = await _loadCarEntryData();
                setState(() {
                  allCars = cars;
                  filterCars();
                });
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: filteredAllCars.length,
                itemBuilder: (BuildContext context, int index) {
                  final car = filteredAllCars[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 6,
                          color: getColorFromString(car.color),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${car.make} ${car.model}',
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            fontFamily: 'Readex Pro',
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    '${car.year}',
                                    style: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          fontFamily: 'Readex Pro',
                                          color: Colors.black,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_gas_station,
                                    size: 16,
                                    color: FlutterFlowTheme.of(context).secondaryText,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Consumption: ${car.consumption} L/100km',
                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              if (car.tankSize > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.map,
                                        size: 16,
                                        color: FlutterFlowTheme.of(context).primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Est. range: ${car.estimatedRange}',
                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                              fontFamily: 'Readex Pro',
                                              color: Colors.black,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.speed,
                                    size: 16,
                                    color: FlutterFlowTheme.of(context).secondaryText,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${car.drivenKm} km',
                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                          fontFamily: 'Readex Pro',
                                          color: Colors.black,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: FlutterFlowTheme.of(context).secondaryText,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Owner: ${car.ownerUsername}',
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                            fontFamily: 'Readex Pro',
                                            color: Colors.black,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: FlutterFlowTheme.of(context).secondaryText,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Location: ${car.location}',
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                            fontFamily: 'Readex Pro',
                                            color: Colors.black,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.car_repair,
                                    size: 16,
                                    color: FlutterFlowTheme.of(context).secondaryText,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    car.type,
                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                          fontFamily: 'Readex Pro',
                                          color: Colors.black,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  void showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(VoidCallback) setStateDialog) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.filter_list),
                  SizedBox(width: 8),
                  Text('Filter vehicles'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                     DropdownButtonFormField<String>(
                       decoration: InputDecoration(
                         labelText: 'Make',
                         enabledBorder: OutlineInputBorder(
                           borderSide: BorderSide(
                             color: FlutterFlowTheme.of(context).alternate,
                             width: 2,
                           ),
                           borderRadius: BorderRadius.circular(8),
                         ),
                       ),
                       value: currentMakeTextFormFieldValue.isEmpty ? null : currentMakeTextFormFieldValue,
                       items: [
                         const DropdownMenuItem(value: '', child: Text('All makes')),
                         ...makes.map((make) => DropdownMenuItem(value: make, child: Text(make))),
                       ],
                       onChanged: (value) {
                         setStateDialog(() {
                           currentMakeTextFormFieldValue = value ?? ''; models = modelsByMake[currentMakeTextFormFieldValue] ?? []; currentModelTextFormFieldValue = '';
                         });
                       },
                     ),
                     const SizedBox(height: 12),
                     DropdownButtonFormField<String>(
                       decoration: InputDecoration(
                         labelText: 'Model',
                         enabledBorder: OutlineInputBorder(
                           borderSide: BorderSide(
                             color: FlutterFlowTheme.of(context).alternate,
                             width: 2,
                           ),
                           borderRadius: BorderRadius.circular(8),
                         ),
                       ),
                       value: currentModelTextFormFieldValue.isEmpty ? null : currentModelTextFormFieldValue,
                       items: [
                         const DropdownMenuItem(value: '', child: Text('All models')),
                         ...models.map((model) => DropdownMenuItem(value: model, child: Text(model))),
                       ],
                       onChanged: (value) {
                         setStateDialog(() {
                           currentModelTextFormFieldValue = value ?? '';
                         });
                       },
                     ),
                     const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Color',
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: currentColorTextFormFieldValue.isEmpty ? null : currentColorTextFormFieldValue,
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('All colors'),
                          ),
                          ...colorList.map((color) => DropdownMenuItem(
                                value: color,
                                child: Text(color),
                              )),
                        ],
                        onChanged: (value) {
                         setStateDialog(() {
                            currentColorTextFormFieldValue = value ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Type',
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: typeController.text.isEmpty ? null : typeController.text,
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('All types'),
                          ),
                          ...carList.map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              )),
                        ],
                        onChanged: (value) {
                         setStateDialog(() {
                            typeController.text = value ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                         controller: locationController,
                         decoration: InputDecoration(
                           labelText: 'Location',
                           enabledBorder: OutlineInputBorder(
                             borderSide: BorderSide(
                               color: FlutterFlowTheme.of(context).alternate,
                               width: 2,
                             ),
                             borderRadius: BorderRadius.circular(8),
                           ),
                         ),
                         onChanged:(v){setStateDialog((){});}
                       ),
                       const SizedBox(height: 16),
                      Text('Mileage range', style: FlutterFlowTheme.of(context).labelLarge),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minKmController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Min km',
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).alternate,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (v) => setStateDialog(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: maxKmController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Max km',
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).alternate,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (v) => setStateDialog(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Year range', style: FlutterFlowTheme.of(context).labelLarge),
                      const SizedBox(height: 12),
                      RangeSlider(
                        values: RangeValues(
                          currentYearMinValue.toDouble(),
                          currentYearMaxValue.toDouble(),
                        ),
                        min: 1900,
                        max: DateTime.now().year.toDouble(),
                        divisions: DateTime.now().year - 1900,
                        labels: RangeLabels(
                          currentYearMinValue.toString(),
                          currentYearMaxValue.toString(),
                        ),
                        onChanged: (RangeValues values) {
                         setStateDialog(() {
                            currentYearMinValue = values.start.round();
                            currentYearMaxValue = values.end.round();
                            minYearController.text = currentYearMinValue.toString();
                            maxYearController.text = currentYearMaxValue.toString();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Reset'),
                  onPressed: () {
                    resetFilters();
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                  ),
                  onPressed: () {
                    setState(() {
                      filterCars();
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('Apply'),
                ),
              ],
            );
         }
       );
      },
    );
  }
}

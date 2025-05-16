import 'package:consumption/auth_screens/login_screen.dart';
import 'package:consumption/home_page.dart';
import 'package:consumption/inner_screens/forms/add_car_form.dart';
import 'package:consumption/inner_screens/list_cars.dart';
import 'package:consumption/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/services.dart';

import '../auth_screens/home_screen.dart';
import '../helper/firebase.dart';
import '../helper/flutter_flow/flutter_flow_icon_button.dart';
import '../helper/flutter_flow/flutter_flow_theme.dart';
import '../models/car_entry.dart';
import '../../components/components.dart';

enum Operation { modify, add }

class MyEntries extends StatefulWidget {
  const MyEntries({super.key});

  @override
  _MyEntriesState createState() => _MyEntriesState();
}

class CsvRecord {
  final int year;
  final String make;
  final String model;
  CsvRecord({required this.year, required this.make, required this.model});
}

class _MyEntriesState extends State<MyEntries> {
  int currentFuelValue = 0;
  int currentDistanceValue = 0;
  TextEditingController fuelController = TextEditingController();
  TextEditingController distanceController = TextEditingController();
  List<CarEntry> ownCars = [];
  List<CsvRecord> csvRecords = [];
  List<int> csvYears = [];
  Map<int, List<String>> csvMakesByYear = {};
  Map<String, List<String>> csvModelsByYearMake = {};

  // Helper function to convert color string to Color
  Color getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      default:
        return Colors.grey;
    }
  }

  Future<List<CarEntry>> _loadCarEntryData() async {
    // Load the data asynchronously
    final data = await loadCarEntrysFromFirestore();

    // Return the loaded data
    return data;
  }

  void _refreshCarList() {
    if (isLoggedIn) {
      _loadCarEntryData().then((value) {
        setState(() {
          //only load where auth.email matches username
          ownCars = value
              .where(
                  (element) => element.ownerUsername == auth.currentUser!.email)
              .toList();

          // Update all cars' consumption and range estimates
          for (var car in ownCars) {
            car.refreshConsumption();
          }
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Check login status
    isLoggedIn = FirebaseAuth.instance.currentUser != null;

    loadCsvAsset();
    _refreshCarList();
  }

  Future<void> loadCsvAsset() async {
    final raw = await rootBundle.loadString('assets/csv/2020.csv');
    final lines = raw.split('\n');
    for (var line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(',');
      final year = int.tryParse(parts[0]) ?? 0;
      final make = parts[1];
      final model = parts[2];
      csvRecords.add(CsvRecord(year: year, make: make, model: model));
    }
    csvYears = csvRecords.map((e) => e.year).toSet().toList()..sort();
    for (var r in csvRecords) {
      csvMakesByYear.putIfAbsent(r.year, () => []).add(r.make);
    }
    csvMakesByYear.forEach((y, list) {
      csvMakesByYear[y] = list.toSet().toList()..sort();
    });
    for (var r in csvRecords) {
      final key = '${r.year}|${r.make}';
      csvModelsByYearMake.putIfAbsent(key, () => []).add(r.model);
    }
    csvModelsByYearMake.forEach((k, list) {
      csvModelsByYearMake[k] = list.toSet().toList()..sort();
    });
    setState(() {});
  }

  void _deleteVehicle(CarEntry car) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Vehicle'),
          content: const Text('Are you sure you want to delete this vehicle?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  removeCarEntryFromDb(car.id);
                  removeEntry(car.id);
                });
                Navigator.of(context).pop();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
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
                  isLoggedIn = false;
                  ownCars.clear();
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
      body: ownCars.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No vehicles yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first vehicle with the + button',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: ownCars.length,
              itemBuilder: (BuildContext context, int index) {
                CarEntry car = ownCars[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: Text(
                                '${car.make} ${car.model} (${car.year})',
                                style: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .override(
                                      fontFamily: 'Readex Pro',
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: getColorFromString(car.color),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
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
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Readex Pro',
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                  ),
                            ),
                            if (car.initialKm > 0)
                              Text(
                                ' (initial: ${car.initialKm} km)',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Readex Pro',
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      fontSize: 12,
                                    ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
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
                              style: FlutterFlowTheme.of(context).bodyMedium,
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
                                  'Est. range with full tank: ${car.estimatedRange}',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Readex Pro',
                                        color: FlutterFlowTheme.of(context).primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FlutterFlowIconButton(
                              borderRadius: 20,
                              borderWidth: 1,
                              buttonSize: 40,
                              fillColor: FlutterFlowTheme.of(context).accent1,
                              icon: Icon(
                                Icons.local_gas_station,
                                color: FlutterFlowTheme.of(context).primaryBackground,
                                size: 20,
                              ),
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      fuelController.clear();
                                      distanceController.text = car.drivenKm.toString();
                                      return AlertDialog(
                                        title: const Text('Add fuel'),
                                        content: SizedBox(
                                          height: 180,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    flex: 2,
                                                    child: Text('Fuel amount (liters):'),
                                                  ),
                                                  Expanded(
                                                    flex: 3,
                                                    child: TextField(
                                                      controller: fuelController,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      onChanged: (String newValue) {
                                                        if (newValue.isNotEmpty) {
                                                          currentFuelValue = int.parse(
                                                              fuelController.text);
                                                        }
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
                                              const SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    flex: 2,
                                                    child: Text('Current odometer:'),
                                                  ),
                                                  Expanded(
                                                    flex: 3,
                                                    child: TextField(
                                                      controller: distanceController,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      onChanged: (String newValue) {
                                                        if (newValue.isNotEmpty) {
                                                          currentDistanceValue =
                                                              int.parse(
                                                                  distanceController
                                                                      .text);
                                                        }
                                                      },
                                                      decoration:
                                                          const InputDecoration(
                                                              border:
                                                                  OutlineInputBorder(),
                                                              hintText: 'Km'),
                                                    ),
                                                  ),
                                                ],
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
                                                if (fuelController.text.isEmpty ||
                                                    distanceController.text.isEmpty) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Please fill in all fields'))
                                                  );
                                                  return;
                                                }

                                                setState(() {
                                                  ownCars[index].fuelSum +=
                                                      currentFuelValue;
                                                  ownCars[index].drivenKm =
                                                      currentDistanceValue;
                                                  ownCars[index]
                                                      .refreshConsumption();

                                                  // Update the car in the database
                                                  modifyCarEntryInDb(ownCars[index]);

                                                  Navigator.of(context).pop();
                                                });
                                              },
                                              child: const Text('Save')),
                                        ],
                                      );
                                    });
                              },
                            ),
                            const SizedBox(width: 8),
                            FlutterFlowIconButton(
                              borderRadius: 20,
                              borderWidth: 1,
                              buttonSize: 40,
                              fillColor: FlutterFlowTheme.of(context).tertiary,
                              icon: Icon(
                                Icons.edit,
                                color: FlutterFlowTheme.of(context).primaryBackground,
                                size: 20,
                              ),
                              onPressed: () async {
                                await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Dialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Edit Vehicle',
                                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                                              ),
                                              const SizedBox(height: 16),
                                              TextField(
                                                controller: TextEditingController(text: ownCars[index].make),
                                                decoration: const InputDecoration(labelText: 'Make', border: OutlineInputBorder()),
                                                onChanged: (val) => ownCars[index].make = val,
                                              ),
                                              const SizedBox(height: 12),
                                              TextField(
                                                controller: TextEditingController(text: ownCars[index].model),
                                                decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
                                                onChanged: (val) => ownCars[index].model = val,
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextField(
                                                      controller: TextEditingController(text: ownCars[index].year.toString()),
                                                      decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                                                      keyboardType: TextInputType.number,
                                                      onChanged: (val) => ownCars[index].year = int.tryParse(val) ?? ownCars[index].year,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: TextField(
                                                      controller: TextEditingController(text: ownCars[index].color),
                                                      decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder()),
                                                      onChanged: (val) => ownCars[index].color = val,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              TextField(
                                                controller: TextEditingController(text: ownCars[index].type),
                                                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                                                onChanged: (val) => ownCars[index].type = val,
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextField(
                                                      controller: TextEditingController(text: ownCars[index].drivenKm.toString()),
                                                      decoration: const InputDecoration(labelText: 'Odometer (km)', border: OutlineInputBorder()),
                                                      keyboardType: TextInputType.number,
                                                      onChanged: (val) => ownCars[index].drivenKm = int.tryParse(val) ?? ownCars[index].drivenKm,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: TextField(
                                                      controller: TextEditingController(text: ownCars[index].initialKm.toString()),
                                                      decoration: const InputDecoration(labelText: 'Initial km', border: OutlineInputBorder()),
                                                      keyboardType: TextInputType.number,
                                                      onChanged: (val) => ownCars[index].initialKm = int.tryParse(val) ?? ownCars[index].initialKm,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              TextField(
                                                controller: TextEditingController(text: ownCars[index].tankSize.toString()),
                                                decoration: const InputDecoration(labelText: 'Tank size (L)', border: OutlineInputBorder()),
                                                keyboardType: TextInputType.number,
                                                onChanged: (val) => ownCars[index].tankSize = int.tryParse(val) ?? ownCars[index].tankSize,
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.black,
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        modifyCarEntryInDb(ownCars[index]);
                                                      });
                                                      Navigator.of(context).pop();
                                                      _refreshCarList();
                                                    },
                                                    child: const Text('Save'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            FlutterFlowIconButton(
                              borderRadius: 20,
                              borderWidth: 1,
                              buttonSize: 40,
                              fillColor: Colors.red,
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                _deleteVehicle(car);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) {
              CarEntry newCar = CarEntry.empty();
              int? selectedYear;
              String? selectedMake;
              String? selectedModel;
              return StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add Vehicle',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            const SizedBox(height: 16),
                            // Year dropdown
                            DropdownButtonFormField<int>(
                              decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                              value: selectedYear,
                              items: csvYears.map((y) => DropdownMenuItem<int>(value: y, child: Text(y.toString()))).toList(),
                              onChanged: (val) => setStateDialog(() {
                                selectedYear = val;
                                newCar.year = val ?? 0;
                                selectedMake = null;
                                selectedModel = null;
                              }),
                            ),
                            const SizedBox(height: 12),
                            // Make dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: 'Make', border: OutlineInputBorder()),
                              value: selectedMake,
                              items: selectedYear != null
                                  ? csvMakesByYear[selectedYear]!
                                      .map((m) => DropdownMenuItem<String>(value: m, child: Text(m)))
                                      .toList()
                                  : [],
                              onChanged: (val) => setStateDialog(() {
                                selectedMake = val;
                                newCar.make = val ?? '';
                                selectedModel = null;
                              }),
                            ),
                            const SizedBox(height: 12),
                            // Model dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
                              value: selectedModel,
                              items: (selectedYear != null && selectedMake != null)
                                  ? csvModelsByYearMake['${selectedYear}|${selectedMake}']!
                                      .map((mo) => DropdownMenuItem<String>(value: mo, child: Text(mo)))
                                      .toList()
                                  : [],
                              onChanged: (val) => setStateDialog(() {
                                selectedModel = val;
                                newCar.model = val ?? '';
                              }),
                            ),
                            const SizedBox(height: 12),
                            // Color input
                            TextField(
                              decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder()),
                              onChanged: (val) => newCar.color = val,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                              onChanged: (val) => newCar.type = val,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(labelText: 'Odometer (km)', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => newCar.drivenKm = int.tryParse(val) ?? 0,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(labelText: 'Initial km', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => newCar.initialKm = int.tryParse(val) ?? 0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              decoration: const InputDecoration(labelText: 'Tank size (L)', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => newCar.tankSize = int.tryParse(val) ?? 0,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      newCar.id = DateTime.now().millisecondsSinceEpoch;
                                      newCar.ownerUsername = auth.currentUser!.email!;
                                      addCarEntryToDb(newCar);
                                    });
                                    Navigator.of(context).pop();
                                    _refreshCarList();
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        backgroundColor: FlutterFlowTheme.of(context).primary,
        elevation: 4,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void removeEntry(int id) {
    ownCars.removeWhere((element) => element.id == id);
  }
}
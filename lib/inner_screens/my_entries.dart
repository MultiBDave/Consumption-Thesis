import 'package:consumption/auth_screens/login_screen.dart';
import 'package:consumption/home_page.dart';
import 'package:consumption/inner_screens/forms/add_car_form.dart';
import 'package:consumption/inner_screens/list_cars.dart';
import 'package:consumption/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '../auth_screens/home_screen.dart';
import '../helper/firebase.dart';
import '../helper/flutter_flow/flutter_flow_icon_button.dart';
import '../helper/flutter_flow/flutter_flow_theme.dart';
import '../models/car_entry.dart';
import '../../components/components.dart';
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
    
    _refreshCarList();
  }

  void _deleteVehicle(CarEntry car) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Vehicle'),
          content: Text('Are you sure you want to delete this vehicle?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  removeCarEntryFromDb(car.id);
                  removeEntry(car.id);
                });
                Navigator.of(context).pop();
              },
              child: Text(
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
            )
          )
        : ListView.builder(
            itemCount: ownCars.length,
            itemBuilder: (BuildContext context, int index) {
              CarEntry car = ownCars[index];
              
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      Divider(),
                      Row(
                        children: [
                          Icon(
                            Icons.speed,
                            size: 16,
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                          SizedBox(width: 4),
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
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_gas_station,
                            size: 16,
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                          SizedBox(width: 4),
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
                              SizedBox(width: 4),
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
                      SizedBox(height: 8),
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
                                      content: Container(
                                        height: 180,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
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
                                            SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
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
                                                  SnackBar(content: Text('Please fill in all fields'))
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
                          SizedBox(width: 8),
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
                                            Text(
                                              'Edit Vehicle',
                                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                                            ),
                                            SizedBox(height: 16),
                                            TextField(
                                              controller: TextEditingController(text: ownCars[index].make),
                                              decoration: InputDecoration(labelText: 'Make', border: OutlineInputBorder()),
                                              onChanged: (val) => ownCars[index].make = val,
                                            ),
                                            SizedBox(height: 12),
                                            TextField(
                                              controller: TextEditingController(text: ownCars[index].model),
                                              decoration: InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
                                              onChanged: (val) => ownCars[index].model = val,
                                            ),
                                            SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: TextEditingController(text: ownCars[index].year.toString()),
                                                    decoration: InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                                                    keyboardType: TextInputType.number,
                                                    onChanged: (val) => ownCars[index].year = int.tryParse(val) ?? ownCars[index].year,
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: TextField(
                                                    controller: TextEditingController(text: ownCars[index].color),
                                                    decoration: InputDecoration(labelText: 'Color', border: OutlineInputBorder()),
                                                    onChanged: (val) => ownCars[index].color = val,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 12),
                                            TextField(
                                              controller: TextEditingController(text: ownCars[index].type),
                                              decoration: InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                                              onChanged: (val) => ownCars[index].type = val,
                                            ),
                                            SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: TextEditingController(text: ownCars[index].drivenKm.toString()),
                                                    decoration: InputDecoration(labelText: 'Odometer (km)', border: OutlineInputBorder()),
                                                    keyboardType: TextInputType.number,
                                                    onChanged: (val) => ownCars[index].drivenKm = int.tryParse(val) ?? ownCars[index].drivenKm,
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: TextField(
                                                    controller: TextEditingController(text: ownCars[index].initialKm.toString()),
                                                    decoration: InputDecoration(labelText: 'Initial km', border: OutlineInputBorder()),
                                                    keyboardType: TextInputType.number,
                                                    onChanged: (val) => ownCars[index].initialKm = int.tryParse(val) ?? ownCars[index].initialKm,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 12),
                                            TextField(
                                              controller: TextEditingController(text: ownCars[index].tankSize.toString()),
                                              decoration: InputDecoration(labelText: 'Tank size (L)', border: OutlineInputBorder()),
                                              keyboardType: TextInputType.number,
                                              onChanged: (val) => ownCars[index].tankSize = int.tryParse(val) ?? ownCars[index].tankSize,
                                            ),
                                            SizedBox(height: 20),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: Text('Cancel'),
                                                ),
                                                SizedBox(width: 8),
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
                                                  child: Text('Save'),
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
                          SizedBox(width: 8),
                          FlutterFlowIconButton(
                            borderRadius: 20,
                            borderWidth: 1,
                            buttonSize: 40,
                            fillColor: Colors.red,
                            icon: Icon(
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
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Vehicle',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(labelText: 'Make', border: OutlineInputBorder()),
                          onChanged: (val) => newCar.make = val,
                        ),
                        SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
                          onChanged: (val) => newCar.model = val,
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => newCar.year = int.tryParse(val) ?? 0,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(labelText: 'Color', border: OutlineInputBorder()),
                                onChanged: (val) => newCar.color = val,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                          onChanged: (val) => newCar.type = val,
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(labelText: 'Odometer (km)', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => newCar.drivenKm = int.tryParse(val) ?? 0,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(labelText: 'Initial km', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => newCar.initialKm = int.tryParse(val) ?? 0,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(labelText: 'Tank size (L)', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => newCar.tankSize = int.tryParse(val) ?? 0,
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Cancel'),
                            ),
                            SizedBox(width: 8),
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
                              child: Text('Add'),
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
        backgroundColor: FlutterFlowTheme.of(context).primary,
        elevation: 4,
        child: Icon(
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

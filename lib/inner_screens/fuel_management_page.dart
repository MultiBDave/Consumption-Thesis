import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:consumption/helper/firebase.dart';
import 'package:consumption/models/car_entry.dart';
import 'package:flutter/material.dart';

import 'my_entries.dart';

class FuelEntry {
  final int id;
  final int fuelAmount;
  final int carId;
  final double pricePerUnit;
  final int kmDriven;
  Timestamp? date;

  FuelEntry({
    this.id = 0,
    required this.fuelAmount,
    required this.carId,
    required this.pricePerUnit,
    required this.kmDriven,
    this.date,
  });
}

class FuelManagementPage extends StatefulWidget {
  final CarEntry car;

  FuelManagementPage({required this.car});

  @override
  _FuelManagementPageState createState() => _FuelManagementPageState();
}

List<FuelEntry> fuelEntries = [];

class _FuelManagementPageState extends State<FuelManagementPage> {
  final TextEditingController fuelAmountController = TextEditingController();
  final TextEditingController fuelPriceController = TextEditingController();
  final TextEditingController kmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadFuelEntries(); // Load the fuel entries for the car
  }

  Future<void> loadFuelEntries() async {
    // Replace with actual function to load fuel entries from your database
    List<FuelEntry> entries = await loadFuelEntriesFromFirestore(widget.car);

    setState(() {
      fuelEntries = entries;
    });
  }

  @override
  void dispose() {
    fuelAmountController.dispose();
    fuelPriceController.dispose();
    kmController.dispose();
    super.dispose();
  }

  void deleteFuelEntry(FuelEntry entry) {
    // Replace with your actual function to remove the entry from your database
    removeFuelEntryFromFirestore(entry);

    setState(() {
      fuelEntries.remove(entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Management'),
      ),
      body: ListView.builder(
        itemCount: fuelEntries.length,
        itemBuilder: (context, index) {
          FuelEntry entry = fuelEntries[index];

          return Dismissible(
            key: ValueKey<int>(fuelEntries[index].id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 30,
              ),
            ),
            onDismissed: (direction) {
              deleteFuelEntry(entry);
            },
            child: ListTile(
              title: Text(
                '${entry.fuelAmount} liters @ ${entry.pricePerUnit.toStringAsFixed(2)} per unit',
              ),
              subtitle: Text('Kilometers Driven: ${entry.kmDriven}'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  editFuelDialog(context, entry, refresh);
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addFuelDialog(widget.car, context, refresh);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Placeholder for loading data from Firestore (replace this with your implementation)
  Future<List<FuelEntry>> loadFuelEntriesFromFirestore(CarEntry car) async {
    return loadFuelEntriesFromDb(car);
  }

  // Placeholder for deleting an entry from Firestore (replace this with your implementation)
  void removeFuelEntryFromFirestore(FuelEntry entry) {
    removeFuelEntryFromDb(entry);
  }

  void refresh() {
    setState(() {});
  }

  void editFuelDialog(BuildContext context, FuelEntry entry, Function refresh) {
    final fuelAmountController =
        TextEditingController(text: entry.fuelAmount.toString());
    final fuelPriceController =
        TextEditingController(text: entry.pricePerUnit.toString());
    final kmController = TextEditingController(text: entry.kmDriven.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Fuel Entry'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: fuelAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Fuel Amount (liters)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: fuelPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Price per Unit',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: kmController,
                  decoration: const InputDecoration(
                    labelText: 'Kilometers Driven',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                // Parse updated values
                int? fuelAmount = int.tryParse(fuelAmountController.text);
                double? pricePerUnit =
                    double.tryParse(fuelPriceController.text);
                int? kmDriven = int.tryParse(kmController.text);

                if (fuelAmount != null &&
                    pricePerUnit != null &&
                    kmDriven != null) {
                  // Create an updated entry
                  FuelEntry updatedEntry = FuelEntry(
                    id: entry.id,
                    fuelAmount: fuelAmount,
                    carId: entry.carId,
                    pricePerUnit: pricePerUnit,
                    kmDriven: kmDriven,
                    date: entry.date,
                  );

                  // Update the fuel entry in the database
                  modifyFuelEntryInDb(updatedEntry).then((_) {
                    Navigator.of(context).pop();
                    refresh(); // Refresh the UI after update
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Invalid input, please check again.')),
                  );
                }
              },
              child:
                  const Text('Update', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }
}

void addFuelEntryToFirebase(int carId, FuelEntry entry) {
  addFuelEntryToDb(carId, entry);
}

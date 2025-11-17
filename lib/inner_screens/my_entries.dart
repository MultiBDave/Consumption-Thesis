// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reminder.dart';

import '../auth_screens/home_screen.dart';
import '../helper/firebase.dart';
import '../helper/flutter_flow/flutter_flow_icon_button.dart';
import '../helper/flutter_flow/flutter_flow_theme.dart';
import '../models/car_entry.dart';
import '../models/fuel_entry.dart';
import '../../components/components.dart';
import '../main.dart';
import 'car_fuel_entries_screen.dart';
// imports intentionally removed (unused)

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
  final double fuelTankSize;
  CsvRecord({required this.year, required this.make, required this.model, required this.fuelTankSize});
}

class _MyEntriesState extends State<MyEntries> {
  int currentFuelValue = 0;
  int currentDistanceValue = 0;
  int todaysReminderCount = 0;
  TextEditingController fuelController = TextEditingController();
  TextEditingController distanceController = TextEditingController();
  List<CarEntry> ownCars = [];
  List<CsvRecord> csvRecords = [];
  List<String> csvMakes = [];
  Map<String, List<String>> csvModelsByMake = {};
  Map<String, double> csvTankByMakeModel = {};
  final List<int> yearRange = [for (var y = 1970; y <= DateTime.now().year; y++) y];
  final List<String> carTypes = ['Van','Sedan','Coupe','Hatchback','SUV','Convertible','Wagon','Pickup','Minivan','Bus','Other'];

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
    _loadTodaysReminders();
  }

  Future<void> _loadTodaysReminders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => todaysReminderCount = 0);
      return;
    }
    final all = await loadRemindersForUser(user.email!);
    final now = DateTime.now();
    final count = all.where((r) => r.date.year == now.year && r.date.month == now.month && r.date.day == now.day).length;
    setState(() => todaysReminderCount = count);
    return;
  }

  Future<void> loadCsvAsset() async {
    final raw = await rootBundle.loadString('assets/csv/2020.csv');
    final lines = raw.split('\n');
    for (var line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(',');
      // year = parts[0], make=parts[1], model=parts[2], tank size=parts[3]
      csvRecords.add(CsvRecord(
        year: int.tryParse(parts[0]) ?? 0,
        make: parts[1],
        model: parts[2],
        fuelTankSize: double.tryParse(parts[3]) ?? 0.0,
      ));
    }
    // Build make list and model map
    csvMakes = csvRecords.map((e) => e.make).toSet().toList()..sort();
    for (var r in csvRecords) {
      csvModelsByMake.putIfAbsent(r.make, () => []).add(r.model);
      csvTankByMakeModel['${r.make}|${r.model}'] = r.fuelTankSize;
    }
    csvModelsByMake.updateAll((k, v) => v.toSet().toList()..sort());
    setState(() {});
    return;
  }

  Future<void> _deleteVehicle(CarEntry car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Vehicle'),
          content: const Text('Are you sure you want to delete this vehicle?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      await removeCarEntryFromDb(car.id);
      setState(() {
        removeEntry(car.id);
      });
    }
    return;
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
          // Calendar with today's badge
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  color: Colors.white,
                  tooltip: 'Calendar',
                  onPressed: () async {
              // Capture parent context so we can navigate after closing the dialog
              final parentContext = context;
              // Show calendar dialog (load reminders for current user)
              await showDialog(
                context: context,
                builder: (context) {
                  DateTime selectedDate = DateTime.now();
                  List reminders = [];
                  List<CarEntry> ownCars = [];

                  Future<void> loadData() async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      reminders = await loadRemindersForUser(user.email!);
                      final cars = await loadCarEntrysFromFirestore();
                      ownCars = cars.where((c) => c.ownerUsername == user.email).toList();
                    }
                  }

                  return FutureBuilder<void>(
                    future: loadData(),
                    builder: (context, snapshot) {
                      return StatefulBuilder(
                        builder: (context, setState) {
                          final dayReminders = reminders.where((r) =>
                              r.date.year == selectedDate.year &&
                              r.date.month == selectedDate.month &&
                              r.date.day == selectedDate.day).toList();

                          return AlertDialog(
                            contentPadding: const EdgeInsets.all(8),
                            title: Text('Calendar - ${DateFormat.yMMMM().format(selectedDate)}'),
                            content: SizedBox(
                              width: 520,
                              height: 420,
                              child: Column(
                                children: [
                                  CalendarDatePicker(
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                    onDateChanged: (d) {
                                      setState(() {
                                        selectedDate = d;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: dayReminders.isEmpty
                                        ? const Center(child: Text('No reminders for this day'))
                                        : ListView.builder(
                                            itemCount: dayReminders.length,
                                            itemBuilder: (c, i) {
                                              final r = dayReminders[i];
                                              return ListTile(
                                                  title: Text(r.title),
                                                  subtitle: Text(r.description),
                                                  onTap: () {
                                                    if (r.carId != null) {
                                                      final matched = ownCars.where((c) => c.id == r.carId).toList();
                                                      if (matched.isNotEmpty) {
                                                        final carToOpen = matched.first;
                                                        Navigator.of(parentContext).pop();
                                                        Navigator.push(parentContext, MaterialPageRoute(builder: (ctx) => CarFuelEntriesScreen(car: carToOpen)));
                                                      }
                                                    }
                                                  },
                                                      trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (r.carId != null) Padding(
                                                      padding: const EdgeInsets.only(right:8.0),
                                                      child: Builder(
                                                        builder: (ctx) {
                                                          final matched = ownCars.where((c) => c.id == r.carId).toList();
                                                          if (matched.isNotEmpty) {
                                                            final mc = matched.first;
                                                            return Text('Car: ${mc.make} ${mc.model} (${mc.year})');
                                                          }
                                                          return Text('Car: ${r.carId}');
                                                        },
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.edit),
                                                      onPressed: () async {
                                                        await showDialog(
                                                          context: context,
                                                          builder: (ctx2) {
                                                            final titleController = TextEditingController(text: r.title);
                                                            final descController = TextEditingController(text: r.description);
                                                            int? selectedCar = r.carId;
                                                            DateTime editDate = r.date;
                                                            return AlertDialog(
                                                              title: const Text('Edit reminder'),
                                                              content: StatefulBuilder(
                                                                builder: (context, setStateDialog) {
                                                                  return SizedBox(
                                                                    width: 420,
                                                                    child: Column(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                                                                        const SizedBox(height:8),
                                                                        TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                                                                        const SizedBox(height:8),
                                                                        DropdownButtonFormField<int?>(
                                                                          decoration: const InputDecoration(labelText: 'Car (optional)'),
                                                                          initialValue: selectedCar,
                                                                          items: [
                                                                            const DropdownMenuItem<int?>(value: null, child: Text('None')),
                                                                          ] + ownCars.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text('${c.make} ${c.model}'))).toList(),
                                                                          onChanged: (v) => setStateDialog(() => selectedCar = v),
                                                                        ),
                                                                        const SizedBox(height:8),
                                                                        TextButton(
                                                                          onPressed: () async {
                                                                            final picked = await showDatePicker(context: context, initialDate: editDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                                                                            if (picked != null) setStateDialog(() => editDate = picked);
                                                                          },
                                                                          child: Text('Date: ${DateFormat.yMMMd().format(editDate)}'),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                              actions: [
                                                                TextButton(onPressed: () => Navigator.of(ctx2).pop(), child: const Text('Cancel')),
                                                                TextButton(onPressed: () async {
                                                                      r.title = titleController.text;
                                                                      r.description = descController.text;
                                                                      r.carId = selectedCar;
                                                                      r.date = editDate;
                                                                      await updateReminderInDb(r);
                                                                      // Refresh parent's today's badge count so the icon updates
                                                                      await _loadTodaysReminders();
                                                                      Navigator.of(ctx2).pop();
                                                                      setState(() {});
                                                                    }, child: const Text('Save')),
                                                              ],
                                                            );
                                                          }
                                                        );
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete, color: Colors.red),
                                                      onPressed: () async {
                                                        final ok = await showDialog<bool>(
                                                          context: context,
                                                          builder: (c) => AlertDialog(
                                                            title: const Text('Delete'),
                                                            content: const Text('Delete this reminder?'),
                                                            actions: [
                                                              TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                                                              TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Delete')),
                                                            ],
                                                          ),
                                                        );
                                                        if (ok ?? false) {
                                                          await removeReminderFromDb(r.id);
                                                          // refresh today's badge
                                                          await _loadTodaysReminders();
                                                          reminders.removeAt(i);
                                                          setState(() {});
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // Add reminder dialog
                                  final titleController = TextEditingController();
                                  final descController = TextEditingController();
                                  int? selectedCarId;
                                  DateTime reminderDate = selectedDate;
                                  await showDialog(
                                    context: context,
                                    builder: (ctxAdd) {
                                      return AlertDialog(
                                        title: const Text('Add reminder'),
                                        content: StatefulBuilder(
                                          builder: (context, setStateDialog) {
                                            return SizedBox(
                                              width: 420,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                                                  const SizedBox(height:8),
                                                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                                                  const SizedBox(height:8),
                                                  DropdownButtonFormField<int?>(
                                                    decoration: const InputDecoration(labelText: 'Car (optional)'),
                                                    initialValue: selectedCarId,
                                                    items: [
                                                      const DropdownMenuItem<int?>(value: null, child: Text('None')),
                                                    ] + ownCars.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text('${c.make} ${c.model}'))).toList(),
                                                    onChanged: (v) => setStateDialog(() => selectedCarId = v),
                                                  ),
                                                  const SizedBox(height:8),
                                                  TextButton(onPressed: () async {
                                                    final picked = await showDatePicker(context: context, initialDate: reminderDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                                                    if (picked != null) setStateDialog(() => reminderDate = picked);
                                                  }, child: Text('Date: ${DateFormat.yMMMd().format(reminderDate)}')),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.of(ctxAdd).pop(), child: const Text('Cancel')),
                                          TextButton(onPressed: () async {
                                            final user = FirebaseAuth.instance.currentUser;
                                            if (user == null) return;
                                            final newReminder = Reminder(
                                              id: DateTime.now().millisecondsSinceEpoch,
                                              carId: selectedCarId,
                                              title: titleController.text,
                                              description: descController.text,
                                              date: reminderDate,
                                              ownerUsername: user.email ?? '',
                                            );
                                            await addReminderToDb(newReminder);
                                            // refresh parent's badge count
                                            await _loadTodaysReminders();
                                            reminders.add(newReminder);
                                            Navigator.of(ctxAdd).pop();
                                            setState(() {});
                                          }, child: const Text('Add')),
                                        ],
                                      );
                                    }
                                  );
                                },
                                child: const Text('Add reminder'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
                  },
                ),
                if (todaysReminderCount > 0)
                  Positioned(
                    right: 6,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Center(
                        child: Text(
                          todaysReminderCount > 99 ? '99+' : todaysReminderCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                await navigator.push(MaterialPageRoute(
                                  builder: (c) => CarFuelEntriesScreen(car: car),
                                ));
                              },
                            ),
                            const SizedBox(width: 8),
                            FlutterFlowIconButton(
                              borderRadius: 20,
                              borderWidth: 1,
                              buttonSize: 40,
                              fillColor: FlutterFlowTheme.of(context).tertiary,
                              icon: Icon(
                                Icons.add_circle,
                                color: FlutterFlowTheme.of(context).primaryBackground,
                                size: 20,
                              ),
                              onPressed: () async {
                                // Capture the scaffold messenger before showing the dialog to avoid context issues
                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                await showDialog(
                                    context: context,
                                    builder: (BuildContext dialogContext) {
                                      fuelController.clear();
                                      distanceController.text = car.drivenKm.toString();
                                      final TextEditingController costController = TextEditingController();
                                      DateTime selectedDate = DateTime.now();
                                      return AlertDialog(
                                        title: const Text('Quick Add Fuel'),
                                        content: StatefulBuilder(
                                          builder: (context, setState) {
                                            return SingleChildScrollView(
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                                                ),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Expanded(
                                                          flex: 2,
                                                          child: Text('Date:'),
                                                        ),
                                                        Expanded(
                                                          flex: 3,
                                                          child: TextButton(
                                                            onPressed: () async {
                                                              final picked = await showDatePicker(
                                                                context: context,
                                                                initialDate: selectedDate,
                                                                firstDate: DateTime(2000),
                                                                lastDate: DateTime.now().add(const Duration(days: 3650)),
                                                              );
                                                              if (picked != null) {
                                                                setState(() => selectedDate = picked);
                                                              }
                                                            },
                                                            child: Align(
                                                              alignment: Alignment.centerLeft,
                                                              child: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
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
                                                            keyboardType: TextInputType.number,
                                                            onChanged: (String newValue) {
                                                              if (newValue.isNotEmpty) {
                                                                currentFuelValue = int.tryParse(fuelController.text) ?? 0;
                                                              }
                                                            },
                                                            decoration: const InputDecoration(
                                                              border: OutlineInputBorder(),
                                                              hintText: 'Amount',
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          flex: 2,
                                                          child: Text('Cost (${NumberFormat.simpleCurrency().currencySymbol}):'),
                                                        ),
                                                        Expanded(
                                                          flex: 3,
                                                          child: TextField(
                                                            controller: costController,
                                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                            decoration: const InputDecoration(
                                                              border: OutlineInputBorder(),
                                                              hintText: 'Total cost',
                                                            ),
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
                                                            keyboardType: TextInputType.number,
                                                            onChanged: (String newValue) {
                                                              if (newValue.isNotEmpty) {
                                                                currentDistanceValue = int.tryParse(distanceController.text) ?? 0;
                                                              }
                                                            },
                                                            decoration: const InputDecoration(
                                                              border: OutlineInputBorder(),
                                                              hintText: 'Km',
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.of(dialogContext).pop();
                                              },
                                              child: const Text('Cancel')),
                                          TextButton(
                                              onPressed: () async {
                                                if (fuelController.text.isEmpty ||
                                                    distanceController.text.isEmpty) {
                                                  scaffoldMessenger.showSnackBar(
                                                    const SnackBar(content: Text('Please fill in all fields'))
                                                  );
                                                  return;
                                                }

                                                try {
                                                  final parsedCost = double.tryParse(costController.text) ?? 0.0;

                                                  // Create a new fuel entry
                                                  final newFuelEntry = FuelEntry(
                                                    id: DateTime.now().millisecondsSinceEpoch,
                                                    carId: car.id,
                                                    fuelAmount: currentFuelValue,
                                                    odometer: currentDistanceValue,
                                                    date: selectedDate,
                                                    cost: parsedCost,
                                                  );

                                                  await addFuelEntryToDb(newFuelEntry);

                                                  // Update the car's total fuel and odometer
                                                  setState(() {
                                                    car.fuelSum += currentFuelValue;
                                                    car.drivenKm = currentDistanceValue;
                                                    car.refreshConsumption();
                                                  });

                                                  // Update the car in the database
                                                  await modifyCarEntryInDb(car);

                                                  Navigator.of(dialogContext).pop();

                                                  // Show success message using captured scaffold messenger
                                                  scaffoldMessenger.showSnackBar(
                                                    const SnackBar(content: Text('Fuel entry added successfully!'))
                                                  );
                                                } catch (e) {
                                                  debugPrint('Error adding fuel entry: $e');
                                                  scaffoldMessenger.showSnackBar(
                                                    SnackBar(content: Text('Error: ${e.toString()}')),
                                                  );
                                                }
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
                                              TextField(
                                                controller: TextEditingController(text: ownCars[index].initialKm.toString()),
                                                decoration: const InputDecoration(labelText: 'Initial km', border: OutlineInputBorder()),
                                                keyboardType: TextInputType.number,
                                                onChanged: (val) => ownCars[index].initialKm = int.tryParse(val) ?? ownCars[index].initialKm,
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
                              onPressed: () async {
                                await _deleteVehicle(car);
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
                          int selectedYear = DateTime.now().year;
                          String? selectedMake;
              final tankController = TextEditingController();
              return StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Add Vehicle',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            const SizedBox(height: 16),
                            // Year dropdown
                            DropdownButtonFormField<int>(
                              decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                              initialValue: selectedYear,
                              items: yearRange.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                              onChanged: (val) => setStateDialog(() {
                                selectedYear = val!;
                                newCar.year = selectedYear;
                              }),
                            ),
                            const SizedBox(height: 12),
                            // Make dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: 'Make', border: OutlineInputBorder()),
                              initialValue: selectedMake,
                              items: csvMakes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                              onChanged: (val) => setStateDialog(() {
                                selectedMake = val;
                                newCar.make = val!;
                              }),
                            ),
                            const SizedBox(height: 12),
                            // Model dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
                              initialValue: null,
                              items: selectedMake != null
                                  ? csvModelsByMake[selectedMake!]!
                                      .map((mo) => DropdownMenuItem(value: mo, child: Text(mo)))
                                      .toList()
                                  : [],
                              onChanged: (val) => setStateDialog(() {
                                newCar.model = val!;
                                final key = '${newCar.make}|${newCar.model}';
                                final defaultTank = csvTankByMakeModel[key] ?? 0.0;
                                newCar.tankSize = defaultTank.round();
                                tankController.text = newCar.tankSize.toString();
                              }),
                            ),
                            const SizedBox(height: 12),
                            // Color input
                            TextField(
                              decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder()),
                              onChanged: (val) => newCar.color = val,
                            ),
                            const SizedBox(height: 12),
                            // Type dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                              initialValue: null,
                              items: carTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (val) => newCar.type = val!,
                            ),
                            const SizedBox(height: 12),
                            // Only initial km input; drivenKm defaults to initialKm
                            TextField(
                              decoration: const InputDecoration(labelText: 'Initial km (km)', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                final km = int.tryParse(val) ?? 0;
                                newCar.initialKm = km;
                                newCar.drivenKm = km;
                              },
                            ),
                            const SizedBox(height: 12),
                            // Tank size defaulted from CSV, editable
                            TextField(
                              controller: tankController,
                              decoration: const InputDecoration(labelText: 'Tank size (L)', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => newCar.tankSize = int.tryParse(val) ?? newCar.tankSize,
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

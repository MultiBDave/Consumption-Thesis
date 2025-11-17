// ignore_for_file: use_build_context_synchronously, deprecated_member_use, sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// chart removed: fl_chart import not needed here
import 'car_costs_screen.dart';
import '../helper/firebase.dart';
// ...existing imports
import '../helper/flutter_flow/flutter_flow_theme.dart';
import '../models/car_entry.dart';
import '../models/fuel_entry.dart';

class CarFuelEntriesScreen extends StatefulWidget {
  final CarEntry car;

  const CarFuelEntriesScreen({super.key, required this.car});

  @override
  State<CarFuelEntriesScreen> createState() => _CarFuelEntriesScreenState();
}

class _CarFuelEntriesScreenState extends State<CarFuelEntriesScreen> {
  List<FuelEntry> fuelEntries = [];
  bool isLoading = true;

  double get totalFuelCost {
    return fuelEntries.fold(0.0, (s, e) => s + (e.cost));
  }

  @override
  void initState() {
    super.initState();
    _loadFuelEntries();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data whenever the screen is displayed
    _loadFuelEntries();
  }

  Future<void> _loadFuelEntries() async {
    setState(() {
      isLoading = true;
    });

    try {
      final entries = await loadFuelEntriesForCar(widget.car.id);
      setState(() {
        fuelEntries = entries;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading fuel entries: $e')),
      );
    }
  }

  Future<void> _deleteFuelEntry(FuelEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this fuel entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await removeFuelEntryFromDb(entry.id);
        _loadFuelEntries();
        // Recalculate car's consumption
        updateCarConsumption();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting entry: $e')),
        );
      }
    }
  }

  Future<void> updateCarConsumption() async {
    double consumption = await calculateConsumptionFromEntries(
      widget.car.id, 
      widget.car.initialKm
    );

    setState(() {
      widget.car.consumption = consumption.toStringAsFixed(2);
      widget.car.updateEstimatedRange();
      
      // Update the sum of fuel
      if (fuelEntries.isNotEmpty) {
        widget.car.fuelSum = fuelEntries
            .fold(0, (sum, entry) => sum + entry.fuelAmount);
      } else {
        widget.car.fuelSum = 0;
      }
      
      // Update latest odometer reading
      if (fuelEntries.isNotEmpty) {
        int maxOdometer = fuelEntries
            .map((e) => e.odometer)
            .reduce((a, b) => a > b ? a : b);
        widget.car.drivenKm = maxOdometer;
      }
    });

    // Update in database
    await modifyCarEntryInDb(widget.car);
  }

  void _showAddEditFuelDialog({FuelEntry? existingEntry}) {
    // Capture active context for SnackBars to avoid deactivated widget errors
    final BuildContext parentContext = context;
    final isEditing = existingEntry != null;
    final TextEditingController fuelAmountController = TextEditingController(
      text: isEditing ? existingEntry.fuelAmount.toString() : '',
    );
    final TextEditingController costController = TextEditingController(
      text: isEditing ? existingEntry.cost.toStringAsFixed(2) : '',
    );
    final TextEditingController odometerController = TextEditingController(
      text: isEditing
          ? existingEntry.odometer.toString()
          : widget.car.drivenKm.toString(),
    );

    DateTime selectedDate = isEditing ? existingEntry.date : DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Fuel Entry' : 'Add Fuel Entry'),
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
                              controller: fuelAmountController,
                              keyboardType: TextInputType.number,
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
                              controller: odometerController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'km',
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Capture the dialog navigator/messenger before any awaits
                // so we can safely close the dialog afterwards without
                // popping the parent route.
                final navigator = Navigator.of(context);
                // We'll use the dialog's navigator to close the dialog.
                // (No separate dialog messenger needed here.)

                if (fuelAmountController.text.isEmpty || odometerController.text.isEmpty) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }
                try {
                  final fuelAmount = int.parse(fuelAmountController.text);
                  final odometer = int.parse(odometerController.text);
                  final parsedCost = double.tryParse(costController.text) ?? 0.0;

                  // Build a temp entry representing the edited/new entry for validation
                  final int candidateId = isEditing ? existingEntry.id : DateTime.now().millisecondsSinceEpoch;
                  final FuelEntry candidateEntry = FuelEntry(
                    id: candidateId,
                    carId: widget.car.id,
                    fuelAmount: fuelAmount,
                    odometer: odometer,
                    date: selectedDate,
                    cost: parsedCost,
                  );

                  // Load all existing entries and include the candidate, then validate odometer monotonicity by date
                  List<FuelEntry> allEntries = await loadFuelEntriesForCar(widget.car.id);
                  if (isEditing) {
                    allEntries = allEntries.map((e) => e.id == candidateId ? candidateEntry : e).toList();
                  } else {
                    allEntries.add(candidateEntry);
                  }
                  allEntries.sort((a, b) => a.date.compareTo(b.date)); // oldest -> newest

                  for (var i = 1; i < allEntries.length; i++) {
                    final prev = allEntries[i - 1];
                    final next = allEntries[i];
                    // Allow any ordering for entries on the same day (user may fill twice).
                    // Only flag a conflict if the later entry has a strictly later date and a lower odometer.
                    if (next.date.isAfter(prev.date) && next.odometer < prev.odometer) {
                      if (!mounted) return;
                        // This dialog uses a parent context captured before async work.
                        // The mounted check ensures the State is still valid.
                        await showDialog<void>(
                          context: parentContext,
                          builder: (ctx) => AlertDialog(
                          title: const Text('Odometer / Date Conflict'),
                          content: Text(
                            'Odometer inconsistency:\n'
                            '${DateFormat('MMM d, yyyy').format(prev.date)} shows ${prev.odometer} km\n'
                            'but ${DateFormat('MMM d, yyyy').format(next.date)} shows ${next.odometer} km.\n\n'
                            'Please correct the date or odometer before saving.'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                  }

                  if (isEditing) {
                    existingEntry.fuelAmount = fuelAmount;
                    existingEntry.odometer = odometer;
                    existingEntry.cost = parsedCost;
                    existingEntry.date = selectedDate;
                    await updateFuelEntry(existingEntry);
                  } else {
                    await addFuelEntryToDb(candidateEntry);
                  }
                  await _loadFuelEntries();
                  await updateCarConsumption();
                  if (!mounted) return;
                  // Close the dialog (use the dialog's navigator, not the parent)
                  navigator.pop();
                } catch (e) {
                  if (!mounted) return;
                  // Show error on the parent scaffold to ensure visibility
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
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
        title: Text('${widget.car.make} ${widget.car.model} - Fuel Log'),
        backgroundColor: FlutterFlowTheme.of(context).primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Costs',
            onPressed: () async {
              final navigator = Navigator.of(context);
              // Navigate to costs screen
              await navigator.push(MaterialPageRoute(
                builder: (c) => CarCostsScreen(car: widget.car),
              ));
              // Reload entries when returning
              await _loadFuelEntries();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Car summary card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: 
                              Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          child: Icon(
                            Icons.directions_car,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.car.make} ${widget.car.model}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: FlutterFlowTheme.of(context).primaryText,
                                ),
                              ),
                              Text(
                                '${widget.car.year} • ${widget.car.color} • ${widget.car.type}',
                                style: TextStyle(
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          'Consumption',
                          '${widget.car.getConsumption()} L/100km',
                          Icons.opacity,
                        ),
                        _buildStatColumn(
                          'Total Fuel',
                          '${widget.car.fuelSum} L',
                          Icons.local_gas_station,
                        ),
                        _buildStatColumn(
                          'Fuel Cost',
                          NumberFormat.simpleCurrency().format(totalFuelCost),
                          Icons.monetization_on,
                        ),
                        _buildStatColumn(
                          'Range',
                          widget.car.estimatedRange,
                          Icons.directions,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Fuel entries list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : fuelEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_gas_station_outlined,
                              size: 80,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No fuel entries yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _showAddEditFuelDialog(),
                              child: const Text('Add First Entry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: fuelEntries.length,
                        itemBuilder: (context, index) {
                          final entry = fuelEntries[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.local_gas_station),
                              ),
                              title: Text('${entry.fuelAmount} liters — ${NumberFormat.simpleCurrency().format(entry.cost)}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Odometer: ${entry.odometer} km'),
                                  Text(DateFormat('MMM d, yyyy').format(entry.date)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        _showAddEditFuelDialog(existingEntry: entry),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteFuelEntry(entry),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditFuelDialog(),
        child: const Icon(Icons.add),
        backgroundColor: FlutterFlowTheme.of(context).primary,
      ),
    );
  }
  
  Widget _buildStatColumn(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: FlutterFlowTheme.of(context).secondaryText),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: FlutterFlowTheme.of(context).secondaryText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: FlutterFlowTheme.of(context).primaryText,
          ),
        ),
      ],
    );
  }

  
}

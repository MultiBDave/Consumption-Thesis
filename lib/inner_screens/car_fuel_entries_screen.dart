import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helper/firebase.dart';
import '../helper/flutter_flow/flutter_flow_icon_button.dart';
import '../helper/flutter_flow/flutter_flow_theme.dart';
import '../models/car_entry.dart';
import '../models/fuel_entry.dart';

class CarFuelEntriesScreen extends StatefulWidget {
  final CarEntry car;

  const CarFuelEntriesScreen({Key? key, required this.car}) : super(key: key);

  @override
  State<CarFuelEntriesScreen> createState() => _CarFuelEntriesScreenState();
}

class _CarFuelEntriesScreenState extends State<CarFuelEntriesScreen> {
  List<FuelEntry> fuelEntries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
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
    final isEditing = existingEntry != null;
    final TextEditingController fuelAmountController = TextEditingController(
      text: isEditing ? existingEntry.fuelAmount.toString() : '',
    );
    final TextEditingController odometerController = TextEditingController(
      text: isEditing
          ? existingEntry.odometer.toString()
          : widget.car.drivenKm.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Fuel Entry' : 'Add Fuel Entry'),
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
                      controller: fuelAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
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
                      controller: odometerController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (fuelAmountController.text.isEmpty ||
                  odometerController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }

              try {
                final fuelAmount = int.parse(fuelAmountController.text);
                final odometer = int.parse(odometerController.text);

                if (isEditing) {
                  // Update existing entry
                  existingEntry.fuelAmount = fuelAmount;
                  existingEntry.odometer = odometer;
                  await updateFuelEntry(existingEntry);
                } else {
                  // Create new entry
                  final newEntry = FuelEntry(
                    id: DateTime.now().millisecondsSinceEpoch,
                    carId: widget.car.id,
                    fuelAmount: fuelAmount,
                    odometer: odometer,
                    date: DateTime.now(),
                  );
                  await addFuelEntryToDb(newEntry);
                }

                // Refresh entries and update car's data
                Navigator.of(context).pop();
                await _loadFuelEntries();
                await updateCarConsumption();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.car.make} ${widget.car.model} - Fuel Log'),
        backgroundColor: FlutterFlowTheme.of(context).primary,
        foregroundColor: Colors.white,
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
                              title: Text('${entry.fuelAmount} liters'),
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
        onPressed: _showAddEditFuelDialog,
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

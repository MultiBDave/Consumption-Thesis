import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/car_entry.dart';
import '../models/fuel_entry.dart';
import '../models/extra_cost.dart';
import '../helper/firebase.dart';
import '../helper/flutter_flow/flutter_flow_theme.dart';

class CarCostsScreen extends StatefulWidget {
  final CarEntry car;
  const CarCostsScreen({Key? key, required this.car}) : super(key: key);

  @override
  State<CarCostsScreen> createState() => _CarCostsScreenState();
}

class _CarCostsScreenState extends State<CarCostsScreen> {
  List<FuelEntry> fuelEntries = [];
  List<ExtraCost> extraCosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => isLoading = true);
    fuelEntries = await loadFuelEntriesForCar(widget.car.id);
    extraCosts = await loadExtraCostsForCar(widget.car.id);
    setState(() => isLoading = false);
  }

  double get totalFuelCost {
    return fuelEntries.fold(0.0, (s, e) => s + (e.cost));
  }

  double get totalExtraCost {
    return extraCosts.fold(0.0, (s, e) => s + (e.amount));
  }

  Future<void> _showAddExtraCostDialog({ExtraCost? existing}) async {
  final isEditing = existing != null;
  final TextEditingController amountCtrl = TextEditingController(text: existing?.amount.toString() ?? '');
  final TextEditingController categoryCtrl = TextEditingController(text: existing?.category ?? 'Maintenance');
  final TextEditingController descCtrl = TextEditingController(text: existing?.description ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Cost' : 'Add Extra Cost'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            TextField(
              controller: categoryCtrl,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
          actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            final amount = double.tryParse(amountCtrl.text) ?? 0.0;
            final category = categoryCtrl.text.trim();
            final desc = descCtrl.text.trim();
            try {
              if (isEditing) {
                final updated = ExtraCost(
                  id: existing.id,
                  carId: existing.carId,
                  amount: amount,
                  category: category,
                  description: desc,
                  date: existing.date,
                );
                await updateExtraCostInDb(updated);
              } else {
                final cost = ExtraCost(
                  id: DateTime.now().millisecondsSinceEpoch,
                  carId: widget.car.id,
                  amount: amount,
                  category: category,
                  description: desc,
                  date: DateTime.now(),
                );
                await addExtraCostToDb(cost);
              }
              await _loadAll();
              Navigator.of(context).pop();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }, child: Text(isEditing ? 'Save' : 'Add')),
        ],
      ),
    );
  }

  Future<void> _deleteExtraCost(ExtraCost cost) async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Delete cost'),
      content: const Text('Are you sure you want to delete this cost?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (ok ?? false) {
      await removeExtraCostFromDb(cost.id);
      await _loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.car.make} ${widget.car.model} - Costs'),
        backgroundColor: FlutterFlowTheme.of(context).primary,
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Summary', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total fuel cost'),
                          Text('${NumberFormat.simpleCurrency().format(totalFuelCost)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total extra cost'),
                          Text('${NumberFormat.simpleCurrency().format(totalExtraCost)}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Grand total', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${NumberFormat.simpleCurrency().format(totalFuelCost + totalExtraCost)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Fuel entries', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...fuelEntries.map((e) => Card(
                child: ListTile(
                  title: Text('${e.fuelAmount} L — ${NumberFormat.simpleCurrency().format(e.cost)}'),
                  subtitle: Text('${e.odometer} km • ${DateFormat.yMMMd().format(e.date)}'),
                ),
              )),
              const SizedBox(height: 16),
              Text('Extra costs', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...extraCosts.map((c) => Card(
                child: ListTile(
                  title: Text('${c.category} — ${NumberFormat.simpleCurrency().format(c.amount)}'),
                  subtitle: Text('${c.description} • ${DateFormat.yMMMd().format(c.date)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddExtraCostDialog(existing: c),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteExtraCost(c),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExtraCostDialog(),
        child: const Icon(Icons.add),
        backgroundColor: FlutterFlowTheme.of(context).primary,
      ),
    );
  }
}

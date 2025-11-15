import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/car_entry.dart';
import '../models/fuel_entry.dart';
import '../models/extra_cost.dart';
import '../helper/firebase.dart';
import '../helper/flutter_flow/flutter_flow_theme.dart';
import 'package:fl_chart/fl_chart.dart';
// dart:math no longer required here

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
  DateTime selectedDate = existing?.date ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(isEditing ? 'Edit Cost' : 'Add Extra Cost'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(flex: 2, child: Text('Amount')),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(flex: 2, child: Text('Category')),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(flex: 2, child: Text('Description')),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(flex: 2, child: Text('Date')),
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setStateDialog(() => selectedDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        child: Text(DateFormat.yMMMd().format(selectedDate)),
                      ),
                    ),
                  ),
                ],
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
                    date: selectedDate,
                  );
                  await updateExtraCostInDb(updated);
                } else {
                  final cost = ExtraCost(
                    id: DateTime.now().millisecondsSinceEpoch,
                    carId: widget.car.id,
                    amount: amount,
                    category: category,
                    description: desc,
                    date: selectedDate,
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

  // Build a small combined pie chart widget: fuel vs extra
  Widget _buildCombinedPieChart() {
    final double fuel = totalFuelCost;
    final double extra = totalExtraCost;
    if (fuel == 0 && extra == 0) return Center(child: Text('No cost data'));

    final total = fuel + extra;
    final fuelPct = total > 0 ? (fuel / total) * 100 : 0.0;
    final extraPct = total > 0 ? (extra / total) * 100 : 0.0;

    final sections = <PieChartSectionData>[
      PieChartSectionData(
        color: Theme.of(context).colorScheme.primary,
        value: fuel,
        title: '${fuelPct.toStringAsFixed(0)}%',
        radius: 72,
        titleStyle: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        color: Theme.of(context).colorScheme.secondary,
        value: extra,
        title: '${extraPct.toStringAsFixed(0)}%',
        radius: 72,
        titleStyle: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 6,
              centerSpaceRadius: 36,
              borderData: FlBorderData(show: false),
              // show values on tap/hovers? keep static for now
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem(Theme.of(context).colorScheme.primary, 'Fuel', fuel),
            const SizedBox(width: 16),
            _legendItem(Theme.of(context).colorScheme.secondary, 'Extra', extra),
          ],
        ),
      ],
    );
  }

  // Build pie chart for extra costs grouped by category
  Widget _buildExtraByCategoryChart() {
    if (extraCosts.isEmpty) return Center(child: Text('No extra costs'));

    // Sum by category
    final Map<String, double> byCat = {};
    for (var c in extraCosts) {
      byCat[c.category] = (byCat[c.category] ?? 0.0) + c.amount;
    }

    // Generate colors
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.brown,
      Colors.cyan,
    ];

    final sections = <PieChartSectionData>[];
    int i = 0;
    final total = byCat.values.fold(0.0, (a, b) => a + b);
    byCat.forEach((cat, sum) {
      final pct = total > 0 ? (sum / total) * 100 : 0.0;
      sections.add(PieChartSectionData(
        color: colors[i % colors.length],
        value: sum,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 58,
        titleStyle: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
      ));
      i++;
    });

    // Build legend widgets
    final legend = <Widget>[];
    i = 0;
    byCat.forEach((cat, sum) {
      legend.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(width: 14, height: 14, color: colors[i % colors.length]),
            const SizedBox(width: 8),
            Flexible(child: Text('$cat — ${NumberFormat.simpleCurrency().format(sum)}')),
          ],
        ),
      ));
      i++;
    });

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 4,
              centerSpaceRadius: 22,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: legend),
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label, double amount) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text('$label — ${NumberFormat.simpleCurrency().format(amount)}'),
      ],
    );
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
              // Charts (responsive: side-by-side on wide screens)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 700;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cost breakdown', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      SizedBox(height: 8),
                                      SizedBox(height: 240, child: _buildCombinedPieChart()),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    children: [
                                      SizedBox(height: 8),
                                      SizedBox(height: 240, child: _buildExtraByCategoryChart()),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                SizedBox(height: 200, child: _buildCombinedPieChart()),
                                const SizedBox(height: 12),
                                SizedBox(height: 220, child: _buildExtraByCategoryChart()),
                              ],
                            ),
                        ],
                      );
                    },
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

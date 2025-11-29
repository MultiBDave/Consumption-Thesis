import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:consumption/helper/firebase.dart' as fb;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../helper/flutter_flow/flutter_flow_theme.dart';
import '../models/car_entry.dart';
import '../models/extra_cost.dart';
import '../models/fuel_entry.dart';

class CarDetailsScreen extends StatefulWidget {
  final CarEntry car;
  const CarDetailsScreen({super.key, required this.car});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  String? imageUrl;
  String description = '';
  String imageDescription = '';
  List<ExtraCost> costs = [];
  List<FuelEntry> fuelEntries = [];
  bool isOwner = false;
  bool loading = true;
  late TextEditingController _descriptionController;
  late TextEditingController _imageDescriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _imageDescriptionController = TextEditingController();
    _loadDetails();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _imageDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    isOwner = user != null && user.email == widget.car.ownerUsername;

    // Try to load imageUrl and description from the car document
    final snapshot = await FirebaseFirestore.instance
        .collection('CarEntrys')
        .where('id', isEqualTo: widget.car.id)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      imageUrl = data['imageUrl'] as String?;
      description = data['description'] as String? ?? '';
      imageDescription = data['imageDescription'] as String? ?? '';
    }

    costs = await fb.loadExtraCostsForCar(widget.car.id);
    fuelEntries = await fb.loadFuelEntriesForCar(widget.car.id);

    // ensure controller is synced with loaded description
    _descriptionController.text = description;
    _imageDescriptionController.text = imageDescription;

    setState(() {
      loading = false;
    });
  }

  Future<void> _showSetImageUrlDialog() async {
    final controller = TextEditingController(text: imageUrl ?? '');
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set image URL'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'https://...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final url = controller.text.trim();
                // Update Firestore directly
                final snap = await FirebaseFirestore.instance.collection('CarEntrys').where('id', isEqualTo: widget.car.id).limit(1).get();
                if (snap.docs.isNotEmpty) {
                  final docRef = snap.docs.first.reference;
                  await docRef.set({'imageUrl': url}, SetOptions(merge: true));
                }
                setState(() => imageUrl = url.isEmpty ? null : url);
                navigator.pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditImageCaptionDialog() async {
    final controller = TextEditingController(text: imageDescription);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit image caption'),
          content: TextField(
            controller: controller,
            maxLength: 100,
            decoration: const InputDecoration(hintText: 'Caption (max 100 chars)'),
            maxLines: 3,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final text = controller.text.trim();
                // save to Firestore
                final snap = await FirebaseFirestore.instance.collection('CarEntrys').where('id', isEqualTo: widget.car.id).limit(1).get();
                if (snap.docs.isNotEmpty) {
                  final docRef = snap.docs.first.reference;
                  await docRef.set({'imageDescription': text}, SetOptions(merge: true));
                }
                setState(() {
                  imageDescription = text;
                  _imageDescriptionController.text = text;
                });
                navigator.pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveDescription() async {
    final messenger = ScaffoldMessenger.of(context);
    // Update description directly in Firestore
    final snap = await FirebaseFirestore.instance.collection('CarEntrys').where('id', isEqualTo: widget.car.id).limit(1).get();
    if (snap.docs.isNotEmpty) {
      final docRef = snap.docs.first.reference;
      await docRef.set({'description': description}, SetOptions(merge: true));
    }
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Description saved')));
  }

  // Removed maintenance chart; costs are shown in cost breakdown below.

  double get _totalFuelCost => fuelEntries.fold(0.0, (s, e) => s + (e.cost));
  double get _totalExtraCost => costs.fold(0.0, (s, e) => s + (e.amount));

  Widget _legendItem(Color color, String label, double amount) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text('$label — ${NumberFormat.simpleCurrency().format(amount)}'),
      ],
    );
  }

  Widget _buildCombinedPieChart() {
    final double fuel = _totalFuelCost;
    final double extra = _totalExtraCost;
    if (fuel == 0 && extra == 0) return const Center(child: Text('No cost data'));

    final total = fuel + extra;
    final fuelPct = total > 0 ? (fuel / total) * 100 : 0.0;
    final extraPct = total > 0 ? (extra / total) * 100 : 0.0;

    final sections = <PieChartSectionData>[
      PieChartSectionData(
        color: Theme.of(context).colorScheme.primary,
        value: fuel,
        title: '${fuelPct.toStringAsFixed(0)}%',
        radius: 72,
        titleStyle: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        color: Theme.of(context).colorScheme.secondary,
        value: extra,
        title: '${extraPct.toStringAsFixed(0)}%',
        radius: 72,
        titleStyle: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
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
            _legendItem(Theme.of(context).colorScheme.secondary, 'Maintenance', extra),
          ],
        ),
      ],
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

  Widget _buildExtraByCategoryChart() {
    if (costs.isEmpty) return const Center(child: Text('No extra costs'));

    final Map<String, double> byCat = {};
    for (var c in costs) {
      byCat[c.category] = (byCat[c.category] ?? 0.0) + c.amount;
    }

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
    byCat.forEach((cat, catSum) {
      final pct = total > 0 ? (catSum / total) * 100 : 0.0;
      sections.add(PieChartSectionData(
        color: colors[i % colors.length],
        value: catSum,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 58,
        titleStyle: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
      ));
      i++;
    });

    final legend = <Widget>[];
    i = 0;
    byCat.forEach((cat, catSum) {
      legend.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(width: 14, height: 14, color: colors[i % colors.length]),
            const SizedBox(width: 8),
            Flexible(child: Text('$cat — ${NumberFormat.simpleCurrency().format(catSum)}')),
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

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    return Scaffold(
      appBar: AppBar(
        title: Text('${car.make} ${car.model}'),
        backgroundColor: FlutterFlowTheme.of(context).primary,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic stats (styled like CarFuelEntriesScreen summary)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
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
                                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha((0.2 * 255).round()),
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
                                      Text('${car.make} ${car.model}', style: FlutterFlowTheme.of(context).titleLarge),
                                      Text('${car.year} • ${car.color} • ${car.type}', style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatColumn('Consumption', '${car.getConsumption()} L/100km', Icons.opacity),
                                _buildStatColumn('Total Fuel', '${car.fuelSum} L', Icons.local_gas_station),
                                _buildStatColumn('Fuel Cost', NumberFormat.simpleCurrency().format(_totalFuelCost), Icons.monetization_on),
                                _buildStatColumn('Range', car.estimatedRange, Icons.directions),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Cost breakdown (combined pie + extra-by-category)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth > 700;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cost breakdown',
                                  style: (Theme.of(context).textTheme.titleLarge ?? const TextStyle()).copyWith(color: Colors.black),
                                ),
                                const SizedBox(height: 8),
                                if (wide)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: SizedBox(height: 240, child: _buildCombinedPieChart())),
                                      const SizedBox(width: 12),
                                      Expanded(child: SizedBox(height: 240, child: _buildExtraByCategoryChart())),
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
                  ),

                  // Image and description laid out side-by-side
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // picture label removed per design
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: flexible image area (approx 2/3)
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  Container(
                                    constraints: const BoxConstraints(maxHeight: 380),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: imageUrl != null && imageUrl!.isNotEmpty
                                                ? Center(
                                                    child: Image.network(
                                                      imageUrl!,
                                                      fit: BoxFit.contain,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                    ),
                                                  )
                                                : Center(child: Icon(Icons.image, size: 64, color: Colors.grey.shade600)),
                                          ),
                                          if ((imageDescription).isNotEmpty)
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                alignment: Alignment.center,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                decoration: BoxDecoration(color: Colors.black54, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))),
                                                child: Text(
                                                  imageDescription.length > 100 ? imageDescription.substring(0, 100) : imageDescription,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (isOwner)
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: _showSetImageUrlDialog,
                                          child: const Text('Set image URL'),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton(
                                          onPressed: _showEditImageCaptionDialog,
                                          child: const Text('Edit caption'),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final navigator = Navigator.of(context);
                                            final snap = await FirebaseFirestore.instance.collection('CarEntrys').where('id', isEqualTo: widget.car.id).limit(1).get();
                                            if (snap.docs.isNotEmpty) {
                                              final docRef = snap.docs.first.reference;
                                              await docRef.set({'imageUrl': ''}, SetOptions(merge: true));
                                            }
                                            if (!mounted) return;
                                            setState(() => imageUrl = null);
                                            navigator.pop();
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right: description area (approx 1/3)
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Description', style: FlutterFlowTheme.of(context).titleMedium.copyWith(color: Colors.black)),
                                  const SizedBox(height: 8),
                                  if (isOwner)
                                    TextField(
                                      controller: _descriptionController,
                                      maxLines: 10,
                                      onChanged: (v) => description = v,
                                      decoration: const InputDecoration(border: OutlineInputBorder()),
                                    )
                                  else
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(description.isNotEmpty ? description : 'No description', style: const TextStyle(color: Colors.black)),
                                    ),
                                  const SizedBox(height: 8),
                                  if (isOwner)
                                    ElevatedButton(onPressed: _saveDescription, child: const Text('Save description')),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

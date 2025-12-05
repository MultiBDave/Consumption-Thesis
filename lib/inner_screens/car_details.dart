import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../helper/firebase.dart' as fb;
import '../models/reminder.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../helper/date_utils.dart';
import '../helper/flutter_flow/flutter_flow_theme.dart';
import '../models/car_entry.dart';
import '../models/extra_cost.dart';
import '../models/fuel_entry.dart';
import '../models/service_item.dart';

class CarDetailsScreen extends StatefulWidget {
  final CarEntry car;
  final bool openServices;
  const CarDetailsScreen({super.key, required this.car, this.openServices = false});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  final GlobalKey _servicesKey = GlobalKey();
  String? imageUrl;
  String description = '';
  String imageDescription = '';
  List<ExtraCost> costs = [];
  List<FuelEntry> fuelEntries = [];
  List<ServiceItem> services = [];
  bool isOwner = false;
  bool loading = true;
  late TextEditingController _descriptionController;
  late TextEditingController _imageDescriptionController;
  // Service interval controllers
  late TextEditingController _lastServiceOdometerController;
  late TextEditingController _serviceIntervalKmController;
  late TextEditingController _serviceIntervalMonthsController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _imageDescriptionController = TextEditingController();
    _lastServiceOdometerController = TextEditingController(text: widget.car.lastServiceOdometer.toString());
    _serviceIntervalKmController = TextEditingController(text: widget.car.serviceIntervalKm.toString());
    _serviceIntervalMonthsController = TextEditingController(text: widget.car.serviceIntervalMonths.toString());
    _loadDetails();
  }

  // Common maintenance presets (label, default km interval, default months interval)
  final List<Map<String, dynamic>> _servicePresets = [
    {'label': 'Oil change', 'km': 10000, 'months': 6},
    {'label': 'Tyre rotation', 'km': 10000, 'months': 6},
    {'label': 'Brake check / pads', 'km': 30000, 'months': 12},
    {'label': 'Air filter', 'km': 20000, 'months': 12},
    {'label': 'Timing belt', 'km': 100000, 'months': 60},
    {'label': 'Battery check', 'km': 24000, 'months': 12},
    {'label': 'Transmission service', 'km': 60000, 'months': 48},
    {'label': 'Coolant change', 'km': 50000, 'months': 36},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _imageDescriptionController.dispose();
    _lastServiceOdometerController.dispose();
    _serviceIntervalKmController.dispose();
    _serviceIntervalMonthsController.dispose();
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
    // Load services and ensure defaults exist
    services = await _loadServicesForCarLocal(widget.car.id);
    final defaults = {
      'Timing belt/ Timing chain change': {'km': 70000, 'months': 60},
      'Oil change': {'km': 10000, 'months': 12},
      'Transmission fluid change': {'km': 60000, 'months': 60},
      'Tyre balance/change': {'km': 20000, 'months': 12},
      'Suspension check': {'km': 20000, 'months': 12},
    };
    for (var key in defaults.keys) {
      final exists = services.any((s) => s.name == key);
      if (!exists) {
        final now = DateTime.now();
        final preset = defaults[key]!;
        final service = ServiceItem(
          id: now.millisecondsSinceEpoch + key.hashCode,
          carId: widget.car.id,
          name: key,
          lastKm: 0,
          lastDate: null,
          intervalKm: preset['km'] as int,
          intervalMonths: preset['months'] as int,
          ownerUsername: widget.car.ownerUsername,
        );
        await _addServiceLocal(service);
        services.add(service);
      }
    }

    // ensure controller is synced with loaded description
    _descriptionController.text = description;
    _imageDescriptionController.text = imageDescription;
    // sync controllers for service defaults (if any)
    if (services.isNotEmpty) {
      // keep controllers ready; UI uses per-item controllers where needed
    }
    setState(() {
      loading = false;
    });

    // If requested, scroll to the services card after the frame
    if (widget.openServices) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _servicesKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
        }
      });
    }
  }

  // Local service helpers (use Firestore directly to avoid cross-import issues)
  Future<List<ServiceItem>> _loadServicesForCarLocal(int carId) async {
    List<ServiceItem> services = [];
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Services').where('carId', isEqualTo: carId).get();
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      services.add(ServiceItem.fromMap(data));
    }
    return services;
  }

  Future<void> _addServiceLocal(ServiceItem service) async {
    final data = service.toMap();
    await FirebaseFirestore.instance.collection('Services').add(data);
  }

  Future<void> _updateServiceLocal(ServiceItem service) async {
    final snap = await FirebaseFirestore.instance.collection('Services').where('id', isEqualTo: service.id).limit(1).get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.set(service.toMap(), SetOptions(merge: true));
    } else {
      await FirebaseFirestore.instance.collection('Services').add(service.toMap());
    }
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
                                // Active toggle for owners (hidden entirely for non-owners)
                                Builder(builder: (ctx) {
                                  final userEmail = FirebaseAuth.instance.currentUser?.email;
                                  final isOwner = userEmail != null && userEmail == car.ownerUsername;
                                  if (!isOwner) return const SizedBox.shrink();
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Active', style: TextStyle(fontSize: 12)),
                                      Switch(
                                        value: car.active,
                                        onChanged: (val) async {
                                          final scaffold = ScaffoldMessenger.of(ctx);
                                          setState(() => car.active = val);
                                          await fb.modifyCarEntryInDb(car);
                                          if (val) {
                                            final existing = await fb.loadRemindersForUser(car.ownerUsername);
                                            final exists = existing.any((r) => r.carId == car.id && r.title == 'Tyre pressure check');
                                            if (!exists) {
                                              final now = DateTime.now();
                                              final rem = Reminder(
                                                id: now.millisecondsSinceEpoch,
                                                carId: car.id,
                                                title: 'Tyre pressure check',
                                                description: 'Monthly tyre pressure check',
                                                date: addMonths(now, 1),
                                                ownerUsername: car.ownerUsername,
                                              );
                                              await fb.addReminderToDb(rem);
                                            }
                                            if (!mounted) return;
                                            scaffold.showSnackBar(const SnackBar(content: Text('Car activated — tyre reminders enabled')));
                                          } else {
                                            final existing = await fb.loadRemindersForUser(car.ownerUsername);
                                            for (var r in existing.where((r) => r.carId == car.id && r.title == 'Tyre pressure check')) {
                                              await fb.removeReminderFromDb(r.id);
                                            }
                                            if (!mounted) return;
                                            scaffold.showSnackBar(const SnackBar(content: Text('Car deactivated — tyre reminders removed')));
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                }),
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
                        // Service / maintenance settings (owners only)
                          if (isOwner)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Card(
                              key: _servicesKey,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Service & maintenance', style: FlutterFlowTheme.of(context).titleMedium.copyWith(color: Colors.black)),
                                    const SizedBox(height: 6),
                                    // (Preset/quick inputs removed — only per-service rows shown)
                                    const SizedBox(height: 12),
                                    // Per-service list (compact)
                                    const SizedBox(height: 8),
                                    ...services.map((s) {
                                      final TextEditingController lastKmCtrl = TextEditingController(text: s.lastKm.toString());
                                      final TextEditingController intKmCtrl = TextEditingController(text: s.intervalKm.toString());
                                      final TextEditingController intMoCtrl = TextEditingController(text: s.intervalMonths.toString());
                                      // compute next due date if possible
                                      DateTime? nextDueDate;
                                      if (s.lastDate != null && s.intervalMonths > 0) {
                                        try {
                                          nextDueDate = addMonths(s.lastDate!, s.intervalMonths);
                                        } catch (_) {
                                          nextDueDate = null;
                                        }
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  if (nextDueDate != null)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 2.0),
                                                      child: Text('Next due: ${DateFormat('MMM d, yyyy').format(nextDueDate)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 90,
                                              child: TextField(controller: lastKmCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Last km', isDense: true, border: OutlineInputBorder())),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 90,
                                              child: TextField(controller: intKmCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Int km', isDense: true, border: OutlineInputBorder())),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 80,
                                              child: TextField(controller: intMoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mo', isDense: true, border: OutlineInputBorder())),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.calendar_today),
                                              tooltip: 'Set last service date',
                                              onPressed: () async {
                                                final picked = await showDatePicker(context: context, initialDate: s.lastDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 3650)));
                                                if (picked != null) {
                                                  s.lastDate = picked;
                                                  await _updateServiceLocal(s);
                                                  setState(() {});
                                                }
                                              },
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                s.lastKm = int.tryParse(lastKmCtrl.text) ?? s.lastKm;
                                                s.intervalKm = int.tryParse(intKmCtrl.text) ?? s.intervalKm;
                                                s.intervalMonths = int.tryParse(intMoCtrl.text) ?? s.intervalMonths;
                                                await _updateServiceLocal(s);
                                                // also create/update a date-based reminder if intervalMonths set
                                                  if (s.lastDate != null && s.intervalMonths > 0) {
                                                    final nextDate = addMonths(s.lastDate!, s.intervalMonths);
                                                  final existing = await fb.loadRemindersForUser(s.ownerUsername);
                                                  final matches = existing.where((r) => r.carId == s.carId && r.title == 'Service due: ${s.name}').toList();
                                                  if (matches.isNotEmpty) {
                                                    final ex = matches.first;
                                                    ex.date = nextDate;
                                                    await fb.updateReminderInDb(ex);
                                                  } else {
                                                    final now = DateTime.now();
                                                    final rem = Reminder(id: now.millisecondsSinceEpoch + s.name.hashCode, carId: s.carId!, title: 'Service due: ${s.name}', description: 'Scheduled service for ${s.name}', date: nextDate, ownerUsername: s.ownerUsername);
                                                    await fb.addReminderToDb(rem);
                                                  }
                                                }
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service saved')));
                                                setState(() {});
                                              },
                                              child: const Text('Save'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

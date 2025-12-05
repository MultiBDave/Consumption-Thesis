import 'package:flutter/material.dart';
import 'helper/persistent_bottom_bar_scaffold.dart';
import 'inner_screens/my_entries.dart';
import 'inner_screens/list_cars.dart';
import 'inner_screens/car_details.dart';
import 'package:intl/intl.dart';
import 'models/reminder.dart';
import 'models/car_entry.dart';
import 'helper/firebase.dart' as fb;

class HomePage extends StatefulWidget {
  static String id = 'home_page';

  final List<Reminder>? overdueReminders;

  HomePage({super.key, this.overdueReminders});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _tab1navigatorKey = GlobalKey<NavigatorState>();
  final _tab2navigatorKey = GlobalKey<NavigatorState>();
  @override
  void initState() {
    super.initState();
    if (widget.overdueReminders != null && widget.overdueReminders!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOverdueDialog());
    }
  }

  Future<void> _showOverdueDialog() async {
    final reminders = widget.overdueReminders!;
    // load cars once to map ids to CarEntry
    final cars = await fb.loadCarEntrysFromFirestore();
    final Map<int, CarEntry> carById = {for (var c in cars) c.id: c};

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Overdue service(s)'),
            content: SizedBox(
              width: 360,
              height: 260,
              child: ListView.separated(
                itemCount: reminders.length,
                separatorBuilder: (c, i) => const Divider(),
                itemBuilder: (c, i) {
                  final r = reminders[i];
                  final car = r.carId != null ? carById[r.carId!] : null;
                  final carName = car != null && car.make.isNotEmpty ? '${car.make} ${car.model}' : '';
                  final dateText = DateFormat.yMMMd().format(r.date);

                  return ListTile(
                    title: Text(r.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateText, style: const TextStyle(fontSize: 12)),
                        if (carName.isNotEmpty) Text(carName, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                    isThreeLine: carName.isNotEmpty,
                    onTap: car == null
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            Navigator.of(this.context).push(MaterialPageRoute(builder: (ctx) => CarDetailsScreen(car: car, openServices: true)));
                          },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Per-item Later (snooze)
                        IconButton(
                          icon: const Icon(Icons.snooze),
                          tooltip: 'Snooze 7 days',
                          onPressed: () async {
                            final now = DateTime.now();
                            final newDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
                            // store previous date for undo if not already stored
                            r.previousDate = r.previousDate ?? r.date;
                            r.date = newDate;
                            r.snoozedUntil = newDate;
                            await fb.updateReminderInDb(r);
                            setStateDialog(() {});
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Reminder snoozed 7 days')));
                          },
                        ),
                        // Undo snooze if present
                        if (r.snoozedUntil != null)
                          IconButton(
                            icon: const Icon(Icons.undo),
                            tooltip: 'Undo snooze',
                            onPressed: () async {
                              // Restore previous date if available, otherwise set to today
                              final restored = r.previousDate ?? DateTime.now();
                              r.date = restored;
                              r.snoozedUntil = null;
                              r.previousDate = null;
                              await fb.updateReminderInDb(r);
                              setStateDialog(() {});
                              if (!mounted) return;
                              ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Snooze undone')));
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Reschedule all shown reminders to 7 days from now and set snoozedUntil
                  final now = DateTime.now();
                  final newDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
                  for (var r in reminders) {
                    // store previous date if not already set
                    r.previousDate = r.previousDate ?? r.date;
                    r.date = newDate;
                    r.snoozedUntil = newDate;
                    await fb.updateReminderInDb(r);
                  }
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Reminders moved 7 days ahead')));
                },
                child: const Text('Later'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PersistentBottomBarScaffold(
      items: [
        PersistentTabItem(
          tab: const ListCarsScreen(),
          icon: Icons.search,
          title: 'Search',
          navigatorkey: _tab1navigatorKey,
        ),
        PersistentTabItem(
          tab: MyEntries(),
          icon: Icons.notes,
          title: 'My Entries',
          navigatorkey: _tab2navigatorKey,
        ),
      ],
    );
  }
}

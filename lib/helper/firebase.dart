import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car_entry.dart';
import '../models/fuel_entry.dart';
import '../models/extra_cost.dart';

Future<void> addDocumentToCollection(
    String collectionName, Map<String, dynamic> data) async {
  // Add a new document to the collection
  await FirebaseFirestore.instance.collection(collectionName).add(data);
}

Future<void> updateCarEntry(CarEntry carEntry, String documentID) async {
  final documentReference =
      FirebaseFirestore.instance.collection('CarEntrys').doc(documentID);
  final carEntryData = {
    'id': carEntry.id,
    'model': carEntry.model,
    'make': carEntry.make,
    'year': carEntry.year,
    'color': carEntry.color,
    'ownerUsername': carEntry.ownerUsername,
    'location': carEntry.location,
    'type': carEntry.type,
    'drivenKm': carEntry.drivenKm,
    'fuelSum': carEntry.fuelSum,
    'initialKm': carEntry.initialKm,
    'tankSize': carEntry.tankSize,
  };
  await documentReference.set(carEntryData, SetOptions(merge: true));
}

Future<CarEntry> getCarEntryFromDb(int id) async {
  String docID = await getDocumentID(id, 'CarEntrys');
  var snapshot = await FirebaseFirestore.instance.collection('CarEntrys').doc(docID).get();
  final data = snapshot.data()!;

  CarEntry carEntry = CarEntry.fuel(
    id: data['id'],
    model: data['model'],
    make: data['make'],
    year: data['year'],
    color: data['color'],
    ownerUsername: data['ownerUsername'],
    location: data['location'],
    type: data['type'],
    drivenKm: data['drivenKm'],
    fuelSum: data['fuelSum'],
    initialKm: data['initialKm'] ?? 0,
    tankSize: data['tankSize'] ?? 0,
  );
  return carEntry;
}

Future<void> modifyCarEntryInDb(CarEntry carEntry) async {
  final docID = await getDocumentID(carEntry.id, 'CarEntrys');
  if (docID.isEmpty) {
    // If no existing doc, create new
    await addCarEntryToDb(carEntry);
  } else {
    await updateCarEntry(carEntry, docID);
  }
}

Future<void> addCarEntryToDb(CarEntry carEntry) async {
  final carEntryData = {
    'id': carEntry.id,
    'model': carEntry.model,
    'make': carEntry.make,
    'year': carEntry.year,
    'color': carEntry.color,
    'ownerUsername': carEntry.ownerUsername,
    'location': carEntry.location,
    'type': carEntry.type,
    'drivenKm': carEntry.drivenKm,
    'fuelSum': carEntry.fuelSum,
    'initialKm': carEntry.initialKm,
    'tankSize': carEntry.tankSize,
  };
  await addDocumentToCollection('CarEntrys', carEntryData);
}

Future<void> removeCarEntryFromDb(int id) async {
  final docID = await getDocumentID(id, 'CarEntrys');
  if (docID.isEmpty) return;
  await FirebaseFirestore.instance.collection('CarEntrys').doc(docID).delete();
}

Future<String> getDocumentID(int id, String collection) async {
  var snapshot =
      await FirebaseFirestore.instance.collection(collection).where('id', isEqualTo: id).get();

  if (snapshot.docs.isEmpty) {
    return '';
  } else {
    return snapshot.docs[0].id;
  }
}

Future<List<CarEntry>> loadCarEntrysFromFirestore() async {
  List<CarEntry> CarEntrys = [];
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('CarEntrys').get();
  for (var doc in querySnapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    CarEntrys.add(CarEntry.fuel(
        id: data['id'],
        model: data['model'],
        make: data['make'],
        year: data['year'],
        color: data['color'],
        ownerUsername: data['ownerUsername'],
        location: data['location'],
        type: data['type'],
        drivenKm: data['drivenKm'],
        fuelSum: data['fuelSum'],
        initialKm: data['initialKm'] ?? 0,
        tankSize: data['tankSize'] ?? 0));
  }
  return CarEntrys;
}

Future<void> addFuelEntryToDb(FuelEntry fuelEntry) async {
  final fuelEntryData = fuelEntry.toMap();
  await addDocumentToCollection('FuelEntries', fuelEntryData);
}

Future<void> updateFuelEntry(FuelEntry fuelEntry) async {
  final docID = await getDocumentID(fuelEntry.id, 'FuelEntries');
  if (docID.isEmpty) {
    // If no existing doc, create new
    await addFuelEntryToDb(fuelEntry);
  } else {
    final documentReference = FirebaseFirestore.instance.collection('FuelEntries').doc(docID);
    await documentReference.set(fuelEntry.toMap(), SetOptions(merge: true));
  }
}

Future<void> removeFuelEntryFromDb(int id) async {
  final docID = await getDocumentID(id, 'FuelEntries');
  if (docID.isEmpty) return;
  await FirebaseFirestore.instance.collection('FuelEntries').doc(docID).delete();
}

Future<FuelEntry?> getFuelEntryFromDb(int id) async {
  String docID = await getDocumentID(id, 'FuelEntries');
  if (docID.isEmpty) return null;
  
  var snapshot = await FirebaseFirestore.instance.collection('FuelEntries').doc(docID).get();
  if (!snapshot.exists) return null;
  
  final data = snapshot.data()!;
  return FuelEntry(
    id: data['id'],
    carId: data['carId'],
    fuelAmount: data['fuelAmount'],
    odometer: data['odometer'],
    date: (data['date'] as Timestamp).toDate(),
    cost: (data['cost'] is num) ? (data['cost'] as num).toDouble() : 0.0,
  );
}

Future<List<FuelEntry>> loadFuelEntriesForCar(int carId) async {
  List<FuelEntry> fuelEntries = [];
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('FuelEntries')
      .where('carId', isEqualTo: carId)
      .orderBy('date', descending: true)
      .get();
      
  for (var doc in querySnapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    fuelEntries.add(FuelEntry(
      id: data['id'],
      carId: data['carId'],
      fuelAmount: data['fuelAmount'],
      odometer: data['odometer'],
      date: (data['date'] as Timestamp).toDate(),
      cost: (data['cost'] is num) ? (data['cost'] as num).toDouble() : 0.0,
    ));
  }
  return fuelEntries;
}

// Extra costs (maintenance, insurance, tolls, etc.)
Future<void> addExtraCostToDb(ExtraCost cost) async {
  final data = cost.toMap();
  await addDocumentToCollection('ExtraCosts', data);
}

Future<void> removeExtraCostFromDb(int id) async {
  final docID = await getDocumentID(id, 'ExtraCosts');
  if (docID.isEmpty) return;
  await FirebaseFirestore.instance.collection('ExtraCosts').doc(docID).delete();
}

Future<void> updateExtraCostInDb(ExtraCost cost) async {
  final docID = await getDocumentID(cost.id, 'ExtraCosts');
  final data = cost.toMap();
  if (docID.isEmpty) {
    // If it doesn't exist yet, add it
    await addExtraCostToDb(cost);
  } else {
    final documentReference = FirebaseFirestore.instance.collection('ExtraCosts').doc(docID);
    await documentReference.set(data, SetOptions(merge: true));
  }
}

Future<List<ExtraCost>> loadExtraCostsForCar(int carId) async {
  List<ExtraCost> costs = [];
  // Avoid server-side ordering to prevent requiring a composite index.
  // We'll fetch by carId and sort locally by date descending.
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('ExtraCosts')
      .where('carId', isEqualTo: carId)
      .get();

  for (var doc in querySnapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    costs.add(ExtraCost.fromMap(data));
  }

  costs.sort((a, b) => b.date.compareTo(a.date));
  return costs;
}

Future<double> calculateConsumptionFromEntries(int carId, int initialKm) async {
  List<FuelEntry> entries = await loadFuelEntriesForCar(carId);
  if (entries.isEmpty) return 0.0;
  
  entries.sort((a, b) => a.odometer.compareTo(b.odometer));
  
  int totalFuel = entries.fold(0, (sum, entry) => sum + entry.fuelAmount);
  int maxOdometer = entries.isEmpty ? initialKm : entries.map((e) => e.odometer).reduce((a, b) => a > b ? a : b);
  int distanceDriven = maxOdometer - initialKm;
  
  if (distanceDriven <= 0 || totalFuel <= 0) return 0.0;
  
  return (totalFuel / distanceDriven) * 100;
}

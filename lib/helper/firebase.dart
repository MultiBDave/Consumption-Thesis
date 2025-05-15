import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car_entry.dart';

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

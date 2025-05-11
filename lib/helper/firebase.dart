import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../models/car_entry.dart';

Future<void> addDocumentToCollection(
    String collectionName, Map<String, dynamic> data) async {
  // Add a new document to the collection
  await db.collection(collectionName).add(data);
}

void updateCarEntry(CarEntry CarEntry, String documentID) {
  DocumentReference documentReference =
      FirebaseFirestore.instance.collection('CarEntrys').doc(documentID);
  Map<String, dynamic> CarEntryData = {
    'id': CarEntry.id,
    'model': CarEntry.model,
    'make': CarEntry.make,
    'year': CarEntry.year,
    'color': CarEntry.color,
    'ownerUsername': CarEntry.ownerUsername,
    'location': CarEntry.location,
    'type': CarEntry.type,
    'drivenKm': CarEntry.drivenKm,
    'fuelSum': CarEntry.fuelSum,
    'initialKm': CarEntry.initialKm,
    'tankSize': CarEntry.tankSize,
  };
  documentReference.set(CarEntryData, SetOptions(merge: true));
}

Future<CarEntry> getCarEntryFromDb(int id) async {
  String docID = await getDocumentID(id, 'CarEntrys');
  var snapshot = await db.collection('CarEntrys').doc(docID).get();
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

void modifyCarEntryInDb(CarEntry CarEntry) async {
  String docID = await getDocumentID(CarEntry.id, 'CarEntrys');
  updateCarEntry(CarEntry, docID);
}

void addCarEntryToDb(CarEntry CarEntry) {
  Map<String, dynamic> CarEntryData = {
    'id': CarEntry.id,
    'model': CarEntry.model,
    'make': CarEntry.make,
    'year': CarEntry.year,
    'color': CarEntry.color,
    'ownerUsername': CarEntry.ownerUsername,
    'location': CarEntry.location,
    'type': CarEntry.type,
    'drivenKm': CarEntry.drivenKm,
    'fuelSum': CarEntry.fuelSum,
    'initialKm': CarEntry.initialKm,
    'tankSize': CarEntry.tankSize,
  };
  addDocumentToCollection('CarEntrys', CarEntryData);
}

void removeCarEntryFromDb(int id) async {
  String docID = await getDocumentID(id, 'CarEntrys');
  await db.collection('CarEntrys').doc(docID).delete();
}

Future<String> getDocumentID(int id, String collection) async {
  var snapshot =
      await db.collection(collection).where('id', isEqualTo: id).get();

  if (snapshot.docs.isEmpty) {
    return '';
  } else {
    return snapshot.docs[0].id;
  }
}

Future<List<CarEntry>> loadCarEntrysFromFirestore() async {
  List<CarEntry> CarEntrys = [];
  QuerySnapshot querySnapshot = await db.collection('CarEntrys').get();
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

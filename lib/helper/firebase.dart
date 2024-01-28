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
  };
  documentReference.set(CarEntryData, SetOptions(merge: true));
}

Future<CarEntry> getCarEntryFromDb(int id) async {
  String docID = await getDocumentID(id, 'CarEntrys');
  var snapshot = await db.collection('CarEntrys').doc(docID).get();
  CarEntry carEntry = CarEntry.fuel(
    id: snapshot.data()!['id'],
    model: snapshot.data()!['model'],
    make: snapshot.data()!['make'],
    year: snapshot.data()!['year'],
    color: snapshot.data()!['color'],
    ownerUsername: snapshot.data()!['ownerUsername'],
    location: snapshot.data()!['location'],
    type: snapshot.data()!['type'],
    drivenKm: snapshot.data()!['drivenKm'],
    fuelSum: snapshot.data()!['fuelSum'],
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
    CarEntrys.add(CarEntry.fuel(
        id: doc['id'],
        model: doc['model'],
        make: doc['make'],
        year: doc['year'],
        color: doc['color'],
        ownerUsername: doc['ownerUsername'],
        location: doc['location'],
        type: doc['type'],
        drivenKm: doc['drivenKm'],
        fuelSum: doc['fuelSum']));
  }
  return CarEntrys;
}

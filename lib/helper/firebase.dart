import 'package:cloud_firestore/cloud_firestore.dart';
import '../inner_screens/fuel_management_page.dart';
import '../main.dart';
import '../models/car_entry.dart';

Future<void> addDocumentToCollection(
    String collectionName, Map<String, dynamic> data) async {
  // Add a new document to the collection
  await db.collection(collectionName).add(data);
}

void addFuelEntryToDb(int carId, FuelEntry entry) {
  Map<String, dynamic> fuelEntryData = {
    'id': entry.id,
    'carId': carId,
    'fuelAmount': entry.fuelAmount,
    'pricePerUnit': entry.pricePerUnit,
    'kmDriven': entry.kmDriven,
    'date': Timestamp.now(),
  };
  addDocumentToCollection('FuelEntries', fuelEntryData);
}

Future<List<FuelEntry>> loadFuelEntriesFromDb(CarEntry car) async {
  List<FuelEntry> fuelEntries = [];
  QuerySnapshot querySnapshot = await db
      .collection('FuelEntries')
      .where('carId', isEqualTo: car.id)
      .get();
  for (var doc in querySnapshot.docs) {
    fuelEntries.add(FuelEntry(
      id: doc['id'],
      carId: doc['carId'],
      fuelAmount: doc['fuelAmount'],
      pricePerUnit: doc['pricePerUnit'],
      kmDriven: doc['kmDriven'],
      date: doc['date'],
    ));
  }
  return fuelEntries;
}

void removeFuelEntryFromDb(FuelEntry fuelEntry) async {
  String docID = await getDocumentID(fuelEntry.id, 'FuelEntries');
  await db.collection('FuelEntries').doc(docID).delete();
}

updateFuelEntry(FuelEntry fuelEntry, String documentID) {
  DocumentReference documentReference =
      FirebaseFirestore.instance.collection('FuelEntries').doc(documentID);
  Map<String, dynamic> fuelEntryData = {
    'id': fuelEntry.id,
    'carId': fuelEntry.carId,
    'fuelAmount': fuelEntry.fuelAmount,
    'pricePerUnit': fuelEntry.pricePerUnit,
    'kmDriven': fuelEntry.kmDriven,
    'date': fuelEntry.date,
  };
  documentReference.set(fuelEntryData, SetOptions(merge: true));
}

loadConsumptionFromCar(CarEntry car) async {
  List<FuelEntry> fuelEntries = await loadFuelEntriesFromDb(car);
  int fuelSum = 0;
  int drivenKm = 0;
  for (var entry in fuelEntries) {
    fuelSum += entry.fuelAmount;
    drivenKm += entry.kmDriven;
  }
  car.fuelSum = fuelSum;
  car.drivenKmSincePurchase = drivenKm;
  car.refreshConsumption();
  modifyCarEntryInDb(car);
}

modifyFuelEntryInDb(FuelEntry fuelEntry) async {
  String docID = await getDocumentID(fuelEntry.id, 'FuelEntries');
  updateFuelEntry(fuelEntry, docID);
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
    'drivenKmSincePurchase': CarEntry.drivenKmSincePurchase,
    'fuelSum': CarEntry.fuelSum,
    'consumption': CarEntry.consumption,
    'moneySpentOnFuel': CarEntry.moneySpentOnFuel
  };
  documentReference.set(CarEntryData, SetOptions(merge: true));
}

Future<List<CarEntry>> getUserCars(String username) async {
  List<CarEntry> userCars = [];
  QuerySnapshot querySnapshot = await db
      .collection('CarEntrys')
      .where('ownerUsername', isEqualTo: username)
      .get();
  for (var doc in querySnapshot.docs) {
    userCars.add(CarEntry.fuel(
        id: doc['id'],
        model: doc['model'],
        make: doc['make'],
        year: doc['year'],
        color: doc['color'],
        ownerUsername: doc['ownerUsername'],
        location: doc['location'],
        type: doc['type'],
        drivenKm: doc['drivenKm'],
        drivenKmSincePurchase: doc['drivenKmSincePurchase'] ?? 0,
        fuelSum: doc['fuelSum'],
        consumption: doc['consumption'],
        moneySpentOnFuel: doc['moneySpentOnFuel'] ?? 0.0));
  }
  return userCars;
}

Future<CarEntry> getCarEntryFromDb(int id) async {
  String docID = await getDocumentID(id, 'CarEntrys');
  var snapshot = await db.collection('CarEntrys').doc(docID).get();
  int drivenSincePurchase = 0;
  if (snapshot.data()!.containsKey('drivenKmSincePurchase')) {
    drivenSincePurchase = snapshot.data()!['drivenKmSincePurchase'];
  }
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
    drivenKmSincePurchase: drivenSincePurchase,
    fuelSum: snapshot.data()!['fuelSum'],
    consumption: snapshot.data()!['consumption'],
    moneySpentOnFuel: snapshot.data()!['moneySpentOnFuel'],
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
    'drivenKmSincePurchase':
        0, // 'drivenKmSincePurchase' is not used in 'CarEntry.fuel
    'fuelSum': CarEntry.fuelSum,
    'consumption': 0.0,
    'moneySpentOnFuel': 0.0
  };
  addDocumentToCollection('CarEntrys', CarEntryData);
}

void removeCarEntryFromDb(CarEntry CarEntry) async {
  String docID = await getDocumentID(CarEntry.id, 'CarEntrys');
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
  int drivenSincePurchase = 0;
  for (var doc in querySnapshot.docs) {
    if (doc['drivenKmSincePurchase'] != null) {
      drivenSincePurchase = doc['drivenKmSincePurchase'];
    }
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
        drivenKmSincePurchase: doc['drivenKmSincePurchase'] ?? 0,
        fuelSum: doc['fuelSum'],
        consumption: doc['consumption'],
        moneySpentOnFuel: doc['moneySpentOnFuel'] ?? 0.0));
  }
  return CarEntrys;
}

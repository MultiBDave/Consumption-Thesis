class FuelEntry {
  int id;
  int carId;
  int fuelAmount;
  int odometer;
  DateTime date;

  FuelEntry({
    required this.id,
    required this.carId,
    required this.fuelAmount,
    required this.odometer,
    required this.date,
  });

  // Create from Firestore data
  factory FuelEntry.fromMap(Map<String, dynamic> map) {
    return FuelEntry(
      id: map['id'],
      carId: map['carId'],
      fuelAmount: map['fuelAmount'],
      odometer: map['odometer'],
      date: map['date'].toDate(),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carId': carId,
      'fuelAmount': fuelAmount,
      'odometer': odometer,
      'date': date,
    };
  }
}

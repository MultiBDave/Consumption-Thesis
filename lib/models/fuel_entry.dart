class FuelEntry {
  int id;
  int carId;
  int fuelAmount;
  int odometer;
  DateTime date;
  double cost; // total cost for this fill-up (in default currency)

  FuelEntry({
    required this.id,
    required this.carId,
    required this.fuelAmount,
    required this.odometer,
    required this.date,
    this.cost = 0.0,
  });

  // Create from Firestore data
  factory FuelEntry.fromMap(Map<String, dynamic> map) {
    return FuelEntry(
      id: map['id'],
      carId: map['carId'],
      fuelAmount: map['fuelAmount'],
      odometer: map['odometer'],
      date: (map['date'] as dynamic).toDate(),
      cost: (map['cost'] is num) ? (map['cost'] as num).toDouble() : 0.0,
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
      'cost': cost,
    };
  }
}

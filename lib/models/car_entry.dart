import 'package:consumption/helper/firebase.dart';

class CarEntry {
  int id;
  String make;
  String model;
  int year;
  String color;
  String ownerUsername;
  String location;
  String type;
  int drivenKm;
  int drivenKmSincePurchase = 0;
  int fuelSum = 0;
  String consumption = "";

  CarEntry(
      {required this.id,
      required this.make,
      required this.model,
      required this.year,
      required this.color,
      required this.ownerUsername,
      required this.location,
      required this.type,
      required this.drivenKm,
      required this.drivenKmSincePurchase});

  CarEntry.fuel({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.ownerUsername,
    required this.location,
    required this.type,
    required this.drivenKm,
    required this.drivenKmSincePurchase,
    required this.fuelSum,
  });

  String getConsumption() {
    print(consumption);
    return (fuelSum / drivenKmSincePurchase * 100).toStringAsFixed(2);
  }

  void refreshConsumption() {
    consumption = getConsumption();
    print(consumption);
    modifyCarEntryInDb(this);
  }

  CarEntry.empty()
      : id = 0,
        make = "",
        model = "",
        year = 0,
        color = "",
        ownerUsername = "",
        location = "",
        type = "",
        drivenKm = 0;
}

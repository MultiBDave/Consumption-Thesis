import 'package:consumption/inner_screens/my_entries.dart';

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
  double consumption = 0.0;
  double moneySpentOnFuel = 0.0;

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
      required this.drivenKmSincePurchase,
      required this.consumption,
      required this.moneySpentOnFuel});

  CarEntry.fuel(
      {required this.id,
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
      required this.consumption,
      required this.moneySpentOnFuel});

  void refreshConsumption() {
    consumption = (fuelSum / drivenKmSincePurchase * 100);
  }

  CarEntry.empty()
      : id = ownCars.length + 1,
        make = "",
        model = "",
        year = 0,
        color = "",
        ownerUsername = "",
        location = "",
        type = "",
        drivenKm = 0;
}

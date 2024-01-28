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
  int fuelSum = 0;
  String consumption = "";

  CarEntry({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.ownerUsername,
    required this.location,
    required this.type,
    required this.drivenKm,
  });

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
    required this.fuelSum,
  });

  String getConsumption() {
    return (fuelSum / drivenKm * 100).toStringAsFixed(2);
  }

  void refreshConsumption() {
    consumption = getConsumption();
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

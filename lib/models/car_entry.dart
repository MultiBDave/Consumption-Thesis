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
  int initialKm = 0; // Initial mileage for used cars
  int fuelSum = 0;
  int tankSize = 0; // Tank size in liters
  String consumption = "";
  String estimatedRange = ""; // Estimated range with full tank

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
    this.initialKm = 0,
    this.tankSize = 0,
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
    this.initialKm = 0,
    this.tankSize = 0,
  });

  String getConsumption() {
    // Calculate actual driven kilometers (excluding initial km)
    int actualKm = drivenKm - initialKm;
    if (actualKm <= 0 || fuelSum <= 0) {
      return "0.00";
    }
    return (fuelSum / actualKm * 100).toStringAsFixed(2);
  }

  void refreshConsumption() {
    consumption = getConsumption();
    updateEstimatedRange();
  }
  
  void updateEstimatedRange() {
    if (tankSize <= 0 || consumption == "0.00") {
      estimatedRange = "N/A";
      return;
    }
    
    // Calculate estimated range with full tank
    double consumptionValue = double.tryParse(consumption) ?? 0.0;
    if (consumptionValue <= 0) {
      estimatedRange = "N/A";
      return;
    }
    
    int range = ((tankSize / consumptionValue) * 100).round();
    estimatedRange = "$range km";
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
        drivenKm = 0,
        initialKm = 0,
        tankSize = 0;
}

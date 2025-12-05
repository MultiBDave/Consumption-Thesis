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
  String imageUrl = '';
  String description = '';
  String consumption = "";
  String estimatedRange = ""; // Estimated range with full tank
  bool active = false; // Whether the car is active/in use
  // Service interval fields
  int lastServiceOdometer = 0;
  DateTime? lastServiceDate;
  int serviceIntervalKm = 0; // interval in km between services
  int serviceIntervalMonths = 0; // interval in months between services

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
    this.imageUrl = '',
    this.description = '',
    this.active = false,
    this.lastServiceOdometer = 0,
    this.lastServiceDate,
    this.serviceIntervalKm = 0,
    this.serviceIntervalMonths = 0,
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
    this.imageUrl = '',
    this.description = '',
    this.active = false,
    this.lastServiceOdometer = 0,
    this.lastServiceDate,
    this.serviceIntervalKm = 0,
    this.serviceIntervalMonths = 0,
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
        
  DateTime? nextServiceDate() {
    if (lastServiceDate == null) return null;
    if (serviceIntervalMonths <= 0) return null;
    // Add months using calendar-month arithmetic instead of approximating
    // months as 30 days. This preserves month boundaries (e.g. Jan 31 + 1
    // month -> Feb 28/29).
    DateTime addMonths(DateTime date, int months) {
      final int newMonth = date.month + months;
      int year = date.year + (newMonth - 1) ~/ 12;
      int month = ((newMonth - 1) % 12) + 1;
      // clamp day to last day of target month
      int day = date.day;
      int daysInTargetMonth(int y, int m) {
        final nextMonth = m == 12 ? DateTime(y + 1, 1, 1) : DateTime(y, m + 1, 1);
        return nextMonth.subtract(const Duration(days: 1)).day;
      }

      final maxDay = daysInTargetMonth(year, month);
      if (day > maxDay) day = maxDay;
      return DateTime(year, month, day, date.hour, date.minute, date.second, date.millisecond, date.microsecond);
    }

    return addMonths(lastServiceDate!, serviceIntervalMonths);
  }
        
}

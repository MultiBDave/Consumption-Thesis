import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:fast_csv/fast_csv.dart' as _fast_csv;

Map<String, List<String>> carData = {};

Future<void> loadCsvData() async {
  final rawData = await rootBundle.loadString('csv/2020.csv');

  final csvTable = _fast_csv.parse(rawData);

  // Check if the data is read correctly
  print("CSV Table first row (should be headers): ${csvTable.first}");
  print("CSV Table second row (should be first data row): ${csvTable[1]}");

  for (var row in csvTable.sublist(1)) {
    String make = row[1].toString();
    String model = row[2].toString();
    if (carData.containsKey(make)) {
      if (!carData[make]!.contains(model)) {
        carData[make]!.add(model);
      }
    } else {
      carData[make] = [model];
    }
  }

  // Debug print to check what carData contains after processing
  print("Car Data Loaded: $carData");
}

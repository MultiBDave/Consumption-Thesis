import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceItem {
  int id;
  int? carId;
  String name;
  int lastKm;
  DateTime? lastDate;
  int intervalKm;
  int intervalMonths;
  String ownerUsername;

  ServiceItem({
    required this.id,
    this.carId,
    required this.name,
    required this.lastKm,
    this.lastDate,
    required this.intervalKm,
    required this.intervalMonths,
    required this.ownerUsername,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carId': carId,
      'name': name,
      'lastKm': lastKm,
      'lastDate': lastDate != null ? Timestamp.fromDate(lastDate!) : null,
      'intervalKm': intervalKm,
      'intervalMonths': intervalMonths,
      'ownerUsername': ownerUsername,
    };
  }

  factory ServiceItem.fromMap(Map<String, dynamic> m) {
    return ServiceItem(
      id: m['id'],
      carId: m['carId'],
      name: m['name'] ?? '',
      lastKm: m['lastKm'] ?? 0,
      lastDate: m['lastDate'] != null ? (m['lastDate'] as Timestamp).toDate() : null,
      intervalKm: m['intervalKm'] ?? 0,
      intervalMonths: m['intervalMonths'] ?? 0,
      ownerUsername: m['ownerUsername'] ?? '',
    );
  }
}

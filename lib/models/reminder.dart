import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  int id;
  int? carId; // null means a user-level reminder not tied to a car
  String title;
  String description;
  DateTime date;
  String ownerUsername;

  Reminder({
    required this.id,
    this.carId,
    required this.title,
    required this.description,
    required this.date,
    required this.ownerUsername,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carId': carId,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'ownerUsername': ownerUsername,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> m) {
    return Reminder(
      id: m['id'],
      carId: m['carId'],
      title: m['title'] ?? '',
      description: m['description'] ?? '',
      date: (m['date'] as Timestamp).toDate(),
      ownerUsername: m['ownerUsername'] ?? '',
    );
  }
}

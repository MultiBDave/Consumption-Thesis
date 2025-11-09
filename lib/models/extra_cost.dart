class ExtraCost {
  int id;
  int carId;
  double amount;
  String category; // e.g., maintenance, insurance, toll
  String description;
  DateTime date;

  ExtraCost({
    required this.id,
    required this.carId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
  });

  factory ExtraCost.fromMap(Map<String, dynamic> map) {
    return ExtraCost(
      id: map['id'],
      carId: map['carId'],
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carId': carId,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date,
    };
  }
}

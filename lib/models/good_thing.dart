class GoodThing {
  const GoodThing({
    required this.id,
    required this.date,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime date;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;

  GoodThing copyWith({
    String? id,
    DateTime? date,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoodThing(
      id: id ?? this.id,
      date: date ?? this.date,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': _dateKey(date),
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GoodThing.fromMap(Map<String, Object?> map) {
    return GoodThing(
      id: map['id']! as String,
      date: DateTime.parse(map['date']! as String),
      text: map['text']! as String,
      createdAt: DateTime.parse(map['createdAt']! as String),
      updatedAt: DateTime.parse(map['updatedAt']! as String),
    );
  }

  static String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.isArchived,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String emoji;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;

  Habit copyWith({
    String? id,
    String? name,
    String? emoji,
    bool? isArchived,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'isArchived': isArchived,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, Object?> map) {
    return Habit(
      id: map['id']! as String,
      name: map['name']! as String,
      emoji: map['emoji'] as String? ?? '✓',
      isArchived: map['isArchived'] as bool? ?? false,
      sortOrder: map['sortOrder'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt']! as String),
    );
  }
}

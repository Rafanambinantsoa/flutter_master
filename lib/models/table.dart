class DiningTable {
  final String id;
  final int number;
  final int capacity;

  DiningTable({required this.id, required this.number, required this.capacity});

  /// Vérifie si deux tables sont égales basées sur leur ID
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiningTable &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

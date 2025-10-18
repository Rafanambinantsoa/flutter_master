class DiningTable {
  final String id;
  final int number;
  final int capacity;
  bool isOccupied;

  DiningTable({
    required this.id,
    required this.number,
    required this.capacity,
    this.isOccupied = false,
  });
}

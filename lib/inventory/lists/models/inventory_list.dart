class InventoryList {
  final int id;
  final String name;
  final String type;
  final int sortOrder;

  InventoryList(this.id, this.name,
      {this.type = 'REGULAR', this.sortOrder = 0});

  bool get isOpenList => type.toUpperCase() == 'OPEN';

  factory InventoryList.fromJson(Map<String, dynamic> json) {
    return InventoryList(
      json['id'],
      json['name'],
      type: json['type'] ?? 'REGULAR',
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

class InventoryList {
  final int id;
  final String name;
  final String type;

  InventoryList(this.id, this.name, {this.type = 'REGULAR'});

  bool get isOpenList => type.toUpperCase() == 'OPEN';

  factory InventoryList.fromJson(Map<String, dynamic> json) {
    return InventoryList(
      json['id'],
      json['name'],
      type: json['type'] ?? 'REGULAR',
    );
  }
}

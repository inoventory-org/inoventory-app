class InventoryList {
  final int id;
  final String name;

  InventoryList(this.id, this.name);

  factory InventoryList.fromJson(Map<String, dynamic> json) {
    return InventoryList(
      json['id'],
      json['name'],
    );
  }
}
import 'package:inoventory_ui/config/constants.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inoventory_ui/models/inventory_list_item.dart';

abstract class ItemService {
  static const backendUrl = Constants.inoventoryBackendUrl;
  static const listUrl = "$backendUrl/api/v1/inventory-lists";

  Future<List<InventoryListItem>> all(int listId);
  Future<InventoryListItem> add(InventoryListItem item);
  Future<InventoryListItem> update(int itemId, InventoryListItem updatedItem);
  Future<void> delete(int listId, int itemId);

  String getSpecificListUrl(int listId) {
    return "$listUrl/$listId/items";
  }

  String getSpecificItemUrl(int listId, int itemId) {
    return "$listUrl/$listId/items/$itemId";
  }
}

class ItemServiceImpl extends ItemService {
  @override
  Future<InventoryListItem> add(InventoryListItem item) async {
    final response = await http.post(Uri.parse(getSpecificListUrl(item.listId)),
        headers: {HttpHeaders.contentTypeHeader: "application/json"},
        body: jsonEncode(<String, dynamic>{
          "listId": item.listId.toString(),
          "productEan": item.productEan,
          "expirationDate": item.expirationDate
        }));

    if (response.statusCode != HttpStatus.created) {
      throw Exception("Failed to create list");
    }

    return InventoryListItem.fromJson(jsonDecode(response.body));
  }

  @override
  Future<List<InventoryListItem>> all(int listId) async {
    final response = await http.get(Uri.parse(getSpecificListUrl(listId)));

    if (response.statusCode != HttpStatus.ok) {
      throw Exception("Failed to fetch lists");
    }

    Iterable itemsJson = jsonDecode(response.body);
    return itemsJson.map((json) => InventoryListItem.fromJson(json)).toList();
  }

  @override
  Future<InventoryListItem> update(
      int itemId, InventoryListItem updatedItem) async {
    final response = await http.put(
        Uri.parse(getSpecificItemUrl(updatedItem.listId, updatedItem.id)),
        headers: {HttpHeaders.contentTypeHeader: "application/json"},
        body: jsonEncode(<String, dynamic>{
          "listId": updatedItem.listId.toString(),
          "productEan": updatedItem.productEan,
          "expirationDate": updatedItem.expirationDate
        }));

    if (response.statusCode != HttpStatus.ok) {
      throw Exception("Failed to create list");
    }

    return InventoryListItem.fromJson(jsonDecode(response.body));
  }

  @override
  Future<void> delete(int listId, int itemId) async {
    final response =
        await http.delete(Uri.parse(getSpecificItemUrl(listId, itemId)));

    if (response.statusCode != HttpStatus.ok) {
      throw Exception("Failed to delete list");
    }
    print("Successfully deleted!");
  }
}

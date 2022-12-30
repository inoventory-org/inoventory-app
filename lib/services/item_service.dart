import 'package:inoventory_ui/config/constants.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inoventory_ui/models/inventory_list_item.dart';

abstract class ItemService {
  static const backendUrl = Constants.inoventoryBackendUrl;
  static const listUrl = "$backendUrl/api/v1/inventory-lists";

  Future< List<InventoryListItemWrapper>> all(int listId);
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
        })).timeout(const Duration(seconds: 5));

    if (response.statusCode != HttpStatus.created) {
      throw Exception("Failed to create list");
    }

    return InventoryListItem.fromJson(jsonDecode(response.body));
  }

  @override
  Future< List<InventoryListItemWrapper>> all(int listId) async {
    final response = await http.get(Uri.parse(getSpecificListUrl(listId)))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != HttpStatus.ok) {
      throw Exception("Failed to fetch lists");
    }

    // For some reason decoding to Map<String, List<InventoryListItemWrapper>> is not working
    // hence the following complex code
    final Map<String, dynamic> itemsJson = jsonDecode(response.body);
    final Map<String, List<InventoryListItem>> items = {};
    itemsJson.forEach((productEan, value) {
      items[productEan] = (value as List).map((i) => InventoryListItem.fromJson(i)).toList();
    });
    return items.entries.map((e) => InventoryListItemWrapper.fromItems(e.value)).toList();
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
        })).timeout(const Duration(seconds: 5));

    if (response.statusCode != HttpStatus.ok) {
      throw Exception("Failed to create list");
    }

    return InventoryListItem.fromJson(jsonDecode(response.body));
  }

  @override
  Future<void> delete(int listId, int itemId) async {
    final response =
        await http.delete(Uri.parse(getSpecificItemUrl(listId, itemId)))
            .timeout(const Duration(seconds: 5));

    if (response.statusCode != HttpStatus.ok) {
      throw Exception("Failed to delete list");
    }
    print("Successfully deleted!");
  }
}

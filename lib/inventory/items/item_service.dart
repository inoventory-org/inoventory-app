import 'package:dio/dio.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:inoventory_ui/inventory/items/inventory_item.dart';

abstract class ItemService {
  static const backendUrl = Constants.inoventoryBackendUrl;
  static const listUrl = "$backendUrl/api/v1/inventory-lists";
  final timeout = const Duration(seconds: 5);

  Future< List<InventoryListItemWrapper>> all(int listId);
  Future<InventoryItem> add(InventoryItem item);
  Future<InventoryItem> update(int itemId, InventoryItem updatedItem);
  Future<void> delete(int listId, int itemId);

  String getSpecificListUrl(int listId) {
    return "$listUrl/$listId/items";
  }

  String getSpecificItemUrl(int listId, int itemId) {
    return "$listUrl/$listId/items/$itemId";
  }
}

class ItemServiceImpl extends ItemService {
  final Dio dio;

  ItemServiceImpl(this.dio);

  @override
  Future<InventoryItem> add(InventoryItem item) async {
    final response = await dio.post(getSpecificListUrl(item.listId),
        options: Options(headers: {HttpHeaders.contentTypeHeader: "application/json"}),
        data: {
          "listId": item.listId.toString(),
          "productEan": item.productEan,
          "expirationDate": item.expirationDate
        }).timeout(timeout);

    if (response.statusCode != HttpStatus.created) {
      throw Exception("Failed to create list");
    }

    return InventoryItem.fromJson(response.data);
  }

  @override
  Future< List<InventoryListItemWrapper>> all(int listId) async {
    final response = await dio.get(getSpecificListUrl(listId))
        .timeout(timeout);

    if (response.statusCode != HttpStatus.ok) {
      throw Exception("Failed to fetch lists");
    }

    // For some reason decoding to Map<String, List<InventoryListItemWrapper>> is not working
    // hence the following complex code
    final Map<String, dynamic> itemsJson = response.data;
    final Map<String, List<InventoryItem>> items = {};
    itemsJson.forEach((productEan, value) {
      items[productEan] = (value as List).map((i) => InventoryItem.fromJson(i)).toList();
    });
    return items.entries.map((e) => InventoryListItemWrapper.fromItems(e.value)).toList();
  }

  @override
  Future<InventoryItem> update(
      int itemId, InventoryItem updatedItem) async {
    final response = await dio.put(getSpecificItemUrl(updatedItem.listId, updatedItem.id),
        options: Options(headers: {HttpHeaders.contentTypeHeader: "application/json"}),
        data: {
          "listId": updatedItem.listId.toString(),
          "productEan": updatedItem.productEan,
          "expirationDate": updatedItem.expirationDate
        }).timeout(timeout);

    if (response.statusCode != HttpStatus.ok) {
      throw Exception("Failed to create list");
    }

    return InventoryItem.fromJson(response.data);
  }

  @override
  Future<void> delete(int listId, int itemId) async {
    final response =
        await dio.delete(getSpecificItemUrl(listId, itemId))
            .timeout(timeout);

    if (response.statusCode != HttpStatus.ok) {
      throw Exception("Failed to delete list");
    }
    developer.log("Successfully deleted!");
  }
}

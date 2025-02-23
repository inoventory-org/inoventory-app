import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/inventory/items/models/item.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';

abstract class InventoryListService {
  static const backendUrl = Constants.inoventoryBackendUrl;
  static const listUrl = "$backendUrl/api/v1/inventory-lists";

  Future<List<InventoryList>> all();
  Future<InventoryList> get(int listId);
  Future<InventoryList> add(InventoryList list);
  Future<InventoryList> update(int listId, InventoryList updatedList);
  Future<void> delete(int listId);

  String getSpecificListUrl(int listId) {
    return "$listUrl/$listId";
  }
}

@Injectable(as: InventoryListService)
class InventoryListServiceImpl extends InventoryListService {
  final timeoutDuration = const Duration(seconds: 10);
  final Dio dio;

  InventoryListServiceImpl(this.dio);

  @override
  Future<InventoryList> add(InventoryList list) async {
    final response = await dio.post(InventoryListService.listUrl,
        options: Options(
            headers: {HttpHeaders.contentTypeHeader: "application/json"}),
        data: {"name": list.name}).timeout(timeoutDuration);

    if (response.statusCode != HttpStatus.created) {
      throw Exception("Failed to create list");
    }

    return InventoryList.fromJson(response.data);
  }

  @override
  Future<List<InventoryList>> all() async {
    final response =
        await dio.get(InventoryListService.listUrl).timeout(timeoutDuration);

    if (response.statusCode != HttpStatus.ok) {
      throw Exception("Failed to fetch lists");
    }

    Iterable listsJson = response.data;
    return listsJson.map((json) => InventoryList.fromJson(json)).toList();
  }

  @override
  Future<InventoryList> get(int listId) async {
    final response =
    await dio.get("${InventoryListService.listUrl}/$listId").timeout(timeoutDuration);

    if (response.statusCode != HttpStatus.ok) {
      throw Exception("Failed to fetch list with id $listId");
    }

    print("Debug: ");
    print(response.data);
    InventoryList inventoryList = InventoryList.fromJson(response.data);
    return inventoryList;
  }

  @override
  Future<InventoryList> update(int listId, InventoryList updatedList) async {
    final response = await dio.put(getSpecificListUrl(listId),
        options: Options(
            headers: {HttpHeaders.contentTypeHeader: "application/json"}),
        data: <String, String>{
          "name": updatedList.name
        }).timeout(timeoutDuration);

    if (response.statusCode != HttpStatus.ok) {
      throw Exception("Failed to update list");
    }

    return InventoryList.fromJson(response.data);
  }

  @override
  Future<void> delete(int listId) async {
    final response =
        await dio.delete(getSpecificListUrl(listId)).timeout(timeoutDuration);

    if (response.statusCode != HttpStatus.ok) {
      throw Exception("Failed to delete list");
    }
  }
}

class InventoryListServiceMock {
  final List<InventoryList> _lists = [
    InventoryList(0, "Pantry"),
    InventoryList(1, "fridge"),
    InventoryList(2, "garage"),
  ];

  final Map<String, List<Item>> listToItems = {"0": [], "1": [], "2": []};

  List<InventoryList> all() {
    return _lists;
  }

  List<Item> getListItems(InventoryList list) {
    return listToItems[list.id] ?? [];
  }

  void addItemToList(InventoryList list, Item item) {
    listToItems[list.id]?.add(item);
  }
}

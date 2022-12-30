import 'dart:async';

import 'package:inoventory_ui/models/inventory_list.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inoventory_ui/models/inventory_list_item.dart';

abstract class InventoryListService {
  static const backendUrl = Constants.inoventoryBackendUrl;
  static const listUrl = "$backendUrl/api/v1/inventory-lists";

  Future<List<InventoryList>> all();
  Future<InventoryList> add(InventoryList list);
  Future<InventoryList> update(int listId, InventoryList updatedList);
  Future<void> delete(int listId);

  String getSpecificListUrl(int listId) {
    return "$listUrl/$listId";
  }
}

class InventoryListServiceImpl extends InventoryListService {

  final http.Client client;

  InventoryListServiceImpl({required this.client});

  @override
  Future<InventoryList> add(InventoryList list) async {
    final response = await http.post(Uri.parse(InventoryListService.listUrl),
        headers: {HttpHeaders.contentTypeHeader: "application/json"},
        body: jsonEncode(<String, String>{"name": list.name})
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode != HttpStatus.created) {
      throw Exception("Failed to create list");
    }

    return InventoryList.fromJson(jsonDecode(response.body));
  }

  @override
  Future<List<InventoryList>> all() async {
    final response = await http.get(Uri.parse(InventoryListService.listUrl))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != HttpStatus.ok) {
      throw Exception("Failed to fetch lists");
    }

    Iterable listsJson = jsonDecode(response.body);
    return listsJson.map((json) => InventoryList.fromJson(json)).toList();
  }

  @override
  Future<InventoryList> update(int listId, InventoryList updatedList) async {
    final response = await http.put(Uri.parse(getSpecificListUrl(listId)),
        headers: {HttpHeaders.contentTypeHeader: "application/json"},
        body: jsonEncode(<String, String>{"name": updatedList.name})
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode != HttpStatus.ok) {
      throw Exception("Failed to update list");
    }

    return InventoryList.fromJson(jsonDecode(response.body));
  }

  @override
  Future<void> delete(int listId) async {
    final response = await http.delete(Uri.parse(getSpecificListUrl(listId)))
        .timeout(const Duration(seconds: 5));

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

  final Map<String, List<InventoryListItem>> listToItems = {
    "0": [],
    "1": [],
    "2": []
  };

  List<InventoryList> all() {
    return _lists;
  }

  List<InventoryListItem> getListItems(InventoryList list) {
    return listToItems[list.id] ?? [];
  }

  void addItemToList(InventoryList list, InventoryListItem item) {
    listToItems[list.id]?.add(item);
  }
}

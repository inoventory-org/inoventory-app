import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/inventory/items/item_service.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list_service.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/inventory/lists/widgets/create_list_widget.dart';
import 'package:inoventory_ui/inventory/lists/widgets/edit_list_widget.dart';
import 'package:inoventory_ui/inventory/lists/widgets/list_overview_widget.dart';
import 'package:inoventory_ui/products/widgets/inoventory_drawer.dart';
import 'package:inoventory_ui/shared/widgets/confirmation_modal.dart';
import 'package:inoventory_ui/shared/widgets/future_error_retry_widget.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_appbar.dart';

class InventoryListRoute extends StatefulWidget {
  final Future<void> Function() logout;
  const InventoryListRoute({Key? key, required this.logout}) : super(key: key);

  @override
  State<InventoryListRoute> createState() => _InventoryListRouteState();
}

class _InventoryListRouteState extends State<InventoryListRoute> {
  final listService = getIt<InventoryListService>();
  final itemService = getIt<ItemService>();
  late Future<List<InventoryList>> futureLists;
  List<InventoryList>? _lists;
  Map<int, int> _listCounts = {};

  @override
  void initState() {
    super.initState();
    futureLists = _loadLists();
  }

  Future<List<InventoryList>> _loadLists() async {
    final lists = await listService.all();
    final counts = await _loadListCounts(lists);
    _lists = List.of(lists);
    _listCounts = counts;
    return lists;
  }

  Future<Map<int, int>> _loadListCounts(List<InventoryList> lists) async {
    final entries = await Future.wait(
      lists.map((list) async {
        final wrappers = await itemService.all(list.id);
        final count = wrappers.fold<int>(
          0,
          (sum, wrapper) => sum + wrapper.items.length,
        );
        return MapEntry(list.id, count);
      }),
    );
    return Map<int, int>.fromEntries(entries);
  }

  Future<void> onEdit(InventoryList list) async {
    final navigator = Navigator.of(context);
    navigator
        .push(MaterialPageRoute(
            builder: (context) => EditListWidget(oldList: list)))
        .whenComplete(_refreshList);
    await _refreshList();
  }

  Future<void> onDelete(int listId, BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return ConfirmationModal(
              title: "Delete List?",
              message: "Are you sure you want to delete the list?",
              onConfirm: () async {
                await listService.delete(listId);
                await _refreshList();
              });
        });
  }

  Future<void> _refreshList() async {
    setState(() {
      futureLists = _loadLists();
    });
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final currentLists = _lists;
    if (currentLists == null) {
      return;
    }

    final normalizedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final previousLists = List<InventoryList>.from(currentLists);
    final reorderedLists = List<InventoryList>.from(currentLists);
    final movedList = reorderedLists.removeAt(oldIndex);
    reorderedLists.insert(normalizedNewIndex, movedList);

    setState(() {
      _lists = reorderedLists;
    });

    try {
      final persistedLists = await listService
          .reorder(reorderedLists.map((list) => list.id).toList());
      setState(() {
        _lists = persistedLists;
      });
    } catch (e) {
      setState(() {
        _lists = previousLists;
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not save list order: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const InoventoryAppBar(), //AppBar(title: const Text("My Lists")),
      drawer: InoDrawer(logout: widget.logout),
      body: RefreshIndicator(
        onRefresh: _refreshList,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: FutureBuilder<List<InventoryList>>(
          future: futureLists,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                developer.log(
                    "An error occurred while retrieving inventory lists.",
                    error: snapshot.error);
                return FutureErrorRetryWidget(
                    onRetry: _refreshList,
                    child: const Text(
                        "An error occurred while retrieving inventory lists. Try again"));
              }
              if (snapshot.hasData) {
                return MyInventoryListsWidget(
                  lists: _lists ?? snapshot.data!,
                  listCounts: _listCounts,
                  onDelete: onDelete,
                  onEdit: onEdit,
                  onReorder: _onReorder,
                );
              }
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final navigator = Navigator.of(context);
          navigator
              .push(MaterialPageRoute(
                  builder: (context) => const CreateListWidget()))
              .whenComplete(_refreshList);
        },
      ),
    );
  }
}

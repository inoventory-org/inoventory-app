import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
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
  late Future<List<InventoryList>> futureLists;

  @override
  void initState() {
    super.initState();
    futureLists = listService.all();
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
      futureLists = listService.all();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const InoventoryAppBar(), //AppBar(title: const Text("My Lists")),
      drawer: InoDrawer(logout: widget.logout),
      body:
      RefreshIndicator(
        onRefresh: _refreshList,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: FutureBuilder<List<InventoryList>>(
          future: futureLists,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                developer.log("An error occurred while retrieving inventory lists.", error: snapshot.error);
                return FutureErrorRetryWidget(onRetry: _refreshList, child: const Text("An error occurred while retrieving inventory lists. Try again"));
              }
              if (snapshot.hasData) {
                return MyInventoryListsWidget(lists: snapshot.data!, onDelete: onDelete, onEdit: onEdit);
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

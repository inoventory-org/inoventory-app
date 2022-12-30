import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/dependencies.dart';
import 'package:inoventory_ui/models/inventory_list.dart';
import 'package:inoventory_ui/widgets/ConfirmationModal.dart';
import 'package:inoventory_ui/widgets/list/create_list_widget.dart';
import 'package:inoventory_ui/widgets/list/lists_widget.dart';

class InventoryListRoute extends StatefulWidget {
  const InventoryListRoute({Key? key}) : super(key: key);

  @override
  State<InventoryListRoute> createState() => _InventoryListRouteState();
}

class _InventoryListRouteState extends State<InventoryListRoute> {
  final listService = Dependencies.inoventoryListService;
  late Future<List<InventoryList>> futureLists;

  @override
  void initState() {
    super.initState();
    futureLists = listService.all();
  }

  Future<void> deleteList(int listId, BuildContext context) {
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
      appBar: AppBar(title: const Text("My Lists")),
      body: RefreshIndicator(
        onRefresh: _refreshList,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: FutureBuilder<List<InventoryList>>(
          future: futureLists,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Center(child: Text('${snapshot.error}'));
              }
              if (snapshot.hasData) {
                return MyInventoryListsWidget(lists: snapshot.data!, deleteList: deleteList);
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


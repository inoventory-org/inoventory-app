import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/dependencies.dart';
import 'package:inoventory_ui/models/inventory_list.dart';
import 'package:inoventory_ui/widgets/MyFutureBuilder.dart';
import 'package:inoventory_ui/widgets/list/create_list_widget.dart';
import 'package:inoventory_ui/widgets/list/lists_widget.dart';

class InventoryListWidget extends StatefulWidget {
  const InventoryListWidget({Key? key}) : super(key: key);

  @override
  State<InventoryListWidget> createState() => _InventoryListWidgetState();
}

class _InventoryListWidgetState extends State<InventoryListWidget> {
  final inventoryListService = Dependencies.inoventoryListService;
  late Future<List<InventoryList>> futureLists;

  @override
  void initState() {
    super.initState();
    futureLists = inventoryListService.all();
  }

  Future<void> _refreshList() async {
    print("Refreshing List");
    setState(() {
      futureLists = inventoryListService.all();
    });
  }

  @override
  Widget build(BuildContext context) {
    print("Rebuilding...");
    return Scaffold(
      appBar: AppBar(title: const Text("My Lists")),
      body: MyFutureBuilder<List<InventoryList>>(
          future: futureLists,
          futureFetcher: inventoryListService.all,
          successBuilder: (context, snapshot) {
            return ListsWidget(lists: snapshot.data ?? [], listService: inventoryListService);
          }),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CreateListWidget())
          ).then((value) => _refreshList());
        },
      ),
    );
  }
}

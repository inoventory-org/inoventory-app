import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/inventory/lists/overview/list_service.dart';

class EditListWidget extends StatefulWidget {
  final InventoryList oldList;
  const EditListWidget({super.key, required this.oldList});

  @override
  EditeListWidgetState createState() => EditeListWidgetState();
}

class EditeListWidgetState extends State<EditListWidget> {
  final _formKey = GlobalKey<FormState>();
  final _listService = getIt<ListService>();
  late TextEditingController _nameController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _nameController = TextEditingController(text: widget.oldList.name);
  }

  void _updateList() async {
    if (_formKey.currentState == null) {
      return;
    }
    if (_formKey.currentState!.validate()) {
      final navigator = Navigator.of(context);
      final newListName = _nameController.text;
      await _listService.update(
          widget.oldList.id, InventoryList(0, newListName));
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update List")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'New List Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null) {
                      return null;
                    }
                    return (value.isEmpty || value == widget.oldList.name)
                        ? 'Enter a new name'
                        : null;
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                    onPressed: _updateList,
                    child: const Text('Update List',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

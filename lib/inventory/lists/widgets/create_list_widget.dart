import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list_service.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';

class CreateListWidget extends StatefulWidget {
  const CreateListWidget({super.key});

  @override
  CreateListWidgetState createState() => CreateListWidgetState();
}

class CreateListWidgetState extends State<CreateListWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _listService = getIt<InventoryListService>();

  void _createList() async {
    if (_formKey.currentState == null) {
      return;
    }
    if (_formKey.currentState!.validate()) {
      final navigator = Navigator.of(context);
      final listName = _nameController.text;
      await _listService.add(InventoryList(0, listName));
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add List")),
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
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null) {
                      return null;
                    }
                    return value.isEmpty ? 'Enter a new name' : null;
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                    onPressed: _createList,
                    child: const Text('Create List',
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

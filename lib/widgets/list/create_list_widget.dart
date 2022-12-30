import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/dependencies.dart';
import 'package:inoventory_ui/models/inventory_list.dart';

class CreateListWidget extends StatefulWidget {
  const CreateListWidget({super.key});

  @override
  _CreateListWidgetState createState() => _CreateListWidgetState();
}

class _CreateListWidgetState extends State<CreateListWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _listService = Dependencies.inoventoryListService;

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
      appBar: AppBar(title: const Text("Create List")),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(8.0),
                hintText: 'Enter List Name',
                border: OutlineInputBorder(),

              ),
              validator: (value) {
                if (value == null) {
                  return null;
                }
                return value.isEmpty ? 'Please enter a list name' :  null;
              },
            ),
            TextButton(
              onPressed: _createList,
              child: Text('Create List', style: TextStyle(
                    fontSize: 24,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

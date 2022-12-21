import 'package:flutter/material.dart';

class EditProductView extends StatefulWidget {
  const EditProductView({Key? key}) : super(key: key);

  @override
  State<EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends State<EditProductView> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  // form example: https://github.com/erozonachi/flutter_form_handling/blob/dev/lib/main.dart
  // article: https://dev.to/erozonachi/create-and-handle-flutter-input-form-like-a-pro-2k9c

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("New Product")),
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                // The validator receives the text that the user has entered.
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Validate returns true if the form is valid, or false otherwise.
                    if (_formKey.currentState!.validate()) {
                      // If the form is valid, display a snackbar. In the real world,
                      // you'd often call a server or save the information in a database.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Processing Data')),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        )
    );
  }
}

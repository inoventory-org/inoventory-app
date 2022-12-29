import 'package:flutter/material.dart';

class ConfirmationModal extends StatelessWidget {
  final String title;
  final String message;
  final void Function()? onConfirm;
  final void Function()? onCancel;

  const ConfirmationModal(
      {Key? key,
      required this.title,
      required this.message,
      this.onConfirm,
      this.onCancel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            onCancel?.call();
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Confirm'),
          onPressed: () {
            onConfirm?.call();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

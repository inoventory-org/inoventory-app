import 'package:flutter/material.dart';

class ConfirmationModal extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function()? onConfirm;
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
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  Theme.of(context).primaryColor),
              foregroundColor: MaterialStateProperty.all<Color>(
                  Theme.of(context).textTheme.bodyMedium?.color ??
                      Colors.black)),
          onPressed: () async {
            final navigator = Navigator.of(context);
            if (onConfirm != null) {
              await onConfirm!();
            }
            navigator.pop();
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

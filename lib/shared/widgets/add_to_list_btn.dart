import 'package:flutter/material.dart';

class AddToListButton extends StatelessWidget {
  final void Function() onPressed;

  const AddToListButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Add to List",
                style: TextStyle(fontSize: 30, color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              Icon(Icons.add_circle, color: Theme.of(context).textTheme.bodyMedium?.color)
            ],
          ),
        ));
  }
}

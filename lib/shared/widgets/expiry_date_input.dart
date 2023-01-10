import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:inoventory_ui/shared/widgets/container_with_box_decoration.dart';
import 'package:intl/intl.dart';

class ExpiryDateEntry extends StatefulWidget {
  final String? initialDate;
  final void Function(String date)? onDateSet;

  const ExpiryDateEntry({Key? key, this.initialDate, this.onDateSet})
      : super(key: key);

  @override
  State<ExpiryDateEntry> createState() => _ExpiryDateEntryState();
}

class _ExpiryDateEntryState extends State<ExpiryDateEntry> {
  TextEditingController dateInput = TextEditingController();
  //text editing controller for text field

  @override
  void initState() {
    dateInput.text =
        widget.initialDate ?? ""; //set the initial value of text field
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ContainerWithBoxDecoration(
        boxColor: Theme.of(context).colorScheme.background,
        externalPadding: 5,
        internalPadding: 0,
        child: Container(
            padding: const EdgeInsets.all(12),
            height: 80,
            child: Center(
                child: TextField(
              controller: dateInput, //editing controller of this TextField
              decoration: const InputDecoration(
                icon: Icon(Icons.calendar_today),
                labelText: "Expiry Date (Optional)",
              ),
              readOnly:
                  true, //set it true, so that user will not able to edit text
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(
                        2000), //DateTime.now() - not to allow to choose before today.
                    lastDate: DateTime(2101));

                if (pickedDate != null) {
                  String formattedDate =
                      DateFormat('yyyy-MM-dd').format(pickedDate);
                  //you can implement different kind of Date Format here according to your requirement
                  if (widget.onDateSet != null) {
                    widget.onDateSet!(formattedDate);
                  }
                  setState(() {
                    dateInput.text =
                        formattedDate; //set output date to TextField value.
                  });
                } else {
                  developer.log("Date is not selected");
                }
              },
            ))));
  }
}

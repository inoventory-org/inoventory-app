import 'package:flutter/material.dart';
import 'package:inoventory_ui/widgets/container_with_box_decoration.dart';
import 'dart:developer' as developer;

class AmountInput extends StatefulWidget {
  final int? initialAmount;
  final void Function()? onIncrease;
  final void Function()? onDecrease;

  const AmountInput({super.key, this.initialAmount, this.onIncrease, this.onDecrease});

  @override
  _AmountInputState createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  late int _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.initialAmount ?? 1;
  }

  void _incrementAmount() {
    if (widget.onIncrease != null){
      widget.onIncrease!();
    }
    setState(() {
      _amount++;
    });
  }

  void _decrementAmount() {
    if (widget.onDecrease != null){
      widget.onDecrease!();
    }
    setState(() {
      if (_amount > 1) _amount--;
      developer.log("Amount cannot be less than 1");
    });
  }

  @override
  Widget build(BuildContext context) {
    return ContainerWithBoxDecoration(
        boxColor: Theme.of(context).colorScheme.primary,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Amount:", style: TextStyle(fontSize: 30)),
            Expanded(
              child: TextField(
                controller: TextEditingController()..text = _amount.toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, backgroundColor: Theme.of(context).colorScheme.secondary),
                onChanged: (value) {
                  setState(() {
                    _amount = int.parse(value);
                  });
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              onPressed: _incrementAmount,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward),
              onPressed: _decrementAmount,
            ),
          ],
        ),
      );
  }
}

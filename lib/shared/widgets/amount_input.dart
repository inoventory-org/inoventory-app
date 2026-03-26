import 'dart:developer' as developer;

import 'package:flutter/material.dart';

class AmountInput extends StatefulWidget {
  final int? initialAmount;
  final void Function()? onIncrease;
  final void Function()? onDecrease;

  const AmountInput(
      {super.key, this.initialAmount, this.onIncrease, this.onDecrease});

  @override
  AmountInputState createState() => AmountInputState();
}

class AmountInputState extends State<AmountInput> {
  late int _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.initialAmount ?? 1;
  }

  void _incrementAmount() {
    if (widget.onIncrease != null) {
      widget.onIncrease!();
    }
    setState(() {
      _amount++;
    });
  }

  void _decrementAmount() {
    if (widget.onDecrease != null) {
      widget.onDecrease!();
    }
    setState(() {
      if (_amount > 1) _amount--;
      developer.log("Amount cannot be less than 1");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Quantity", 
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
          ),
          Row(
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  elevation: 2,
                ),
                icon: const Icon(Icons.remove),
                onPressed: _amount > 1 ? _decrementAmount : null,
              ),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: TextEditingController()..text = _amount.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _amount = int.tryParse(value) ?? _amount;
                    });
                  },
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 2,
                ),
                icon: const Icon(Icons.add),
                onPressed: _incrementAmount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

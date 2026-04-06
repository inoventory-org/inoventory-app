import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/inventory/items/item_service.dart';
import 'package:inoventory_ui/inventory/items/models/item.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/products/routes/product_detail_route.dart';
import 'package:inoventory_ui/products/widgets/product_info.dart';
import 'package:inoventory_ui/shared/widgets/amount_input.dart';
import 'package:inoventory_ui/shared/widgets/expiry_date_input.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_network_image.dart';

class AddItemView extends StatefulWidget {
  final Product product;
  final InventoryList list;

  // called upon successfully adding item
  final void Function(Item item)? onSuccess;

  // called upon error when trying to add item
  final void Function(Item item)? onError;

  // A function that is called after adding items to the list. Can be used for example to pop elements from the navigator to return to the caller
  final void Function()? postAddCallback;

  const AddItemView(this.product, this.list,
      {super.key, this.postAddCallback, this.onSuccess, this.onError});

  @override
  State<AddItemView> createState() => _AddItemViewState();
}

class _AddItemViewState extends State<AddItemView> {
  final ItemService _itemService = getIt<ItemService>();
  final List<Item> _items = <Item>[];
  int _amount = 0;

  String? get _defaultOpenedAt => widget.list.isOpenList
      ? DateFormat('yyyy-MM-dd').format(DateTime.now())
      : null;

  @override
  void initState() {
    super.initState();
    _items.add(Item(
      _amount,
      widget.list.id,
      widget.product.ean,
      widget.product.name,
      openedAt: _defaultOpenedAt,
    ));
    _amount++;
  }

  void _increaseAmount() {
    setState(() {
      String? lastExpiryDate;
      lastExpiryDate = _items[_amount - 1].expirationDate;

      _items.add(Item(
          _amount, widget.list.id, widget.product.ean, widget.product.name,
          expirationDate: lastExpiryDate,
          openedAt: _defaultOpenedAt));
      _amount++;
    });
  }

  void _decreaseAmount() {
    setState(() {
      if (_amount > 1) {
        _items.removeLast();
        _amount--;
      }
    });
  }

  Future<void> onAddToListPressed() async {
    if (widget.list.isOpenList &&
        _items.any((item) => item.expirationDate == null)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please add an expiration date before opening an item.",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    for (var item in _items) {
      try {
        await _itemService.add(item);
        widget.onSuccess?.call(item);
      } catch (e) {
        developer.log("An error occurred while adding item.", error: e);
        widget.onError?.call(item);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error adding item: $e"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    widget.postAddCallback?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.list.isOpenList
            ? "Opening ${widget.product.name}"
            : "Adding ${widget.product.name} to List"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(children: [
            if (widget.product.imageUrl != null)
              InoventoryNetworkImage(url: widget.product.imageUrl!),
            ProductInfo(
              product: widget.product,
              onBarcodeTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProductDetailRoute(
                      product: widget.product,
                      list: widget.list,
                    ),
                  ),
                );
              },
            ),
            AmountInput(
                onIncrease: _increaseAmount, onDecrease: _decreaseAmount),
            for (var item in _items)
              ExpiryDateEntry(
                  initialDate: item.expirationDate,
                  onDateSet: (date) {
                    item.expirationDate = date;
                  }),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: onAddToListPressed, child: const Icon(Icons.bookmark)),
    );
  }
}

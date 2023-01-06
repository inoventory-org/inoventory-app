import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/dependencies.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list.dart';
import 'package:inoventory_ui/inventory/items/inventory_item.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/inventory/items/item_service.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_network_image.dart';
import 'package:inoventory_ui/shared/widgets/amount_input.dart';
import 'package:inoventory_ui/shared/widgets/expiry_date_input.dart';

class AddProductView extends StatefulWidget {
  final Product product;
  final InventoryList list;

  const AddProductView(this.product, this.list, {Key? key}) : super(key: key);

  @override
  State<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
  int _amount = 0;
  final ItemService itemService = Dependencies.itemService;
  final List<InventoryItem> _items = <InventoryItem>[];

  @override
  void initState() {
    super.initState();
    _items.add(InventoryItem(_amount, widget.list.id, widget.product.ean));
    _amount++;
  }

  void _increaseAmount() {
    setState(() {
      String? lastExpiryDate;
      lastExpiryDate = _items[_amount - 1].expirationDate;

      _items.add(InventoryItem(_amount, widget.list.id, widget.product.ean,
          expirationDate: lastExpiryDate));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Adding ${widget.product.name} to List")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(children: [
            InoventoryNetworkImage(url: widget.product.imageUrl!),
            AmountInput(
                onIncrease: _increaseAmount, onDecrease: _decreaseAmount),
            for (var item in _items)
              ExpiryDateEntry(
                  initialDate: item.expirationDate,
                  onDateSet: (date) {
                    item.expirationDate = date;
                  })
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            for (var item in _items) {
              itemService.add(item);
            }
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          child: const Icon(Icons.bookmark)),
    );
  }
}
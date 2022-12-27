import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/dependencies.dart';
import 'package:inoventory_ui/models/inventory_list.dart';
import 'package:inoventory_ui/models/inventory_list_item.dart';
import 'package:inoventory_ui/models/product.dart';
import 'package:inoventory_ui/services/inventory_list/inventory_list_service.dart';
import 'package:inoventory_ui/widgets/InoventoryNetworkImage.dart';
import 'package:inoventory_ui/widgets/amount_input.dart';
import 'package:inoventory_ui/widgets/expiry_date_input.dart';

class AddProductView extends StatefulWidget {
  final Product product;
  final InventoryList list;

  const AddProductView(this.product, this.list, {Key? key}) : super(key: key);

  @override
  State<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
  int _amount = 0;
  final InventoryListService listService = Dependencies.inoventoryListService; // TODO: real dependency injection here
  final List<InventoryListItem> _items = <InventoryListItem>[];

  @override
  void initState() {
    super.initState();
    _items.add(InventoryListItem(_amount.toString(), widget.product.name,
        expiryDate: "2022-12-31"));
    _amount++;
  }

  void _increaseAmount() {
    setState(() {
      String? lastExpiryDate;
      lastExpiryDate = _items[_amount-1].expiryDate;

      _items.add(InventoryListItem(_amount.toString(), widget.product.name,
          expiryDate: lastExpiryDate));
      _amount++;
    });
  }

  void _decreaseAmount() {
    setState(() {
      if (_amount > 1) {
        _items.removeLast();
        _amount--;
      }
      ;
    });
  }

  @override
  Widget build(BuildContext context) {
    print(_amount);
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
              ExpiryDateEntry(initialDate: item.expiryDate, onDateSet: (date) {
                item.expiryDate = date;
              })
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: (){
        for (var item in _items) {
          listService.addItemToList(widget.list, item);
        }
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }, child: const Icon(Icons.bookmark)),
    );
  }
}
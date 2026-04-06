import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/expiry_scan/controllers/expiry_scan_controller.dart';
import 'package:inoventory_ui/expiry_scan/models/expiry_scan_candidate.dart';
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
  final ExpiryScanController expiryScanController;

  const AddItemView(this.product, this.list,
      {super.key,
      required this.expiryScanController,
      this.postAddCallback,
      this.onSuccess,
      this.onError});

  @override
  State<AddItemView> createState() => _AddItemViewState();
}

class _AddItemViewState extends State<AddItemView> {
  final ItemService _itemService = getIt<ItemService>();
  final List<Item> _items = <Item>[];
  final Map<int, List<ExpiryScanCandidate>> _rowSuggestions =
      <int, List<ExpiryScanCandidate>>{};
  int _amount = 0;
  int _lastProcessedDetectionEvent = 0;

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
    widget.expiryScanController.addListener(_handleExpiryScanUpdates);
  }

  void _increaseAmount() {
    setState(() {
      String? lastExpiryDate;
      lastExpiryDate = _items[_amount - 1].expirationDate;

      _items.add(Item(
          _amount, widget.list.id, widget.product.ean, widget.product.name,
          expirationDate: lastExpiryDate, openedAt: _defaultOpenedAt));
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

  void _handleExpiryScanUpdates() {
    if (!mounted) {
      return;
    }

    final int eventId = widget.expiryScanController.eventId;
    if (eventId == _lastProcessedDetectionEvent) {
      setState(() {});
      return;
    }
    _lastProcessedDetectionEvent = eventId;

    final detection = widget.expiryScanController.latestDetection;
    final int? targetRowIndex = widget.expiryScanController.targetRowIndex;
    if (targetRowIndex == null || detection.candidates.isEmpty) {
      setState(() {});
      return;
    }

    if (detection.requiresConfirmation) {
      setState(() {
        _rowSuggestions
          ..clear()
          ..[targetRowIndex] = detection.candidates;
      });
      return;
    }

    final ExpiryScanCandidate? candidate = detection.bestCandidate;
    if (candidate == null) {
      setState(() {});
      return;
    }

    _applyScannedDate(candidate.isoDate, rowIndex: targetRowIndex);
  }

  void _applyScannedDate(String isoDate, {required int rowIndex}) {
    setState(() {
      if (rowIndex == 0 && _items.length > 1) {
        for (final Item item in _items) {
          item.expirationDate = isoDate;
        }
      } else if (rowIndex >= 0 && rowIndex < _items.length) {
        _items[rowIndex].expirationDate = isoDate;
      }
      _rowSuggestions.clear();
    });

    widget.expiryScanController.markSuccess();
    HapticFeedback.lightImpact();
  }

  void _onExpirySuggestionSelected(
    int rowIndex,
    ExpiryScanCandidate candidate,
  ) {
    _applyScannedDate(candidate.isoDate, rowIndex: rowIndex);
  }

  void _onExpiryScanRequested(int rowIndex) {
    setState(() {
      _rowSuggestions.clear();
    });
    widget.expiryScanController.startScanning(targetRowIndex: rowIndex);
  }

  Future<void> onAddToListPressed() async {
    if (widget.list.isOpenList &&
        _items.any((item) =>
            item.expirationDate == null || item.expirationDate!.isEmpty)) {
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
  void dispose() {
    widget.expiryScanController.removeListener(_handleExpiryScanUpdates);
    super.dispose();
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
            for (var entry in _items.indexed)
              ExpiryDateEntry(
                  label: _items.length > 1
                      ? 'Expiry Date ${entry.$1 + 1}'
                      : 'Expiry Date (Optional)',
                  initialDate: entry.$2.expirationDate,
                  isScanSupported: widget.expiryScanController.isSupported,
                  isScanning: widget.expiryScanController.isScanning &&
                      widget.expiryScanController.targetRowIndex == entry.$1,
                  isTargeted:
                      widget.expiryScanController.targetRowIndex == entry.$1,
                  suggestions: _rowSuggestions[entry.$1] ?? const [],
                  applyToAllHint: entry.$1 == 0 && _items.length > 1
                      ? 'Applies to all ${_items.length} items by default'
                      : null,
                  onScanRequested: () => _onExpiryScanRequested(entry.$1),
                  onSuggestionSelected: (candidate) =>
                      _onExpirySuggestionSelected(entry.$1, candidate),
                  onDismissSuggestions:
                      widget.expiryScanController.cancelSuggestions,
                  status: widget.expiryScanController.targetRowIndex == entry.$1
                      ? widget.expiryScanController.status
                      : ExpiryScanStatus.idle,
                  onDateSet: (date) {
                    entry.$2.expirationDate = date;
                  }),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: onAddToListPressed, child: const Icon(Icons.bookmark)),
    );
  }
}

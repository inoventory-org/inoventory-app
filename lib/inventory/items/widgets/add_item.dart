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
  final void Function()? onDismiss;
  final ExpiryScanController expiryScanController;

  const AddItemView(this.product, this.list,
      {super.key,
      required this.expiryScanController,
      this.postAddCallback,
      this.onDismiss,
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
  final ScrollController _scrollController = ScrollController();
  int _amount = 0;
  int _lastProcessedDetectionEvent = 0;
  double _dragDismissDistance = 0;

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

  void _dismissView() {
    widget.expiryScanController.stopScanning();
    widget.onDismiss?.call();
  }

  void _onDismissDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy <= 0) {
      _dragDismissDistance = 0;
      return;
    }
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      _dragDismissDistance = 0;
      return;
    }
    _dragDismissDistance += details.delta.dy;
  }

  void _onDismissDragEnd(DragEndDetails details) {
    final bool shouldDismiss = _dragDismissDistance > 70 ||
        (details.primaryVelocity != null && details.primaryVelocity! > 700);
    _dragDismissDistance = 0;
    if (shouldDismiss) {
      _dismissView();
    }
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
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerTopExpiryScan() {
    final int rowIndex = widget.expiryScanController.targetRowIndex ?? 0;
    _onExpiryScanRequested(rowIndex);
  }

  Widget _buildCompactProductHeader(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.product.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InoventoryNetworkImage(
                    url: widget.product.imageUrl!,
                    height: 88,
                    width: 88,
                    boxFit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 88,
                  width: 88,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 36,
                    color: colorScheme.primary,
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (widget.product.brands != null &&
                        widget.product.brands!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.product.brands!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                    if (widget.product.weight != null &&
                        widget.product.weight!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.product.weight!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.65),
                            ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProductDetailRoute(
                                product: widget.product,
                                list: widget.list,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.qr_code_2,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.product.ean,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                        color: colorScheme.primary,
                                      ),
                                ),
                              ),
                              Icon(
                                Icons.open_in_new,
                                color: colorScheme.primary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.product.tags != null &&
              widget.product.tags!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.product.tags!
                  .take(6)
                  .map(
                    (tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpirySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quantity & Expiry',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Set the amount and scan or pick expiry dates below.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          AmountInput(onIncrease: _increaseAmount, onDecrease: _decreaseAmount),
          const SizedBox(height: 8),
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
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        leadingWidth: 28,
        leading: const SizedBox.shrink(),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                widget.product.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.expiryScanController.isSupported)
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: _triggerTopExpiryScan,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(0, 34),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  icon: const Icon(Icons.document_scanner_outlined, size: 16),
                  label: const Text('Scan Exp'),
                ),
              ),
          ],
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: _onDismissDragUpdate,
        onVerticalDragEnd: _onDismissDragEnd,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCompactProductHeader(context),
                      const SizedBox(height: 14),
                      _buildExpirySection(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: onAddToListPressed, child: const Icon(Icons.bookmark)),
    );
  }
}

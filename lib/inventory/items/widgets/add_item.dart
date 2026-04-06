import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/expiry_scan/controllers/expiry_scan_controller.dart';
import 'package:inoventory_ui/expiry_scan/expiry_date_picker.dart';
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
  final ScrollController _scrollController = ScrollController();
  int _amount = 0;
  int _lastProcessedDetectionEvent = 0;
  double _dragDismissDistance = 0;
  bool _showScanExpiryPulse = false;
  bool _isShowingScanConfirmation = false;
  Timer? _scanExpiryPulseTimer;
  Timer? _scanExpiryPulseStopTimer;

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
    _startScanExpiryPulse();
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

  Future<void> _handleExpiryScanUpdates() async {
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
    if (targetRowIndex == null ||
        detection.candidates.isEmpty ||
        _isShowingScanConfirmation) {
      setState(() {});
      return;
    }

    final ExpiryScanCandidate? candidate = detection.bestCandidate;
    if (candidate == null) {
      setState(() {});
      return;
    }

    _isShowingScanConfirmation = true;
    final ExpiryDateScanConfirmationResult? result =
        await confirmScannedExpiryDate(
      context,
      candidates: detection.candidates,
      initialDate: candidate.isoDate,
      title: 'Confirm expiry date',
      helpText: targetRowIndex == 0 && _items.length > 1
          ? 'Choose the scanned date to apply to all items, or retry the capture.'
          : 'Choose the scanned date before applying it.',
    );
    _isShowingScanConfirmation = false;
    if (!mounted || result == null) {
      widget.expiryScanController.cancelSuggestions();
      return;
    }

    switch (result.action) {
      case ExpiryScanConfirmationAction.confirm:
        final String? isoDate = result.isoDate;
        if (isoDate != null && isoDate.isNotEmpty) {
          _applyScannedDate(isoDate, rowIndex: targetRowIndex);
        } else {
          widget.expiryScanController.cancelSuggestions();
        }
      case ExpiryScanConfirmationAction.retry:
        _onExpiryScanRequested(targetRowIndex);
      case ExpiryScanConfirmationAction.cancel:
        widget.expiryScanController.cancelSuggestions();
    }
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
      widget.expiryScanController.markSuccess();
    });
    HapticFeedback.lightImpact();
  }

  void _onExpiryScanRequested(int rowIndex) {
    widget.expiryScanController.startScanning(targetRowIndex: rowIndex);
  }

  void _dismissView() {
    widget.expiryScanController.stopScanning();
    widget.onDismiss?.call();
  }

  void _startScanExpiryPulse() {
    if (!widget.expiryScanController.isSupported) {
      return;
    }
    _showScanExpiryPulse = true;
    _scanExpiryPulseTimer =
        Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _showScanExpiryPulse = !_showScanExpiryPulse;
      });
    });
    _scanExpiryPulseStopTimer = Timer(const Duration(seconds: 3), () {
      _scanExpiryPulseTimer?.cancel();
      if (!mounted) {
        return;
      }
      setState(() {
        _showScanExpiryPulse = false;
      });
    });
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
    _scanExpiryPulseTimer?.cancel();
    _scanExpiryPulseStopTimer?.cancel();
    super.dispose();
  }

  int _targetRowForQuickScan() {
    final int missingIndex = _items.indexWhere(
      (item) => item.expirationDate == null || item.expirationDate!.isEmpty,
    );
    if (missingIndex != -1) {
      return missingIndex;
    }
    return widget.expiryScanController.targetRowIndex ?? 0;
  }

  bool get _hasMissingExpiryDates => _items.any(
        (item) => item.expirationDate == null || item.expirationDate!.isEmpty,
      );

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
              applyToAllHint: entry.$1 == 0 && _items.length > 1
                  ? 'Applies to all ${_items.length} items by default'
                  : null,
              onScanRequested: () => _onExpiryScanRequested(entry.$1),
              status: widget.expiryScanController.targetRowIndex == entry.$1
                  ? widget.expiryScanController.status
                  : ExpiryScanStatus.idle,
              onDateSet: (date) {
                setState(() {
                  entry.$2.expirationDate = date;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.expiryScanController.isSupported &&
                _hasMissingExpiryDates)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Next step: scan the expiry date',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (widget.expiryScanController.isSupported) ...[
              AnimatedOpacity(
                duration: const Duration(milliseconds: 240),
                opacity: _showScanExpiryPulse ? 0.55 : 1,
                child: FilledButton.icon(
                  onPressed: () =>
                      _onExpiryScanRequested(_targetRowForQuickScan()),
                  icon: Icon(
                    widget.expiryScanController.isScanning
                        ? Icons.center_focus_strong
                        : Icons.document_scanner_outlined,
                  ),
                  label: Text(
                    widget.expiryScanController.isScanning
                        ? 'Scanning Expiry'
                        : 'Scan Expiry',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            FilledButton.icon(
              onPressed: onAddToListPressed,
              icon: const Icon(Icons.bookmark),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
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
            _buildBottomActionBar(context),
          ],
        ),
      ),
    );
  }
}

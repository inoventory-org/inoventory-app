import 'package:flutter/material.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_popup_menu.dart';

import '../models/sorting_options.dart';

class InoventoryAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Function()? onSearchButtonPressed;
  final Function()? onGroupButtonPressed;
  final SortingOptions? sortingOptions;
  final bool isFocusExpiring;
  final Function()? onFocusExpiringToggled;

  const InoventoryAppBar({
    super.key,
    this.title = "inoventory",
    this.subtitle,
    this.onSearchButtonPressed,
    this.sortingOptions,
    this.onGroupButtonPressed,
    this.isFocusExpiring = false,
    this.onFocusExpiringToggled,
  });

  @override
  State<InoventoryAppBar> createState() => _InoventoryAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _InoventoryAppBarState extends State<InoventoryAppBar> {
  bool _isAsc = false;
  bool _withSorting = false;

  @override
  void initState() {
    _withSorting = widget.sortingOptions != null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final actions = _buildActions(context);
    return AppBar(
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title),
          if (widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                widget.subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      ),
      actions: actions,
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      if (widget.onFocusExpiringToggled != null)
        _buildCompactAction(
          context: context,
          icon: Icon(
            widget.isFocusExpiring
                ? Icons.notification_important
                : Icons.notifications_none,
            color:
                widget.isFocusExpiring ? Theme.of(context).colorScheme.error : null,
          ),
          onPressed: widget.onFocusExpiringToggled!,
        ),
      if (widget.onGroupButtonPressed != null)
        _buildCompactAction(
          context: context,
          icon: const Icon(Icons.line_style),
          onPressed: widget.onGroupButtonPressed!,
        ),
      if (_withSorting)
        _buildCompactAction(
          context: context,
          icon: _isAsc
              ? const Icon(Icons.arrow_upward)
              : const Icon(Icons.arrow_downward),
          onPressed: () {
            setState(() {
              _isAsc = !_isAsc;
            });
            widget.sortingOptions!.onSortingDirectionChange();
          },
        ),
      if (_withSorting)
        Theme(
          data: Theme.of(context).copyWith(
            visualDensity: VisualDensity.compact,
          ),
          child: InoventoryPopupMenu(sortingOptions: widget.sortingOptions!),
        ),
      _buildCompactAction(
        context: context,
        icon: const Icon(Icons.search),
        onPressed: widget.onSearchButtonPressed ?? () {},
      ),
    ];
  }

  Widget _buildCompactAction({
    required BuildContext context,
    required Widget icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: icon,
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      constraints: const BoxConstraints(
        minWidth: 36,
        minHeight: 36,
      ),
      visualDensity: VisualDensity.compact,
      splashRadius: 20,
    );
  }
}

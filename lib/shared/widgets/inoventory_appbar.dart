import 'package:flutter/material.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_popup_menu.dart';

import '../models/sorting_options.dart';

class InoventoryAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Function()? onSearchButtonPressed;
  final Function()? onGroupButtonPressed;
  final SortingOptions? sortingOptions;

  const InoventoryAppBar({super.key, this.title = "inoventory", this.onSearchButtonPressed, this.sortingOptions, this.onGroupButtonPressed});

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
    return AppBar(
      title: Text(widget.title),
      actions: [
        widget.onGroupButtonPressed != null ? IconButton(icon: const Icon(Icons.line_style), onPressed: widget.onGroupButtonPressed) : Container(),
        _withSorting
            ? IconButton(
                icon: _isAsc ? const Icon(Icons.arrow_upward) : const Icon(Icons.arrow_downward),
                onPressed: () {
                  setState(() {
                    _isAsc = !_isAsc;
                  });
                  widget.sortingOptions!.onSortingDirectionChange();
                },
              )
            : Container(),
        _withSorting ? InoventoryPopupMenu(sortingOptions: widget.sortingOptions!) : Container(),
        IconButton(icon: const Icon(Icons.search), onPressed: widget.onSearchButtonPressed ?? () {}),
      ],
    );
  }
}

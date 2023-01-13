import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import 'package:inoventory_ui/shared/widgets/future_error_retry_widget.dart';

class MyFutureBuilder<T> extends StatefulWidget {
  final Future<T> future;
  final Future<T> Function() futureFetcher;
  final Widget Function(BuildContext context, AsyncSnapshot<T> snapshot)
      successBuilder;
  final Widget Function(BuildContext context, AsyncSnapshot<T> snapshot)?
      loadingBuilder;
  final Widget Function(BuildContext context, AsyncSnapshot<T> snapshot)?
      errorBuilder;

  const MyFutureBuilder(
      {Key? key,
      required this.future,
      required this.futureFetcher,
      required this.successBuilder,
      this.loadingBuilder,
      this.errorBuilder})
      : super(key: key);

  @override
  State<MyFutureBuilder> createState() => _MyFutureBuilderState<T>();
}

class _MyFutureBuilderState<T> extends State<MyFutureBuilder<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.futureFetcher();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.futureFetcher();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      onRefresh: () async {
        _refresh();
      },
      child: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              if (widget.loadingBuilder != null) {
                return widget.loadingBuilder!(context, snapshot);
              }
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              developer.log("An error occurred while retrieving products.",
                  error: snapshot.error);
              return FutureErrorRetryWidget(
                  onRetry: _refresh,
                  child: const Center(
                      child: Text(
                          'An error occurred while fetching data. Please try again.')));
            }
            return widget.successBuilder(context, snapshot);
          }),
    );
  }
}

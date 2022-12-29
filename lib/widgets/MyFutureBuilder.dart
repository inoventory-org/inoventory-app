import 'package:flutter/material.dart';

class MyFutureBuilder<T> extends StatefulWidget {
  final Future<T> future;
  final Future<T> Function() futureFetcher;
  final Widget Function(BuildContext context, AsyncSnapshot<T> snapshot) successBuilder;
  final Widget Function(BuildContext context, AsyncSnapshot<T> snapshot)? loadingBuilder;
  final Widget Function(BuildContext context, AsyncSnapshot<T> snapshot)? errorBuilder;

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

  void _refresh() {
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
              if (widget.errorBuilder != null) {
                return widget.errorBuilder!(context, snapshot);
              }
              return Center(child: Text('${snapshot.error}'));
            }

            return widget.successBuilder(context, snapshot);
          }),
    );
  }
}

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:inoventory_ui/shared/widgets/future_error_retry_widget.dart';

class ItemsFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final void Function() onRetry;
  final Widget Function(BuildContext context, AsyncSnapshot<T> snapshot) successBuilder;

  const ItemsFutureBuilder(this.future, this.onRetry, this.successBuilder, {super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            developer.log(snapshot.toString());
            developer.log("An error occurred while retrieving items.", error: snapshot.error);
            return FutureErrorRetryWidget(onRetry: onRetry, child: const Center(child: Text('An error occurred while retrieving items. Please try again.')));
          }
          if (snapshot.hasData) {
            return successBuilder(context, snapshot);
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

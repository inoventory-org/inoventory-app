import 'package:flutter/material.dart';

class FutureErrorRetryWidget extends StatelessWidget {
  final void Function() onRetry;
  final Widget? child;
  final String? buttonText;
  const FutureErrorRetryWidget({Key? key, required this.onRetry, this.child, this.buttonText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: child
                ?? const Text('An error occurred while fetching data. Please try again.')),
            const SizedBox(height: 10),
            TextButton(onPressed: onRetry, child:  Text(buttonText ?? "Retry"))
          ]),
    );
  }
}

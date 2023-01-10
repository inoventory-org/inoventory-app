import 'package:flutter/material.dart';

class ContainerWithBoxDecoration extends StatelessWidget {
  final Widget child;
  final Color? boxColor;
  final double borderRadius;
  final double externalPadding;
  final double internalPadding;

  const ContainerWithBoxDecoration(
      {Key? key,
      required this.child,
      this.boxColor,
      this.borderRadius = 15,
      this.externalPadding = 8.0,
      this.internalPadding = 8.0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(externalPadding),
        child: Container(
            padding: EdgeInsets.all(internalPadding),
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: child));
  }
}

import 'package:flutter/material.dart';

class InoventoryNetworkImage extends StatelessWidget {
  final String url;
  final double height;
  final double width;
  final BoxFit? boxFit;

  const InoventoryNetworkImage(
      {Key? key,
      required this.url,
      this.height = 400,
      this.width = double.infinity,
      this.boxFit = BoxFit.scaleDown})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(url),
          fit: boxFit,
        ),
      ),
    );
  }
}

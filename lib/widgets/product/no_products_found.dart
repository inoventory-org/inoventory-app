import 'package:flutter/material.dart';

class CentralizedElementWithPlusButton extends StatelessWidget {
  final Widget? centralElement;
  final Widget? nextWidget;

  const CentralizedElementWithPlusButton(
      {Key? key,
      this.centralElement = const Text("No results found"),
      this.nextWidget})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: nextWidget != null
            ? [
                Center(child: centralElement),
                const SizedBox(height: 10),
                Center(
                    child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.black,
                        child: IconButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) =>
                                      nextWidget ?? const Placeholder()));
                            },
                            color: Colors.white,
                            icon: const Icon(Icons.add))))
              ]
            : [
                Center(child: centralElement),
              ]);
  }
}

import 'package:flutter/material.dart';

class NoProductsFound extends StatelessWidget {
  final Widget? nextWidget;

  const NoProductsFound({Key? key, this.nextWidget}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: nextWidget != null
            ? [
                const Center(child: Text("No results found")),
                const SizedBox(height: 10),
                Center(
                    child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.black,
                        child: IconButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => nextWidget ?? const Placeholder()));
                            },
                            color: Colors.white,
                            icon: const Icon(Icons.add))))
              ]
            : [
                const Center(child: Text("No results found")),
              ]
    );
  }
}

import 'package:flutter/material.dart';
import 'package:inoventory_ui/views/error_view.dart';
import 'package:inoventory_ui/views/home_view.dart';

void main() {
  ErrorWidget.builder =
      (errorDetails) => ErrorView(errorDetails: errorDetails);
  runApp(const InoventoryHome());
}

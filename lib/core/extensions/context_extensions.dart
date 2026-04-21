import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  void showSnack(
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
    SnackBarBehavior? behavior,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: behavior,
      ),
    );
  }
}

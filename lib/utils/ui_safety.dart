import 'package:flutter/material.dart';

class UiSafety {
  UiSafety._();

  static void showSnackBar(BuildContext context, SnackBar snackBar) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(snackBar);
  }
}

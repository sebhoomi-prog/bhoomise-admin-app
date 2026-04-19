import 'package:flutter/material.dart';

/// Dismiss software keyboard — use after admin actions and on tap-outside wrappers.
void adminDismissKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
}

/// Wraps [child]; taps on empty areas dismiss the keyboard without blocking scroll/taps on controls.
class AdminTapOutsideUnfocus extends StatelessWidget {
  const AdminTapOutsideUnfocus({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: adminDismissKeyboard,
      child: child,
    );
  }
}

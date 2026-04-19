import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Full-screen flat customer shell background ([ColorScheme.surface] — Figma Customer Home).
class CustomerShellBackground extends StatelessWidget {
  const CustomerShellBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bg = DesignTokens.customerShellBackground(Theme.of(context).colorScheme);
    return ColoredBox(color: bg, child: child);
  }
}

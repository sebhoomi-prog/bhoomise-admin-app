import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'customer_shell_background.dart';

/// Body wrapper when [Scaffold.extendBodyBehindAppBar] is true and the app bar uses
/// a transparent [AppBarTheme.backgroundColor].
///
/// [SafeArea] alone only insets the **status bar**; it does not account for the
/// toolbar, so lists and forms draw **under** the app bar. This widget adds
/// `viewPadding.top + toolbarHeight` so content aligns with the design baseline.
class BhoomiseUnderTransparentAppBar extends StatelessWidget {
  const BhoomiseUnderTransparentAppBar({
    super.key,
    required this.child,
    this.applyShellBackground = true,
  });

  final Widget child;

  /// When true, paints [CustomerShellBackground] behind the padded content.
  final bool applyShellBackground;

  @override
  Widget build(BuildContext context) {
    final top = DesignTokens.underTransparentAppBarTopPadding(context);

    final padded = SafeArea(
      top: false,
      left: true,
      right: true,
      bottom: true,
      child: Padding(
        padding: EdgeInsets.only(top: top),
        child: child,
      ),
    );

    if (applyShellBackground) {
      return CustomerShellBackground(child: padded);
    }
    return padded;
  }
}

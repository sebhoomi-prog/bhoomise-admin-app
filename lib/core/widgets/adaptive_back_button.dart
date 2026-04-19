import 'package:flutter/material.dart';

/// True when this route can pop (there is a screen below on the navigator stack).
bool routeCanPop(BuildContext context) {
  return Navigator.maybeOf(context)?.canPop() ?? false;
}

/// Dismisses this route if possible. Prefer over [Get.back] for nested navigators.
void routeMaybePop(BuildContext context) {
  Navigator.maybeOf(context)?.maybePop();
}

/// Material [AppBar] leading: platform back icon (iOS chevron vs Android arrow) when
/// [routeCanPop] is true; otherwise `null` so the app bar does not show a dead control.
///
/// Set [automaticallyImplyLeading] to `!routeCanPop(context)` when using this as [AppBar.leading].
Widget? adaptiveAppBarLeading(BuildContext context, {Color? color}) {
  if (!routeCanPop(context)) return null;
  return IconButton(
    icon: const BackButtonIcon(),
    color: color,
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: () => routeMaybePop(context),
  );
}

/// Use as [AppBar.automaticallyImplyLeading] together with [adaptiveAppBarLeading].
bool adaptiveAppBarImplyLeading(BuildContext context) =>
    !routeCanPop(context);

/// For custom frosted headers (no [AppBar]): platform back icon
/// ([BackButtonIcon], iOS vs Material), or [SizedBox.shrink] when root.
Widget adaptiveFrostedBackControl(
  BuildContext context, {
  required Color iconColor,
  double iconSize = 24,
}) {
  if (!routeCanPop(context)) return const SizedBox.shrink();
  return IconButton(
    icon: const BackButtonIcon(),
    color: iconColor,
    iconSize: iconSize,
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: () => routeMaybePop(context),
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
  );
}

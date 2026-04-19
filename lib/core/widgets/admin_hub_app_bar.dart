import 'package:flutter/material.dart';

import '../theme/admin_surface.dart';
import 'adaptive_back_button.dart';

/// Shared app bar for partner shells (avatar + title + mode pill).
/// Use [modeBadgeText] `STORE` for vendor / retailer, `ADMIN MODE` for supply admin.
///
/// Back control appears automatically when this route can pop (e.g. pushed stack routes);
/// root tabs have no back — important on iOS where there is no hardware back key.
class AdminHubAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminHubAppBar({
    super.key,
    this.title = 'Bhoomise',
    this.showModeBadge = true,
    this.modeBadgeText = 'ADMIN MODE',
    this.actions,
    this.backgroundColor = AdminSurface.background,
  });

  final String title;
  final bool showModeBadge;

  /// e.g. `STORE`, `ADMIN MODE` — keep short for small screens.
  final String modeBadgeText;

  final List<Widget>? actions;
  final Color backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: backgroundColor,
      foregroundColor: AdminSurface.headline,
      leading: adaptiveAppBarLeading(context, color: AdminSurface.headline),
      automaticallyImplyLeading: adaptiveAppBarImplyLeading(context),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AdminSurface.darkCard.withValues(alpha: 0.15),
            child: const Icon(
              Icons.person_rounded,
              size: 18,
              color: AdminSurface.headline,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AdminSurface.headline,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (showModeBadge && modeBadgeText.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AdminSurface.darkCard,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                modeBadgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: actions,
    );
  }
}

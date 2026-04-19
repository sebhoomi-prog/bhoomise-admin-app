import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';

/// Explains admin access and shows the signed-in operator identity.
class AdminSecurityCenterPage extends StatelessWidget {
  const AdminSecurityCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Security · access')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Who can use admin tools',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Firestore and Storage rules treat you as an admin if your Firebase Auth '
            'token has admin: true, your phone matches admin_phones/{E.164}, or the '
            'bootstrap ops number in rules. Phone login must expose phone_number on the token.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            'Signed-in operator',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final u = Get.find<AuthController>().currentUser.value;
            final uid = u?.uid ?? '—';
            final phone = u?.phoneNumber ?? '—';
            return Material(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv('UID', uid),
                    const SizedBox(height: 8),
                    _kv('Phone', phone),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () => Get.toNamed(AppRoutes.profileEdit),
            child: const Text('Edit public profile'),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          k,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: DesignTokens.figmaLabelMuted,
          ),
        ),
        SelectableText(
          v,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DesignTokens.figmaSectionInk,
          ),
        ),
      ],
    );
  }
}

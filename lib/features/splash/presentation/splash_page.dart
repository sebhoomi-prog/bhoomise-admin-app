import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/session/phone_otp_route_persistence.dart';
import '../../../core/session/app_session_service.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/design_tokens.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../profile/domain/usecases/resolve_post_auth_destination.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() async {
      final auth = Get.find<AuthController>();
      final prefs = Get.find<SharedPreferences>();
      await Future.wait<void>([
        Future<void>.delayed(const Duration(milliseconds: 1600)),
        auth.waitForInitialAuth(),
      ]);
      if (!mounted) return;

      final loggedIn = auth.currentUser.value != null;
      if (loggedIn) {
        await PhoneOtpRoutePersistence.clear(prefs);
      } else if (PhoneOtpRoutePersistence.shouldResumeOtp(prefs)) {
        // After reCAPTCHA WebView Android may recreate the activity — [Get.offNamed](otp)
        // never ran; resume OTP instead of sending user to guest shell.
        Get.offAllNamed(
          AppRoutes.otp,
          arguments: PhoneOtpRoutePersistence.routeArguments(prefs),
        );
        return;
      }

      // Guest-first (see `.cursor/config/project-config`): browse without login; OTP at checkout.
      if (!loggedIn) {
        Get.offAllNamed(AppRoutes.home);
        return;
      }
      final uid = auth.currentUser.value!.uid;

      try {
        final dest = await Get.find<ResolvePostAuthDestination>()(uid);
        if (dest == PostAuthDestination.completeProfile) {
          Get.offAllNamed(AppRoutes.signupProfile);
        } else {
          final session = Get.find<AppSessionService>();
          Get.offAllNamed(session.mainShellRouteAfterAuth);
        }
      } on Object catch (_) {
        final session = Get.find<AppSessionService>();
        Get.offAllNamed(session.mainShellRouteAfterAuth);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.spaceXl),
                decoration: DesignTokens.softCard(context),
                child: SvgPicture.asset(
                  AppIcons.logo,
                  height: 112,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceXl),
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceXs),
              Text(
                AppStrings.tagline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceXl),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

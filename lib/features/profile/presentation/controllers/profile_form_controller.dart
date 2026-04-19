import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/session/app_session_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/save_user_profile.dart';

class ProfileFormController extends GetxController {
  ProfileFormController(this._saveUserProfile);

  final SaveUserProfile _saveUserProfile;

  final RxBool loading = false.obs;

  bool get isSignup => Get.currentRoute == AppRoutes.signupProfile;

  Future<void> submit({
    required String displayName,
    String? email,
  }) async {
    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;
    if (user == null) return;

    loading.value = true;
    try {
      final trimmedEmail = email?.trim();
      await _saveUserProfile(
        UserProfile(
          uid: user.uid,
          displayName: displayName.trim(),
          email: (trimmedEmail == null || trimmedEmail.isEmpty)
              ? null
              : trimmedEmail,
          phoneNumber: user.phoneNumber,
          profileCompleted: true,
        ),
      );
      if (isSignup) {
        final session = Get.find<AppSessionService>();
        Get.offAllNamed(session.mainShellRouteAfterAuth);
      } else {
        Get.back<void>();
      }
    } finally {
      loading.value = false;
    }
  }
}

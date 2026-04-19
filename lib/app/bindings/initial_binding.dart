import 'package:get/get.dart';

import 'auth_dependencies.dart';
import 'core_dependencies.dart';
import 'profile_dependencies.dart';

/// Composes feature DI. `SharedPreferences` is registered before the app widget tree runs.
/// Order: core → profile (needed for post-auth) → auth → address → commerce.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    CoreDependencies.register();
    ProfileDependencies.register();
    AuthDependencies.register();
  }
}

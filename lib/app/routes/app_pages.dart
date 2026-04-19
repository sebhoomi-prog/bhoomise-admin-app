import 'package:get/get.dart';

import '../../apps/admin/pages/admin_audit_activity_page.dart';
import '../../apps/admin/pages/admin_customer_home_page.dart';
import '../../apps/admin/pages/admin_dashboard_shell_page.dart';
import '../../apps/admin/pages/admin_master_products_page.dart';
import '../../apps/admin/pages/admin_platform_console_page.dart';
import '../../apps/admin/pages/admin_security_center_page.dart';
import '../../apps/admin/pages/admin_users_directory_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/phone_login_page.dart';
import '../../features/profile/presentation/controllers/profile_form_controller.dart';
import '../../features/profile/presentation/pages/profile_form_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../modules/admin/navigation/presentation/controllers/admin_shell_controller.dart';
import '../../modules/customer/home/data/customer_home_firestore_datasource.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const PhoneLoginPage(),
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpVerificationPage(),
    ),
    GetPage(
      name: AppRoutes.signupProfile,
      page: () => const ProfileFormPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProfileFormController(Get.find()), fenix: true);
      }),
    ),
    GetPage(
      name: AppRoutes.profileEdit,
      page: () => const ProfileFormPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProfileFormController(Get.find()), fenix: true);
      }),
    ),
    GetPage(
      name: AppRoutes.adminSupply,
      page: () => const AdminDashboardShellPage(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AdminShellController>()) {
          Get.put(AdminShellController(), permanent: true);
        }
      }),
    ),
    GetPage(
      name: AppRoutes.adminCustomerHome,
      page: () => const AdminCustomerHomePage(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<CustomerHomeFirestoreDataSource>()) {
          Get.lazyPut<CustomerHomeFirestoreDataSource>(
            () => CustomerHomeFirestoreDataSource(),
            fenix: true,
          );
        }
      }),
    ),
    GetPage(
      name: AppRoutes.adminMasterProducts,
      page: () => const AdminMasterProductsPage(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AdminShellController>()) {
          Get.put(AdminShellController(), permanent: true);
        }
      }),
    ),
    GetPage(
      name: AppRoutes.adminUsersDirectory,
      page: () => const AdminUsersDirectoryPage(),
    ),
    GetPage(
      name: AppRoutes.adminAuditActivity,
      page: () => const AdminAuditActivityPage(),
    ),
    GetPage(
      name: AppRoutes.adminSecurityCenter,
      page: () => const AdminSecurityCenterPage(),
    ),
    GetPage(
      name: AppRoutes.adminPlatformConsole,
      page: () => const AdminPlatformConsolePage(),
    ),
  ];
}

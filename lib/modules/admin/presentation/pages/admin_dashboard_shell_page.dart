import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/bhoomise_role_bottom_nav.dart';
import '../../navigation/presentation/controllers/admin_shell_controller.dart';
import '../widgets/admin_keyboard.dart';
import 'admin_coupon_management_page.dart';
import 'global_supply_page.dart';
import 'admin_vendor_listing_approvals_page.dart';
import 'admin_profile_tab_page.dart';

/// Admin shell — Figma 4-tab: **MARKET** · **SPORE** · **GARDEN** · **PROFILE**.
class AdminDashboardShellPage extends StatefulWidget {
  const AdminDashboardShellPage({super.key});

  @override
  State<AdminDashboardShellPage> createState() =>
      _AdminDashboardShellPageState();
}

class _AdminDashboardShellPageState extends State<AdminDashboardShellPage> {
  static const _items = <BhoomiseBottomNavItem>[
    BhoomiseBottomNavItem(icon: Icons.storefront_outlined, label: 'MARKET'),
    BhoomiseBottomNavItem(icon: Icons.science_outlined, label: 'SPORE'),
    BhoomiseBottomNavItem(icon: Icons.eco_rounded, label: 'GARDEN'),
    BhoomiseBottomNavItem(icon: Icons.person_rounded, label: 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) {
    final shell = Get.find<AdminShellController>();
    return Obx(
      () => Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: AdminTapOutsideUnfocus(
          child: IndexedStack(
            index: shell.tabIndex.value,
            children: const [
              GlobalSupplyPage(),
              AdminVendorListingApprovalsPage(),
              AdminCouponManagementPage(),
              AdminProfileTabPage(),
            ],
          ),
        ),
        bottomNavigationBar: BhoomiseRoleBottomNav(
          currentIndex: shell.tabIndex.value,
          onTap: (i) {
            adminDismissKeyboard();
            shell.setTab(i);
          },
          items: _items,
          partnerFigmaStyle: true,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../services/admin/admin_api_service.dart';
import '../login/login_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF007D34);
    const surfaceColor = Color(0xFFF8F9FA);
    const textSecondary = Color(0xFF718096);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: brandGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, size: 28),
            SizedBox(width: 12),
            Text(
              'bAdmin',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<AuthBloc>().add(const AuthSignOutRequested());
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(builder: (_) => const LoginPage()),
                          (_) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [brandGreen, Color(0xFF00A86B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.waving_hand_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Welcome, Admin!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You are logged in successfully. Start managing your Bhoomise platform.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Quick actions title
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            // Quick action cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _QuickActionCard(
                  icon: Icons.inventory_2_rounded,
                  title: 'Products',
                  subtitle: 'Test API',
                  color: Colors.blue,
                  onTap: () => _testApi(context, 'List Products', () async {
                    final api = GetIt.I<AdminApiService>();
                    final products = await api.listProducts();
                    debugPrint('Products: ${products.length}');
                  }),
                ),
                _QuickActionCard(
                  icon: Icons.shopping_bag_rounded,
                  title: 'Orders',
                  subtitle: 'Test API',
                  color: Colors.orange,
                  onTap: () => _testApi(context, 'List Orders', () async {
                    final api = GetIt.I<AdminApiService>();
                    final orders = await api.listOrders();
                    debugPrint('Orders: ${orders.length}');
                  }),
                ),
                _QuickActionCard(
                  icon: Icons.store_rounded,
                  title: 'Stores',
                  subtitle: 'Test API',
                  color: Colors.purple,
                  onTap: () => _testApi(context, 'List Stores', () async {
                    final api = GetIt.I<AdminApiService>();
                    final stores = await api.listStores();
                    debugPrint('Stores: ${stores.length}');
                  }),
                ),
                _QuickActionCard(
                  icon: Icons.people_rounded,
                  title: 'Users',
                  subtitle: 'Test API',
                  color: Colors.teal,
                  onTap: () => _testApi(context, 'List Users', () async {
                    final api = GetIt.I<AdminApiService>();
                    final users = await api.listUsers();
                    debugPrint('Users: ${users.length}');
                  }),
                ),
                _QuickActionCard(
                  icon: Icons.local_offer_rounded,
                  title: 'Coupons',
                  subtitle: 'Test API',
                  color: Colors.pink,
                  onTap: () => _testApi(context, 'List Coupons', () async {
                    final api = GetIt.I<AdminApiService>();
                    final coupons = await api.listCoupons();
                    debugPrint('Coupons: ${coupons.length}');
                  }),
                ),
                _QuickActionCard(
                  icon: Icons.person_rounded,
                  title: 'My Profile',
                  subtitle: 'Test /me API',
                  color: Colors.indigo,
                  onTap: () => _testApi(context, 'Get Me', () async {
                    final api = GetIt.I<AdminApiService>();
                    final me = await api.getMe();
                    debugPrint('Me: ${me.phone} (${me.role})');
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: brandGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Development Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The admin dashboard is connected to the API. '
                    'Implement feature screens using BLoC + services pattern.',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: brandGreen, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'API Connected',
                          style: TextStyle(
                            color: brandGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _testApi(BuildContext context, String apiName, Future<void> Function() call) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Testing $apiName...'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await call();
      messenger.showSnackBar(
        SnackBar(
          content: Text('$apiName: Success!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$apiName: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

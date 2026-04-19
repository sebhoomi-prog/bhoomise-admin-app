import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/app_strings.dart';
import '../core/deeplink/deeplink_handler.dart';
import '../core/deeplink/deeplink_service.dart';
import '../core/theme/app_theme.dart';
import 'bindings/initial_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class BhoomiseApp extends StatefulWidget {
  const BhoomiseApp({super.key});

  @override
  State<BhoomiseApp> createState() => _BhoomiseAppState();
}

class _BhoomiseAppState extends State<BhoomiseApp> {
  late final DeeplinkService _deeplinkService;

  @override
  void initState() {
    super.initState();
    _deeplinkService = DeeplinkService(DeeplinkHandler());
    _deeplinkService.init();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.light(),
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}

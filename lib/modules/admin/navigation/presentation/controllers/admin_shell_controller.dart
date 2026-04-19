import 'package:get/get.dart';

/// Drives the admin [IndexedStack] tab so in-shell shortcuts can jump between sections.
class AdminShellController extends GetxController {
  final RxInt tabIndex = 0.obs;

  void setTab(int i) => tabIndex.value = i.clamp(0, 3);
}

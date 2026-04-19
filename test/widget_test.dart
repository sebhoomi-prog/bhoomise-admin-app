import 'package:flutter_test/flutter_test.dart';

import 'package:bhoomise/core/constants/app_strings.dart';
import 'package:bhoomise/core/utils/money.dart';

void main() {
  test('formatInrMinor formats minor units as INR', () {
    expect(formatInrMinor(10000), '₹100');
  });

  test('AppStrings app name is stable', () {
    expect(AppStrings.appName, 'Bhoomise');
  });
}

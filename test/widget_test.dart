import 'package:flutter_test/flutter_test.dart';
import 'package:golpoghor/core/constants/app_constants.dart';

void main() {
  test('smoke — test framework works', () {
    expect(1 + 1, 2);
  });

  test('app constants — name and page size', () {
    expect(AppConstants.appName, isNotEmpty);
    expect(AppConstants.feedPageSize, greaterThan(0));
    expect(AppConstants.commentMaxLength, greaterThan(0));
  });
}

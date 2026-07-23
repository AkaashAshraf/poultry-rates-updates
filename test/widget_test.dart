// The default `flutter create` template generates a counter-app smoke test
// that pumps `MyApp` — a class this project never had (the root widget here
// is `PoultryRatesApp`, defined in lib/app.dart). Pumping it directly also
// isn't practical for a plain `flutter test`: `main()` calls
// `Firebase.initializeApp()` and `EasyLocalization.ensureInitialized()`,
// both of which need platform channels / asset bundles that aren't wired
// up in the default test environment without extra mocking.
//
// Until that test harness exists, this file covers pure-Dart logic that
// doesn't depend on Firebase, widgets, or localization assets — the kind
// of thing that's cheap to keep correct and catches real regressions.

import 'package:flutter_test/flutter_test.dart';
import 'package:poultry_rates_app/core/constants/app_constants.dart';
import 'package:poultry_rates_app/core/utils/formatters.dart';

void main() {
  group('RateCategoryX', () {
    test('fromKey resolves each category key round-trip', () {
      for (final category in RateCategory.values) {
        expect(RateCategoryX.fromKey(category.key), category);
      }
    });

    test('fromKey falls back to chicken for an unknown key', () {
      expect(RateCategoryX.fromKey('not-a-real-category'), RateCategory.chicken);
    });

    test('egg defaults to a per-dozen unit, others to per-kg', () {
      expect(RateCategory.egg.defaultUnitKey, 'unit.perDozen');
      expect(RateCategory.chicken.defaultUnitKey, 'unit.perKg');
      expect(RateCategory.meat.defaultUnitKey, 'unit.perKg');
    });
  });

  group('AppFormatters.price', () {
    test('drops decimals for whole numbers', () {
      expect(AppFormatters.price(450), '450');
    });

    test('keeps two decimal places for fractional prices', () {
      expect(AppFormatters.price(449.5), '449.50');
    });
  });

  group('AppFormatters.timeAgo', () {
    test('reports "now" for the current moment', () {
      expect(AppFormatters.timeAgo(DateTime.now()), 'now');
    });

    test('reports whole hours for same-day timestamps', () {
      final threeHoursAgo = DateTime.now().subtract(const Duration(hours: 3));
      expect(AppFormatters.timeAgo(threeHoursAgo), '3h');
    });
  });
}

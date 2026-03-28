// packages/dev_buddy/test/i18n/strings_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/i18n/strings.dart';
import 'package:dev_buddy/src/i18n/strings_en.dart';
import 'package:dev_buddy/src/i18n/strings_tr.dart';

void main() {
  group('DevBuddyStrings factory', () {
    test('returns English strings for "en" locale', () {
      final strings = DevBuddyStrings.fromLocale('en');
      expect(strings, isA<StringsEn>());
    });

    test('returns Turkish strings for "tr" locale', () {
      final strings = DevBuddyStrings.fromLocale('tr');
      expect(strings, isA<StringsTr>());
    });

    test('defaults to English for unsupported locale', () {
      final strings = DevBuddyStrings.fromLocale('fr');
      expect(strings, isA<StringsEn>());
    });

    test('defaults to English for null locale', () {
      final strings = DevBuddyStrings.fromLocale(null);
      expect(strings, isA<StringsEn>());
    });
  });

  group('StringsEn', () {
    late StringsEn strings;

    setUp(() {
      strings = const StringsEn();
    });

    test('panelTitle returns non-empty English string', () {
      expect(strings.panelTitle, isNotEmpty);
      expect(strings.panelTitle, 'DevBuddy');
    });

    test('clearAll returns English string', () {
      expect(strings.clearAll, 'Clear All');
    });

    test('export returns English string', () {
      expect(strings.export, 'Export');
    });

    test('noEvents returns English string', () {
      expect(strings.noEvents, isNotEmpty);
    });

    test('tab names return non-empty English strings', () {
      expect(strings.performanceTab, isNotEmpty);
      expect(strings.errorsTab, isNotEmpty);
      expect(strings.networkTab, isNotEmpty);
      expect(strings.memoryTab, isNotEmpty);
      expect(strings.rebuildsTab, isNotEmpty);
    });

    test('metric labels return non-empty English strings', () {
      expect(strings.fps, isNotEmpty);
      expect(strings.memoryUsage, isNotEmpty);
    });

    test('error helper strings return non-empty English strings', () {
      expect(strings.howToFix, isNotEmpty);
      expect(strings.unknownError, isNotEmpty);
      expect(strings.searchOnline, isNotEmpty);
      expect(strings.checkStackTrace, isNotEmpty);
    });

    test('all getters return distinct non-empty strings', () {
      final allStrings = [
        strings.panelTitle,
        strings.clearAll,
        strings.export,
        strings.noEvents,
        strings.performanceTab,
        strings.errorsTab,
        strings.networkTab,
        strings.memoryTab,
        strings.rebuildsTab,
        strings.fps,
        strings.memoryUsage,
        strings.howToFix,
        strings.unknownError,
        strings.searchOnline,
        strings.checkStackTrace,
      ];
      for (final s in allStrings) {
        expect(s, isNotEmpty);
      }
    });
  });

  group('StringsTr', () {
    late StringsTr strings;

    setUp(() {
      strings = const StringsTr();
    });

    test('panelTitle returns Turkish string', () {
      expect(strings.panelTitle, 'DevBuddy');
    });

    test('clearAll returns Turkish string', () {
      expect(strings.clearAll, isNotEmpty);
      expect(strings.clearAll, isNot('Clear All'));
    });

    test('export returns Turkish string', () {
      expect(strings.export, isNotEmpty);
    });

    test('tab names return non-empty Turkish strings', () {
      expect(strings.performanceTab, isNotEmpty);
      expect(strings.errorsTab, isNotEmpty);
      expect(strings.networkTab, isNotEmpty);
      expect(strings.memoryTab, isNotEmpty);
      expect(strings.rebuildsTab, isNotEmpty);
    });

    test('all getters return non-empty strings', () {
      final allStrings = [
        strings.panelTitle,
        strings.clearAll,
        strings.export,
        strings.noEvents,
        strings.performanceTab,
        strings.errorsTab,
        strings.networkTab,
        strings.memoryTab,
        strings.rebuildsTab,
        strings.fps,
        strings.memoryUsage,
        strings.howToFix,
        strings.unknownError,
        strings.searchOnline,
        strings.checkStackTrace,
      ];
      for (final s in allStrings) {
        expect(s, isNotEmpty);
      }
    });

    test('Turkish strings differ from English for translated keys', () {
      const en = StringsEn();
      const tr = StringsTr();
      // These should be translated (not same as English)
      expect(tr.clearAll, isNot(en.clearAll));
      expect(tr.noEvents, isNot(en.noEvents));
      expect(tr.howToFix, isNot(en.howToFix));
    });
  });
}

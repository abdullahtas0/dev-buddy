// packages/dev_buddy/lib/src/i18n/strings_tr.dart
import 'strings.dart';

/// Turkish string implementation for DevBuddy UI.
class StringsTr extends DevBuddyStrings {
  const StringsTr();

  // Panel
  @override
  String get panelTitle => 'DevBuddy';
  @override
  String get clearAll => 'Hepsini Temizle';
  @override
  String get export => 'Rapor Al';
  @override
  String get noEvents => 'Henuz kayitli olay yok.';

  // Tabs
  @override
  String get performanceTab => 'Performans';
  @override
  String get errorsTab => 'Hatalar';
  @override
  String get networkTab => 'Ag';
  @override
  String get memoryTab => 'Bellek';
  @override
  String get rebuildsTab => 'Yeniden Cizimler';

  // Metrics
  @override
  String get fps => 'FPS';
  @override
  String get memoryUsage => 'Bellek Kullanimi';

  // Error helpers
  @override
  String get howToFix => 'Nasil duzeltilir';
  @override
  String get unknownError => 'Bilinmeyen hata';
  @override
  String get searchOnline => 'Internette ara';
  @override
  String get checkStackTrace => 'Yigin izini kontrol et';

  // Module empty states
  @override
  String get noPerformanceIssues => 'Performans sorunu tespit edilmedi';
  @override
  String get noErrorsCaught => 'Hata yakalanmadi';
  @override
  String get noNetworkRequests => 'Ag istegi yakalanmadi';
  @override
  String get noMemoryIssues => 'Bellek sorunu tespit edilmedi';
  @override
  String get noRebuildData => 'Henuz yeniden cizim verisi yok';

  // Rebuild tracker
  @override
  String get topRebuilders => 'En Cok Yeniden Cizilenler';
}

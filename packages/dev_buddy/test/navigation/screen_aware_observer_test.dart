// packages/dev_buddy/test/navigation/screen_aware_observer_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/navigation/screen_aware_observer.dart';

void main() {
  group('DevBuddyNavigatorObserverImpl', () {
    late DevBuddyNavigatorObserverImpl observer;

    setUp(() {
      observer = DevBuddyNavigatorObserverImpl();
    });

    group('currentScreen', () {
      test('returns null when no routes have been pushed', () {
        expect(observer.currentScreen, isNull);
      });

      test('returns route name after push', () {
        final route = _createRoute('/home');
        observer.didPush(route, null);

        expect(observer.currentScreen, equals('/home'));
      });

      test('returns previous route name after pop', () {
        final homeRoute = _createRoute('/home');
        final detailRoute = _createRoute('/detail');

        observer.didPush(homeRoute, null);
        observer.didPush(detailRoute, homeRoute);

        expect(observer.currentScreen, equals('/detail'));

        observer.didPop(detailRoute, homeRoute);

        expect(observer.currentScreen, equals('/home'));
      });

      test('returns null after popping the last route', () {
        final route = _createRoute('/home');
        observer.didPush(route, null);
        observer.didPop(route, null);

        expect(observer.currentScreen, isNull);
      });

      test('returns new route name after replace', () {
        final homeRoute = _createRoute('/home');
        final settingsRoute = _createRoute('/settings');

        observer.didPush(homeRoute, null);
        observer.didReplace(newRoute: settingsRoute, oldRoute: homeRoute);

        expect(observer.currentScreen, equals('/settings'));
      });
    });

    group('screenHistory', () {
      test('is empty initially', () {
        expect(observer.screenHistory, isEmpty);
      });

      test('records screen on push', () {
        final route = _createRoute('/home');
        observer.didPush(route, null);

        expect(observer.screenHistory, hasLength(1));
        expect(observer.screenHistory.first.screenName, equals('/home'));
      });

      test('records all visited screens in order', () {
        observer.didPush(_createRoute('/home'), null);
        observer.didPush(_createRoute('/detail'), _createRoute('/home'));
        observer.didPush(_createRoute('/settings'), _createRoute('/detail'));

        final names =
            observer.screenHistory.map((r) => r.screenName).toList();
        expect(names, equals(['/home', '/detail', '/settings']));
      });

      test('records screen transitions with timestamps', () {
        final before = DateTime.now();

        observer.didPush(_createRoute('/home'), null);

        final after = DateTime.now();
        final record = observer.screenHistory.first;

        expect(record.timestamp.isAfter(before) ||
            record.timestamp.isAtSameMomentAs(before), isTrue);
        expect(record.timestamp.isBefore(after) ||
            record.timestamp.isAtSameMomentAs(after), isTrue);
      });

      test('returns an unmodifiable list', () {
        observer.didPush(_createRoute('/home'), null);

        expect(
          () => observer.screenHistory.add(
            ScreenTransitionRecord(
              screenName: '/hack',
              timestamp: DateTime.now(),
            ),
          ),
          throwsUnsupportedError,
        );
      });
    });

    group('didPush', () {
      test('ignores routes with null name', () {
        final route = _createRoute(null);
        observer.didPush(route, null);

        expect(observer.currentScreen, isNull);
        expect(observer.screenHistory, isEmpty);
      });
    });

    group('didPop', () {
      test('removes the current route from the stack', () {
        final homeRoute = _createRoute('/home');
        final detailRoute = _createRoute('/detail');

        observer.didPush(homeRoute, null);
        observer.didPush(detailRoute, homeRoute);
        observer.didPop(detailRoute, homeRoute);

        expect(observer.currentScreen, equals('/home'));
      });

      test('does not add duplicate history entries on pop', () {
        final homeRoute = _createRoute('/home');
        final detailRoute = _createRoute('/detail');

        observer.didPush(homeRoute, null);
        observer.didPush(detailRoute, homeRoute);

        final countBefore = observer.screenHistory.length;
        observer.didPop(detailRoute, homeRoute);

        expect(observer.screenHistory.length, equals(countBefore));
      });
    });

    group('didReplace', () {
      test('replaces current route in the stack', () {
        final homeRoute = _createRoute('/home');
        final detailRoute = _createRoute('/detail');
        final settingsRoute = _createRoute('/settings');

        observer.didPush(homeRoute, null);
        observer.didPush(detailRoute, homeRoute);
        observer.didReplace(newRoute: settingsRoute, oldRoute: detailRoute);

        expect(observer.currentScreen, equals('/settings'));
      });

      test('records replacement in history', () {
        final homeRoute = _createRoute('/home');
        final settingsRoute = _createRoute('/settings');

        observer.didPush(homeRoute, null);
        observer.didReplace(newRoute: settingsRoute, oldRoute: homeRoute);

        final names =
            observer.screenHistory.map((r) => r.screenName).toList();
        expect(names, contains('/settings'));
      });
    });

    group('didRemove', () {
      test('removes route from the stack', () {
        final homeRoute = _createRoute('/home');
        final detailRoute = _createRoute('/detail');
        final settingsRoute = _createRoute('/settings');

        observer.didPush(homeRoute, null);
        observer.didPush(detailRoute, homeRoute);
        observer.didPush(settingsRoute, detailRoute);

        // Remove middle route
        observer.didRemove(detailRoute, settingsRoute);

        // Current should still be settings (top of stack)
        expect(observer.currentScreen, equals('/settings'));
      });
    });
  });
}

Route<dynamic> _createRoute(String? name) {
  return MaterialPageRoute<dynamic>(
    settings: RouteSettings(name: name),
    builder: (_) => const SizedBox.shrink(),
  );
}

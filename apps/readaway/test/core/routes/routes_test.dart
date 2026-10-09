import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/routes/routes.dart';

void main() {
  group('Routes path helpers', () {
    test('root path "/" handles segments, lastSegment, and parentPath', () {
      const root = Routes(path: '/', name: 'Library');

      expect(root.segments, isEmpty);
      expect(root.lastSegment, '');
      expect(root.lastPath, '/');
      expect(root.parentPath, '/');
    });

    test('top-level route "/settings" properties', () {
      const settings = Routes(path: '/settings', name: 'Settings');

      expect(settings.segments, ['settings']);
      expect(settings.lastSegment, 'settings');
      expect(settings.lastPath, '/settings');
      expect(settings.parentPath, '/');
    });

    test('nested route "/settings/voices" properties', () {
      const voices = Routes(path: '/settings/voices', name: 'VoiceLibrary');

      expect(voices.segments, ['settings', 'voices']);
      expect(voices.lastSegment, 'voices');
      expect(voices.lastPath, '/voices');
      expect(voices.parentPath, '/settings');
    });

    test('handles trailing slashes gracefully', () {
      const trailing = Routes(path: '/settings/fonts/', name: 'CustomFonts');

      expect(trailing.segments, ['settings', 'fonts']);
      expect(trailing.lastSegment, 'fonts');
      expect(trailing.lastPath, '/fonts');
      expect(trailing.parentPath, '/settings');
    });

    test('child() creates correctly formatted sub-routes', () {
      const root = Routes(path: '/', name: 'Root');
      final childOfRoot = root.child('settings', name: 'Settings');
      expect(childOfRoot.path, '/settings');
      expect(childOfRoot.name, 'Settings');

      const settings = Routes(path: '/settings', name: 'Settings');
      final subRoute = settings.child('voices', name: 'VoiceLibrary');
      expect(subRoute.path, '/settings/voices');
      expect(subRoute.name, 'VoiceLibrary');
      expect(subRoute.lastSegment, 'voices');
      expect(subRoute.parentPath, '/settings');
    });

    test('AppRoutes provides correct paths and nested segments', () {
      final routes = AppRoutes();

      expect(routes.library.path, '/');
      expect(routes.reader.path, '/reader');

      expect(routes.settings.path, '/settings');
      expect(routes.settingsVoices.path, '/settings/voices');
      expect(routes.settingsVoices.lastSegment, 'voices');
      expect(routes.settingsFonts.path, '/settings/fonts');
      expect(routes.settingsFonts.lastSegment, 'fonts');
    });
  });
}

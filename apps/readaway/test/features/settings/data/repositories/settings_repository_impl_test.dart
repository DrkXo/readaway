import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/models/models.dart';
import 'package:readaway/src/features/settings/data/repositories/settings_repository_impl.dart';

import '../../../../helpers/test_mocks.dart';

void main() {
  late MockSettingsService mockSettingsService;
  late SettingsRepositoryImpl repository;

  setUp(() {
    mockSettingsService = MockSettingsService();
    repository = SettingsRepositoryImpl(mockSettingsService);
  });

  group('SettingsRepositoryImpl', () {
    test('getSettings returns current settings from SettingsService', () async {
      const expectedSettings = Settings(
        screenWakeLock: true,
        globalViewSettings: GlobalViewSettings(selectedScheme: 'tokyo_night'),
      );
      when(mockSettingsService.settings).thenReturn(expectedSettings);

      final result = await repository.getSettings().run();

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable(), equals(expectedSettings));
      verify(mockSettingsService.settings).called(1);
    });

    test('saveSettings delegates to SettingsService.save', () async {
      const newSettings = Settings(
        screenWakeLock: false,
        globalViewSettings: GlobalViewSettings(selectedScheme: 'kanagawa'),
      );
      when(mockSettingsService.save(newSettings)).thenAnswer((_) async {});

      final result = await repository.saveSettings(newSettings).run();

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable(), equals(unit));
      verify(mockSettingsService.save(newSettings)).called(1);
    });

    test('resetSettings saves default Settings to SettingsService', () async {
      when(mockSettingsService.save(const Settings())).thenAnswer((_) async {});

      final result = await repository.resetSettings().run();

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable(), equals(unit));
      verify(mockSettingsService.save(const Settings())).called(1);
    });

    test('watchSettings delegates to SettingsService.changes', () {
      final stream = Stream<Settings>.value(const Settings());
      when(mockSettingsService.changes).thenAnswer((_) => stream);

      final resultStream = repository.watchSettings();

      expect(resultStream, emits(const Settings()));
      verify(mockSettingsService.changes).called(1);
    });
  });
}

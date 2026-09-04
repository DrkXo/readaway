import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

WakelockService get wakelockService => GetIt.I.get<WakelockService>();

/// Thin wrapper around [WakelockPlus] that keeps the device screen awake.
@Singleton()
class WakelockService {
  Future<void> enable() => WakelockPlus.enable();
  Future<void> disable() => WakelockPlus.disable();
  Future<void> setEnabled(bool enabled) => WakelockPlus.toggle(enable: enabled);
  Future<bool> get isEnabled => WakelockPlus.enabled;
}

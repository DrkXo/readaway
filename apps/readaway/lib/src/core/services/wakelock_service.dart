part of 'services.dart';

WakelockService get wakelockService => GetIt.I.get<WakelockService>();

/// Thin wrapper around [WakelockPlus] that keeps the device screen awake.
///
/// This service isolates the `wakelock_plus` plugin behind a small, testable
/// API so the rest of the app never depends on the plugin directly. It is
/// intentionally scoped: callers decide *when* the wakelock should be active
/// (e.g. only while the reader is open) rather than enabling it globally.
@Singleton()
class WakelockService {
  /// Enables the screen wakelock, preventing the device from sleeping.
  Future<void> enable() => WakelockPlus.enable();

  /// Disables the screen wakelock, allowing the device to sleep normally.
  Future<void> disable() => WakelockPlus.disable();

  /// Enables or disables the wakelock based on [enabled].
  Future<void> setEnabled(bool enabled) => WakelockPlus.toggle(enable: enabled);

  /// Whether the screen wakelock is currently active.
  Future<bool> get isEnabled => WakelockPlus.enabled;
}

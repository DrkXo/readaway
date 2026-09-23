import 'package:audio_session/audio_session.dart';
import 'package:media_kit/media_kit.dart' as mk hide PlayerState;

/// A unified representation of an output audio device across platforms.
///
/// Wraps the platform-specific device types ([AudioDevice] from
/// `audio_session` on mobile, [mk.AudioDevice] from `media_kit` on desktop)
/// behind a single [id] + [name] surface so UI can render a consistent
/// device list without branching on platform.
class OutputAudioDevice {
  const OutputAudioDevice({
    required this.id,
    required this.name,
    this.native,
  });

  /// Stable identifier used to match the currently-selected device.
  final String id;

  /// Human-readable device name shown in the UI.
  final String name;

  /// The platform-specific device this wraps (mobile [AudioDevice] or
  /// desktop [mk.AudioDevice]).
  final Object? native;

  OutputAudioDevice.mobile(AudioDevice device)
    : id = device.id,
      name = device.name,
      native = device;

  OutputAudioDevice.desktop(mk.AudioDevice device)
    : id = device.name,
      name = device.description.isNotEmpty ? device.description : device.name,
      native = device;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutputAudioDevice &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          native == other.native);

  @override
  int get hashCode => Object.hash(runtimeType, id, name, native);

  @override
  String toString() => 'OutputAudioDevice(id: $id, name: $name, native: $native)';
}

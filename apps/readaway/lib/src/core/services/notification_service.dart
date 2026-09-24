import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../flavors.dart';

NotificationService get notificationService =>
    GetIt.I.get<NotificationService>();

@Singleton()
class NotificationService {
  final _log = AppLogger.instance.scope('NotificationService');

  final PackageInfo _packageInfo;

  NotificationService(this._packageInfo);

  late final String _defaultChannelId;
  String get defaultChannelId => _defaultChannelId;

  late final String _defaultChannelName;
  String get defaultChannelName => _defaultChannelName;

  late final String _defaultChannelDescription;
  String get defaultChannelDescription => _defaultChannelDescription;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final String _defaultIcon = '@mipmap/ic_launcher';
  String get defaultIcon => _defaultIcon;

  String get audioServiceNotificationIcon =>
      _defaultIcon.startsWith('@') ? _defaultIcon.substring(1) : _defaultIcon;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  @PostConstruct(preResolve: true)
  Future<void> initialize({
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
  }) async {
    if (_initialized) return;

    _defaultChannelId = '${_packageInfo.packageName}.general';
    _defaultChannelName = F.name;
    _defaultChannelDescription = 'General';

    final android = AndroidInitializationSettings(_defaultIcon);
    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    final linux = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );
    final windows = WindowsInitializationSettings(
      appName: F.title,
      appUserModelId: _packageInfo.packageName,
      guid: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb',
    );
    final settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
      windows: windows,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
    _initialized = true;
    _log.d('NotificationService initialised');
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) return false;

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      return await androidImpl.requestNotificationsPermission() ?? false;
    }

    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      return await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final macosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macosImpl != null) {
      return await macosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) return false;
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      return await androidImpl.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? channelName,
    String? channelDescription,
  }) async {
    if (!_initialized) return;
    final details = _buildDetails(
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
    );
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> cancel(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> pendingNotifications() async {
    if (!_initialized) return const [];
    return _plugin.pendingNotificationRequests();
  }

  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async {
    if (!_initialized) return null;
    return _plugin.getNotificationAppLaunchDetails();
  }

  NotificationDetails _buildDetails({
    String? channelId,
    String? channelName,
    String? channelDescription,
  }) {
    final android = AndroidNotificationDetails(
      _packageInfo.packageName,
      _defaultChannelName,
      channelDescription: _defaultChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwin = DarwinNotificationDetails();
    const linux = LinuxNotificationDetails();
    const windows = WindowsNotificationDetails();
    return NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
      windows: windows,
    );
  }
}

part of 'services.dart';

NotificationService get notificationService =>
    GetIt.I.get<NotificationService>();

/// Thin wrapper around `flutter_local_notifications` that isolates the plugin
/// behind a small, testable API so the rest of the app never depends on the
/// plugin directly.
///
/// The service is responsible for:
///  * Initialising the plugin once at startup (see [initialize]).
///  * Requesting the platform notification permission.
///  * Showing simple local notifications.
///  * Scheduling notifications at a future date/time.
///  * Cancelling pending/active notifications.
///
/// It intentionally does NOT decide *when* notifications should be shown —
/// callers (blocs, services) decide that.
@Singleton(
  dependsOn: [
    PackageInfoService,
  ],
)
class NotificationService {
  final PackageInfoService _packageInfoService;

  NotificationService(this._packageInfoService);

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

  bool _initialized = false;

  /// Whether the plugin has been initialised.
  bool get isInitialized => _initialized;

  @PostConstruct(preResolve: true)
  Future<void> initialize({
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
  }) async {
    if (_initialized) return;

    _defaultChannelId = '${_packageInfoService.packageName}.general';

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
      appUserModelId: _packageInfoService.packageName,
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
    logger.d('NotificationService initialised');
  }

  /// Requests the notification permission on the current platform.
  ///
  /// On Android 13+ this shows the system permission dialog. On iOS/macOS it
  /// requests alert/badge/sound permissions. On other platforms it's a no-op.
  /// Returns `true` if permission was granted (or isn't required).
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

    // Linux/Windows/Web don't require an explicit permission request.
    return true;
  }

  /// Whether notifications are currently enabled on the platform.
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

  /// Shows a simple notification immediately.
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

  /// Cancels the notification with [id].
  Future<void> cancel(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id: id);
  }

  /// Cancels all notifications shown/scheduled by this plugin.
  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  /// Returns the list of pending (scheduled) notification requests.
  Future<List<PendingNotificationRequest>> pendingNotifications() async {
    if (!_initialized) return const [];
    return _plugin.pendingNotificationRequests();
  }

  /// Details on whether the app was launched by tapping a notification.
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
      _packageInfoService.packageName,
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

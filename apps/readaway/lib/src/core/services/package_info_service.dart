part of "services.dart";

PackageInfoService get packageInfoService => GetIt.I<PackageInfoService>();

@singleton
class PackageInfoService {
  PackageInfo? _packageInfo;

  /// Parsed semantic version
  // late final Version semVersion;

  bool get isInitialized => _packageInfo != null;

  PackageInfo get packageInfo {
    if (_packageInfo == null) {
      throw StateError(
        'PackageInfoService is not initialized. Call init() first.',
      );
    }
    return _packageInfo!;
  }

  String get appName => packageInfo.appName;

  String get packageName => packageInfo.packageName;

  String get version => packageInfo.version;

  String get buildNumber => packageInfo.buildNumber;

  String get buildSignature => packageInfo.buildSignature;

  /// Example: 1.2.3+45
  String get fullVersion => '$version+$buildNumber';

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    if (isInitialized) return;

    _packageInfo = await PackageInfo.fromPlatform();

    logger.d('PackageInfo => ${_packageInfo.toString()}');
  }

  Future<void> ensureInitialized() async {
    if (!isInitialized) {
      await init();
    }
  }
}

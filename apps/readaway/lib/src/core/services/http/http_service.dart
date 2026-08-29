part of '../services.dart';

@lazySingleton
@Singleton()
class HttpService {
  final LoggingService logger;

  final Dio _dio;

  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  /// On-disk cache used by [getCached]. Null until [initialize] runs.
  CacheStore? _cacheStore;
  DioCacheInterceptor? _cacheInterceptor;

  static const _defaultTimeout = Duration(seconds: 30);

  Dio get dio => _dio;
  Map<String, String> get defaultHeaders =>
      _dio.options.headers.cast<String, String>();

  HttpService({
    required this.logger,
  }) : _dio = Dio(
         BaseOptions(
           connectTimeout: _defaultTimeout,
           receiveTimeout: _defaultTimeout,
           sendTimeout: _defaultTimeout,
           contentType: 'application/json',
         ),
       ) {
    _configureAdapter();
  }

  void _configureAdapter() {
    _dio.httpClientAdapter = NativeAdapter(
      createCronetEngine: () => CronetEngine.build(
        cacheMode: CacheMode.disabled,
        enableBrotli: true,
        enableHttp2: true,
        enableQuic: true,
        enablePublicKeyPinningBypassForLocalTrustAnchors: true,
      ),
      createCupertinoConfiguration: () =>
          URLSessionConfiguration.ephemeralSessionConfiguration()
            ..allowsCellularAccess = true
            ..allowsConstrainedNetworkAccess = true
            ..allowsExpensiveNetworkAccess = true
            ..httpShouldUsePipelining = true
            ..timeoutIntervalForRequest = _defaultTimeout,
    );
  }

  @PostConstruct(preResolve: true)
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();

    try {
      await _initCache();
      _addInterceptors();
      _isInitialized = true;
      _initCompleter!.complete();
    } catch (e, stackTrace) {
      _initCompleter!.completeError(e, stackTrace);
      _initCompleter = null;
      rethrow;
    }
  }

  /// Sets up the on-disk HTTP cache used by [getCached]. The default policy
  /// is [CachePolicy.noCache], so ordinary requests (and large model
  /// downloads) are never cached — only callers that opt in via [getCached]
  /// get cached responses.
  Future<void> _initCache() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'dio_cache'));
    await dir.create(recursive: true);
    _cacheStore = FileCacheStore(dir.path);
    _cacheInterceptor = DioCacheInterceptor(
      options: CacheOptions(
        store: _cacheStore!,
        policy: CachePolicy.noCache,
      ),
    );
  }

  void _addInterceptors() {
    _dio.interceptors.addAll([
      ?_cacheInterceptor,
      InterceptorsWrapper(
        onError: _onError,
      ),
    ]);
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) await initialize();
  }

  // Interceptor Callbacks

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        /// TODO: Implement actual token refresh logic here
        // final newOptions = await _retryRequest(err.requestOptions);
        // return handler.resolve(await _dio.fetch(newOptions));
      } catch (refreshError) {
        return handler.reject(_mapDioErrorToApiException(err));
      }
    }
    return handler.reject(_mapDioErrorToApiException(err));
  }

  // Error Mapping

  DioException _mapDioErrorToApiException(
    DioException err, [
    CustomErrorTypes? forcedType,
  ]) {
    if (err.error is ApiException && forcedType == null) {
      return err;
    }

    final errorType = forcedType ?? _getDioErrorType(err);
    final message = _getErrorMessage(err, errorType);

    final apiException = ApiException(
      message: message,
      statusCode: err.response?.statusCode,
      errorType: errorType,
      data: err.response?.data,
    );

    return err.copyWith(
      error: apiException,
      message: message,
    );
  }

  CustomErrorTypes _getDioErrorType(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return CustomErrorTypes.timeout;

      case DioExceptionType.connectionError:
        return CustomErrorTypes.noInternet;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        if (statusCode == null) return CustomErrorTypes.unknown;

        return switch (statusCode) {
          400 => CustomErrorTypes.badRequest,
          401 => CustomErrorTypes.unauthorized,
          404 => CustomErrorTypes.notFound,
          >= 500 => CustomErrorTypes.serverError,
          _ => CustomErrorTypes.unknown,
        };

      default:
        return CustomErrorTypes.unknown;
    }
  }

  String _getErrorMessage(DioException err, CustomErrorTypes errorType) {
    final responseData = err.response?.data;
    if (err.type == DioExceptionType.badResponse && responseData is Map) {
      if (responseData['message'] is String) return responseData['message'];
      if (responseData['error'] is String) return responseData['error'];
    }
    return errorType.message;
  }

  // Optimized HTTP Methods

  Future<Response<T>> get<T>({
    required String path,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _ensureInitialized();
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Like [get], but serves a cached response for [maxStale] and falls back
  /// to the last-known-good cached copy (even if stale) when the network is
  /// unreachable. Intended for slowly-changing remote data such as the TTS
  /// model manifest.
  Future<Response<T>> getCached<T>({
    required String path,
    Map<String, dynamic>? queryParameters,
    Duration maxStale = const Duration(days: 1),
    Map<String, String>? headers,
    ResponseType? responseType,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _ensureInitialized();
    // Tell the cache interceptor (and any upstream proxy) that we're happy
    // to serve a response up to [maxStale] old. Without this, the freshness
    // of a cached entry is governed solely by the server's Cache-Control
    // (e.g. GitHub's `max-age=60`), which would revalidate far too often.
    final cacheControl = 'max-stale=${maxStale.inSeconds}';
    final mergedHeaders = <String, String>{
      ...?headers,
      if (!(headers?.containsKey('Cache-Control') ?? false))
        'Cache-Control': cacheControl,
    };
    final store = _cacheStore;
    if (store == null) {
      return get<T>(
        path: path,
        queryParameters: queryParameters,
        options: Options(
          headers: mergedHeaders,
          responseType: responseType,
        ),
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    }
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options:
          CacheOptions(
            store: store,
            policy: CachePolicy.request,
            maxStale: maxStale,
            // Serve the last-known-good copy when offline instead of failing.
            hitCacheOnErrorExcept: const [401, 403],
          ).toOptions().copyWith(
            headers: mergedHeaders,
            responseType: responseType,
          ),
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _ensureInitialized();
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _ensureInitialized();
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> patch<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _ensureInitialized();
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _ensureInitialized();
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // Forms / Payload Operations

  Future<Response<T>> postFormData<T>({
    required String path,
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return post<T>(
      path: path,
      data: formData,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> putFormData<T>({
    required String path,
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return put<T>(
      path: path,
      data: formData,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response> download({
    required String url,
    required String savePath,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _ensureInitialized();
    return _dio.download(
      url,
      savePath,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }
}

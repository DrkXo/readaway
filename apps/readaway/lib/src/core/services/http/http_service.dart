part of '../services.dart';

@lazySingleton
@Singleton()
class HttpService {
  final LoggingService logger;

  final Dio _dio;

  bool _isInitialized = false;
  Completer<void>? _initCompleter;

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
      _addInterceptors();
      _isInitialized = true;
      _initCompleter!.complete();
    } catch (e, stackTrace) {
      _initCompleter!.completeError(e, stackTrace);
      _initCompleter = null;
      rethrow;
    }
  }

  void _addInterceptors() {
    _dio.interceptors.addAll([
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

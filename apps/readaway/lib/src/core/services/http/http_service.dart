import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:injectable/injectable.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

import '../../error/errors.dart';
import '../logging_service.dart';
import '../path_service.dart';

export 'package:dio/dio.dart';

@lazySingleton
@Singleton()
class HttpService {
  final LoggingService logger;
  final AppPathService _pathService;

  final Dio _dio;

  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  CacheStore? _cacheStore;
  DioCacheInterceptor? _cacheInterceptor;

  static const _defaultTimeout = Duration(seconds: 30);

  Dio get dio => _dio;
  Map<String, String> get defaultHeaders =>
      _dio.options.headers.cast<String, String>();

  HttpService({
    required this.logger,
    required this._pathService,
  })  : _dio = Dio(
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

  Future<void> _initCache() async {
    final dir = await _pathService.getHttpCacheDirectory();
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

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    return handler.reject(_mapDioErrorToApiException(err));
  }

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

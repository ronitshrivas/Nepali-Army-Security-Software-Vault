import 'package:dio/dio.dart';
import '../core/config.dart';
import 'token_store.dart';

/// Thin Dio wrapper: attaches the bearer token, transparently refreshes it on a
/// 401 using the stored refresh token, and surfaces a clean error message.
///
/// When a refresh fails, [onAuthLost] is invoked so the app can return the user
/// to the login screen.
class ApiClient {
  final Dio _dio;
  final TokenStore _store;
  void Function()? onAuthLost;

  bool _refreshing = false;

  ApiClient(this._store)
      : _dio = Dio(BaseOptions(
          baseUrl: '${AppConfig.apiBaseUrl}/api',
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
          // We handle non-2xx ourselves rather than throwing on every status.
          validateStatus: (s) => s != null && s < 500,
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _store.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) async {
        // Attempt one silent refresh + retry on a 401 (skip the auth routes).
        final path = response.requestOptions.path;
        final isAuthRoute = path.contains('/auth/');
        if (response.statusCode == 401 && !isAuthRoute && !_refreshing) {
          final retried = await _tryRefreshAndRetry(response.requestOptions);
          if (retried != null) {
            return handler.resolve(retried);
          }
          onAuthLost?.call();
        }
        handler.next(response);
      },
    ));
  }

  Dio get raw => _dio;

  Future<Response?> _tryRefreshAndRetry(RequestOptions original) async {
    final refresh = await _store.refreshToken;
    if (refresh == null || refresh.isEmpty) return null;

    _refreshing = true;
    try {
      final resp = await _dio.post('/auth/refresh',
          data: {'refreshToken': refresh},
          options: Options(headers: {'Authorization': null}));
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = resp.data as Map<String, dynamic>;
        await _store.updateAccess(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );
        // Replay the original request with the new token.
        final newToken = data['accessToken'];
        final opts = Options(
          method: original.method,
          headers: {...original.headers, 'Authorization': 'Bearer $newToken'},
        );
        return _dio.request(
          original.path,
          data: original.data,
          queryParameters: original.queryParameters,
          options: opts,
        );
      }
    } catch (_) {
      // fall through
    } finally {
      _refreshing = false;
    }
    return null;
  }

  // Convenience verbs -------------------------------------------------------

  Future<Response> get(String path, {Map<String, dynamic>? query}) =>
      _dio.get(path, queryParameters: query);

  Future<Response> post(String path, {Object? data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {Object? data}) =>
      _dio.put(path, data: data);
}

/// A typed failure carrying a human-readable message for the UI.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

String friendlyError(Object e) {
  if (e is ApiException) return e.message;
  if (e is DioException) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Cannot reach the server. Check your connection.';
    }
  }
  return 'Something went wrong. Please try again.';
}

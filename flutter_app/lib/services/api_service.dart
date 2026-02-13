import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiService(storage);
});

class ApiService {
  late final Dio _dio;
  final StorageService _storage;

  ApiService(this._storage) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _storage.clearAll();
        }
        return handler.next(error);
      },
    ));
  }

  // ── GET ────────────────────────────────────────────────
  Future<Response> get(String url, {Map<String, dynamic>? params}) async {
    return _dio.get(url, queryParameters: params);
  }

  // ── POST ───────────────────────────────────────────────
  Future<Response> post(String url, {dynamic data}) async {
    return _dio.post(url, data: data);
  }

  // ── PUT ────────────────────────────────────────────────
  Future<Response> put(String url, {dynamic data, Map<String, dynamic>? params}) async {
    return _dio.put(url, data: data, queryParameters: params);
  }

  // ── DELETE ─────────────────────────────────────────────
  Future<Response> delete(String url) async {
    return _dio.delete(url);
  }
}

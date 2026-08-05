import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class DioClient {
  late final Dio _dio;
  final SecureStorageService _storageService;

  // 10.0.2.2 apunta al 'localhost' de la máquina host desde cualquier
  // emulador Android (celular o reloj) — mismo backend que usa AppMovil.
  static const String baseUrl = 'http://10.0.2.2:3000';

  DioClient(this._storageService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await _storageService.clearTokens();
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class NetworkModule {
  static const String _baseUrl = "https://drawai-api.drawai.site/";

  static Dio getDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. Add Device ID (Simple implementation, can be improved with device_info_plus)
          options.headers["X-Device-ID"] = "flutter_device_placeholder";

          // 3. Add Firebase Auth Token
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            try {
              final token = await user.getIdToken();
              if (token != null) {
                options.headers["Authorization"] = "Bearer $token";
              }
            } catch (e) {
              debugPrint("Error getting Firebase token: $e");
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Force logout logic would go here
            FirebaseAuth.instance.signOut();
          }
          return handler.next(e);
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
        ),
      );
    }

    return dio;
  }

  static ApiService getApiService() {
    return ApiService(getDio());
  }
}

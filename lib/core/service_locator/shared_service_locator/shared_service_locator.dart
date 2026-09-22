import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:mushaf_alsawy/core/cache_manager/cache_manager.dart';
import 'package:mushaf_alsawy/core/http/api_consumer.dart';
import 'package:mushaf_alsawy/core/http/endpoints.dart';

class SharedServiceLocator {
  static Future<void> execute({required GetIt getIt}) async {
    final token = await CacheManager.getAccessToken();
    getIt.registerLazySingleton<Dio>(
      () {
        return Dio(
          BaseOptions(
            baseUrl: Endpoints.baseUrl,
            connectTimeout: const Duration(seconds: 60),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              // Disable gzip/deflate from server to avoid malformed compressed responses
              'Accept-Encoding': 'identity',
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
              'Accept-Language': 'ar',
              //  AppRouter.router.configuration.navigatorKey
              //             .currentContext?.isArabic ??
              //         false
              //     ? 'ar'
              //     : 'en',

              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
          ),
        )..interceptors.addAll(
            [
              if (kDebugMode)
                PrettyDioLogger(
                  logPrint: (object) {
                    log(object.toString());
                  },
                  requestHeader: true,
                  requestBody: true,
                  responseBody: true,
                  responseHeader: false,
                  error: true,
                  compact: true,
                  enabled: true,
                  request: true,
                  maxWidth: 90,
                ),
            ],
          );
      },
    );
    getIt.registerLazySingleton<ApiConsumer>(
        () => BaseApiConsumer(dio: getIt<Dio>()));

    // getIt.registerLazySingleton<PusherConsumer>(() => PusherConsumerImpl(appKey: "69d83bf354bcf8c0a712",cluster:"mt1" ));
    // getIt.registerLazySingleton<LocalNotificationConsumer>(() => LocalNotificationServiceImpl()..initialize());
    // getIt.registerLazySingleton<FirebaseService>(() => FirebaseService(getIt()));
    // getIt<FirebaseService>().initializeFirebaseMessaging();
  }
}

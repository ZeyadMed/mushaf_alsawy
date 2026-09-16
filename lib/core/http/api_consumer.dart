import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:mushaf_alsawy/core/extensions/context_extension.dart';
import 'package:mushaf_alsawy/core/helpers/logger.dart';
import 'package:mushaf_alsawy/main.dart';
import 'either.dart';
import 'failure.dart';

abstract final class ApiConsumer {
  Future<Either<Failure, Map<String, dynamic>>> get(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  Future<Either<Failure, Map<String, dynamic>>> post(
    String url, {
    Map<String, dynamic>? data,
    FormData? formData,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  Future<Either<Failure, Map<String, dynamic>>> postFormData(
    String url, {
    Map<String, dynamic>? data,
    FormData? formData,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  Future<Either<Failure, Map<String, dynamic>>> patch(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  Future<Either<Failure, Map<String, dynamic>>> put(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool formData = false,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  Future<Either<Failure, Map<String, dynamic>>> delete(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  });

  Future<Either<Failure, String>> downloadFile({
    required String url,
    required String savePath,
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  Future<Either<Failure, Map<String, dynamic>>> head(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  });

  Future<Either<Failure, Map<String, dynamic>>> uploadFile(
    String url, {
    required Map<String, dynamic> formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  void addInterceptor(Interceptor interceptor);

  void removeAllInterceptors();

  void updateHeader(Map<String, dynamic> headers);

  Future<Either<Failure, Map<String, dynamic>>> retryApiCall(
    Future<Either<Failure, Map<String, dynamic>>> Function() apiCall, {
    int retryCount = 0,
  });
}

final class BaseApiConsumer implements ApiConsumer {
  final Dio _dio;
  final int maxRetries;
  final Duration retryDelay;

  BaseApiConsumer({
    required Dio dio,
    int maxRetries = 5,
    Duration retryDelay = const Duration(seconds: 2),
  })  : _dio = dio,
        maxRetries = 2,
        retryDelay = const Duration(seconds: 5);

  @override
  Future<Either<Failure, Map<String, dynamic>>> retryApiCall(
    Future<Either<Failure, Map<String, dynamic>>> Function() apiCall, {
    int retryCount = 2,
  }) async {
    final result = await apiCall();
    return result.fold(
      (failure) async {
        if (retryCount < maxRetries) {
          log("API failed, retrying attempt #${retryCount + 1}");
          await Future.delayed(retryDelay);
          return retryApiCall(apiCall, retryCount: retryCount + 1); //recursion
        } else {
          log("Max retries reached, API failed: ${failure.message}");
          return Left(failure);
        }
      },
      (success) => Right(success),
    );
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> get(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    apiCall() async {
      try {
        final response = await _dio.get(
          url,
          queryParameters: queryParameters,
          options: Options(headers: headers),
          cancelToken: cancelToken,
          data: data,
          onReceiveProgress: onReceiveProgress,
        );
        return Right<Failure, Map<String, dynamic>>(
            response.data as Map<String, dynamic>);
      } on DioException catch (e) {
        loggerError(e.toString());
        final failure = await _handleDioError(e);
        return Left<Failure, Map<String, dynamic>>(failure);
      } catch (e) {
        return Left<Failure, Map<String, dynamic>>(
            UnknownFailure(message: 'An unexpected error occurred: $e'));
      }
    }

    return await retryApiCall(apiCall);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> head(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.head(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );
      return Right<Failure, Map<String, dynamic>>(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      loggerError(e.toString());
      final failure = await _handleDioError(e);
      return Left<Failure, Map<String, dynamic>>(failure);
    } catch (e) {
      return Left<Failure, Map<String, dynamic>>(
          UnknownFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> patch(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      Response response = await _dio.patch(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
        data: data,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return Right(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      loggerError(e.toString());
      final failure = await _handleDioError(e);
      return Left(failure);
    } catch (e) {
      return Left(UnknownFailure(
          message: 'An unexpected error occurred${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> post(
    String url, {
    Map<String, dynamic>? data,
    FormData? formData,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      Response response = await _dio.post(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        data: data,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      log('right');
      return Right(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      log('left $e');
      loggerError(e.toString());
      final failure = await await _handleDioError(e);
      return Left(failure);
    } catch (e) {
      return Left(UnknownFailure(
          message: 'An unexpected error occurred${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> put(
    String url, {
    Object? data,
    bool formData = false,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      Response response = await _dio.put(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
        data: data,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return Right(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      loggerError(e.toString());
      final failure = await _handleDioError(e);
      return Left(failure);
    } catch (e) {
      return Left(UnknownFailure(
          message: 'An unexpected error occurred${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> delete(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      Response response = await _dio.delete(
        url,
        queryParameters: queryParameters,
        data: data,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );

      return Right(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      loggerError(e.toString());
      final failure = await _handleDioError(e);
      return Left(failure);
    } catch (e) {
      return Left(UnknownFailure(
          message: 'An unexpected error occurred${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> downloadFile({
    required String url,
    required String savePath,
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return Right(savePath); // Return the saved file path
    } on DioException catch (e) {
      loggerError(e.toString());
      return Left(await _handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(
          message: 'An unexpected error occurred ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> uploadFile(String url,
      {required Map<String, dynamic> formData,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) async {
    try {
      Response response = await _dio.post(
        url,
        data: FormData.fromMap(formData),
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return Right(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      loggerError(e.toString());
      return Left(await _handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(
          message: 'An unexpected error occurred${e.toString()}'));
    }
  }

  @override
  void removeAllInterceptors() {
    _dio.options.headers.clear();
  }

  @override
  void updateHeader(Map<String, dynamic> headers) {
    _dio.options.headers.addAll(headers);
  }

  @override
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  Future<Failure> _handleDioError(DioException error) async {
   switch (error.type) {
      case DioExceptionType.cancel:
        navigatorKey.currentContext!.showErrorMessage('تم الغاء الطلب ');
        return ServerFailure(
          message: 'تم إلغاء الطلب ',
        );

      case DioExceptionType.connectionTimeout:
        navigatorKey.currentContext!.showErrorMessage('انتهت مهلة الاتصال ');
        return ServerFailure(message: 'انتهت مهلة الاتصال ');

      case DioExceptionType.sendTimeout:
        navigatorKey.currentContext!.showErrorMessage('انتهت مهلة الاتصال ');
        return ServerFailure(message: 'انتهت مهلة الإرسال في الاتصال ');

      case DioExceptionType.receiveTimeout: // ← أضف دي
        navigatorKey.currentContext!
            .showErrorMessage('انتهت مهلة استقبال البيانات ');
        return ServerFailure(message: 'انتهت مهلة استقبال البيانات ');

      case DioExceptionType.badResponse:
        // ... الكود بتاعك زي ما هو
        if (error.response?.data != null) {
          // ... باقي الكود
        }
        // مهم: لو مفيش return جوه الـ if، لازم يكون في return هنا كمان
        return ServerFailure(
          message: 'حدث خطأ في السيرفر',
          statusCode: error.response?.statusCode,
        );

      case DioExceptionType.connectionError:
        navigatorKey.currentContext!
            .showErrorMessage('لا يوجد اتصال بالإنترنت');
        return ServerFailure(message: 'لا يوجد اتصال بالإنترنت');

      case DioExceptionType.badCertificate:
        return ServerFailure(message: 'مشكلة في شهادة الأمان');

      case DioExceptionType.unknown:
      default:
        navigatorKey.currentContext!.showErrorMessage('حدث خطأ غير متوقع');
        return ServerFailure(message: error.message ?? 'حدث خطأ غير متوقع');
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> postFormData(
    String url, {
    Map<String, dynamic>? data,
    FormData? formData,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      Response response = await _dio.post(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      log('right');
      return Right(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      log('left $e');
      loggerError(e.toString());
      final failure = await _handleDioError(e);
      return Left(failure);
    } catch (e) {
      return Left(UnknownFailure(
          message: 'An unexpected error occurred${e.toString()}'));
    }
  }
}

import 'dart:io';

import 'package:dio/dio.dart';
import '../http/api_consumer.dart';
import '../http/either.dart';
import '../http/failure.dart';
import '../http/params.dart';
import 'logger.dart';

class GenericDataSource {
  final ApiConsumer _apiConsumer;

  GenericDataSource(this._apiConsumer);

  Future<Either<Failure, List<T>>> fetchData<T>({
    required String endpoint,
    PaginationParams? paginationParams,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    Map<String, dynamic>? headers,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final result = await _apiConsumer.get(
      endpoint,
      queryParameters: {
        if (paginationParams != null) ...paginationParams.toJson(),
        if (queryParameters != null) ...queryParameters,
      }..removeWhere((key, value) => value == null || value == ''),
      headers: headers,
      data: data,
    );
    return result.fold(
      (left) => Left(left),
      (right) {
        try {
          // If result is a map that contains a 'data' list
          if (right['data'] is Map && right['data']['data'] is List) {
            final items = (right['data']['data'] as List)
                .map((e) => fromJson(e))
                .toList();
            return Right(items);
          }

          // If result is a list directly
          if (right['data'] is List) {
            final items =
                (right['data'] as List).map((e) => fromJson(e)).toList();
            return Right(items);
          }

          // If data is a list directly
          if (right['data'] is List) {
            final items =
                (right['data'] as List).map((e) => fromJson(e)).toList();
            return Right(items);
          }

          // no matching collection found
          return const Right([]);
        } catch (e, stackTrace) {
          loggerError(stackTrace);
          loggerWarn(e.toString());
          return const Right([]);
        }
      },
    );
  }

  Future<Either<Failure, T>> fetchResult<T>({
    required String endpoint,
    PaginationParams? params,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final result = await _apiConsumer.get(endpoint,
        data: data,
        queryParameters: {
          if (params != null) ...params.toJson(),
          if (queryParameters != null) ...queryParameters,
        },
        headers: headers);
    return result.fold(
      (left) => Left(left),
      (right) {
        if (T == Null) {
          return Right(null as T);
        }
        if (T == String) {
          logger('right: ${right["data"]}');
          return Right(right["data"] as T);
        }

        // If no `fromJson` parser was provided, assume caller expects no payload
        // (e.g. `Either<Failure, void>`). Return a successful empty value.
        if (fromJson == null) {
          return Right(null as T);
        }

        // If a `fromJson` is provided, try to pass the nested payload where possible.
        // Many APIs wrap the payload inside a top-level `data` or `result` object.
        try {
          final Map<String, dynamic> response = right;
          final dynamic payload = response.containsKey('data')
              ? response['data']
              : response.containsKey('data')
                  ? response['data']
                  : response;

          if (payload is Map<String, dynamic>) {
            return Right(fromJson(payload));
          }

          return Right(fromJson(response));
        } catch (e, stackTrace) {
          loggerError(stackTrace);
          loggerWarn(e.toString());
          return Left(ParsingFailure(message: e.toString()));
        }
      },
    );
  }

  Future<Either<Failure, T>> postData<T>({
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final result = await _apiConsumer.post(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
    );
    return result.fold(
      (left) => Left(left),
      (right) {
        logger('GenericDataSource.postData raw right: $right');
        try {
          if (T == Null) {
            return Right(right as T);
          } else if (T == String) {
            logger('right: $right');
            return Right(right['result'] ?? "" as T);
          } else if (T == int) {
            return Right(right['result'] ?? 0 as T);
          } else {
            return Right(right as T);
          }
        } catch (e, stackTrace) {
          loggerError(stackTrace);
          loggerWarn(e.toString());
          return Left(ParsingFailure(message: e.toString()));
        }
      },
    );
  }

  Future<Either<Failure, T>> postFormData<T>({
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    // Process the data to handle lists properly
    final processedData = _processFormData(data ?? {});

    final result = await _apiConsumer.uploadFile(
      endpoint,
      formData: await processedData,
      queryParameters: queryParameters,
      options: Options(
        headers: headers,
      ),
    );

    return result.fold(
      (left) => Left(left),
      (right) {
        try {
          if (T == Null) {
            return Right(null as T);
          } else if (T == int) {
            return Right((right['id'] ?? 0) as T);
          } else if (T == String) {
            logger('right: $right');
            return Right((right['redirect_url'] ?? "") as T);
          } else {
            return Right(null as T);
          }
        } catch (e, stackTrace) {
          loggerError(stackTrace);
          loggerWarn(e.toString());
          return Left(ParsingFailure(message: e.toString()));
        }
      },
    );
  }

  Future<Map<String, dynamic>> _processFormData(
      Map<String, dynamic> data) async {
    final processed = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is File) {
        // Handle File objects by converting to MultipartFile
        final file = value;
        final fileName = file.path.split('/').last;
        // guard against missing files to avoid PathNotFoundException
        if (await file.exists()) {
          processed[key] = await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          );
        } else {
          loggerWarn(
              'File for key `$key` does not exist: ${file.path} -- skipping attachment.');
        }
      } else if (value is List) {
        // Handle lists
        processed.remove(key);
        for (int i = 0; i < value.length; i++) {
          if (value[i] is File) {
            // Handle File in list
            final file = value[i] as File;
            final fileName = file.path.split('/').last;
            if (await file.exists()) {
              processed['$key[$i]'] = await MultipartFile.fromFile(
                file.path,
                filename: fileName,
              );
            } else {
              loggerWarn(
                  'File for key `$key[$i]` does not exist: ${file.path} -- skipping attachment.');
            }
          } else {
            processed['$key[$i]'] = value[i];
          }
        }
      } else if (value is Map) {
        // Recursively process maps
        try {
          final stringMap = Map<String, dynamic>.from(value);
          processed[key] = await _processFormData(stringMap);
        } catch (e) {
          final convertedMap = <String, dynamic>{};
          value.forEach((k, v) => convertedMap[k.toString()] = v);
          processed[key] = await _processFormData(convertedMap);
        }
      } else {
        processed[key] = value;
      }
    }

    return processed;
  }

  Future<Either<Failure, T>> deleteData<T>({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final result = await _apiConsumer.delete(
      endpoint,
      queryParameters: queryParameters,
      headers: headers,
    );
    return result.fold(
      (left) => Left(left),
      (right) {
        try {
          if (T == Null) {
            return Right(null as T);
          } else if (T == int) {
            return Right(right['id'] ?? 0 as T);
          } else if (T == String) {
            logger('right: $right');
            return Right(right['redirect_url'] ?? "" as T);
          } else {
            return Right(null as T);
          }
        } catch (e, stackTrace) {
          loggerError(stackTrace);
          loggerWarn(e.toString());
          return Left(ParsingFailure(message: e.toString()));
        }
      },
    );
  }

  Future<Either<Failure, T>> patchData<T>({
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final result = await _apiConsumer.patch(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
    );
    return result.fold(
      (left) => Left(left),
      (right) {
        try {
          if (T == Null) {
            return Right(null as T);
          } else if (T == int) {
            return Right(right['id'] ?? 0 as T);
          } else if (T == String) {
            logger('right: $right');
            return Right(right['redirect_url'] ?? "" as T);
          } else {
            return Right(null as T);
          }
        } catch (e, stackTrace) {
          loggerError(stackTrace);
          loggerWarn(e.toString());
          return Left(ParsingFailure(message: e.toString()));
        }
      },
    );
  }

  Future<Either<Failure, T>> updateData<T>({
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final result = await _apiConsumer.put(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
    );
    return result.fold(
      (left) => Left(left),
      (right) {
        try {
          if (T == Null) {
            return Right(null as T);
          } else if (T == int) {
            return Right(right['id'] ?? 0 as T);
          } else if (T == String) {
            logger('right: $right');
            return Right(right['redirect_url'] ?? "" as T);
          } else {
            return Right(null as T);
          }
        } catch (e, stackTrace) {
          loggerError(stackTrace);
          loggerWarn(e.toString());
          return Left(ParsingFailure(message: e.toString()));
        }
      },
    );
  }

  Future<Either<Failure, T>> head<T>(
      {required String endpoint,
      required int id,
      Map<String, dynamic>? headers,
      Map<String, dynamic>? queryParameters}) async {
    final result = await _apiConsumer.head(
      endpoint,
      queryParameters: queryParameters,
      headers: headers,
    );
    return result.fold(
      (left) => Left(left),
      (right) {
        try {
          if (T == Null) {
            return Right(null as T);
          } else if (T == String) {
            logger('right: $right');
            return Right(right['redirect_url'] ?? "" as T);
          } else {
            return Right(null as T);
          }
        } catch (e, stackTrace) {
          loggerError(stackTrace);
          loggerWarn(e.toString());
          return Left(ParsingFailure(message: e.toString()));
        }
      },
    );
  }
}

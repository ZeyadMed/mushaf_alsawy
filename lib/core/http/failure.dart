abstract class Failure {
  final String message;
  final int? statusCode;

  Failure(this.message, {this.statusCode});
}

class AuthFailure extends Failure {
  AuthFailure({required String message, int? statusCode})
      : super(message, statusCode: statusCode);
}

class ValidationFailure extends Failure {
  final List<String> errors;

  ValidationFailure(
      {required String message, required this.errors, int? statusCode})
      : super(message, statusCode: statusCode);
}

class ConnectionFailure extends Failure {
  ConnectionFailure({required String message, int? statusCode})
      : super(message, statusCode: statusCode);
}

class CacheFailure extends Failure {
  CacheFailure({required String message, int? statusCode})
      : super(message, statusCode: statusCode);
}

class RequestTimeOutFailure extends Failure {
  RequestTimeOutFailure({required String message, int? statusCode})
      : super(message, statusCode: statusCode);
}

class SendTimeOutFailure extends Failure {
  SendTimeOutFailure({required String message, int? statusCode})
      : super(message, statusCode: statusCode);
}

class UnknownFailure extends Failure {
  UnknownFailure({required String message, int? statusCode})
      : super(message, statusCode: statusCode);
}

class ServerFailure extends Failure {
  ServerFailure({required String message, int? statusCode})
      : super(message, statusCode: statusCode);
}

class UnauthorizedFailure extends Failure {
  UnauthorizedFailure({required String message, int? statusCode})
      : super(message, statusCode: statusCode);
}

class NetworkFailure extends Failure {
  NetworkFailure({required String message, int? statusCode})
      : super(message, statusCode: statusCode);
}

class PaymentFailure extends Failure {
  PaymentFailure({required String message, int? statusCode})
      : super(message, statusCode: statusCode);
}

class SyncAppFailure extends Failure {
  SyncAppFailure({required String message, int? statusCode})
      : super(message, statusCode: statusCode);
}

class VerifyOTPFailure extends Failure {
  VerifyOTPFailure({required String message, int? statusCode})
      : super(message, statusCode: statusCode);
}

class ParsingFailure extends Failure {
  ParsingFailure({required String message, int? statusCode})
      : super(message, statusCode: statusCode);
}

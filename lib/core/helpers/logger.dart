import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

void logger(message) {
  if (kDebugMode) {
    Logger().d(message);
  }
}

void loggerError(message) {
  if (kDebugMode) {
    Logger().e(message);
  }
}

void loggerWarn(message) {
  if (kDebugMode) {
    Logger().w(message);
  }
}

void loggerVerbose(message) {
  if (kDebugMode) {
    Logger().t(message);
  }
}

void loggerInfo(message) {
  if (kDebugMode) {
    Logger().i(message);
  }
}

void loggerFatal(message) {
  if (kDebugMode) {
    Logger().f(message);
  }
}
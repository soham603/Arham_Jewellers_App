import 'dart:developer' as developer;

class LogColors {
  static const String reset = '\x1B[0m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
}

class Logger {
  static void debug(String tag, dynamic message) {
    final msg =
        "${LogColors.cyan}[DEBUG][$tag]${LogColors.reset} $message";
    _log(msg);
  }

  static void info(String tag, dynamic message) {
    final msg =
        "${LogColors.green}[INFO][$tag]${LogColors.reset} $message";
    _log(msg);
  }

  static void warning(String tag, dynamic message) {
    final msg =
        "${LogColors.yellow}[WARNING][$tag]${LogColors.reset} $message";
    _log(msg);
  }

  static void error(String tag, dynamic message,
      {StackTrace? stackTrace}) {
    final msg =
        "${LogColors.red}[ERROR][$tag]${LogColors.reset} $message";
    _log(msg);

    if (stackTrace != null) {
      _log("${LogColors.red}$stackTrace${LogColors.reset}");
    }
  }

  static void verbose(String tag, dynamic message) {
    final msg =
        "${LogColors.magenta}[VERBOSE][$tag]${LogColors.reset} $message";
    _log(msg);
  }

  static void _log(String message) {
    print(message);
    developer.log(message);
  }
}
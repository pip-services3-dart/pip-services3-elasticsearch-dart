import 'dart:async';

import 'package:pip_services3_commons/pip_services3_commons.dart';
import 'package:test/test.dart';
import 'package:pip_services3_components/pip_services3_components.dart';

class LoggerFixture {
  late CachedLogger _logger;

  LoggerFixture(CachedLogger logger) {
    _logger = logger;
  }

  void testLogLevel() {
    expect(_logger.getLevel().index >= LogLevel.None.index, isTrue);
    expect(_logger.getLevel().index <= LogLevel.Trace.index, isTrue);
  }

  Future testSimpleLogging() async {
    _logger.setLevel(LogLevel.Trace);

    _logger.fatal(null, null, 'Fatal error message');
    _logger.error(null, null, 'Error message');
    _logger.warn(null, 'Warning message');
    _logger.info(null, 'Information message');
    _logger.debug(null, 'Debug message');
    _logger.trace(null, 'Trace message');

    _logger.dump();
    await Future.delayed(Duration(milliseconds: 1000));
  }

  Future testErrorLogging() async {
    try {
      // Raise an exception
      throw Exception('Test error');
    } catch (err) {
      var ex = ApplicationException().wrap(err);
      _logger.fatal('123', ex, 'Fatal error');
      _logger.error('123', ex, 'Recoverable error');

      expect(ex, isNotNull);
    }

    _logger.dump();
    await Future.delayed(Duration(milliseconds: 1000));
  }
}

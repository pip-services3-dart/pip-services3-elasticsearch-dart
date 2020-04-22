import 'dart:async';

import 'package:intl/intl.dart';

import 'package:elastic_client/console_http_transport.dart';
import 'package:elastic_client/elastic_client.dart' as elastic;

import 'package:pip_services3_commons/pip_services3_commons.dart';
import 'package:pip_services3_rpc/pip_services3_rpc.dart';
import 'package:pip_services3_components/pip_services3_components.dart';

/// Logger that dumps execution logs to ElasticSearch service.
///
/// ElasticSearch is a popular search index. It is often used
/// to store and index execution logs by itself or as a part of
/// ELK (ElasticSearch - Logstash - Kibana) stack.
///
/// Authentication is not supported in this version.
///
/// ### Configuration parameters ###
///
/// - [level]:             maximum log level to capture
/// - [source]:            source (context) name
/// - [connection(s)]:
///     - [discovery_key]:         (optional) a key to retrieve the connection from [IDiscovery]
///     - [protocol]:              connection protocol: http or https
///     - [host]:                  host name or IP address
///     - [port]:                  port number
///     - [uri]:                   resource URI or connection string with all parameters in it
/// - [options]:
///     - [interval]:        interval in milliseconds to save log messages (default: 10 seconds)
///     - [max_cache_size]:  maximum number of messages stored in this cache (default: 100)
///     - [index]:           ElasticSearch index name (default: 'log')
///     - [date_format]      The date format to use when creating the index name. Eg. log-yyyyMMdd (default: 'yyyyMMdd'). See [https://pub.dev/documentation/intl/latest/intl/DateFormat-class.html]
///     - [daily]:           true to create a new index every day by adding date suffix to the index
///                        name (default: false)
///     - [reconnect]:       reconnect timeout in milliseconds (default: 60 sec)
///     - [timeout]:         invocation timeout in milliseconds (default: 30 sec)
///     - [max_retries]:     maximum number of retries (default: 3)
///     - [index_message]:   true to enable indexing for message object (default: false)
///
/// ### References ###
///
/// - \*:context-info:\*:\*:1.0      (optional) [ContextInfo] to detect the context id and specify counters source
/// - \*:discovery:\*:\*:1.0         (optional) [IDiscovery] services to resolve connection
///
/// ### Example ###
///
///     var logger = ElasticSearchLogger();
///     logger.configure(ConfigParams.fromTuples([
///         'connection.protocol', 'http',
///         'connection.host', 'localhost',
///         'connection.port', 9200
///     ]));
///
///     await logger.open('123')
///         ...
///
///     logger.error('123', ex, 'Error occured: %s', ex.message);
///     logger.debug('123', 'Everything is OK.');

class ElasticSearchLogger extends CachedLogger
    implements IReferenceable, IOpenable {
  final _connectionResolver = HttpConnectionResolver();

  Timer _timer;
  String _index = 'log';
  String _dateFormat = 'yyyyMMdd';
  bool _dailyIndex = false;
  String _currentIndex;
  int _reconnect = 60000;
  int _timeout = 30000;
  int _maxRetries = 3;
  bool _indexMessage = false;

  elastic.Client _client;
  ConsoleHttpTransport _transport;

  /// Creates a new instance of the logger.
  ElasticSearchLogger() : super();

  /// Configures component by passing configuration parameters.
  ///
  /// -  [config]    configuration parameters to be set.
  @override
  void configure(ConfigParams config) {
    super.configure(config);

    _connectionResolver.configure(config);

    _index = config.getAsStringWithDefault('index', _index);
    _dateFormat = config.getAsStringWithDefault('date_format', _dateFormat);
    _dailyIndex = config.getAsBooleanWithDefault('daily', _dailyIndex);
    _reconnect =
        config.getAsIntegerWithDefault('options.reconnect', _reconnect);
    _timeout = config.getAsIntegerWithDefault('options.timeout', _timeout);
    _maxRetries =
        config.getAsIntegerWithDefault('options.max_retries', _maxRetries);
    _indexMessage =
        config.getAsBooleanWithDefault('options.index_message', _indexMessage);
  }

  /// Sets references to dependent components.
  ///
  /// -  [references] 	references to locate the component dependencies.
  @override
  void setReferences(IReferences references) {
    super.setReferences(references);
    _connectionResolver.setReferences(references);
  }

  /// Checks if the component is opened.
  ///
  /// Return true if the component has been opened and false otherwise.
  @override
  bool isOpen() {
    return _timer != null;
  }

  /// Opens the component.
  ///
  /// -  [correlationId] 	(optional) transaction id to trace execution through call chain.
  /// Return 			Future that receives null no errors occured.
  /// Throws error
  @override
  Future open(String correlationId) async {
    if (isOpen()) {
      return null;
    }

    var connection = await _connectionResolver.resolve(correlationId);
    if (connection == null) {
      throw ConfigException(
          correlationId, 'NO_CONNECTION', 'Connection is not configured');
    }

    var uri = connection.getUri();

    // var options = {
    //     host: uri,
    //     requestTimeout: this._timeout,
    //     deadTimeout: this._reconnect,
    //     maxRetries: this._maxRetries
    // };

    _transport = ConsoleHttpTransport(Uri.parse(uri));
    _client = elastic.Client(_transport);

    await _createIndexIfNeeded(correlationId, true);
    _timer = Timer.periodic(Duration(milliseconds: interval), (tm) {
      dump();
    });
  }

  /// Closes component and frees used resources.
  ///
  /// -  [correlationId] 	(optional) transaction id to trace execution through call chain.
  /// Return 			Future that receives null no errors occured.
  /// Throws error
  @override
  Future close(String correlationId) async {
    await save(cache);
    if (_timer != null) {
      _timer.cancel();
    }

    cache = [];
    _timer = null;
    _client = null;
    await _transport.close();
    _transport = null;
  }

  String _getCurrentIndex() {
    if (!_dailyIndex) return _index;

    return _index +
        '-' +
        DateFormat(_dateFormat).format(DateTime.now().toUtc());
  }

  Future _createIndexIfNeeded(String correlationId, bool force) async {
    var newIndex = _getCurrentIndex();
    if (!force && _currentIndex == newIndex) {
      return null;
    }

    _currentIndex = newIndex;
    var exists = await _client.indexExists(_currentIndex);

    if (exists) {
      return null;
    }

    await _client.updateIndex(_currentIndex, {
      'settings': {'number_of_shards': 1},
      'mappings': {
        'log_message': {
          'properties': {
            'time': {'type': 'date', 'index': true},
            'source': {'type': 'keyword', 'index': true},
            'level': {'type': 'keyword', 'index': true},
            'correlation_id': {'type': 'text', 'index': true},
            'error': {
              'type': 'object',
              'properties': {
                'type': {'type': 'keyword', 'index': true},
                'category': {'type': 'keyword', 'index': true},
                'status': {'type': 'integer', 'index': false},
                'code': {'type': 'keyword', 'index': true},
                'message': {'type': 'text', 'index': false},
                'details': {'type': 'object'},
                'correlation_id': {'type': 'text', 'index': false},
                'cause': {'type': 'text', 'index': false},
                'stack_trace': {'type': 'text', 'index': false}
              }
            },
            'message': {'type': 'text', 'index': _indexMessage}
          }
        }
      }
    });
  }

  /// Saves log messages from the cache.
  ///
  /// -  [messages]  a list with log messages
  /// Return  Future that receives null for success.
  /// Throws error
  @override
  Future save(List<LogMessage> messages) async {
    if (!isOpen() && messages.isEmpty) {
      return null;
    }

    await _createIndexIfNeeded('elasticsearch_logger', false);

    var bulk = <Doc>[];
    for (var message in messages) {
      var doc = Doc(IdGenerator.nextLong(), message.toJson(),
          index: _currentIndex, type: 'log_message');
      bulk.add(doc);
    }

    var compleate =
        await _client.updateDocs(_currentIndex, 'log_message', bulk);
    if (!compleate) {
      throw ApplicationException('Logger', 'elasticsearch_logger', 'SAVE_ERROR',
          'Can\'t save log messages to Elasticsearch server!');
    }
  }
}

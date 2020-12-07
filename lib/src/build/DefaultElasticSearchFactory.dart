import 'package:pip_services3_components/pip_services3_components.dart';
import 'package:pip_services3_commons/pip_services3_commons.dart';
import '../log/ElasticSearchLogger.dart';

/// Creates ElasticSearch components by their descriptors.
///
/// See [ElasticSearchLogger]
class DefaultElasticSearchFactory extends Factory {
  static final descriptor =
      Descriptor('pip-services', 'factory', 'elasticsearch', 'default', '1.0');
  static final ElasticSearchLoggerDescriptor =
      Descriptor('pip-services', 'logger', 'elasticsearch', '*', '1.0');

  /// Create a new instance of the factory.

  DefaultElasticSearchFactory() : super() {
    registerAsType(DefaultElasticSearchFactory.ElasticSearchLoggerDescriptor,
        ElasticSearchLogger);
  }
}

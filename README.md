# <img src="https://uploads-ssl.webflow.com/5ea5d3315186cf5ec60c3ee4/5edf1c94ce4c859f2b188094_logo.svg" alt="Pip.Services Logo" width="200"> <br/> ElasticSearch components for Dart

This module is a part of the [Pip.Services](http://pipservices.org) polyglot microservices toolkit.

The Elasticsearch module contains logging components with data storage on the Elasticsearch server.

The module contains the following packages:
- **Build** - contains a factory for the construction of components
- **Log** - Logging components


<a name="links"></a> Quick links:

* [Configuration](https://www.pipservices.org/recipies/configuration)
* [Logging](https://www.pipservices.org/recipies/active-logic)
* [Virtual memory configuration](https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html)
* [API Reference](https://pub.dev/documentation/pip_services3_elasticsearch/latest/pip_services3_elasticsearch/pip_services3_elasticsearch-library.html)
* [Change Log](CHANGELOG.md)
* [Get Help](https://www.pipservices.org/community/help)
* [Contribute](https://www.pipservices.org/community/contribute)


## Use

Add this to your package's pubspec.yaml file:
```yaml
dependencies:
  pip_services3_elasticsearch: version
```

Now you can install package from the command line:
```bash
pub get
```

Microservice components shall perform logging usual way using CompositeLogger component.
The CompositeLogger will get ElasticSearchLogger from references and will redirect log messages
there among other destinations.

```dart
class MyComponent implements IConfigurable, IReferenceable {
  CompositeLogger _logger = new CompositeLogger();
  
  configure(ConfigParams config) {
    this._logger.configure(config);
  }
  
  setReferences(IReferences refs) {
    this._logger.setReferences(refs);
  }
  
  myMethod(String correlationId, param1) {
    this._logger.trace(correlationId, "Executed method mycomponent.mymethod");
    ....
  }
}
```

Configuration for your microservice that includes ElasticSearch logger may look the following way.

```yaml
...
{{#if ELASTICSEARCH_ENABLED}}
- descriptor: pip-services:logger:elasticsearch:default:1.0
  connection:
    uri: {{{ELASTICSEARCG_SERVICE_URI}}}
    host: {{{ELASTICSEARCH_SERVICE_HOST}}}{{#unless ELASTICSEARCH_SERVICE_HOST}}localhost{{/unless}}
    port: {{ELASTICSEARCG_SERVICE_PORT}}{{#unless ELASTICSEARCH_SERVICE_PORT}}9200{{/unless}}\ 
{{/if}}
...
```

## Develop

For development you shall install the following prerequisites:
* Dart SDK 2
* Visual Studio Code or another IDE of your choice
* Docker

Install dependencies:
```bash
pub get
```

Run automated tests:
```bash
pub run test
```

Generate API documentation:
```bash
./docgen.ps1
```

Before committing changes run dockerized build and test as:
```bash
./build.ps1
./test.ps1
./clear.ps1
```

## Contacts

The library is created and maintained by 
- **Sergey Seroukhov**
- **Levichev Dmitry**

The documentation is written by:
- **Mark Makarychev**
- **Levichev Dmitry**
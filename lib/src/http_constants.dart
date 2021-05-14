export 'dart:io';

enum HttpMethod {
  get,
  head,
  post,
  put,
  delete,
  connect,
  options,
  trace,
  patch,
}

HttpMethod? matchHttpMethod(String value) {
  for (final method in HttpMethod.values) {
    if (method.value == value) {
      return method;
    }
  }
  return null;
}

extension HttpMethodImpl on HttpMethod {
  static const safeMethods = {
    HttpMethod.get,
    HttpMethod.head,
    HttpMethod.options,
    HttpMethod.trace,
  };

  bool get isSafe => safeMethods.contains(this);

  String get value {
    switch (this) {
      case HttpMethod.get:
        return 'GET';
      case HttpMethod.head:
        return 'HEAD';
      case HttpMethod.post:
        return 'POST';
      case HttpMethod.put:
        return 'PUT';
      case HttpMethod.delete:
        return 'DELETE';
      case HttpMethod.connect:
        return 'CONNECT';
      case HttpMethod.options:
        return 'OPTIONS';
      case HttpMethod.trace:
        return 'TRACE';
      case HttpMethod.patch:
        return 'PATCH';
    }
  }
}

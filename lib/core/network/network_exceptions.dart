/// Thrown when remote calls fail; API layer maps Dio and other transport errors here.
class NetworkException implements Exception {
  NetworkException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'NetworkException: $message';
}

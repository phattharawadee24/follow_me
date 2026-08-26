class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  const ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}


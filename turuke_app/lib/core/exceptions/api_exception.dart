class ApiException implements Exception {
  final int statusCode;
  final String body;
  final String userMessage;

  ApiException(this.statusCode, this.body, this.userMessage);

  @override
  String toString() => 'ApiException: $statusCode - $body';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() {
    return 'ApiException: $message (Código: $statusCode)';
  }
}

class NetworkException extends ApiException {
  NetworkException({required super.message});
}

class ValidationException extends ApiException {
  ValidationException({required super.message});
}

class NotFoundException extends ApiException {
  NotFoundException({required super.message}) : super(statusCode: 404);
}

class ServerException extends ApiException {
  ServerException({required super.message, super.statusCode});
}

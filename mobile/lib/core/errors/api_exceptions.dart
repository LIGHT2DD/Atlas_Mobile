class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final List<String>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException({super.message = 'Cannot connect to ATLAS server. Please check your network connection.'})
      : super(statusCode: null);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({super.message = 'Your session has expired. Please sign in again.'})
      : super(statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException({super.message = 'You do not have permission to perform this action.'})
      : super(statusCode: 403);
}

class ConflictException extends ApiException {
  ConflictException({required super.message})
      : super(statusCode: 409);
}

import 'package:dio/dio.dart';

class ApiResponse<T> {
  const ApiResponse({required this.data, this.message});
  final T data;
  final String? message;

  /// Envelope contract: {"data": ..., "message": optional string}.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) parse,
  ) {
    if (!json.containsKey('data'))
      throw const FormatException('Missing response data.');
    return ApiResponse(
      data: parse(json['data']),
      message: json['message'] as String?,
    );
  }
}

enum NetworkFailureKind {
  timeout,
  offline,
  cancelled,
  unauthorized,
  client,
  server,
  invalidResponse,
  unknown,
}

class NetworkFailure implements Exception {
  const NetworkFailure(this.kind, this.message, {this.statusCode});
  final NetworkFailureKind kind;
  final String message;
  final int? statusCode;
  factory NetworkFailure.fromDio(DioException error) {
    final cause = error.error;
    if (cause is NetworkFailure) return cause;
    final status = error.response?.statusCode;
    final kind = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => NetworkFailureKind.timeout,
      DioExceptionType.connectionError => NetworkFailureKind.offline,
      DioExceptionType.cancel => NetworkFailureKind.cancelled,
      DioExceptionType.badResponse =>
        status == 401
            ? NetworkFailureKind.unauthorized
            : (status != null && status >= 500
                  ? NetworkFailureKind.server
                  : NetworkFailureKind.client),
      _ => NetworkFailureKind.unknown,
    };
    return NetworkFailure(kind, switch (kind) {
      NetworkFailureKind.timeout => 'The request timed out.',
      NetworkFailureKind.offline => 'Unable to connect to the service.',
      NetworkFailureKind.cancelled => 'The request was cancelled.',
      NetworkFailureKind.unauthorized => 'Your session has expired.',
      NetworkFailureKind.server => 'The service is temporarily unavailable.',
      NetworkFailureKind.client => 'The service rejected the request.',
      _ => 'The request could not be completed.',
    }, statusCode: status);
  }
  @override
  String toString() =>
      'NetworkFailure(${kind.name}, status: $statusCode): $message';
}

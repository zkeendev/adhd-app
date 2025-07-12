import 'package:http/http.dart' as http;

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic responseBody;

  NetworkException(this.message, {this.statusCode, this.responseBody});

  @override
  String toString() {
    return 'NetworkException: $message (Status: $statusCode)';
  }
}

class HttpErrorHandler {
  /// Checks an HTTP response for error status codes.
  /// If an error status code is found, it throws a [NetworkException].
  /// If the status code indicates success (e.g., 200-299), it does nothing.
  ///
  /// [response]: The HTTP response to check.
  static void checkForErrors(http.Response response) {
    final int statusCode = response.statusCode;
    final String responseBody = response.body;

    // If status code is in the 2xx range, it's generally a success, so do nothing.
    if (statusCode >= 200 && statusCode < 300) return;

    // --- Handle Error Status Codes ---
    print("[HttpErrorHandler] Error Status Code: $statusCode. Body: $responseBody");

    String errorMessage;
    switch (statusCode) {
      case 400:
      case 422:
        errorMessage = "Invalid request (Status: $statusCode). Details: ${response.reasonPhrase}";
        break;

      case 401:
      case 403:
        errorMessage = "Authentication failed with service.";
        break;

      default:
        if (statusCode >= 500 && statusCode < 600) {
          errorMessage = "Service encountered an internal server error. Please try again later.";
        } else if (statusCode >= 400 && statusCode < 500) {
          errorMessage = "Service request failed (Status: $statusCode).";
        } else {
          errorMessage = "Unexpected response from service (Status: $statusCode).";
        }
    }
    throw NetworkException(
      errorMessage,
      statusCode: statusCode,
      responseBody: responseBody,
    );
  }
}

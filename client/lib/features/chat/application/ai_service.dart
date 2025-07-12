import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import 'package:adhd_app/core/utils/http_error_handler.dart';
import 'package:adhd_app/features/chat/domain/chat_message.dart';

class AIServiceException implements Exception {
  final String message;
  final int? statusCode;
  final Object? originalError;

  AIServiceException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() {
    String result =
        'AIServiceException: $message${statusCode != null ? " (Status Code: $statusCode)" : ""}';
    if (originalError != null) {
      result += '\nOriginal Error: $originalError';
    }
    return result;
  }
}

class AIService {
  // Use 10.0.2.2 for Android emulator to connect to localhost on the host machine.
  // For iOS simulator, you can use localhost or 127.0.0.1.
  // For physical devices, you'll need to use your computer's local network IP.
  final String _fastApiBaseUrl = "http://10.0.2.2:8000";
  final Duration _defaultTimeout = const Duration(seconds: 60);

  AIService();

  Future<String?> _getAuthToken(User user) async {
    try {
      // Force refresh the token to ensure it's not expired.
      final String? token = await user.getIdToken(true);
      if (token == null) {
        throw AIServiceException("Fetched ID token is null.");
      }
      return token;
    } catch (e) {
      print("[AIService:_getAuthToken] Error fetching Firebase ID token: $e");
      throw AIServiceException(
        "Could not retrieve authentication token.",
        originalError: e,
      );
    }
  }

  /// Sends a user's message and its client-generated ID to the backend.
  Future<void> sendMessage({
    required User user,
    required ChatMessage message,
  }) async {
    final token = await _getAuthToken(user);

    final String endpoint = '/chat';
    final Uri url = Uri.parse('$_fastApiBaseUrl$endpoint');

    print("[AIService:sendMessage] Calling FastAPI: $url with messageId: '${message.id}'");

    try {
      final http.Response response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_message': message.text,
          'message_id': message.id,
          'client_timestamp': message.timestamp?.toDate().toUtc().toIso8601String(),
        }),
      ).timeout(_defaultTimeout);

      // Throws a NetworkException for non-2xx status codes.
      HttpErrorHandler.checkForErrors(response);

      // A successful (2xx) response means the backend has accepted the request.
      print("[AIService:sendMessage] Backend successfully accepted the request for messageId: ${message.id}");
    } on TimeoutException catch (e, s) {
      print("[AIService:sendMessage] Request timed out: $e\n$s");
      throw AIServiceException(
        "The request to the AI service took too long. Please try again.",
        originalError: e,
      );
    } on http.ClientException catch (e, s) {
      print("[AIService:sendMessage] Network error: $e\n$s");
      throw AIServiceException(
        "Could not connect to the AI service. Please check your network connection.",
        originalError: e,
      );
    } on NetworkException catch (e) {
      print("[AIService:sendMessage] NetworkException from HttpErrorHandler: ${e.message}");
      throw AIServiceException(
        e.message,
        statusCode: e.statusCode,
        originalError: e.responseBody ?? e.toString(),
      );
    } catch (e, s) {
      print("[AIService:sendMessage] Unknown error: $e\n$s");
      throw AIServiceException(
        "An unknown error occurred while contacting the AI service.",
        originalError: e,
      );
    }
  }
}
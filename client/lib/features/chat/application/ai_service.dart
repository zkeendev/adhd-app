import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/chat_message.dart';
import '../../../core/constants/network_constants.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/utils/http_error_handler.dart';


class AIServiceException implements Exception {
  final String message;
  final int? statusCode;
  final Object? originalError;

  AIServiceException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() {
    String res = 'AIServiceException: $message${statusCode != null ? " (Status Code: $statusCode)" : ""}';
    if (originalError != null) {
      res += '\nOriginal Error: $originalError';
    }
    return res;
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
      final String? token = await user.getIdToken(true);
      if (token == null) throw AIServiceException(ErrorMessages.tokenNull);
      return token;
    } catch (e) {
      throw AIServiceException(ErrorMessages.tokenNull, originalError: e);
    }
  }

  /// Sends a user's message and its client-generated ID to the backend.
  Future<void> sendMessage({required User user, required ChatMessage message}) async {
    final token = await _getAuthToken(user);
    final Uri url = Uri.parse('$_fastApiBaseUrl${NetworkConstants.chatEndpoint}');

    print("[AIService:sendMessage] Calling FastAPI: $url with messageId: '${message.id}'");

    try {
      final http.Response response = await http.post(
        url,
        headers: {
          'Content-Type': NetworkConstants.contentType,
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
    } on TimeoutException catch (e) {
      throw AIServiceException(ErrorMessages.requestTimeout, originalError: e);
    } on http.ClientException catch (e) {
      throw AIServiceException(ErrorMessages.network, originalError: e);
    } on NetworkException catch (e) {
      throw AIServiceException(e.message, statusCode: e.statusCode, originalError: e.responseBody ?? e.toString());
    } catch (e) {
      throw AIServiceException(ErrorMessages.unknown, originalError: e);
    }
  }
}
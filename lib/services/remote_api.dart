import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/client.dart';

/// Encapsulates remote interactions for saving client data online.
class RemoteApi {
  RemoteApi._();

  /// Default endpoint uses JSONPlaceholder which accepts arbitrary JSON payloads.
  static const String _defaultEndpoint =
      'https://jsonplaceholder.typicode.com/posts';

  /// Resolve the endpoint from the `REMOTE_SAVE_ENDPOINT` compile-time environment
  /// value, falling back to [_defaultEndpoint] if none is provided.
  static String get _endpoint => const String.fromEnvironment(
        'REMOTE_SAVE_ENDPOINT',
        defaultValue: _defaultEndpoint,
      );

  /// Maximum time to wait for the remote call before considering it failed.
  static const Duration _timeout = Duration(seconds: 10);

  /// Persist the current list of [clients] to the remote endpoint.
  ///
  /// The API accepts any JSON payload, so by default the method posts to
  /// JSONPlaceholder. Consumers can override the target endpoint via the
  /// `--dart-define=REMOTE_SAVE_ENDPOINT=<url>` build argument.
  static Future<RemoteSaveResult> saveClients(
      List<ClientModel> clients) async {
    final uri = Uri.parse(_endpoint);
    final payload = <String, dynamic>{
      'syncedAt': DateTime.now().toUtc().toIso8601String(),
      'clientCount': clients.length,
      'clients': clients.map((c) => c.toMap()).toList(),
    };

    try {
      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      final status = response.statusCode;
      if (status >= 200 && status < 300) {
        return RemoteSaveResult.success(
          statusCode: status,
          message: 'Remote save completed (HTTP $status)',
        );
      }

      return RemoteSaveResult.failure(
        statusCode: status,
        message: 'Remote save failed (HTTP $status)',
      );
    } on TimeoutException catch (err) {
      return RemoteSaveResult.failure(
        message: 'Remote save timed out after ${_timeout.inSeconds}s',
        error: err,
      );
    } catch (err) {
      return RemoteSaveResult.failure(
        message: 'Remote save failed: $err',
        error: err,
      );
    }
  }
}

/// Represents the outcome of attempting to save client data online.
class RemoteSaveResult {
  final bool success;
  final String message;
  final int? statusCode;
  final Object? error;

  const RemoteSaveResult._({
    required this.success,
    required this.message,
    this.statusCode,
    this.error,
  });

  factory RemoteSaveResult.success({required String message, int? statusCode}) {
    return RemoteSaveResult._(
      success: true,
      message: message,
      statusCode: statusCode,
    );
  }

  factory RemoteSaveResult.failure({
    required String message,
    int? statusCode,
    Object? error,
  }) {
    return RemoteSaveResult._(
      success: false,
      message: message,
      statusCode: statusCode,
      error: error,
    );
  }
}

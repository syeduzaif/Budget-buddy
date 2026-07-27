import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../data/models/chat_message_model.dart';

/// Kind of failure returned by the AI proxy, so callers can show the right
/// message without ever parsing (or displaying) upstream provider text.
enum AiApiErrorKind {
  /// `AppConstants.apiBaseUrl` is empty — this build has no backend wired up.
  notConfigured,

  /// No signed-in Firebase user, so no ID token can be minted.
  notSignedIn,

  /// 400 — message missing / too long / malformed body.
  badRequest,

  /// 401 — missing, expired or invalid ID token.
  unauthorized,

  /// 429 — per-user daily quota exhausted.
  quotaExceeded,

  /// 5xx, timeout, socket error, or an unparseable response body.
  unavailable,
}

/// Failure raised by [GeminiService]. Carries only a coarse [kind] plus an
/// optional HTTP [status] for logging — deliberately no upstream error text.
class AiApiException implements Exception {
  const AiApiException(this.kind, {this.status});

  final AiApiErrorKind kind;
  final int? status;

  @override
  String toString() =>
      'AiApiException(${kind.name}${status == null ? '' : ', status: $status'})';
}

/// HTTP client for BuddgetBuddy's **own authenticated AI proxy**.
///
/// This used to embed the Gemini SDK and read a provider API key out of a
/// bundled env asset (defects C1/C2: the key shipped inside every APK we
/// published). It now holds no credential of its own:
/// every request goes to `{AppConstants.apiBaseUrl}/api/chat` or
/// `/api/insights` with a Firebase ID token as bearer, and the server owns the
/// provider credential, the rate limit and the model choice.
///
/// Name and DI lifecycle are unchanged on purpose (registered/deleted in
/// `auth_controller.dart`) to keep the security diff small; renaming to
/// `AiService` is deferred to a follow-up.
///
/// Contract errors are **thrown** as [AiApiException] — this class never
/// returns an error string as if it were an AI answer (defect H3).
class GeminiService extends GetxService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 60);

  /// Max conversation turns sent as context (frozen contract with the proxy).
  static const int maxHistoryTurns = 20;

  /// Max categories sent to `/api/insights` (frozen contract with the proxy).
  static const int maxInsightCategories = 50;

  /// Last failure kind, for diagnostics/UI affordances. Empty when healthy.
  final lastError = ''.obs;

  @override
  void onClose() {
    _client.close();
    super.onClose();
  }

  /// Sends [message] plus prior conversation [history] to `/api/chat`.
  ///
  /// [history] is the conversation BEFORE [message] (the caller must not
  /// include the outgoing message); it is trimmed to the last
  /// [maxHistoryTurns] entries, oldest → newest.
  Future<String> generateResponse(
    String message,
    List<ChatMessageModel> history,
  ) async {
    final trimmed = history.length > maxHistoryTurns
        ? history.sublist(history.length - maxHistoryTurns)
        : history;

    final body = <String, dynamic>{
      'message': message,
      'history': trimmed
          .map((m) => <String, dynamic>{'message': m.message, 'isUser': m.isUser})
          .toList(),
    };

    final json = await _post('/api/chat', body);
    return _requireString(json, 'response');
  }

  /// Sends the current month's budget snapshot to `/api/insights`.
  ///
  /// [categories] must already be sorted by spent descending and capped at
  /// [maxInsightCategories]; [truncatedCount] reports how many were dropped.
  Future<String> generateInsights({
    required String currencyCode,
    required double monthlyIncome,
    required double totalSpent,
    required double totalBudget,
    required List<Map<String, dynamic>> categories,
    int truncatedCount = 0,
    String? month,
  }) async {
    final body = <String, dynamic>{
      'currencyCode': currencyCode,
      'monthlyIncome': monthlyIncome,
      'totalSpent': totalSpent,
      'totalBudget': totalBudget,
      'categories': categories,
      if (truncatedCount > 0) 'truncatedCount': truncatedCount,
      if (month != null && month.isNotEmpty) 'month': month,
    };

    final json = await _post('/api/insights', body);
    return _requireString(json, 'insights');
  }

  /// No-op kept for the clear-chat call site: conversation context now lives in
  /// Firestore (`ai_chat`), not in a client-side SDK session, so deleting the
  /// messages *is* the reset. Retained so `clearChat()` reads coherently and so
  /// a future server-side session cache has a hook.
  void resetChat() {
    lastError.value = '';
  }

  // ── internals ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    if (!AppConstants.isAiConfigured) {
      throw _fail(AiApiErrorKind.notConfigured);
    }

    final token = await _idToken();
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');

    http.Response res;
    try {
      res = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } catch (_) {
      // Socket errors, timeouts, DNS failures — no upstream detail to leak.
      throw _fail(AiApiErrorKind.unavailable);
    }

    switch (res.statusCode) {
      case 200:
        break;
      case 400:
        throw _fail(AiApiErrorKind.badRequest, status: 400);
      case 401:
      case 403:
        throw _fail(AiApiErrorKind.unauthorized, status: res.statusCode);
      case 429:
        throw _fail(AiApiErrorKind.quotaExceeded, status: 429);
      default:
        throw _fail(AiApiErrorKind.unavailable, status: res.statusCode);
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw _fail(AiApiErrorKind.unavailable, status: 200);
    }
    lastError.value = '';
    return decoded;
  }

  Future<String> _idToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw _fail(AiApiErrorKind.notSignedIn);
    }
    try {
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        throw _fail(AiApiErrorKind.notSignedIn);
      }
      return token;
    } on AiApiException {
      rethrow;
    } catch (_) {
      throw _fail(AiApiErrorKind.unauthorized);
    }
  }

  String _requireString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw _fail(AiApiErrorKind.unavailable, status: 200);
  }

  AiApiException _fail(AiApiErrorKind kind, {int? status}) {
    lastError.value = kind.name;
    return AiApiException(kind, status: status);
  }
}

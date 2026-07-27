import 'package:budget_buddy/core/constants/app_constants.dart';
import 'package:budget_buddy/services/app/gemini_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Fails the test if the service ever tries to hit the network while the
/// backend URL is unconfigured.
class _ForbiddenClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    fail('No HTTP request may be made when API_BASE_URL is unset');
  }
}

void main() {
  group('AI proxy configuration guard', () {
    test('apiBaseUrl defaults to empty when no --dart-define is supplied', () {
      // Pins the C2/C3 contract: nothing is baked into the binary by default,
      // and the AI feature must degrade instead of guessing a host.
      expect(AppConstants.apiBaseUrl, isEmpty);
      expect(AppConstants.isAiConfigured, isFalse);
    });

    test('generateResponse throws notConfigured (no network, no crash)',
        () async {
      final service = GeminiService(client: _ForbiddenClient());

      await expectLater(
        service.generateResponse('hello', const []),
        throwsA(isA<AiApiException>().having(
            (e) => e.kind, 'kind', AiApiErrorKind.notConfigured)),
      );
    });

    test('generateInsights throws notConfigured (no network, no crash)',
        () async {
      final service = GeminiService(client: _ForbiddenClient());

      await expectLater(
        service.generateInsights(
          currencyCode: 'PKR',
          monthlyIncome: 100000,
          totalSpent: 42000,
          totalBudget: 90000,
          categories: const [
            {'name': 'Food', 'budgetLimit': 20000, 'spent': 18000},
          ],
        ),
        throwsA(isA<AiApiException>().having(
            (e) => e.kind, 'kind', AiApiErrorKind.notConfigured)),
      );
    });

    test('AiApiException.toString never carries upstream provider text', () {
      const e = AiApiException(AiApiErrorKind.unavailable, status: 503);
      expect(e.toString(), 'AiApiException(unavailable, status: 503)');
    });
  });
}

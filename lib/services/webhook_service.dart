import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class WebhookService {
  static final WebhookService instance = WebhookService._();
  WebhookService._();

  /// Set your live n8n Webhook URL here
  String n8nWebhookUrl = 'https://YOUR_N8N_INSTANCE.com/webhook/emma-whatsapp-webhook';

  bool get isConfigured =>
      n8nWebhookUrl.isNotEmpty && !n8nWebhookUrl.contains('YOUR_N8N_INSTANCE');

  /// Trigger 1: Sent when participant submits drive registration
  Future<void> sendRegistrationSuccess({
    required String submissionId,
    required String participantName,
    required String phone,
    required String driveTitle,
  }) async {
    final payload = {
      'event': 'registration_success',
      'submissionId': submissionId,
      'participantName': participantName.isNotEmpty ? participantName : 'Participant',
      'phone': phone,
      'driveTitle': driveTitle.isNotEmpty ? driveTitle : 'Emma Recycling Drive',
    };
    await _post(payload);
  }

  /// Trigger 2: Sent when manufacturer records and verifies item weight
  Future<void> sendSubmissionVerified({
    required String submissionId,
    required String participantName,
    required String phone,
    required String driveTitle,
    required double weightKg,
  }) async {
    final payload = {
      'event': 'submission_verified',
      'submissionId': submissionId,
      'participantName': participantName.isNotEmpty ? participantName : 'Participant',
      'phone': phone,
      'driveTitle': driveTitle.isNotEmpty ? driveTitle : 'Emma Recycling Drive',
      'weightKg': weightKg,
    };
    await _post(payload);
  }

  Future<void> _post(Map<String, dynamic> payload) async {
    if (!isConfigured) {
      debugPrint('[WebhookService] n8n URL is using placeholder. Skipping webhook.');
      return;
    }
    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse(n8nWebhookUrl));
      request.headers.set('Content-Type', 'application/json; charset=UTF-8');
      request.write(jsonEncode(payload));
      final response = await request.close();
      debugPrint('[WebhookService] Sent to n8n successfully: status ${response.statusCode}');
      client.close();
    } catch (e) {
      debugPrint('[WebhookService] Error sending to n8n: $e');
    }
  }
}

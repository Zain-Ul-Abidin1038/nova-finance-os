import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_finance_os/features/nova_navigator/domain/external_app.dart';

final externalAppServiceProvider = Provider((ref) => ExternalAppService());

class ExternalAppService {
  /// Launch an external app via deep link, falling back to web URL
  Future<LaunchResult> launchApp(ExternalApp app, {String? query}) async {
    safePrint('[ExternalAppService] Launching ${app.name}...');

    // Try deep link first
    final deepLink = app.deepLinkTemplate ?? app.iosScheme ?? '';
    if (deepLink.isNotEmpty) {
      try {
        final uri = Uri.parse(deepLink);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return LaunchResult(
            success: true,
            method: 'deep_link',
            message: 'Opened ${app.name} via deep link',
          );
        }
      } catch (e) {
        safePrint('[ExternalAppService] Deep link failed: $e');
      }
    }

    // Try platform-specific scheme
    if (Platform.isAndroid && app.androidPackage != null) {
      try {
        final uri = Uri.parse(
          'intent://#Intent;package=${app.androidPackage};end',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return LaunchResult(
            success: true,
            method: 'android_intent',
            message: 'Opened ${app.name} on Android',
          );
        }
      } catch (e) {
        safePrint('[ExternalAppService] Android intent failed: $e');
      }
    }

    if (Platform.isIOS && app.iosScheme != null) {
      try {
        final uri = Uri.parse(app.iosScheme!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return LaunchResult(
            success: true,
            method: 'ios_scheme',
            message: 'Opened ${app.name} on iOS',
          );
        }
      } catch (e) {
        safePrint('[ExternalAppService] iOS scheme failed: $e');
      }
    }

    // Fallback to web URL
    try {
      final webUrl = _buildWebUrl(app, query);
      final uri = Uri.parse(webUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return LaunchResult(
        success: true,
        method: 'web_fallback',
        message: 'Opened ${app.name} in browser',
      );
    } catch (e) {
      safePrint('[ExternalAppService] Web fallback failed: $e');
      return LaunchResult(
        success: false,
        method: 'none',
        message: 'Could not open ${app.name}. Please install the app.',
      );
    }
  }

  String _buildWebUrl(ExternalApp app, String? query) {
    if (query != null && query.isNotEmpty) {
      final encoded = Uri.encodeComponent(query);
      // Some apps support search via web URL
      switch (app.id) {
        case 'zomato':
          return '${app.fallbackUrl}/search?q=$encoded';
        case 'amazon':
          return '${app.fallbackUrl}/s?k=$encoded';
        case 'flipkart':
          return '${app.fallbackUrl}/search?q=$encoded';
        case 'bookmyshow':
          return '${app.fallbackUrl}/explore/home';
        default:
          return app.fallbackUrl;
      }
    }
    return app.fallbackUrl;
  }

  /// Launch a generic URL (for custom links)
  Future<bool> launchGenericUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      safePrint('[ExternalAppService] Failed to launch URL: $e');
      return false;
    }
  }
}

class LaunchResult {
  final bool success;
  final String method;
  final String message;

  LaunchResult({
    required this.success,
    required this.method,
    required this.message,
  });
}

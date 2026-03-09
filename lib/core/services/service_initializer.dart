import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/core/services/aws_memory_service.dart';
import 'package:nova_finance_os/core/services/audit_vault_service.dart';
import 'package:nova_finance_os/features/auth/services/auth_service.dart';

final serviceInitializerProvider = Provider((ref) => ServiceInitializer(ref));

/// Service Initializer - Connects Auth with Memory and Audit services
class ServiceInitializer {
  final Ref _ref;
  bool _initialized = false;

  ServiceInitializer(this._ref);

  /// Initialize services after successful authentication
  Future<void> initializeAfterAuth() async {
    if (_initialized) {
      print('[ServiceInitializer] Already initialized');
      return;
    }

    try {
      final authService = _ref.read(authServiceProvider);
      final cognitoSub = authService.cognitoSub;

      if (cognitoSub == null) {
        print('[ServiceInitializer] ERROR: No Cognito sub available');
        return;
      }

      print('[ServiceInitializer] Initializing services for user: $cognitoSub');

      // Initialize AWS Memory Service with Cognito sub as actorId
      final memoryService = _ref.read(awsMemoryServiceProvider);
      memoryService.initialize(cognitoSub);

      // Initialize Audit Vault Service with user ID
      final auditService = _ref.read(auditVaultServiceProvider);
      auditService.initialize(cognitoSub);

      _initialized = true;
      print('[ServiceInitializer] ✓ All services initialized');
    } catch (e) {
      print('[ServiceInitializer] ERROR: $e');
    }
  }

  /// Reset services on sign out
  void reset() {
    _initialized = false;
    print('[ServiceInitializer] Services reset');
  }

  bool get isInitialized => _initialized;
}

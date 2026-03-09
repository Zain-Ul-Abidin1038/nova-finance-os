import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nova_live_nova_finance_os/features/enterprise/api/domain/api_key.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

final apiServiceProvider = Provider((ref) => ApiService());

final apiKeysStreamProvider = StreamProvider<List<ApiKey>>((ref) {
  final service = ref.watch(apiServiceProvider);
  return service.watchApiKeys();
});

class ApiService {
  static const String _apiKeysBox = 'api_keys';
  final _uuid = const Uuid();
  final _random = Random();

  Future<void> initialize() async {
    await Hive.openBox<ApiKey>(_apiKeysBox);
    await _seedApiKeys();
  }

  Future<void> _seedApiKeys() async {
    final box = Hive.box<ApiKey>(_apiKeysBox);
    if (box.isEmpty) {
      final keys = [
        ApiKey(
          id: _uuid.v4(),
          name: 'Production API',
          key: _generateApiKey(),
          permissions: ['read', 'write', 'delete'],
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          expiresAt: DateTime.now().add(const Duration(days: 305)),
          lastUsed: DateTime.now().subtract(const Duration(hours: 2)),
          requestCount: 15847,
          isActive: true,
        ),
        ApiKey(
          id: _uuid.v4(),
          name: 'Development API',
          key: _generateApiKey(),
          permissions: ['read', 'write'],
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          expiresAt: DateTime.now().add(const Duration(days: 335)),
          lastUsed: DateTime.now().subtract(const Duration(days: 1)),
          requestCount: 3421,
          isActive: true,
        ),
      ];

      for (var key in keys) {
        await box.add(key);
      }
    }
  }

  String _generateApiKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return 'gha_${List.generate(32, (index) => chars[_random.nextInt(chars.length)]).join()}';
  }

  Stream<List<ApiKey>> watchApiKeys() {
    final box = Hive.box<ApiKey>(_apiKeysBox);
    return Stream.value(box.values.toList())
        .asyncExpand((initial) => box.watch().map((_) => box.values.toList()).startWith(initial));
  }

  Future<void> createApiKey({
    required String name,
    required List<String> permissions,
    DateTime? expiresAt,
  }) async {
    final box = Hive.box<ApiKey>(_apiKeysBox);
    final apiKey = ApiKey(
      id: _uuid.v4(),
      name: name,
      key: _generateApiKey(),
      permissions: permissions,
      createdAt: DateTime.now(),
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 365)),
      requestCount: 0,
      isActive: true,
    );
    await box.add(apiKey);
  }

  Future<void> toggleApiKey(String keyId) async {
    final box = Hive.box<ApiKey>(_apiKeysBox);
    final apiKey = box.values.firstWhere((k) => k.id == keyId);
    final index = box.values.toList().indexOf(apiKey);

    final updated = ApiKey(
      id: apiKey.id,
      name: apiKey.name,
      key: apiKey.key,
      permissions: apiKey.permissions,
      createdAt: apiKey.createdAt,
      expiresAt: apiKey.expiresAt,
      lastUsed: apiKey.lastUsed,
      requestCount: apiKey.requestCount,
      isActive: !apiKey.isActive,
    );

    await box.putAt(index, updated);
  }

  Future<void> deleteApiKey(String keyId) async {
    final box = Hive.box<ApiKey>(_apiKeysBox);
    final apiKey = box.values.firstWhere((k) => k.id == keyId);
    final index = box.values.toList().indexOf(apiKey);
    await box.deleteAt(index);
  }

  Future<void> regenerateApiKey(String keyId) async {
    final box = Hive.box<ApiKey>(_apiKeysBox);
    final apiKey = box.values.firstWhere((k) => k.id == keyId);
    final index = box.values.toList().indexOf(apiKey);

    final updated = ApiKey(
      id: apiKey.id,
      name: apiKey.name,
      key: _generateApiKey(),
      permissions: apiKey.permissions,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 365)),
      requestCount: 0,
      isActive: true,
    );

    await box.putAt(index, updated);
  }
}

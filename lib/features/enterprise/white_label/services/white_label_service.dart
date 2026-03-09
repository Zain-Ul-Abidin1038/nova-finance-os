import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nova_live_nova_finance_os/features/enterprise/white_label/domain/tenant.dart';
import 'package:uuid/uuid.dart';

final whiteLabelServiceProvider = Provider((ref) => WhiteLabelService());

final tenantsStreamProvider = StreamProvider<List<Tenant>>((ref) {
  final service = ref.watch(whiteLabelServiceProvider);
  return service.watchTenants();
});

class WhiteLabelService {
  static const String _tenantsBox = 'tenants';
  final _uuid = const Uuid();

  Future<void> initialize() async {
    await Hive.openBox<Tenant>(_tenantsBox);
    await _seedTenants();
  }

  Future<void> _seedTenants() async {
    final box = Hive.box<Tenant>(_tenantsBox);
    if (box.isEmpty) {
      final tenants = [
        Tenant(
          id: _uuid.v4(),
          name: 'Acme Corporation',
          domain: 'acme.novaaccountant.com',
          createdAt: DateTime.now().subtract(const Duration(days: 120)),
          isActive: true,
          userCount: 245,
          branding: BrandConfig(
            appName: 'Acme Finance',
            primaryColor: '#FF5722',
            secondaryColor: '#FFC107',
            logoUrl: '',
          ),
          features: {
            'receipts': true,
            'chat': true,
            'analytics': true,
            'api': true,
            'whiteLabel': true,
          },
        ),
        Tenant(
          id: _uuid.v4(),
          name: 'TechStart Inc',
          domain: 'techstart.novaaccountant.com',
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          isActive: true,
          userCount: 87,
          branding: BrandConfig(
            appName: 'TechStart Money',
            primaryColor: '#2196F3',
            secondaryColor: '#00BCD4',
            logoUrl: '',
          ),
          features: {
            'receipts': true,
            'chat': true,
            'analytics': false,
            'api': false,
            'whiteLabel': true,
          },
        ),
      ];

      for (var tenant in tenants) {
        await box.add(tenant);
      }
    }
  }

  Stream<List<Tenant>> watchTenants() {
    final box = Hive.box<Tenant>(_tenantsBox);
    return Stream.value(box.values.toList())
        .asyncExpand((initial) => box.watch().map((_) => box.values.toList()).startWith(initial));
  }

  Future<void> createTenant({
    required String name,
    required String domain,
    required String appName,
    required String primaryColor,
    required String secondaryColor,
  }) async {
    final box = Hive.box<Tenant>(_tenantsBox);
    final tenant = Tenant(
      id: _uuid.v4(),
      name: name,
      domain: domain,
      createdAt: DateTime.now(),
      isActive: true,
      userCount: 0,
      branding: BrandConfig(
        appName: appName,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        logoUrl: '',
      ),
      features: {
        'receipts': true,
        'chat': true,
        'analytics': true,
        'api': false,
        'whiteLabel': true,
      },
    );
    await box.add(tenant);
  }

  Future<void> toggleTenant(String tenantId) async {
    final box = Hive.box<Tenant>(_tenantsBox);
    final tenant = box.values.firstWhere((t) => t.id == tenantId);
    final index = box.values.toList().indexOf(tenant);

    final updated = Tenant(
      id: tenant.id,
      name: tenant.name,
      domain: tenant.domain,
      createdAt: tenant.createdAt,
      isActive: !tenant.isActive,
      userCount: tenant.userCount,
      branding: tenant.branding,
      features: tenant.features,
    );

    await box.putAt(index, updated);
  }

  Future<void> updateBranding(String tenantId, BrandConfig branding) async {
    final box = Hive.box<Tenant>(_tenantsBox);
    final tenant = box.values.firstWhere((t) => t.id == tenantId);
    final index = box.values.toList().indexOf(tenant);

    final updated = Tenant(
      id: tenant.id,
      name: tenant.name,
      domain: tenant.domain,
      createdAt: tenant.createdAt,
      isActive: tenant.isActive,
      userCount: tenant.userCount,
      branding: branding,
      features: tenant.features,
    );

    await box.putAt(index, updated);
  }

  Future<void> toggleFeature(String tenantId, String feature) async {
    final box = Hive.box<Tenant>(_tenantsBox);
    final tenant = box.values.firstWhere((t) => t.id == tenantId);
    final index = box.values.toList().indexOf(tenant);

    final updatedFeatures = Map<String, bool>.from(tenant.features);
    updatedFeatures[feature] = !(updatedFeatures[feature] ?? false);

    final updated = Tenant(
      id: tenant.id,
      name: tenant.name,
      domain: tenant.domain,
      createdAt: tenant.createdAt,
      isActive: tenant.isActive,
      userCount: tenant.userCount,
      branding: tenant.branding,
      features: updatedFeatures,
    );

    await box.putAt(index, updated);
  }

  Future<void> deleteTenant(String tenantId) async {
    final box = Hive.box<Tenant>(_tenantsBox);
    final tenant = box.values.firstWhere((t) => t.id == tenantId);
    final index = box.values.toList().indexOf(tenant);
    await box.deleteAt(index);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_live_nova_finance_os/features/insurance/domain/policy.dart';

final insuranceServiceProvider = Provider((ref) => InsuranceService());

final policiesProvider = StreamProvider<List<InsurancePolicy>>((ref) {
  final service = ref.watch(insuranceServiceProvider);
  return service.watchPolicies();
});

class InsuranceService {
  static const String _boxName = 'insurance_policies';
  Box<InsurancePolicy>? _policiesBox;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    safePrint('[InsuranceService] Initializing...');
    _policiesBox = await Hive.openBox<InsurancePolicy>(_boxName);
    _initialized = true;
  }

  Stream<List<InsurancePolicy>> watchPolicies() async* {
    await initialize();
    yield* _policiesBox!.watch().map((_) => _policiesBox!.values.toList());
  }

  Future<List<InsurancePolicy>> getPolicies() async {
    await initialize();
    return _policiesBox!.values.toList();
  }

  Future<void> addPolicy(InsurancePolicy policy) async {
    await initialize();
    await _policiesBox!.put(policy.id, policy);
  }

  Future<void> updatePolicy(InsurancePolicy policy) async {
    await initialize();
    await _policiesBox!.put(policy.id, policy);
  }

  Future<void> deletePolicy(String id) async {
    await initialize();
    await _policiesBox!.delete(id);
  }

  double getTotalAnnualPremium() {
    return _policiesBox?.values.fold(0.0, (sum, p) => sum + p.annualPremium) ?? 0.0;
  }

  double getTotalCoverage() {
    return _policiesBox?.values.fold(0.0, (sum, p) => sum + p.coverage) ?? 0.0;
  }

  List<InsurancePolicy> getExpiringPolicies() {
    return _policiesBox?.values.where((p) => p.isExpiringSoon).toList() ?? [];
  }
}

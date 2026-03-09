import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_live_nova_finance_os/features/family/domain/family_account.dart';

final familyServiceProvider = Provider((ref) => FamilyService());

final familyAccountProvider = StreamProvider<FamilyAccount?>((ref) {
  final service = ref.watch(familyServiceProvider);
  return service.watchFamilyAccount();
});

final familyMembersProvider = StreamProvider<List<FamilyMember>>((ref) {
  final service = ref.watch(familyServiceProvider);
  return service.watchFamilyMembers();
});

class FamilyService {
  static const String _accountBoxName = 'family_account';
  static const String _membersBoxName = 'family_members';
  Box<FamilyAccount>? _accountBox;
  Box<FamilyMember>? _membersBox;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    safePrint('[FamilyService] Initializing...');
    _accountBox = await Hive.openBox<FamilyAccount>(_accountBoxName);
    _membersBox = await Hive.openBox<FamilyMember>(_membersBoxName);
    _initialized = true;
  }

  Stream<FamilyAccount?> watchFamilyAccount() async* {
    await initialize();
    yield* _accountBox!.watch().map((_) => _accountBox!.values.isNotEmpty ? _accountBox!.values.first : null);
  }

  Stream<List<FamilyMember>> watchFamilyMembers() async* {
    await initialize();
    yield* _membersBox!.watch().map((_) => _membersBox!.values.toList());
  }

  Future<FamilyAccount?> getFamilyAccount() async {
    await initialize();
    return _accountBox!.values.isNotEmpty ? _accountBox!.values.first : null;
  }

  Future<void> createFamilyAccount(FamilyAccount account) async {
    await initialize();
    await _accountBox!.clear();
    await _accountBox!.put(account.id, account);
  }

  Future<void> addMember(FamilyMember member) async {
    await initialize();
    await _membersBox!.put(member.id, member);
  }

  Future<void> updateMember(FamilyMember member) async {
    await initialize();
    await _membersBox!.put(member.id, member);
  }

  Future<void> removeMember(String id) async {
    await initialize();
    await _membersBox!.delete(id);
  }

  double getTotalAllowances() {
    return _membersBox?.values.fold(0.0, (sum, m) => sum + (m.allowance ?? 0)) ?? 0.0;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_live_nova_finance_os/features/shared_goals/domain/shared_goal.dart';

final sharedGoalServiceProvider = Provider((ref) => SharedGoalService());

final sharedGoalsProvider = StreamProvider<List<SharedGoal>>((ref) {
  final service = ref.watch(sharedGoalServiceProvider);
  return service.watchSharedGoals();
});

class SharedGoalService {
  static const String _boxName = 'shared_goals';
  Box<SharedGoal>? _goalsBox;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    safePrint('[SharedGoalService] Initializing...');
    _goalsBox = await Hive.openBox<SharedGoal>(_boxName);
    _initialized = true;
  }

  Stream<List<SharedGoal>> watchSharedGoals() async* {
    await initialize();
    yield* _goalsBox!.watch().map((_) => _goalsBox!.values.toList());
  }

  Future<List<SharedGoal>> getSharedGoals() async {
    await initialize();
    return _goalsBox!.values.toList();
  }

  Future<void> addGoal(SharedGoal goal) async {
    await initialize();
    await _goalsBox!.put(goal.id, goal);
  }

  Future<void> updateGoal(SharedGoal goal) async {
    await initialize();
    await _goalsBox!.put(goal.id, goal);
  }

  Future<void> deleteGoal(String id) async {
    await initialize();
    await _goalsBox!.delete(id);
  }

  Future<void> addContribution(String goalId, double amount) async {
    await initialize();
    final goal = _goalsBox!.get(goalId);
    if (goal != null) {
      final updated = goal.copyWith(currentAmount: goal.currentAmount + amount);
      await updateGoal(updated);
    }
  }

  List<SharedGoal> getActiveGoals() {
    return _goalsBox?.values.where((g) => !g.isCompleted).toList() ?? [];
  }

  List<SharedGoal> getCompletedGoals() {
    return _goalsBox?.values.where((g) => g.isCompleted).toList() ?? [];
  }
}

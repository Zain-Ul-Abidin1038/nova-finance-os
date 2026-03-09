import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_live_nova_finance_os/features/group_expenses/domain/group_expense.dart';

final groupExpenseServiceProvider = Provider((ref) => GroupExpenseService());

final groupExpensesProvider = StreamProvider<List<GroupExpense>>((ref) {
  final service = ref.watch(groupExpenseServiceProvider);
  return service.watchGroupExpenses();
});

class GroupExpenseService {
  static const String _boxName = 'group_expenses';
  Box<GroupExpense>? _expensesBox;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    safePrint('[GroupExpenseService] Initializing...');
    _expensesBox = await Hive.openBox<GroupExpense>(_boxName);
    _initialized = true;
  }

  Stream<List<GroupExpense>> watchGroupExpenses() async* {
    await initialize();
    yield* _expensesBox!.watch().map((_) => _expensesBox!.values.toList());
  }

  Future<List<GroupExpense>> getGroupExpenses() async {
    await initialize();
    return _expensesBox!.values.toList();
  }

  Future<void> addExpense(GroupExpense expense) async {
    await initialize();
    await _expensesBox!.put(expense.id, expense);
  }

  Future<void> updateExpense(GroupExpense expense) async {
    await initialize();
    await _expensesBox!.put(expense.id, expense);
  }

  Future<void> deleteExpense(String id) async {
    await initialize();
    await _expensesBox!.delete(id);
  }

  Future<void> markParticipantPaid(String expenseId, String userId) async {
    await initialize();
    final expense = _expensesBox!.get(expenseId);
    if (expense != null) {
      final updatedParticipants = expense.participants.map((p) {
        if (p.userId == userId) {
          return ExpenseParticipant(
            userId: p.userId,
            name: p.name,
            shareAmount: p.shareAmount,
            paid: true,
          );
        }
        return p;
      }).toList();
      
      final updated = expense.copyWith(participants: updatedParticipants);
      await updateExpense(updated);
    }
  }

  List<GroupExpense> getUnsettledExpenses() {
    return _expensesBox?.values.where((e) => !e.isSettled).toList() ?? [];
  }
}

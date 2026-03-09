import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_live_nova_finance_os/features/enterprise/business/domain/business_expense.dart';

final businessExpenseServiceProvider = Provider((ref) => BusinessExpenseService());

final businessExpensesProvider = StreamProvider<List<BusinessExpense>>((ref) {
  final service = ref.watch(businessExpenseServiceProvider);
  return service.watchBusinessExpenses();
});

class BusinessExpenseService {
  static const String _boxName = 'business_expenses';
  Box<BusinessExpense>? _expensesBox;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    safePrint('[BusinessExpenseService] Initializing...');
    _expensesBox = await Hive.openBox<BusinessExpense>(_boxName);
    _initialized = true;
  }

  Stream<List<BusinessExpense>> watchBusinessExpenses() async* {
    await initialize();
    yield* _expensesBox!.watch().map((_) => _expensesBox!.values.toList());
  }

  Future<List<BusinessExpense>> getBusinessExpenses() async {
    await initialize();
    return _expensesBox!.values.toList();
  }

  Future<void> addExpense(BusinessExpense expense) async {
    await initialize();
    await _expensesBox!.put(expense.id, expense);
  }

  Future<void> updateExpense(BusinessExpense expense) async {
    await initialize();
    await _expensesBox!.put(expense.id, expense);
  }

  Future<void> approveExpense(String id) async {
    await initialize();
    final expense = _expensesBox!.get(id);
    if (expense != null) {
      final updated = expense.copyWith(status: ApprovalStatus.approved);
      await updateExpense(updated);
    }
  }

  Future<void> rejectExpense(String id) async {
    await initialize();
    final expense = _expensesBox!.get(id);
    if (expense != null) {
      final updated = expense.copyWith(status: ApprovalStatus.rejected);
      await updateExpense(updated);
    }
  }

  List<BusinessExpense> getPendingExpenses() {
    return _expensesBox?.values.where((e) => e.isPending).toList() ?? [];
  }

  double getTotalByDepartment(String department) {
    return _expensesBox?.values
        .where((e) => e.department == department && e.isApproved)
        .fold(0.0, (sum, e) => sum + e.amount) ?? 0.0;
  }

  double getTotalByProject(String project) {
    return _expensesBox?.values
        .where((e) => e.project == project && e.isApproved)
        .fold(0.0, (sum, e) => sum + e.amount) ?? 0.0;
  }
}

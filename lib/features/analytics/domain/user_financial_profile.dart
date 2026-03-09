import 'package:nova_finance_os/features/analytics/domain/financial_snapshot.dart';
import 'package:nova_finance_os/features/receipts/domain/receipt.dart';
import 'package:nova_finance_os/features/analytics/services/cashflow_predictor.dart';

/// User Financial Profile
/// Complete financial data for AI analysis
class UserFinancialProfile {
  final FinancialSnapshot snapshot;
  final List<Transaction> transactions;
  final List<Receipt> receipts;
  final List<double> recentExpenses;
  final List<double> netWorthHistory;
  final double expenseStdDev;

  UserFinancialProfile({
    required this.snapshot,
    required this.transactions,
    required this.receipts,
    required this.recentExpenses,
    required this.netWorthHistory,
    required this.expenseStdDev,
  });

  factory UserFinancialProfile.empty() {
    return UserFinancialProfile(
      snapshot: FinancialSnapshot(
        balance: 0,
        monthlyIncome: 0,
        monthlyExpenses: 0,
        topCategories: {},
        savingsRate: 0,
        burnRate: 0,
        daysOfRunway: 0,
        recentTransactions: [],
      ),
      transactions: [],
      receipts: [],
      recentExpenses: [],
      netWorthHistory: [],
      expenseStdDev: 0,
    );
  }
}

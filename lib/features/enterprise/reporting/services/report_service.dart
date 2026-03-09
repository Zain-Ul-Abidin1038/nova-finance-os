import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nova_live_nova_finance_os/features/enterprise/reporting/domain/report.dart';
import 'package:uuid/uuid.dart';

final reportServiceProvider = Provider((ref) => ReportService());

final reportsStreamProvider = StreamProvider<List<Report>>((ref) {
  final service = ref.watch(reportServiceProvider);
  return service.watchReports();
});

class ReportService {
  static const String _reportsBox = 'reports';
  final _uuid = const Uuid();

  Future<void> initialize() async {
    await Hive.openBox<Report>(_reportsBox);
    await _seedReports();
  }

  Future<void> _seedReports() async {
    final box = Hive.box<Report>(_reportsBox);
    if (box.isEmpty) {
      final now = DateTime.now();
      final reports = [
        Report(
          id: _uuid.v4(),
          name: 'Monthly Expense Report',
          type: ReportType.expense,
          startDate: DateTime(now.year, now.month, 1),
          endDate: DateTime(now.year, now.month + 1, 0),
          createdAt: now.subtract(const Duration(days: 5)),
          data: {
            'totalExpenses': 12450.50,
            'categories': {
              'Dining': 2340.00,
              'Transportation': 1890.00,
              'Utilities': 1450.00,
              'Entertainment': 980.00,
              'Other': 5790.50,
            },
            'trend': 'up',
            'percentageChange': 8.5,
          },
        ),
        Report(
          id: _uuid.v4(),
          name: 'Q1 2026 P&L Statement',
          type: ReportType.profitLoss,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 3, 31),
          createdAt: now.subtract(const Duration(days: 15)),
          data: {
            'revenue': 145000.00,
            'expenses': 98500.00,
            'netIncome': 46500.00,
            'profitMargin': 32.1,
            'operatingExpenses': 65000.00,
            'costOfGoodsSold': 33500.00,
          },
        ),
        Report(
          id: _uuid.v4(),
          name: 'Cash Flow Analysis',
          type: ReportType.cashFlow,
          startDate: DateTime(now.year, now.month - 1, 1),
          endDate: DateTime(now.year, now.month, 0),
          createdAt: now.subtract(const Duration(days: 3)),
          data: {
            'openingBalance': 45000.00,
            'closingBalance': 52300.00,
            'netCashFlow': 7300.00,
            'operatingActivities': 12500.00,
            'investingActivities': -3200.00,
            'financingActivities': -2000.00,
          },
        ),
      ];

      for (var report in reports) {
        await box.add(report);
      }
    }
  }

  Stream<List<Report>> watchReports() {
    final box = Hive.box<Report>(_reportsBox);
    return Stream.value(box.values.toList())
        .asyncExpand((initial) => box.watch().map((_) => box.values.toList()).startWith(initial));
  }

  Future<void> generateReport({
    required String name,
    required ReportType type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final box = Hive.box<Report>(_reportsBox);
    
    // Simulate report generation with mock data
    final data = _generateMockData(type);
    
    final report = Report(
      id: _uuid.v4(),
      name: name,
      type: type,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
      data: data,
    );
    
    await box.add(report);
  }

  Map<String, dynamic> _generateMockData(ReportType type) {
    switch (type) {
      case ReportType.expense:
        return {
          'totalExpenses': 10500.00 + (DateTime.now().millisecond % 5000),
          'categories': {
            'Dining': 2000.00,
            'Transportation': 1500.00,
            'Utilities': 1200.00,
          },
        };
      case ReportType.income:
        return {
          'totalIncome': 50000.00 + (DateTime.now().millisecond % 10000),
          'sources': {
            'Salary': 45000.00,
            'Freelance': 5000.00,
          },
        };
      case ReportType.profitLoss:
        return {
          'revenue': 120000.00,
          'expenses': 80000.00,
          'netIncome': 40000.00,
          'profitMargin': 33.3,
        };
      case ReportType.cashFlow:
        return {
          'openingBalance': 40000.00,
          'closingBalance': 48000.00,
          'netCashFlow': 8000.00,
        };
      case ReportType.tax:
        return {
          'taxableIncome': 95000.00,
          'deductions': 15000.00,
          'estimatedTax': 18000.00,
        };
      case ReportType.custom:
        return {'message': 'Custom report data'};
    }
  }

  Future<void> deleteReport(String reportId) async {
    final box = Hive.box<Report>(_reportsBox);
    final report = box.values.firstWhere((r) => r.id == reportId);
    final index = box.values.toList().indexOf(report);
    await box.deleteAt(index);
  }

  List<Report> filterByType(ReportType? type) {
    final box = Hive.box<Report>(_reportsBox);
    if (type == null) return box.values.toList();
    return box.values.where((r) => r.type == type).toList();
  }
}

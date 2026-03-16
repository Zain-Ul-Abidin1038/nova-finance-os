import 'package:hive_flutter/hive_flutter.dart';

/// Tracks purchases made through external apps launched by NovaNavigator
@HiveType(typeId: 20)
class PurchaseRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String appId; // e.g. 'zomato', 'uber'

  @HiveField(2)
  final String appName;

  @HiveField(3)
  final String category; // food, transport, tickets, shopping, bills

  @HiveField(4)
  final String taskDescription; // what the user asked

  @HiveField(5)
  final double? estimatedAmount;

  @HiveField(6)
  final double? actualAmount; // user can update after purchase

  @HiveField(7)
  final DateTime launchedAt;

  @HiveField(8)
  final DateTime? completedAt;

  @HiveField(9)
  final String status; // launched, pending_amount, recorded, cancelled

  @HiveField(10)
  final bool expenseRecorded; // whether auto-recorded to expense ledger

  @HiveField(11)
  final String? notes;

  PurchaseRecord({
    required this.id,
    required this.appId,
    required this.appName,
    required this.category,
    required this.taskDescription,
    this.estimatedAmount,
    this.actualAmount,
    required this.launchedAt,
    this.completedAt,
    this.status = 'launched',
    this.expenseRecorded = false,
    this.notes,
  });

  factory PurchaseRecord.create({
    required String appId,
    required String appName,
    required String category,
    required String taskDescription,
    double? estimatedAmount,
  }) {
    return PurchaseRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      appId: appId,
      appName: appName,
      category: category,
      taskDescription: taskDescription,
      estimatedAmount: estimatedAmount,
      launchedAt: DateTime.now(),
      status: estimatedAmount != null ? 'recorded' : 'pending_amount',
    );
  }

  PurchaseRecord copyWith({
    double? actualAmount,
    DateTime? completedAt,
    String? status,
    bool? expenseRecorded,
    String? notes,
  }) {
    return PurchaseRecord(
      id: id,
      appId: appId,
      appName: appName,
      category: category,
      taskDescription: taskDescription,
      estimatedAmount: estimatedAmount,
      actualAmount: actualAmount ?? this.actualAmount,
      launchedAt: launchedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      expenseRecorded: expenseRecorded ?? this.expenseRecorded,
      notes: notes ?? this.notes,
    );
  }
}

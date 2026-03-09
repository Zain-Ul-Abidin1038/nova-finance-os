import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/features/analytics/domain/financial_snapshot.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

final financialHealthEngineProvider = Provider((ref) => FinancialHealthEngine());

/// Financial Health Engine
/// Calculates comprehensive health score (0-100)
class FinancialHealthEngine {
  /// Calculate overall financial health score
  int calculate(FinancialSnapshot snapshot) {
    safePrint('[HealthEngine] Calculating health score...');

    double score = 0;

    // 1. Savings Rate (0-25 points)
    score += _scoreSavingsRate(snapshot.savingsRate);

    // 2. Runway (0-20 points)
    score += _scoreRunway(snapshot.daysOfRunway);

    // 3. Cashflow (0-20 points)
    score += _scoreCashflow(snapshot.monthlyIncome, snapshot.monthlyExpenses);

    // 4. Balance (0-15 points)
    score += _scoreBalance(snapshot.balance, snapshot.monthlyExpenses);

    // 5. Burn Rate (0-10 points)
    score += _scoreBurnRate(snapshot.burnRate, snapshot.monthlyIncome);

    // 6. Income Stability (0-10 points)
    score += 10; // Placeholder - would analyze income variance

    final finalScore = score.round().clamp(0, 100);
    
    safePrint('[HealthEngine] Health score: $finalScore/100');
    
    return finalScore;
  }

  double _scoreSavingsRate(double rate) {
    if (rate >= 0.3) return 25; // Excellent
    if (rate >= 0.2) return 20; // Good
    if (rate >= 0.1) return 15; // Fair
    if (rate >= 0.05) return 10; // Poor
    return 5; // Critical
  }

  double _scoreRunway(int days) {
    if (days >= 180) return 20; // 6+ months
    if (days >= 90) return 15; // 3+ months
    if (days >= 30) return 10; // 1+ month
    if (days >= 14) return 5; // 2+ weeks
    return 0; // Critical
  }

  double _scoreCashflow(double income, double expenses) {
    if (income <= 0) return 0;
    
    final ratio = expenses / income;
    if (ratio <= 0.5) return 20; // Spending 50% or less
    if (ratio <= 0.7) return 15; // Spending 70% or less
    if (ratio <= 0.9) return 10; // Spending 90% or less
    if (ratio < 1.0) return 5; // Barely positive
    return 0; // Negative cashflow
  }

  double _scoreBalance(double balance, double monthlyExpenses) {
    if (monthlyExpenses <= 0) return 15;
    
    final months = balance / monthlyExpenses;
    if (months >= 6) return 15; // 6+ months
    if (months >= 3) return 12; // 3+ months
    if (months >= 1) return 8; // 1+ month
    if (months >= 0.5) return 4; // 2+ weeks
    return 0; // Less than 2 weeks
  }

  double _scoreBurnRate(double burnRate, double monthlyIncome) {
    if (monthlyIncome <= 0) return 0;
    
    final dailyIncome = monthlyIncome / 30;
    if (burnRate <= dailyIncome * 0.5) return 10; // Burning 50% or less
    if (burnRate <= dailyIncome * 0.7) return 7; // Burning 70% or less
    if (burnRate <= dailyIncome) return 4; // Burning 100% or less
    return 0; // Burning more than earning
  }

  /// Get health status label
  String getHealthStatus(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Poor';
    return 'Critical';
  }

  /// Get health color
  String getHealthColor(int score) {
    if (score >= 80) return '#00FF00'; // Green
    if (score >= 60) return '#00F2FF'; // Teal
    if (score >= 40) return '#FFD700'; // Gold
    if (score >= 20) return '#FFA500'; // Orange
    return '#FF0000'; // Red
  }
}

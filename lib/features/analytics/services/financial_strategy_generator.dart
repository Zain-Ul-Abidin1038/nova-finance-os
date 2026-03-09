import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_finance_os/core/services/nova_service_v3.dart';
import '../domain/user_financial_profile.dart';
import '../domain/financial_strategy.dart';

final financialStrategyGeneratorProvider = Provider((ref) => FinancialStrategyGenerator(
      novaService: ref.read(novaServiceV3Provider),
    ));

/// Financial Strategy Generator
/// Produces structured multi-dimensional financial strategies using AI
class FinancialStrategyGenerator {
  final NovaServiceV3 novaService;

  FinancialStrategyGenerator({required this.novaService});

  /// Generate comprehensive financial strategy
  Future<FinancialStrategy> generate(UserFinancialProfile profile) async {
    safePrint('[StrategyGenerator] Generating strategy...');

    final prompt = _buildStrategyPrompt(profile);

    try {
      final response = await novaService.sendMessage(
        prompt: prompt,
        systemInstruction: _getSystemInstruction(),
        deepReasoning: true, // Use Pro + high thinking for complex strategy
      );

      final strategyText = response['text'] ?? '';
      safePrint('[StrategyGenerator] Generated ${strategyText.length} chars');

      return FinancialStrategy.fromText(strategyText);
    } catch (e) {
      safePrint('[StrategyGenerator] Error: $e');
      return _fallbackStrategy();
    }
  }

  String _buildStrategyPrompt(UserFinancialProfile profile) {
    final runwayMonths = profile.snapshot.daysOfRunway / 30.0;
    final savingsRatePercent = (profile.snapshot.savingsRate * 100);
    
    return '''
Create a comprehensive financial strategy based on this data:

<financial_profile>
Balance: ₹${profile.snapshot.balance.toStringAsFixed(0)}
Monthly Income: ₹${profile.snapshot.monthlyIncome.toStringAsFixed(0)}
Monthly Expenses: ₹${profile.snapshot.monthlyExpenses.toStringAsFixed(0)}
Savings Rate: ${savingsRatePercent.toStringAsFixed(1)}%
Expense Volatility: ${profile.expenseStdDev.toStringAsFixed(0)}
Runway: ${runwayMonths.toStringAsFixed(1)} months
</financial_profile>

<spending_breakdown>
${profile.snapshot.topCategories.entries.map((e) => '${e.key}: ₹${e.value.toStringAsFixed(0)}').join('\n')}
</spending_breakdown>

Generate a structured strategy with these dimensions:

1. SPENDING CONTROL
   - Identify wasteful spending
   - Suggest category limits
   - Recommend behavior changes

2. SAVINGS PLAN
   - Target savings rate
   - Emergency fund goal
   - Investment allocation

3. TAX STRATEGY
   - Deduction optimization
   - Tax-efficient categories
   - Quarterly planning

4. RISK MITIGATION
   - Liquidity improvements
   - Volatility reduction
   - Debt management

5. LIQUIDITY PLAN
   - Cash buffer targets
   - Income diversification
   - Expense smoothing

Format each section with clear, actionable steps.
''';
  }

  String _getSystemInstruction() {
    return '''You are a professional financial strategist for Finance OS.

Your role:
- Analyze financial data comprehensively
- Generate specific, actionable strategies
- Consider Indian financial context
- Prioritize risk management and liquidity
- Be realistic and achievable

Strategy guidelines:
- Each dimension should have 2-4 specific actions
- Actions should be measurable
- Consider user's current situation
- Balance short-term and long-term goals
- Focus on sustainable improvements

Output format:
SPENDING CONTROL:
- [specific action 1]
- [specific action 2]

SAVINGS PLAN:
- [specific action 1]
- [specific action 2]

TAX STRATEGY:
- [specific action 1]
- [specific action 2]

RISK MITIGATION:
- [specific action 1]
- [specific action 2]

LIQUIDITY PLAN:
- [specific action 1]
- [specific action 2]
''';
  }

  FinancialStrategy _fallbackStrategy() {
    return FinancialStrategy(
      spendingControl: SpendingControl(actions: [
        'Review and categorize all expenses',
        'Identify top 3 spending categories',
      ]),
      savingsPlan: SavingsPlan(actions: [
        'Set up automatic savings transfer',
        'Build 3-month emergency fund',
      ]),
      taxStrategy: TaxStrategy(actions: [
        'Track all deductible expenses',
        'Review tax optimization opportunities',
      ]),
      riskMitigation: RiskMitigation(actions: [
        'Maintain minimum cash buffer',
        'Diversify income sources',
      ]),
      liquidityPlan: LiquidityPlan(actions: [
        'Keep 1-month expenses liquid',
        'Monitor cashflow weekly',
      ]),
      generatedAt: DateTime.now(),
    );
  }
}

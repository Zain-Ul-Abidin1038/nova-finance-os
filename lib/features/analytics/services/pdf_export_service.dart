import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nova_finance_os/features/receipts/services/hive_transaction_provider.dart';
import 'package:intl/intl.dart';

final pdfExportServiceProvider = Provider((ref) => PdfExportService(ref));

class PdfExportService {
  final Ref _ref;

  PdfExportService(this._ref);

  Future<String> generateAndSaveReport() async {
    // Request storage permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      // On Android 13+, we might not need this permission
      // Try to proceed anyway
    }

    final transactionState = _ref.read(hiveTransactionProvider);
    
    // Create PDF document
    final pdf = pw.Document();

    // Calculate runway
    final runway = _ref.read(hiveTransactionProvider.notifier).calculateRunway();
    final categoryBreakdown = _ref.read(hiveTransactionProvider.notifier).getCategoryBreakdown();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Finance OS',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateFormat('MMM dd, yyyy').format(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Financial Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Financial Summary',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  _buildSummaryRow('Total Spent', '\$${transactionState.totalBalance.toStringAsFixed(2)}'),
                  _buildSummaryRow('Total Deductible', '\$${transactionState.totalDeductible.toStringAsFixed(2)}'),
                  _buildSummaryRow('Total Receipts', '${transactionState.receipts.length}'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Runway Analysis
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Runway Analysis',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  _buildSummaryRow('Current Balance', '\$${transactionState.totalDeductible.toStringAsFixed(2)}'),
                  _buildSummaryRow('Predicted Runway', '${runway.toStringAsFixed(1)} months'),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Based on current deductible balance and estimated monthly expenses.',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Category Breakdown
            pw.Text(
              'Category Breakdown',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            if (categoryBreakdown.isEmpty)
              pw.Text('No expenses recorded yet.')
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Category', isHeader: true),
                      _buildTableCell('Amount', isHeader: true),
                      _buildTableCell('Percentage', isHeader: true),
                    ],
                  ),
                  // Data rows
                  ...categoryBreakdown.entries.map((entry) {
                    final percentage = (entry.value / transactionState.totalBalance * 100);
                    return pw.TableRow(
                      children: [
                        _buildTableCell(entry.key),
                        _buildTableCell('\$${entry.value.toStringAsFixed(2)}'),
                        _buildTableCell('${percentage.toStringAsFixed(1)}%'),
                      ],
                    );
                  }),
                ],
              ),
            pw.SizedBox(height: 20),

            // Receipt Details
            pw.Text(
              'Receipt Details',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            if (transactionState.receipts.isEmpty)
              pw.Text('No receipts recorded yet.')
            else
              ...transactionState.receipts.asMap().entries.map((entry) {
                final index = entry.key;
                final receipt = entry.value;
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${index + 1}. ${receipt.category}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Total: \$${receipt.total.toStringAsFixed(2)}'),
                      pw.Text('Tax: \$${receipt.tax.toStringAsFixed(2)}'),
                      pw.Text('Deductible (50%): \$${(receipt.total * 0.5).toStringAsFixed(2)}'),
                    ],
                  ),
                );
              }),

            // Footer
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generated by Finance OS - AI-Powered Expense Tracking',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              'This report uses the 50% deduction rule for business meals (alcohol excluded).',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center,
            ),
          ];
        },
      ),
    );

    // Save PDF to device
    final output = await _getOutputFile();
    final file = File(output);
    await file.writeAsBytes(await pdf.save());

    return output;
  }

  pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<String> _getOutputFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${directory.path}/nova_finance_os_report_$timestamp.pdf';
  }
}

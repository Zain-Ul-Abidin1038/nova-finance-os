import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_live_nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_live_nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_live_nova_finance_os/features/real_estate/services/property_service.dart';
import 'package:nova_live_nova_finance_os/features/real_estate/domain/property.dart';
import 'package:uuid/uuid.dart';

class PropertyPortfolioScreen extends ConsumerWidget {
  const PropertyPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Real Estate Portfolio', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.neonTeal),
                  onPressed: () => _showAddPropertyDialog(context, ref),
                ),
              ],
            ),
            propertiesAsync.when(
              data: (properties) {
                if (properties.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.home, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          const Text('No properties yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          const SizedBox(height: 24),
                          NovaActionButton(
                            label: 'Add Property',
                            icon: Icons.add,
                            onPressed: () => _showAddPropertyDialog(context, ref),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final service = ref.read(propertyServiceProvider);
                final totalValue = service.getTotalValue();
                final totalEquity = service.getTotalEquity();
                final totalRental = service.getTotalRentalIncome();

                return SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSummaryCard(totalValue, totalEquity, totalRental),
                      const SizedBox(height: 20),
                      _buildPropertiesList(properties),
                    ]),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.neonTeal))),
              error: (error, stack) => SliverFillRemaining(child: Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.error)))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double totalValue, double totalEquity, double totalRental) {
    return GlassCard(
      borderColor: AppColors.success.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Portfolio Value', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text('\$${totalValue.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Equity', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('\$${totalEquity.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Annual Rental Income', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('\$${totalRental.toStringAsFixed(0)}/year', style: const TextStyle(color: AppColors.neonTeal, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesList(List<Property> properties) {
    return Column(
      children: properties.map((property) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.neonTeal.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.home, color: AppColors.neonTeal, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(property.address, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text(_getPropertyTypeLabel(property.type), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Value', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text('\$${property.currentValue.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Equity', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text('\$${property.equity.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.success, fontSize: 14)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Appreciation', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text('${property.appreciationPercentage.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.neonTeal, fontSize: 14)),
                    ],
                  ),
                  if (property.rentalIncome != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Rental', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        Text('\$${property.rentalIncome!.toStringAsFixed(0)}/mo', style: const TextStyle(color: AppColors.softPurple, fontSize: 14)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  String _getPropertyTypeLabel(PropertyType type) {
    switch (type) {
      case PropertyType.residential:
        return 'Residential';
      case PropertyType.commercial:
        return 'Commercial';
      case PropertyType.land:
        return 'Land';
      case PropertyType.rental:
        return 'Rental Property';
    }
  }

  void _showAddPropertyDialog(BuildContext context, WidgetRef ref) {
    final addressController = TextEditingController();
    final purchasePriceController = TextEditingController();
    final currentValueController = TextEditingController();
    PropertyType selectedType = PropertyType.residential;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Add Property', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: addressController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PropertyType>(
                  value: selectedType,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                  ),
                  items: PropertyType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(_getPropertyTypeLabel(type)),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                TextField(
                  controller: purchasePriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Purchase Price',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                  ),
                ),
                TextField(
                  controller: currentValueController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Current Value',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                final address = addressController.text;
                final purchasePrice = double.tryParse(purchasePriceController.text) ?? 0;
                final currentValue = double.tryParse(currentValueController.text) ?? 0;

                if (address.isNotEmpty && purchasePrice > 0 && currentValue > 0) {
                  final service = ref.read(propertyServiceProvider);
                  final property = Property(
                    id: const Uuid().v4(),
                    userId: 'current_user',
                    address: address,
                    type: selectedType,
                    purchasePrice: purchasePrice,
                    currentValue: currentValue,
                    purchaseDate: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await service.addProperty(property);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add', style: TextStyle(color: AppColors.neonTeal)),
            ),
          ],
        ),
      ),
    );
  }
}

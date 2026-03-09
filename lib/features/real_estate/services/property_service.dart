import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_live_nova_finance_os/features/real_estate/domain/property.dart';

final propertyServiceProvider = Provider((ref) => PropertyService());

final propertiesProvider = StreamProvider<List<Property>>((ref) {
  final service = ref.watch(propertyServiceProvider);
  return service.watchProperties();
});

class PropertyService {
  static const String _boxName = 'properties';
  Box<Property>? _propertiesBox;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    safePrint('[PropertyService] Initializing...');
    _propertiesBox = await Hive.openBox<Property>(_boxName);
    _initialized = true;
  }

  Stream<List<Property>> watchProperties() async* {
    await initialize();
    yield* _propertiesBox!.watch().map((_) => _propertiesBox!.values.toList());
  }

  Future<List<Property>> getProperties() async {
    await initialize();
    return _propertiesBox!.values.toList();
  }

  Future<void> addProperty(Property property) async {
    await initialize();
    await _propertiesBox!.put(property.id, property);
  }

  Future<void> updateProperty(Property property) async {
    await initialize();
    await _propertiesBox!.put(property.id, property);
  }

  Future<void> deleteProperty(String id) async {
    await initialize();
    await _propertiesBox!.delete(id);
  }

  double getTotalEquity() {
    return _propertiesBox?.values.fold(0.0, (sum, p) => sum + p.equity) ?? 0.0;
  }

  double getTotalValue() {
    return _propertiesBox?.values.fold(0.0, (sum, p) => sum + p.currentValue) ?? 0.0;
  }

  double getTotalRentalIncome() {
    return _propertiesBox?.values.fold(0.0, (sum, p) => sum + p.annualRentalIncome) ?? 0.0;
  }
}

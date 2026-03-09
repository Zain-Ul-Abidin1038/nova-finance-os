import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_live_nova_finance_os/features/crypto/domain/crypto_asset.dart';

final cryptoServiceProvider = Provider((ref) => CryptoService());

final cryptoPortfolioProvider = StreamProvider<List<CryptoAsset>>((ref) {
  final service = ref.watch(cryptoServiceProvider);
  return service.watchCryptoAssets();
});

class CryptoService {
  static const String _boxName = 'crypto_assets';
  Box<CryptoAsset>? _cryptoBox;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    safePrint('[CryptoService] Initializing...');
    _cryptoBox = await Hive.openBox<CryptoAsset>(_boxName);
    _initialized = true;
  }

  Stream<List<CryptoAsset>> watchCryptoAssets() async* {
    await initialize();
    yield* _cryptoBox!.watch().map((_) => _cryptoBox!.values.toList());
  }

  Future<List<CryptoAsset>> getCryptoAssets() async {
    await initialize();
    return _cryptoBox!.values.toList();
  }

  Future<void> addCryptoAsset(CryptoAsset asset) async {
    await initialize();
    await _cryptoBox!.put(asset.id, asset);
  }

  Future<void> updateCryptoAsset(CryptoAsset asset) async {
    await initialize();
    await _cryptoBox!.put(asset.id, asset);
  }

  Future<void> deleteCryptoAsset(String id) async {
    await initialize();
    await _cryptoBox!.delete(id);
  }
}

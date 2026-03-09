import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nova_finance_os/app.dart';
import 'package:nova_finance_os/features/receipts/domain/receipt.dart';
import 'package:nova_finance_os/features/finance/domain/transaction_model.dart';
import 'package:nova_finance_os/amplifyconfiguration.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    safePrint('🚀 Initializing Finance OS with Amazon Nova (AWS Bedrock)');

    // Load environment variables for AWS credentials
    try {
      await dotenv.load(fileName: ".env");
      safePrint('✓ Environment variables loaded (AWS credentials)');
    } catch (e) {
      safePrint('⚠️ Could not load .env file: $e');
      safePrint('Make sure .env file exists with AWS credentials');
    }

    // Initialize Hive for local persistence (Speed Layer)
    try {
      await Hive.initFlutter();
      safePrint('✓ Hive initialized (Speed Layer)');
      
      // Register Hive adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ReceiptAdapter());
        safePrint('✓ Receipt adapter registered');
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FinancialTransactionAdapter());
        safePrint('✓ FinancialTransaction adapter registered');
      }
      
      // Open financial transactions box
      await Hive.openBox<FinancialTransaction>('financial_transactions');
      safePrint('✓ Financial transactions box opened');
    } catch (e) {
      safePrint('⚠️ Hive initialization error: $e');
    }

    // Initialize AWS Amplify (Safe Layer)
    try {
      await _configureAmplify();
      safePrint('✓ AWS Amplify configured (Safe Layer)');
    } catch (e) {
      safePrint('⚠️ Amplify initialization error: $e');
      safePrint('App will continue with local-only mode');
    }

    runApp(
      const ProviderScope(
        child: NovaAccountantApp(),
      ),
    );
  } catch (e, stackTrace) {
    safePrint('❌ Fatal error in main: $e');
    safePrint('Stack trace: $stackTrace');
    // Still try to run the app
    runApp(
      const ProviderScope(
        child: NovaAccountantApp(),
      ),
    );
  }
}

/// Configure AWS Amplify with Auth and Storage
Future<void> _configureAmplify() async {
  try {
    // Add plugins
    final authPlugin = AmplifyAuthCognito();
    final storagePlugin = AmplifyStorageS3();

    await Amplify.addPlugins([
      authPlugin,
      storagePlugin,
    ]);

    // Configure Amplify
    await Amplify.configure(amplifyconfig);
    
    safePrint('✓ Amplify plugins configured:');
    safePrint('  - Auth (Cognito)');
    safePrint('  - Storage (S3 Audit Vault)');
  } on AmplifyAlreadyConfiguredException {
    safePrint('⚠️ Amplify already configured');
  } catch (e) {
    safePrint('❌ Error configuring Amplify: $e');
    rethrow;
  }
}

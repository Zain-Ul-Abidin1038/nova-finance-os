# Finance OS - Testing Guide

Complete guide for testing Finance OS with real AWS Bedrock integration on Android and iOS devices.

---

## Prerequisites

- ✅ AWS Bedrock setup complete (see `AWS_BEDROCK_SETUP.md`)
- ✅ `.env` file configured with AWS credentials
- ✅ Flutter dependencies installed (`flutter pub get`)
- ✅ Android device/emulator or iOS device/simulator

---

## Test 1: AWS Bedrock Connection

### Test Nova Lite (Reasoning)
```dart
// Test in app or create test script
final novaLite = NovaLiteService(
  accessKeyId: dotenv.env['AWS_ACCESS_KEY_ID']!,
  secretAccessKey: dotenv.env['AWS_SECRET_ACCESS_KEY']!,
  region: dotenv.env['AWS_REGION']!,
);

final response = await novaLite.sendMessage(
  prompt: 'Analyze this spending: \$500 on groceries, \$200 on dining. Give brief advice.',
);

print(response['message']);
```

**Expected**: Financial advice in 2-3 sentences

---

## Test 2: Receipt Scanning (Vision)

### 2.1 Prepare Test Receipts
- Restaurant receipt
- Grocery store receipt
- Gas station receipt
- Office supplies receipt

### 2.2 Test on Device
1. Launch Finance OS app
2. Tap "Scan Receipt" or camera icon
3. Take photo of receipt
4. Wait for Nova Pro analysis (2-5 seconds)

### 2.3 Verify Extracted Data
Check that Nova Pro correctly extracts:
- ✅ Vendor name
- ✅ Date (YYYY-MM-DD format)
- ✅ Total amount
- ✅ Currency
- ✅ Line items
- ✅ Tax amount
- ✅ Category (dining, groceries, etc.)
- ✅ Tax deductibility percentage
- ✅ Confidence score

### 2.4 Test Different Receipt Types
| Receipt Type | Expected Category | Expected Tax Deduction |
|--------------|-------------------|------------------------|
| Restaurant | Dining | 50% (business meal) |
| Grocery | Groceries | 0% |
| Gas Station | Transportation | 0-100% (business use) |
| Office Supplies | Shopping | 100% (business expense) |
| Hotel | Travel | 100% (business travel) |

---

## Test 3: Cashflow Forecasting

### 3.1 Create Test Data
```dart
final transactions = [
  {'date': '2026-03-01', 'amount': -50.0, 'category': 'dining'},
  {'date': '2026-03-02', 'amount': -100.0, 'category': 'groceries'},
  {'date': '2026-03-03', 'amount': 2000.0, 'category': 'income'},
  {'date': '2026-03-05', 'amount': -1200.0, 'category': 'rent'},
  {'date': '2026-03-07', 'amount': -80.0, 'category': 'utilities'},
];

final forecast = await novaLite.forecastCashflow(
  transactions: transactions,
  daysAhead: 30,
);
```

### 3.2 Verify Forecast
Check that Nova Lite provides:
- ✅ Daily balance predictions
- ✅ Potential shortfall dates
- ✅ Spending pattern analysis
- ✅ Recommendations

---

## Test 4: Budget Analysis

### 4.1 Test Budget vs Spending
```dart
final budgetData = {
  'dining': 300.0,
  'groceries': 400.0,
  'transportation': 200.0,
  'entertainment': 150.0,
};

final spendingData = {
  'dining': 450.0,  // Over budget
  'groceries': 350.0,  // Under budget
  'transportation': 180.0,  // Under budget
  'entertainment': 200.0,  // Over budget
};

final analysis = await novaLite.analyzeBudget(
  budgetData: budgetData,
  spendingData: spendingData,
);
```

### 4.2 Verify Analysis
Check that Nova Lite identifies:
- ✅ Overspending categories (dining, entertainment)
- ✅ Underspending categories (groceries, transportation)
- ✅ Specific amounts over/under
- ✅ Optimization suggestions

---

## Test 5: Knowledge Search (Embeddings)

### 5.1 Test Tax Policy Search
```dart
final embeddingService = NovaEmbeddingService(
  accessKeyId: dotenv.env['AWS_ACCESS_KEY_ID']!,
  secretAccessKey: dotenv.env['AWS_SECRET_ACCESS_KEY']!,
  region: dotenv.env['AWS_REGION']!,
);

// Create knowledge base
final taxPolicies = [
  {
    'text': 'Business meals are 50% deductible',
    'category': 'meals',
  },
  {
    'text': 'Home office expenses are 100% deductible if exclusive use',
    'category': 'office',
  },
  {
    'text': 'Mileage for business travel is deductible at $0.67 per mile',
    'category': 'travel',
  },
];

// Generate embeddings for knowledge base
for (var policy in taxPolicies) {
  policy['embedding'] = await embeddingService.generateEmbedding(policy['text']);
}

// Search
final results = await embeddingService.searchTaxPolicies(
  query: 'Can I deduct restaurant expenses?',
  policies: taxPolicies,
);
```

### 5.2 Verify Search Results
- ✅ Top result should be about business meals
- ✅ Similarity score > 0.7
- ✅ Results ranked by relevance

---

## Test 6: End-to-End Receipt Flow

### Complete User Journey
1. **Scan Receipt**
   - Open app
   - Tap camera icon
   - Take photo of restaurant receipt
   - Wait for analysis

2. **Verify Extraction**
   - Check vendor name is correct
   - Check amount matches receipt
   - Check category is "dining"
   - Check tax deduction is 50%

3. **Save Receipt**
   - Tap "Save"
   - Receipt added to transactions

4. **View Dashboard**
   - Check spending chart updated
   - Check category breakdown includes new receipt
   - Check budget progress updated

5. **Ask AI Assistant**
   - Open chat
   - Ask: "How much did I spend on dining this month?"
   - Verify AI includes the new receipt in response

---

## Test 7: Performance Testing

### 7.1 Response Times
Measure and verify:
- Receipt analysis: < 5 seconds
- Chat response: < 3 seconds
- Embedding search: < 2 seconds
- Cashflow forecast: < 4 seconds

### 7.2 Offline Mode
1. Enable airplane mode
2. Open app
3. Verify:
   - ✅ Can view saved receipts
   - ✅ Can view dashboard
   - ✅ Shows "offline" indicator
   - ❌ Cannot scan new receipts
   - ❌ Cannot use AI chat

4. Disable airplane mode
5. Verify:
   - ✅ App reconnects automatically
   - ✅ Can scan receipts again
   - ✅ Pending operations sync

---

## Test 8: Error Handling

### 8.1 Invalid AWS Credentials
1. Edit `.env` with wrong credentials
2. Restart app
3. Try to scan receipt
4. Verify:
   - ✅ Shows error message
   - ✅ Doesn't crash
   - ✅ Suggests checking credentials

### 8.2 Network Timeout
1. Enable slow network (3G simulation)
2. Scan receipt
3. Verify:
   - ✅ Shows loading indicator
   - ✅ Timeout after 30 seconds
   - ✅ Shows retry option

### 8.3 Invalid Receipt Image
1. Take photo of blank paper
2. Verify:
   - ✅ Nova Pro returns low confidence
   - ✅ App asks to retake photo
   - ✅ Doesn't save invalid data

---

## Test 9: Multi-Platform Testing

### Android Testing
```bash
# Build APK
flutter build apk --release

# Install on device
adb install build/app/outputs/flutter-apk/app-release.apk

# Test on multiple Android versions:
# - Android 10 (API 29)
# - Android 11 (API 30)
# - Android 12 (API 31)
# - Android 13 (API 33)
# - Android 14 (API 34)
```

### iOS Testing
```bash
# Build for iOS
flutter build ios --release

# Test on multiple iOS versions:
# - iOS 14
# - iOS 15
# - iOS 16
# - iOS 17
```

### Test Matrix
| Platform | Version | Camera | AWS | Offline | Status |
|----------|---------|--------|-----|---------|--------|
| Android | 10 | ✅ | ✅ | ✅ | Pass |
| Android | 13 | ✅ | ✅ | ✅ | Pass |
| iOS | 15 | ✅ | ✅ | ✅ | Pass |
| iOS | 17 | ✅ | ✅ | ✅ | Pass |

---

## Test 10: Security Testing

### 10.1 Verify Credentials Not Exposed
```bash
# Check .env is not in Git
git status

# Check .env is in .gitignore
cat .gitignore | grep .env

# Check no credentials in code
grep -r "AKIA" lib/
grep -r "AWS_SECRET" lib/

# Should return no results
```

### 10.2 Test Encrypted Storage
1. Save receipt with sensitive data
2. Check Hive database file
3. Verify data is encrypted
4. Cannot read without app

---

## Test 11: Cost Monitoring

### Track API Costs
1. Go to AWS Console → Bedrock → Usage
2. Monitor costs after testing:
   - 10 receipts scanned
   - 20 chat messages
   - 5 cashflow forecasts
   - 10 knowledge searches

### Expected Costs
- 10 receipts (Nova Pro): ~$0.02
- 20 chat messages (Nova Lite): ~$0.01
- 5 forecasts (Nova Lite): ~$0.005
- 10 searches (Titan Embeddings): ~$0.001

**Total**: ~$0.04 for complete testing

---

## Test Checklist

### Before Release
- [ ] All AWS services working
- [ ] Receipt scanning accurate (>90%)
- [ ] Cashflow forecasting reasonable
- [ ] Budget analysis correct
- [ ] Knowledge search relevant
- [ ] Offline mode works
- [ ] Error handling graceful
- [ ] No crashes on any platform
- [ ] No credentials exposed
- [ ] Performance acceptable
- [ ] Costs within budget

---

## Reporting Issues

If you find bugs during testing:

1. **Check AWS Setup**
   - Verify credentials in `.env`
   - Check model access in Bedrock console
   - Verify IAM permissions

2. **Check Logs**
   ```bash
   flutter logs
   ```

3. **Report Issue**
   - Go to: https://github.com/Zain-Ul-Abidin1038/nova-finance-os/issues
   - Include:
     - Platform (Android/iOS)
     - Version
     - Steps to reproduce
     - Error message
     - Screenshots

---

## Success Criteria

Finance OS is ready for release when:
- ✅ All 11 tests pass
- ✅ Works on Android 10+ and iOS 14+
- ✅ Receipt accuracy > 90%
- ✅ Response times < 5 seconds
- ✅ No crashes in 100 operations
- ✅ Costs < $5 per 100 users/month

---

**Happy Testing! 🧪**

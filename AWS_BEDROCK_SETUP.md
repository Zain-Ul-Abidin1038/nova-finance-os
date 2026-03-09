# AWS Bedrock Setup Guide for Finance OS

This guide will help you set up real AWS Bedrock integration with Amazon Nova models.

---

## Prerequisites

- AWS Account (create at https://aws.amazon.com)
- AWS CLI installed (optional but recommended)
- Credit card for AWS billing (Nova models are pay-per-use)

---

## Step 1: Create AWS Account & Enable Bedrock

### 1.1 Sign Up for AWS
1. Go to https://aws.amazon.com
2. Click "Create an AWS Account"
3. Follow the registration process
4. Add payment method

### 1.2 Enable Amazon Bedrock
1. Sign in to AWS Console: https://console.aws.amazon.com
2. Search for "Bedrock" in the top search bar
3. Click "Amazon Bedrock"
4. Select your region (recommended: **us-east-1** or **us-west-2**)
5. Click "Get Started"

---

## Step 2: Request Model Access

### 2.1 Enable Amazon Nova Models
1. In Bedrock console, click "Model access" in left sidebar
2. Click "Manage model access" button
3. Find and enable these models:
   - ✅ **Amazon Nova Lite** (`us.amazon.nova-lite-v1:0`) - For reasoning
   - ✅ **Amazon Nova Pro** (`us.amazon.nova-pro-v1:0`) - For vision/multimodal
   - ✅ **Amazon Titan Embeddings V2** (`amazon.titan-embed-text-v2:0`) - For embeddings
4. Click "Request model access"
5. Wait for approval (usually instant for Nova models)

### 2.2 Verify Access
1. Go back to "Model access"
2. Ensure all three models show "Access granted" status

---

## Step 3: Create IAM User with Bedrock Permissions

### 3.1 Create IAM User
1. Go to IAM Console: https://console.aws.amazon.com/iam/
2. Click "Users" → "Create user"
3. User name: `finance-os-bedrock-user`
4. Click "Next"

### 3.2 Attach Permissions
1. Select "Attach policies directly"
2. Search for and select: **AmazonBedrockFullAccess**
3. (Optional) For production, create custom policy with minimal permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": [
        "arn:aws:bedrock:*::foundation-model/us.amazon.nova-lite-v1:0",
        "arn:aws:bedrock:*::foundation-model/us.amazon.nova-pro-v1:0",
        "arn:aws:bedrock:*::foundation-model/amazon.titan-embed-text-v2:0"
      ]
    }
  ]
}
```

4. Click "Next" → "Create user"

### 3.3 Create Access Keys
1. Click on the newly created user
2. Go to "Security credentials" tab
3. Scroll to "Access keys"
4. Click "Create access key"
5. Select "Application running outside AWS"
6. Click "Next" → "Create access key"
7. **IMPORTANT:** Copy both:
   - Access key ID (starts with `AKIA...`)
   - Secret access key (only shown once!)
8. Click "Done"

---

## Step 4: Configure Finance OS

### 4.1 Create .env File
```bash
cd nova_ledger_ai
cp .env.example .env
```

### 4.2 Edit .env File
Open `.env` and add your credentials:

```env
# AWS Credentials for Amazon Bedrock
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_REGION=us-east-1
```

**Replace with your actual values from Step 3.3!**

### 4.3 Verify .env is in .gitignore
```bash
cat .gitignore | grep .env
```

Should show `.env` - this prevents committing secrets to Git.

---

## Step 5: Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Verify AWS packages are installed
flutter pub deps | grep aws
```

You should see:
- `aws_common`
- `aws_signature_v4`
- `crypto`

---

## Step 6: Test AWS Bedrock Connection

### 6.1 Create Test Script
Create `test_bedrock.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nova_finance_os/core/services/nova_lite_service.dart';

void main() async {
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  final accessKeyId = dotenv.env['AWS_ACCESS_KEY_ID']!;
  final secretAccessKey = dotenv.env['AWS_SECRET_ACCESS_KEY']!;
  final region = dotenv.env['AWS_REGION'] ?? 'us-east-1';
  
  print('🧪 Testing AWS Bedrock Connection...');
  print('Region: $region');
  
  // Create Nova Lite service
  final novaLite = NovaLiteService(
    accessKeyId: accessKeyId,
    secretAccessKey: secretAccessKey,
    region: region,
  );
  
  // Test message
  print('\n📤 Sending test message to Nova Lite...');
  final response = await novaLite.sendMessage(
    prompt: 'What is 2+2? Answer in one word.',
  );
  
  if (response['success'] == true) {
    print('✅ SUCCESS!');
    print('Response: ${response['message']}');
    print('Usage: ${response['usage']}');
  } else {
    print('❌ FAILED!');
    print('Error: ${response['error']}');
  }
}
```

### 6.2 Run Test
```bash
dart test_bedrock.dart
```

Expected output:
```
🧪 Testing AWS Bedrock Connection...
Region: us-east-1

📤 Sending test message to Nova Lite...
✅ SUCCESS!
Response: Four
Usage: {inputTokens: 12, outputTokens: 2, totalTokens: 14}
```

---

## Step 7: Run Finance OS on Device

### 7.1 Android
```bash
# Connect Android device or start emulator
flutter devices

# Run app
flutter run -d <device-id>
```

### 7.2 iOS
```bash
# Connect iPhone or start simulator
flutter devices

# Run app
flutter run -d <device-id>
```

### 7.3 Test Receipt Scanning
1. Open Finance OS app
2. Go to "Scan Receipt"
3. Take photo of a receipt
4. Watch Nova Pro analyze it in real-time
5. Check extracted data (vendor, amount, category, tax deduction)

---

## Step 8: Monitor Usage & Costs

### 8.1 View Bedrock Usage
1. Go to AWS Console → Bedrock
2. Click "Usage" in left sidebar
3. View model invocations and costs

### 8.2 Estimated Costs (per 1000 requests)
- **Nova Lite**: ~$0.50 (reasoning)
- **Nova Pro**: ~$2.00 (vision)
- **Titan Embeddings**: ~$0.10 (search)

**Total for 100 receipts/month**: ~$3-5

### 8.3 Set Billing Alerts
1. Go to AWS Console → Billing
2. Click "Budgets"
3. Create budget: $10/month
4. Set alert at 80% ($8)

---

## Troubleshooting

### Error: "Access Denied"
- Check IAM permissions
- Verify model access is granted
- Ensure credentials are correct in `.env`

### Error: "Model not found"
- Check region matches model availability
- Nova models available in: us-east-1, us-west-2
- Verify model ID: `us.amazon.nova-lite-v1:0`

### Error: "Invalid signature"
- Check AWS credentials are correct
- Ensure no extra spaces in `.env`
- Verify system time is correct (AWS requires accurate time)

### Error: "Throttling"
- You're hitting rate limits
- Wait a few seconds and retry
- Consider implementing exponential backoff

---

## Security Best Practices

### 1. Never Commit Credentials
```bash
# Verify .env is ignored
git status

# Should NOT show .env file
```

### 2. Rotate Access Keys Regularly
- Rotate every 90 days
- Delete old keys after rotation

### 3. Use IAM Roles in Production
- For production apps, use AWS Cognito Identity Pools
- Provides temporary credentials
- More secure than hardcoded keys

### 4. Monitor CloudTrail
- Enable AWS CloudTrail
- Monitor Bedrock API calls
- Set up alerts for suspicious activity

---

## Next Steps

1. ✅ Test all Nova services (Lite, Pro, Embeddings)
2. ✅ Scan real receipts and verify accuracy
3. ✅ Test cashflow forecasting
4. ✅ Test budget analysis
5. ✅ Test knowledge search
6. ✅ Build and deploy to TestFlight/Play Store

---

## Support

**AWS Bedrock Documentation**: https://docs.aws.amazon.com/bedrock/  
**Amazon Nova Models**: https://aws.amazon.com/bedrock/nova/  
**Finance OS Issues**: https://github.com/Zain-Ul-Abidin1038/nova-finance-os/issues

---

**You're now ready to use real Amazon Nova AI in Finance OS! 🚀**

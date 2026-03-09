# Cloud Services Restoration - Design Document

## Overview
This document outlines the design for restoring cloud AI and backend services to Finance OS, including Nova 3 Pro AI integration and AWS Amplify services (Cognito, S3).

## Architecture

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Application                       │
│              (iOS, Android, Web, Desktop)                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Service Layer                             │
│  • NovaService (AI Analysis)                              │
│  • AWSMemoryService (Financial Memory)                      │
│  • AuditVaultService (Compliance Storage)                   │
│  • AuthService (User Authentication)                        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Cloud Services                            │
│  • Google Nova 3 Pro API                                  │
│  • AWS Cognito (Auth)                                       │
│  • AWS S3 (Storage)                                         │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

#### Receipt Analysis Flow
```
1. User captures receipt image
   └─> CameraScreen

2. Image saved locally
   └─> Hive database (offline-first)

3. Image uploaded to S3
   └─> AuditVaultService.uploadReceiptImage()
   └─> S3: private/{userId}/receipts/{receiptId}/image.jpg

4. Memory context retrieved
   └─> AWSMemoryService.getRecentMemories()
   └─> S3: private/{userId}/memories/index.json

5. AI analysis with context
   └─> NovaService.analyzeReceiptImage()
   └─> Nova 3 Pro Vision API
   └─> Returns: vendor, amount, category, deductions, thought signature

6. Audit trail saved
   └─> AuditVaultService.saveAuditTrail()
   └─> S3: private/{userId}/receipts/{receiptId}/audit.json

7. Memory event stored
   └─> AWSMemoryService.putMemoryEvent()
   └─> S3: private/{userId}/memories/{memoryId}.json
   └─> Updates: private/{userId}/memories/index.json

8. Local database updated
   └─> ReceiptService saves to Hive

9. UI updated
   └─> User sees results with Nova Trace
```

## Component Design

### 1. AWS Memory Service (S3-Based)

**File:** `lib/core/services/aws_memory_service.dart`

**Purpose:** Store and retrieve financial memories, thought signatures, and user patterns using AWS S3.

**Key Features:**
- S3-based storage for scalability and cost-effectiveness
- In-memory cache for fast access
- Index file for efficient querying
- Automatic TTL management (1 year retention)
- Tag-based filtering

**Storage Structure:**
```
S3 Bucket: nova-accountant-audit-vault-{id}
└─ private/{userId}/
   └─ memories/
      ├─ index.json              # Fast lookup index
      ├─ memory_{timestamp1}.json
      ├─ memory_{timestamp2}.json
      └─ ...
```

**Memory Object Schema:**
```json
{
  "id": "memory_1707523200000",
  "userId": "cognito-sub-id",
  "timestamp": 1707523200000,
  "thoughtSignature": "User spent $45 on Italian restaurant...",
  "category": "Business Meal",
  "metadata": {
    "total": 45.00,
    "deductible": 22.50,
    "vendor": "Luigi's Trattoria",
    "tags": ["meal", "business", "italian"]
  },
  "createdAt": "2024-02-09T12:00:00Z"
}
```

**Index File Schema:**
```json
{
  "userId": "cognito-sub-id",
  "lastUpdated": "2024-02-09T12:00:00Z",
  "count": 42,
  "memories": [
    { /* memory object 1 */ },
    { /* memory object 2 */ },
    ...
  ]
}
```

**API Methods:**

1. **`initialize(String userId)`**
   - Sets user ID for all operations
   - Loads memory index from S3
   - Initializes in-memory cache

2. **`putMemoryEvent({thoughtSignature, category, metadata})`**
   - Creates new memory object
   - Uploads to S3 as individual file
   - Updates in-memory cache
   - Updates index file
   - Non-blocking (errors don't fail main flow)

3. **`getMemoryStories({limit, filterTags})`**
   - Returns thought signatures from cache
   - Filters by tags if provided
   - Sorted by timestamp (newest first)
   - Loads from S3 if cache empty

4. **`storeSocialLedgerEntry({personName, amount, type, date})`**
   - Specialized method for IOU tracking
   - Tags: ['loan', 'owed', 'social']
   - Formats thought signature for readability

5. **`storeFinancialWarning({warningType, message, context})`**
   - Specialized method for guardrail warnings
   - Tags: ['warning', 'guardrail']
   - Used for cash crunch detection

6. **`getUnpaidIOUs()`**
   - Retrieves memories with 'loan' or 'owed' tags
   - Parses thought signatures for IOU details
   - Returns list of unpaid debts

7. **`detectCashCrunch()`**
   - Checks recent memories for warning patterns
   - Returns boolean indicating financial stress
   - Used for proactive user warnings

8. **`getSpendingByCategory({days})`**
   - Aggregates spending from recent memories
   - Groups by category
   - Returns map of category → total amount

**Performance Optimizations:**
- In-memory cache reduces S3 API calls
- Index file enables fast queries without listing all objects
- Batch updates to index (not per-memory)
- Limit index to 100 most recent memories
- Lazy loading (only load when needed)

**Error Handling:**
- All methods catch and log errors
- Memory operations never block main flow
- Graceful degradation if S3 unavailable
- Empty results returned on error

### 2. Audit Vault Service

**File:** `lib/core/services/audit_vault_service.dart`

**Purpose:** Store immutable audit trails for compliance and legal requirements.

**Storage Structure:**
```
S3 Bucket: nova-accountant-audit-vault-{id}
└─ private/{userId}/
   ├─ receipts/
   │  └─ {receiptId}/
   │     ├─ image.jpg           # Original receipt image
   │     └─ audit.json          # Complete audit trail
   └─ summaries/
      ├─ 2024-01.json           # Monthly summary
      ├─ 2024-02.json
      └─ ...
```

**Audit Trail Schema:**
```json
{
  "receiptId": "receipt_123",
  "userId": "cognito-sub-id",
  "timestamp": "2024-02-09T12:00:00Z",
  "vendor": "Luigi's Trattoria",
  "total": 45.00,
  "tax": 3.60,
  "category": "Business Meal",
  "deductible": 22.50,
  "thoughtSignature": "AI reasoning...",
  "memoryContext": ["memory1", "memory2"],
  "location": {
    "latitude": 37.7749,
    "longitude": -122.4194,
    "region": "United States"
  },
  "novaModel": "nova-3-pro-vision",
  "version": "1.0",
  "savedAt": "2024-02-09T12:00:05Z"
}
```

**API Methods:**

1. **`saveAuditTrail({receiptId, auditData})`**
   - Uploads audit JSON to S3
   - Adds metadata (userId, timestamp, version)
   - Immutable once saved (versioning enabled)

2. **`getAuditTrail(String receiptId)`**
   - Downloads audit JSON from S3
   - Returns parsed audit data
   - Used for compliance and review

3. **`listAuditTrails()`**
   - Lists all receipt IDs for user
   - Used for bulk operations

4. **`saveMonthlySummary({year, month, summaryData})`**
   - Saves aggregated monthly data
   - Used for tax reporting

5. **`uploadReceiptImage({receiptId, imageBytes, mimeType})`**
   - Uploads original receipt image
   - Supports JPG and PNG
   - Returns S3 path

6. **`getReceiptImageUrl(String receiptId)`**
   - Generates presigned URL for image
   - URL expires after 1 hour
   - Used for display in UI

### 3. Nova Service

**File:** `lib/core/services/nova_service.dart`

**Purpose:** Interface with Google Nova 3 Pro API for AI analysis.

**API Methods:**

1. **`analyzeReceiptImage({base64Image, memoryContext, region})`**
   - Sends image + context to Nova Vision API
   - Uses "high-level thinking" mode
   - Returns structured receipt data
   - Includes thought signature

2. **`sendMessage({prompt, systemInstruction, memoryContext})`**
   - Chat interface with Nova
   - Maintains conversation context
   - Streams responses for real-time feel

**Prompt Engineering:**

Receipt Analysis Prompt:
```
You are a financial AI assistant analyzing a receipt image.

Context from user's financial memory:
{memoryContext}

Current location: {region}

Task:
1. Extract vendor name, total amount, tax, and items
2. Categorize the expense (Business Meal, Office Supplies, etc.)
3. Apply 2026 US tax rules:
   - Business meals: 50% deductible
   - Alcohol: 0% deductible
   - Office supplies: 100% deductible
4. Calculate deductible amount
5. Provide reasoning (thought signature)

Return JSON:
{
  "vendor": "...",
  "total": 0.00,
  "tax": 0.00,
  "category": "...",
  "deductible": 0.00,
  "thoughtSignature": "..."
}
```

### 4. Authentication Flow

**AWS Cognito Integration:**

1. **Sign Up:**
   ```dart
   await Amplify.Auth.signUp(
     username: email,
     password: password,
   );
   ```

2. **Sign In:**
   ```dart
   final result = await Amplify.Auth.signIn(
     username: email,
     password: password,
   );
   ```

3. **Get User ID:**
   ```dart
   final attributes = await Amplify.Auth.fetchUserAttributes();
   final userId = attributes
       .firstWhere((attr) => attr.userAttributeKey.key == 'sub')
       .value;
   ```

4. **Initialize Services:**
   ```dart
   awsMemoryService.initialize(userId);
   auditVaultService.initialize(userId);
   ```

## Security Design

### Data Isolation
- All S3 paths prefixed with `private/{userId}/`
- IAM policies enforce user-specific access
- Cognito Identity Pool provides temporary credentials

### Encryption
- S3 server-side encryption (AES-256)
- HTTPS for all API calls
- Cognito handles password security

### API Key Management
- Nova API key stored in environment variables
- Never hardcoded in source
- Rotation supported without code changes

### Access Control
```
IAM Policy for Authenticated Users:
{
  "Effect": "Allow",
  "Action": [
    "s3:PutObject",
    "s3:GetObject",
    "s3:DeleteObject",
    "s3:ListBucket"
  ],
  "Resource": [
    "arn:aws:s3:::bucket-name/private/${cognito-identity.amazonaws.com:sub}/*"
  ]
}
```

## Performance Considerations

### Caching Strategy
- Memory index cached in-memory
- Receipt data cached in Hive
- Presigned URLs cached for 50 minutes

### Optimization Techniques
- Lazy loading of memory index
- Batch updates to reduce S3 API calls
- Compress images before upload
- Use S3 Transfer Acceleration for large files

### Cost Optimization
- Index file reduces LIST operations
- Individual memory files enable selective retrieval
- TTL prevents unlimited storage growth
- Free tier covers typical usage

## Error Handling

### Network Errors
```dart
try {
  await awsMemoryService.putMemoryEvent(...);
} catch (e) {
  safePrint('[AWS Memory] ❌ Error: $e');
  // Continue without blocking main flow
}
```

### Offline Mode
- Detect connectivity with `connectivity_plus`
- Queue operations for later sync
- Use local Hive data as fallback
- Notify user of offline status

### Retry Logic
- Exponential backoff for transient errors
- Max 3 retries for critical operations
- Immediate failure for auth errors

## Testing Strategy

### Unit Tests
- Mock AWS services
- Test memory storage/retrieval
- Test audit trail creation
- Test error handling

### Integration Tests
- Test with real AWS services (dev environment)
- Verify data isolation
- Test offline mode
- Test sync after reconnection

### Property-Based Tests
- Memory retrieval returns correct count
- Filtering works correctly
- Spending aggregation is accurate
- IOU parsing is consistent

## Deployment

### Environment Configuration
```dart
// Development
const novaApiKey = String.fromEnvironment('GEMINI_API_KEY_DEV');
const awsRegion = 'us-east-1';
const s3Bucket = 'nova-accountant-dev';

// Production
const novaApiKey = String.fromEnvironment('GEMINI_API_KEY_PROD');
const awsRegion = 'us-east-1';
const s3Bucket = 'nova-accountant-prod';
```

### AWS Resources
- Cognito User Pool: `us-east-1_XFgDdU3CA`
- Cognito Identity Pool: `us-east-1:e4b6a556-2cee-453c-8e06-e875df5e8bd2`
- S3 Bucket: `nova-accountant-audit-vault-1770576191`

## Monitoring

### Metrics to Track
- API call success rate
- Average response time
- S3 storage usage
- Memory index size
- Error rate by type

### Logging
```dart
safePrint('[AWS Memory] Storing memory event: $category');
safePrint('[AWS Memory] ✓ Memory event stored');
safePrint('[AWS Memory] ❌ Error storing memory: $e');
```

### Alerts
- High error rate (> 5%)
- Slow response time (> 5s)
- Storage quota exceeded
- API rate limiting

## Future Enhancements

### Phase 2
- DynamoDB for faster queries
- CloudWatch integration
- Real-time sync with WebSockets
- Multi-region support

### Phase 3
- AWS Bedrock Agents for advanced memory
- Custom AI model fine-tuning
- Predictive analytics
- Team collaboration features

## References
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [AWS Cognito Documentation](https://docs.aws.amazon.com/cognito/)
- [Nova API Documentation](https://ai.google.dev/docs)
- [Flutter Amplify Plugin](https://docs.amplify.aws/lib/q/platform/flutter/)

## Correctness Properties

### Property 1: Memory Isolation
**Validates: Requirements 3.4, 5.3**

**Property:** Users can only access their own memories
```dart
∀ user1, user2 where user1 ≠ user2:
  memories(user1) ∩ memories(user2) = ∅
```

**Test Strategy:**
- Create two users with different Cognito subs
- Store memories for each user
- Verify user1 cannot retrieve user2's memories
- Verify S3 paths are correctly isolated

### Property 2: Memory Persistence
**Validates: Requirements 4.2, 5.1**

**Property:** Stored memories are retrievable
```dart
∀ memory m:
  putMemoryEvent(m) → getMemoryStories() contains m
```

**Test Strategy:**
- Store a memory event
- Retrieve recent memories
- Verify the stored memory is in results
- Verify thought signature matches

### Property 3: Audit Immutability
**Validates: Requirements 4.3**

**Property:** Audit trails cannot be modified after creation
```dart
∀ audit a:
  saveAuditTrail(a) → getAuditTrail(a.id) = a
```

**Test Strategy:**
- Save an audit trail
- Attempt to modify it
- Verify original data is unchanged
- Verify S3 versioning preserves history

### Property 4: Spending Aggregation Accuracy
**Validates: Requirements 5.5**

**Property:** Spending totals match sum of individual transactions
```dart
∀ category c, timeRange t:
  getSpendingByCategory(t)[c] = Σ(memories in t where category = c)
```

**Test Strategy:**
- Store multiple memories with amounts
- Calculate expected total manually
- Call getSpendingByCategory()
- Verify totals match

### Property 5: Cash Crunch Detection
**Validates: Requirements 5.2**

**Property:** Cash crunch is detected when warnings exist
```dart
∀ user u:
  (∃ warning in recentMemories(u)) → detectCashCrunch(u) = true
```

**Test Strategy:**
- Store financial warning
- Call detectCashCrunch()
- Verify returns true
- Remove warnings, verify returns false

### Property 6: Tag Filtering
**Validates: Requirements 5.2**

**Property:** Filtered memories contain only matching tags
```dart
∀ tags T:
  ∀ m ∈ getMemoryStories(filterTags: T):
    ∃ t ∈ T: t ∈ m.tags OR t ∈ m.thoughtSignature
```

**Test Strategy:**
- Store memories with various tags
- Filter by specific tag
- Verify all results contain that tag
- Verify non-matching memories excluded

### Property 7: Index Consistency
**Validates: Requirements 5.1**

**Property:** Memory index reflects actual stored memories
```dart
∀ user u:
  index(u).count = |actualMemories(u)|
  ∧ index(u).memories ⊆ actualMemories(u)
```

**Test Strategy:**
- Store multiple memories
- Load index from S3
- Count actual memory files in S3
- Verify index count matches
- Verify index contains correct memories

### Property 8: Offline Graceful Degradation
**Validates: Requirements 6.1-6.4**

**Property:** App functions without network
```dart
∀ operation o:
  networkAvailable = false → o returns cached data OR empty result
  ∧ o does not throw exception
```

**Test Strategy:**
- Disable network
- Attempt memory operations
- Verify no crashes
- Verify cached data returned
- Verify operations queued for sync

## Implementation Status

✅ **Completed:**
- AWS Memory Service (S3-based)
- Audit Vault Service
- Authentication with Cognito
- Receipt image upload
- Memory storage and retrieval
- Index file management
- Error handling

⏳ **In Progress:**
- Nova 3 Pro integration
- Nova Trace display
- Offline sync queue

🔜 **Planned:**
- Property-based tests
- Performance monitoring
- Cost optimization
- Multi-region support


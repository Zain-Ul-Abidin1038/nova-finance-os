# Grounded Search Feature

## Overview

The Grounded Search feature enables Finance OS to provide factual, verifiable answers by searching the web or specific document datastores in real-time. This ensures users get accurate, up-to-date information with proper citations.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interface Layer                      │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         GroundedChatScreen (UI)                      │  │
│  │  - Live status updates                               │  │
│  │  - Citation display                                  │  │
│  │  - Grounded answer badges                            │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   Service Layer                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │      GroundedChatService (Orchestration)             │  │
│  │  - Query analysis                                    │  │
│  │  - Grounding decision logic                          │  │
│  │  - Response streaming                                │  │
│  └──────────────────────────────────────────────────────┘  │
│                            ↓                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │      GroundedSearchService (Core)                    │  │
│  │  - Web search grounding                              │  │
│  │  - Document search grounding                         │  │
│  │  - Hybrid search                                     │  │
│  │  - Citation extraction                               │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   External APIs                              │
│  ┌────────────────────┐  ┌──────────────────────────────┐  │
│  │  Nova API with   │  │  Vertex AI Search            │  │
│  │  Google Search     │  │  (Document Datastores)       │  │
│  │  Grounding         │  │                              │  │
│  └────────────────────┘  └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Features

### 1. Web Search Grounding
- **Purpose**: Get real-time factual information from the web
- **Use Cases**: 
  - Current tax rates
  - Latest regulations
  - Market prices
  - Recent news
- **API**: Nova with `googleSearchRetrieval` tool
- **Benefits**: Always up-to-date information with citations

### 2. Document Search Grounding
- **Purpose**: Search domain-specific knowledge bases
- **Use Cases**:
  - Company tax policies
  - Internal accounting guidelines
  - Historical financial data
  - Compliance documents
- **API**: Nova with Vertex AI Search datastore
- **Benefits**: Accurate domain-specific answers

### 3. Hybrid Search
- **Purpose**: Combine web and document search
- **Use Cases**:
  - Complex queries requiring both sources
  - Verification across multiple sources
- **Benefits**: Most comprehensive answers

### 4. Intelligent Routing
- **Automatic Detection**: Analyzes query to determine if grounding is needed
- **Keywords Detected**:
  - Factual questions: "what is", "who is", "when did", "how much"
  - Current information: "current", "latest", "recent", "today"
  - Domain-specific: "tax", "deduction", "regulation", "law"

### 5. Live Status Updates
- **Real-time Feedback**: Shows what the AI is doing
- **Status Messages**:
  - "Analyzing your question..."
  - "Searching for factual information..."
  - "Thinking..."
  - "Complete"

### 6. Citation Tracking
- **Transparency**: Shows sources for all grounded answers
- **Format**: URL + Title for each source
- **Limit**: Top 3 most relevant sources displayed

## Implementation

### File Structure

```
lib/features/grounded_chat/
├── services/
│   ├── grounded_search_service.dart    # Core search logic
│   └── grounded_chat_service.dart      # Chat orchestration
└── presentation/
    └── grounded_chat_screen.dart       # UI implementation
```

### Key Components

#### 1. GroundedSearchService

```dart
// Web search with Google Search grounding
Future<Map<String, dynamic>> searchWithWebGrounding({
  required String query,
  String? context,
})

// Document search with Vertex AI Search
Future<Map<String, dynamic>> searchWithDocumentGrounding({
  required String query,
  String? context,
  String? datastoreId,
})

// Hybrid search (both web and documents)
Future<Map<String, dynamic>> hybridSearch({
  required String query,
  String? context,
  String? datastoreId,
})

// Determine if query needs grounding
bool shouldUseGrounding(String query)
```

#### 2. GroundedChatService

```dart
// Process message with intelligent grounding
Future<Map<String, dynamic>> processMessage(String message)

// Stream responses with live updates
Stream<Map<String, dynamic>> streamGroundedResponse(String message)
```

#### 3. GroundedChatScreen

- Live status indicator
- Grounded answer badges
- Citation display
- Glassmorphism UI

## Configuration

### Environment Variables

Add to `.env`:

```bash
# Required
GEMINI_API_KEY=your_nova_api_key

# Optional (for document grounding)
GCP_PROJECT_ID=your_gcp_project_id
VERTEX_DATASTORE_ID=your_datastore_id
```

### Vertex AI Search Setup

1. **Create a Datastore**:
   ```bash
   gcloud alpha discovery-engine data-stores create YOUR_DATASTORE_ID \
     --location=global \
     --collection=default_collection \
     --industry-vertical=GENERIC
   ```

2. **Import Documents**:
   ```bash
   gcloud alpha discovery-engine documents import \
     --data-store=YOUR_DATASTORE_ID \
     --location=global \
     --gcs-uri=gs://your-bucket/documents/*.pdf
   ```

3. **Update Configuration**:
   - Set `VERTEX_DATASTORE_ID` in `.env`
   - Set `GCP_PROJECT_ID` in `.env`

## Usage Examples

### Example 1: Current Tax Rate Query

**User**: "What is the current corporate tax rate in the US?"

**System**:
1. Detects factual question
2. Uses web search grounding
3. Returns: "The current US federal corporate tax rate is 21%..."
4. Shows sources: IRS.gov, Tax Foundation, etc.

### Example 2: Domain-Specific Query

**User**: "What expenses are 50% deductible?"

**System**:
1. Detects domain-specific keywords
2. Uses document search grounding (if configured)
3. Returns answer from tax policy documents
4. Shows internal document citations

### Example 3: Conversational Query

**User**: "Thanks for your help!"

**System**:
1. Detects non-factual query
2. Uses regular AI (no grounding)
3. Returns conversational response

## API Request Examples

### Web Search Grounding Request

```json
{
  "contents": [
    {
      "parts": [
        {"text": "What is the current corporate tax rate?"}
      ]
    }
  ],
  "tools": [
    {
      "googleSearchRetrieval": {
        "dynamicRetrievalConfig": {
          "mode": "MODE_DYNAMIC",
          "dynamicThreshold": 0.7
        }
      }
    }
  ],
  "generationConfig": {
    "temperature": 0.2,
    "topP": 0.8,
    "maxOutputTokens": 2048
  }
}
```

### Document Search Grounding Request

```json
{
  "contents": [
    {
      "parts": [
        {"text": "What expenses are deductible?"}
      ]
    }
  ],
  "tools": [
    {
      "retrieval": {
        "vertexAiSearch": {
          "datastore": "projects/PROJECT_ID/locations/global/collections/default_collection/dataStores/DATASTORE_ID"
        },
        "disableAttribution": false
      }
    }
  ],
  "generationConfig": {
    "temperature": 0.2,
    "topP": 0.8,
    "maxOutputTokens": 2048
  }
}
```

## Response Format

### Grounded Response

```dart
{
  'success': true,
  'answer': 'The corporate tax rate is 21%...',
  'citations': [
    {
      'url': 'https://www.irs.gov/...',
      'title': 'IRS Tax Rates',
      'type': 'web'
    }
  ],
  'sources': ['https://www.irs.gov/...'],
  'searchType': 'web',
  'hasGrounding': true
}
```

### Regular Response

```dart
{
  'success': true,
  'message': 'You\'re welcome! Happy to help.',
  'isGrounded': false
}
```

## Benefits

### For Users
- ✅ Accurate, verifiable information
- ✅ Always up-to-date facts
- ✅ Transparent sources
- ✅ Confidence in AI responses

### For Developers
- ✅ Easy integration
- ✅ Automatic grounding detection
- ✅ Fallback to regular AI
- ✅ Extensible architecture

## Best Practices

### 1. Query Optimization
- Keep queries specific and focused
- Use clear, factual language
- Avoid ambiguous questions

### 2. Citation Display
- Always show sources for grounded answers
- Limit to top 3 most relevant citations
- Include both title and URL

### 3. Error Handling
- Fallback to regular AI if grounding fails
- Show clear error messages
- Log failures for debugging

### 4. Performance
- Use web grounding for general queries (faster)
- Use document grounding for domain-specific queries
- Cache frequently asked questions

## Testing

### Manual Testing

1. **Test Web Grounding**:
   ```
   Query: "What is the current inflation rate?"
   Expected: Grounded answer with news sources
   ```

2. **Test Document Grounding**:
   ```
   Query: "What are our company's expense policies?"
   Expected: Answer from internal documents
   ```

3. **Test Regular AI**:
   ```
   Query: "Thank you!"
   Expected: Conversational response, no grounding
   ```

### Automated Testing

```dart
test('should use web grounding for factual questions', () async {
  final service = GroundedSearchService();
  final result = await service.searchWithWebGrounding(
    query: 'What is the current tax rate?',
  );
  
  expect(result['success'], true);
  expect(result['hasGrounding'], true);
  expect(result['citations'], isNotEmpty);
});
```

## Limitations

1. **API Costs**: Grounded search is more expensive than regular AI
2. **Latency**: Web/document search adds 1-3 seconds
3. **Datastore Setup**: Requires Vertex AI Search configuration
4. **Citation Quality**: Depends on source availability

## Future Enhancements

- [ ] Voice output for grounded answers
- [ ] Multi-language support
- [ ] Custom datastore per user
- [ ] Citation confidence scoring
- [ ] Fact-checking mode
- [ ] Offline caching of common queries

## Resources

- [Nova Grounding Documentation](https://ai.google.dev/nova-api/docs/grounding)
- [Vertex AI Search](https://cloud.google.com/generative-ai-app-builder/docs/enterprise-search-introduction)
- [Google Search Grounding](https://ai.google.dev/nova-api/docs/grounding#google-search)

## Support

For issues or questions:
- Check logs: `[Grounded Search]` and `[Grounded Chat]`
- Verify API keys in `.env`
- Ensure Vertex AI Search is configured
- Test with simple queries first

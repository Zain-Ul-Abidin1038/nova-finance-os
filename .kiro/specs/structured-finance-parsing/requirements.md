# Requirements Document: Structured Finance Parsing

## Introduction

The Structured Finance Parsing system enhances the Finance OS app's AI-powered natural language processing by implementing schema-based JSON parsing for financial commands. This system replaces unreliable text-based JSON extraction with structured response schemas, ensuring consistent and accurate parsing of user financial inputs.

## Glossary

- **System**: The Structured Finance Parsing system within Finance OS
- **AI_Parser**: The AIFinanceParser component that processes natural language financial commands
- **Nova_Service**: The NovaServiceV3 that communicates with Google's Nova AI API
- **Finance_Command**: A structured data object representing a parsed financial action
- **Response_Schema**: A predefined JSON schema that constrains AI responses to a specific structure
- **Structured_Message**: An API call that uses response schemas for guaranteed JSON format
- **Thought_Signature**: A trace of the AI's reasoning process during parsing
- **Financial_Action**: The type of operation (add_expense, add_income, add_loan_given, add_loan_taken, query)

## Requirements

### Requirement 1: Schema-Based Response Parsing

**User Story:** As a developer, I want AI responses to follow a predefined schema, so that JSON parsing is reliable and consistent.

#### Acceptance Criteria

1. WHEN the AI_Parser processes a user message, THE System SHALL use structured messages with Response_Schema
2. THE Response_Schema SHALL define the exact structure of Finance_Command objects
3. THE System SHALL use `NovaSchemas.financeCommand` as the Response_Schema for all financial parsing
4. WHEN Nova_Service returns a response, THE System SHALL receive structured data instead of text
5. THE System SHALL eliminate text-based JSON extraction and regex pattern matching

### Requirement 2: Finance Command Schema Structure

**User Story:** As a developer, I want a well-defined schema for financial commands, so that all parsed data follows a consistent format.

#### Acceptance Criteria

1. THE Finance_Command schema SHALL include the following fields: action, amount, currency, category, personName, description
2. THE action field SHALL be one of: add_expense, add_income, add_loan_given, add_loan_taken, query, unknown
3. THE amount field SHALL be a numeric value representing the transaction amount
4. THE currency field SHALL default to "INR" when not specified
5. THE category field SHALL represent the expense/income category
6. THE personName field SHALL be nullable and used for loan transactions
7. THE description field SHALL provide additional context about the transaction

### Requirement 3: Reliable JSON Parsing

**User Story:** As a user, I want my financial commands to be parsed accurately every time, so that my transactions are recorded correctly.

#### Acceptance Criteria

1. WHEN the System receives a structured response, THE System SHALL directly access the data object without text parsing
2. THE System SHALL NOT use try-catch blocks for JSON extraction from text
3. THE System SHALL NOT use regex patterns to extract JSON from markdown or text
4. WHEN parsing fails, THE System SHALL return a clear error message from the Nova_Service
5. THE System SHALL achieve 99%+ parsing success rate for valid financial commands

### Requirement 4: Backward Compatibility

**User Story:** As a user, I want existing financial commands to continue working, so that the parsing improvements don't break my workflow.

#### Acceptance Criteria

1. THE System SHALL support all existing Financial_Action types
2. THE System SHALL maintain the same command execution flow after parsing
3. THE System SHALL preserve Thought_Signature integration for traceability
4. THE System SHALL continue to support multi-transaction parsing
5. THE System SHALL not change the response format returned to calling code

### Requirement 5: Error Handling and Fallback

**User Story:** As a user, I want clear error messages when parsing fails, so that I understand what went wrong.

#### Acceptance Criteria

1. WHEN structured parsing fails, THE System SHALL return an error response with details
2. THE System SHALL include the original error message from Nova_Service
3. THE System SHALL log parsing failures for debugging
4. THE System SHALL NOT crash or throw unhandled exceptions on parsing errors
5. THE System SHALL provide actionable error messages to users

### Requirement 6: Performance Optimization

**User Story:** As a user, I want financial command parsing to be fast, so that my chat experience remains responsive.

#### Acceptance Criteria

1. THE System SHALL complete parsing within 2 seconds for single transactions
2. THE System SHALL eliminate redundant JSON parsing operations
3. THE System SHALL reduce CPU usage by avoiding regex pattern matching
4. THE System SHALL maintain or improve current parsing performance
5. THE System SHALL not introduce memory leaks or excessive allocations

### Requirement 7: Integration with Nova Service V3

**User Story:** As a developer, I want seamless integration with NovaServiceV3, so that structured parsing works with the existing AI infrastructure.

#### Acceptance Criteria

1. THE System SHALL use `novaService.sendStructuredMessage()` for all financial parsing
2. THE System SHALL pass the Response_Schema as a parameter to sendStructuredMessage
3. THE System SHALL receive responses in the format: `{success: bool, data: Map, thoughtSignature: String}`
4. THE System SHALL handle both successful and failed responses from Nova_Service
5. THE System SHALL preserve the isParsing flag for parsing-specific behavior

### Requirement 8: Multi-Transaction Support

**User Story:** As a user, I want to enter multiple transactions in one message, so that I can quickly log several expenses at once.

#### Acceptance Criteria

1. WHEN a message contains multiple transactions, THE System SHALL detect and split them
2. THE System SHALL use structured parsing for each individual transaction
3. THE System SHALL aggregate results from multiple transactions
4. THE System SHALL return a combined success message listing all recorded transactions
5. THE System SHALL maintain transaction order from the original message

### Requirement 9: Thought Signature Preservation

**User Story:** As a developer, I want thought signatures to be preserved, so that I can trace AI reasoning through the parsing process.

#### Acceptance Criteria

1. WHEN structured parsing completes, THE System SHALL extract the Thought_Signature from the response
2. THE System SHALL include the Thought_Signature in the final result
3. THE System SHALL log the Thought_Signature for debugging purposes
4. THE System SHALL maintain Thought_Signature format compatibility with Nova Trace UI
5. THE System SHALL not lose Thought_Signature data during error handling

### Requirement 10: Testing and Validation

**User Story:** As a developer, I want comprehensive tests for structured parsing, so that I can verify reliability improvements.

#### Acceptance Criteria

1. THE System SHALL include unit tests for schema-based parsing
2. THE System SHALL test all Financial_Action types with structured responses
3. THE System SHALL test error handling for malformed schemas
4. THE System SHALL verify backward compatibility with existing commands
5. THE System SHALL measure and report parsing success rates

## Non-Functional Requirements

### Reliability
- 99%+ parsing success rate for valid financial commands
- Zero unhandled exceptions during parsing
- Graceful degradation on API failures

### Performance
- < 2 seconds parsing time for single transactions
- < 5 seconds for multi-transaction messages
- Minimal memory overhead compared to text-based parsing

### Maintainability
- Clear separation between parsing and execution logic
- Well-documented schema definitions
- Comprehensive error logging

### Compatibility
- Works with existing NovaServiceV3 infrastructure
- Maintains current API response format
- Preserves Thought Signature integration

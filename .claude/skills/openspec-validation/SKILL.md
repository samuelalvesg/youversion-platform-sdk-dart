---
name: openspec-validation
description: Validates functional and technical specifications against OpenSpec standards, ensuring completeness, testability, contract consistency, and unambiguous acceptance criteria.
---
# Checklist
1. **Unambiguous Requirements**: No vague qualifiers ("fast", "scalable", "user-friendly") without measurable numeric targets (e.g. p95 < 200ms).
2. **Contract Completeness**: Endpoints, schemas, DTOs, headers, status codes, and error payloads explicitly defined.
3. **State Transitions**: Valid and invalid state transitions documented (idempotency, concurrency, race conditions).
4. **Failure Modes**: Explicit behavior defined for timeouts, network disconnects, third-party outages, and invalid authentication.
5. **Traceability**: Each requirement maps directly to at least one testable acceptance scenario (Given/When/Then).

# Validation Report Format
- **Specification**: `<document-path>`
- **Verdict**: `VALID | NEEDS REVISION | INCOMPLETE`
- **Missing Items**: List of gaps or ambiguities (severity: Critical, Major, Minor).
- **Recommended Fixes**: Concrete suggestions to resolve each gap.

---
name: test-strategy
description: Defines test coverage plans, test level distribution (unit, integration, contract, E2E), edge cases, and regression test suites for new features and bug fixes.
---
# Testing Pyramid & Allocation
1. **Unit Tests (Fast, Isolated, Deterministic)**:
   - High volume (~70%). Cover pure business domain logic, calculation rules, edge cases, and state machines without I/O or network.
2. **Integration Tests (Subsystems & Real Dependencies)**:
   - Medium volume (~20%). Cover repository queries, database migrations, API routes, middleware, and serialized communication.
3. **Contract / E2E Tests (System Boundaries)**:
   - Focused volume (~10%). Cover critical user journeys, external webhook contracts, and end-to-end integration flows.

# Test Strategy Checklist
- Given/When/Then scenario coverage.
- Happy path, boundary values (empty, zero, max), negative/unauthorized paths.
- Concurrency and race conditions where state is shared.
- Idempotency of retries and network reconnects.
- Clear test names following standard convention: `UnitOfWork_StateUnderTest_ExpectedBehavior`.

# Output
Test plan with prioritized test cases, expected inputs/outputs, and target file locations.

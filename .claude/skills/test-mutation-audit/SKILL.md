---
name: test-mutation-audit
description: Evaluates test suite quality and coverage by introducing artificial faults (mutations) to verify that tests fail when code is defective.
---
# Mutation Types
1. **Conditional Mutations**: Invert comparison operators (`>` to `<=`, `==` to `!=`).
2. **Boundary Mutations**: Offset loop boundaries and thresholds (`< n` to `<= n`, `offset + 1`).
3. **Return Value Mutations**: Replace return values with default/null/empty collections.
4. **Statement Removal**: Comment out key side effects or cache updates to ensure tests verify state changes.

# Audit Workflow
1. Identify high-risk or core business logic files.
2. Introduce candidate mutations (manual or via tooling if present in repo).
3. Execute relevant test suites.
4. If tests pass despite the mutation, the mutation **survived**:
   - Flag as inadequate test assertion or missing scenario.
5. If tests fail, the mutation was **killed** (effective test).

# Output (<= 25 lines)
`# | mutated location | mutation applied | test result (killed/survived) | required test coverage improvement`

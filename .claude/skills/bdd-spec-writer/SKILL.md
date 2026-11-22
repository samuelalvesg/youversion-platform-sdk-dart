---
name: bdd-spec-writer
description: Writes executable BDD scenarios (Given/When/Then) with clear acceptance criteria and edge cases. Use before implementing new features or behavior changes.
---
# Rules
- Language: English (Given/When/Then). Clear, unambiguous, domain-driven terminology.
- Declarative over imperative: focus on user intent and business rules, not UI clicks or low-level implementation details.
- Concrete examples over abstract descriptions: include boundary values, invalid inputs, and error states.
- 1 scenario = 1 specific behavior. Keep scenarios independent and idempotent.

# Structure
```gherkin
Feature: <Feature Name>
  As a <role>
  I want <capability>
  So that <business value>

  Scenario: <Happy path>
    Given <initial context/precondition>
    When <action occurs>
    Then <expected outcome/state change>

  Scenario: <Edge case or error handling>
    Given <context>
    When <invalid action or unexpected condition>
    Then <graceful failure or error response>
```

# Output
Append scenarios to the backlog item or specification markdown file under `## Spec`.

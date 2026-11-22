---
name: tech-debt-triage
description: Analyzes, categorizes, and prioritizes technical debt, legacy code, and architectural inconsistencies into actionable backlog tasks with clear risk/reward balance.
---
# Debt Categories
1. **Architecture & Design**: Broken boundaries, cyclic dependencies, missing abstractions.
2. **Code Quality**: Duplicated logic, monolithic methods, missing type safety.
3. **Testing**: Flaky tests, slow test suites, missing edge case regression tests.
4. **Dependencies**: Deprecated libraries, unpatched CVEs, outdated major versions.
5. **Documentation**: Stale specifications, missing setup guides, undocumented contracts.

# Triage Matrix
| Impact \ Effort | Low Effort | High Effort |
|---|---|---|
| **High Impact** | Quick Win (Immediate) | Major Project (Plan Sprint) |
| **Low Impact** | Opportunistic (During touch) | Low Priority / Defer |

# Output Format
`ID | Category | File / Module | Impact (High/Med/Low) | Effort (Low/Med/High) | Remediation Plan`

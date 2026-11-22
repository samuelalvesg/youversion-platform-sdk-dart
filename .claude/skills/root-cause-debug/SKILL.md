---
name: root-cause-debug
description: Investigates software bugs and unexpected behaviors down to their fundamental root cause using structured hypotheses and reproducible evidence, not superficial patches.
---
# Systematic Debugging Protocol
1. **Reproduce**: Establish a minimal, reproducible test case or script demonstrating the failure consistently.
2. **Isolate**: Formulate competing hypotheses. Test one variable at a time via binary search (git bisect, targeted unit test, isolated execution).
3. **Trace**: Inspect logs, stack traces, variable values, and timing. Differentiate symptoms from root causes.
4. **Identify Root Cause**: State exactly why the defect occurs (e.g. state mutation, unhandled race condition, precision loss, schema mismatch).
5. **Verify Fix**: Implement the minimal fix. Confirm that the reproducible test now passes and no existing tests regress.
6. **Regression Guard**: Commit the regression test alongside the fix.

# Diagnostic Output (<= 25 lines)
```
BUG: <description>
REPRODUCTION: <command or test case>
ROOT CAUSE: <file:line + technical explanation>
PROPOSED FIX: <minimal diff explanation>
REGRESSION TEST: <new test path>
```

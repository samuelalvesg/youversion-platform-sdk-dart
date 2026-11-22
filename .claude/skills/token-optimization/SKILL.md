---
name: token-optimization
description: Enforces high-density conciseness, prompt token optimization, and zero conversational filler across all agent interactions. Use to cut context bloat and token consumption without loss of technical accuracy.
---
# Rules for Maximum Conciseness ("Be Concise")
1. **Zero Conversational Filler**:
   - Eliminate all polite pleasantries ("Sure!", "I would be happy to help with that", "Certainly").
   - Eliminate staged run-ups ("Here is the solution:", "Let's dive into...").
   - Start immediately with the answer, action, diagnosis, or code diff.
2. **Direct Fact-First Structure**:
   - Format: `[Context/Issue] -> [Root Cause / Key Action] -> [Implementation / Fix]`.
   - Use direct statements and fragments where syntax clarity allows.
3. **Targeted Reading & Diffing**:
   - Read specific line ranges instead of dumping entire source files.
   - Output minimal unified diffs and surgical edits; avoid reprinting large untouched blocks.
4. **Structured Handoffs**:
   - Handoffs between agents strictly <= 25 lines.
5. **Code Integrity**:
   - Code blocks, variable names, and error traces remain 100% technically exact and intact.

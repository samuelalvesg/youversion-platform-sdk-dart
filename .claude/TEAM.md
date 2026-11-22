# Agent team

How the agents in `.claude/agents/` work together in this repository. The
project's own rules (language, commit and PR conventions, style) live in its
`AGENTS.md` or `CONTRIBUTING.md`; where they differ from this file, they win.

## Pipeline

`@spec-analyst` → `@architect` → `@developer` → `@qa-engineer` → `@reviewer`.

By trigger only, not on every diff: `@secops-engineer` (security, dependencies,
release), `@refactoring-architect` (debt, in a diff separate from features),
`@copywriter-humanizer` (docs, PRs, issues, UI text).

- One owner at a time. Only `@architect` and `@spec-analyst` change specs and
  contracts; only `@developer` changes production code; only `@qa-engineer`
  changes acceptance tests; `@reviewer` and `@secops-engineer` only read.
- The handoff is the only channel between agents (25 lines at most).

```
HANDOFF @from → @to
ITEM: <backlog item or issue>
ESCOPO: <files/modules that MAY change>
FORA: <what must NOT be touched>
CONTRATO: <public API, before → after>
CENÁRIOS: <spec scenario ids the QA will test>
RISCOS: <public API break? generated code? new dependency?>
ORDEM: <who goes first>
AMBIENTE: <shell? tools that are missing?>
```

- Return: `RETORNO @from → @to | STATUS: OK|BLOQUEADO|DIVERGENTE` followed by
  FEITO (done) / NÃO EXECUTADO (not run, with the reason) / PENDENTE (open).
  Outside the ESCOPO, or a spec that diverges → `BLOQUEADO` to `@architect`;
  never expand the scope alone.
- In Claude Code, call the `Agent` tool with `subagent_type: <name>` and the
  handoff verbatim as the prompt (a subagent does not inherit the
  conversation). Without subagents, open `.claude/agents/<name>.md` and switch
  role by writing `[PAPEL: @name]`.

## Delivery gate

Skill `verify-delivery` holds this repository's real commands. A missing tool
or a command that did not run is reported as `NÃO EXECUTADO: <reason>`, never
as green.

## Hard limits (no agent does these alone)

- Merge, or mark a PR ready, without green tests.
- Touch credentials, secrets, `.env` or anything in production.
- Delete what it did not create; send data to an external service.
- Weaken, skip or delete a test to make it pass.
- Commit or push unless the user asked; push to the main branch; force-push.

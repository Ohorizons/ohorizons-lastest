# IMPLEMENTATION_PLAN.md — Template

> Atomic task breakdown with parallelization markers.
> Version: 0.1.0 | Owner: [TEAM_NAME] | Date: [DATE]
>
> [P] = can run in parallel with adjacent [P] tasks
> [S] = sequential, must complete before next task starts
> [GATE] = requires human approval before proceeding
>
> Ref: SDD (2026) arXiv:2601.03878, arXiv:2602.00180

## Approved Scope

**Specification:** [Link to SPECIFICATION.md]
**Constitution:** [Link to CONSTITUTION.md]
**Approved by:** [HUMAN_NAME] on [DATE]

### Files in Scope

<!-- Only files listed here may be created or modified by agents. -->
<!-- The scope-guard hook enforces this boundary. -->

```
src/
  module_a.py          [CREATE]
  module_b.py          [CREATE]
  utils/helper.py      [MODIFY]
tests/
  test_module_a.py     [CREATE]
  test_module_b.py     [CREATE]
docs/
  api-reference.md     [CREATE]
```

### Files Explicitly Out of Scope

```
CONSTITUTION.md        [NEVER — owner-only]
infrastructure/        [NEVER — requires deployer role]
.env                   [NEVER — contains secrets]
```

## Phase 1: Foundation

- [S] Task 1.1: [Description of first task]
  - Files: `src/module_a.py` [CREATE]
  - Acceptance: [How to verify this task is done]

- [P] Task 1.2: [Description of parallel task]
  - Files: `src/module_b.py` [CREATE]
  - Acceptance: [Verification criteria]

- [P] Task 1.3: [Another parallel task]
  - Files: `src/utils/helper.py` [MODIFY]
  - Acceptance: [Verification criteria]

## Phase 2: Tests

- [S] Task 2.1: Write unit tests for module_a
  - Files: `tests/test_module_a.py` [CREATE]
  - Acceptance: All tests pass, coverage > 80%

- [P] Task 2.2: Write unit tests for module_b
  - Files: `tests/test_module_b.py` [CREATE]
  - Acceptance: All tests pass, coverage > 80%

## [GATE] Human Review

> **This is a hard stop.** Agent cannot proceed past this gate
> without explicit human approval. The reviewer must verify:
>
> - [ ] All Phase 1 files match SPECIFICATION.md requirements
> - [ ] All Phase 2 tests verify intent, not just syntax
> - [ ] No files outside approved scope were modified
> - [ ] No security concerns in generated code

**Approved by:** _________________ **Date:** _________________

## Phase 3: Integration

- [S] Task 3.1: [Integration task]
  - Files: [list]
  - Acceptance: [criteria]

- [S] Task 3.2: Write documentation
  - Files: `docs/api-reference.md` [CREATE]
  - Acceptance: All public APIs documented

## Completion Checklist

- [ ] All tasks completed
- [ ] All tests passing
- [ ] No files modified outside approved scope
- [ ] Human review gate approved
- [ ] SPECIFICATION.md acceptance criteria satisfied
- [ ] CONSTITUTION.md principles not violated
- [ ] PR created with clear description

# Project Constitution

> Non-negotiable principles for all SDD specs. Words MUST/SHOULD follow RFC 2119.

## 1) When to Use SDD

| Full Spec Required | Skip Spec (PR Description OK <!-- PR not needed for solo dev -->) |
|---|---|
| New UI features | Bug fixes |
| New API endpoints | Small polish |
| Schema changes | Dependency updates |
| New models | Docs only |

## 2) Feature Naming

- Directory: kebab-case (e.g., `transactions-delete`)
- Branch: feature/description (e.g., `feature/transactions-delete`)

## 3) Spec Completeness

A spec is complete when:
- All acceptance criteria written
- Edge cases identified
- Dependencies documented (existing endpoints, routes)
- API contracts specified

## 4) UI Patterns (Non-Negotiable)

- Bulk operations: toolbar at viewport bottom
- Table selection: checkbox in first column
- Range selection: Shift+click support
- Destructive actions: confirm dialog required

## 5) Data Conventions

- Enums for status/state fields
- Soft deletes preferred
- Timestamps: `created_at`, `updated_at` on all tables

## 6) Review Checklist

Before human checkpoint #4, verify:
- [ ] Tests pass
- [ ] Coverage >= 85%
- [ ] No scope creep (all tasks from tasks.md completed)
- [ ] Rubocop passes

## 7) Governance

- This file lives at `docs/specs/constitution.md`
- Changes require PR approval <!-- Note: Since this is solo dev work, direct commits to main branch are fine -->
- Specs that contradict this must be rewritten

---

**Status**: v1.0
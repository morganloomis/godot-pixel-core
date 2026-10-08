## Context

`openspec/project.md` is the canonical project brief for OpenSpec and agents. It already covers overview, stack, local Godot path, addon layout, domain concepts, and conventions. The change only adjusts that document—no code or shipped addon behavior.

## Goals / Non-Goals

**Goals:**

- Preserve factual accuracy (engine version, paths, addon vs test layout, domain table content in shortened form).
- Make the file faster to read: fewer long paragraphs, tighter table cells where possible, optional bullet summaries for dense rows.
- Add two explicit working norms: **search for current Godot guidance** before implementing, and **prefer engine-native patterns** before bespoke systems.

**Non-Goals:**

- Changing `project.godot`, addon APIs, or any spec under `openspec/specs/` except via separate changes.
- Replacing the domain concept table with something that drops important distinctions (presenter vs body, tiles vs props, etc.).

## Decisions

1. **Structure** — Keep the same top-level sections where they still fit (`Overview`, `Tech stack`, local Godot path, `Addon structure`, `Domain concepts`, `Conventions`). Add a short **Working with Godot** (or similarly named) section that holds research + native-first rules so they are impossible to miss; do not bury them only inside `Conventions`.
2. **Concision** — Merge redundant sentences in Overview; shorten table descriptions to one line each where a line still disambiguates; keep the local executable path as a single fenced path or one line.
3. **Tone** — Use normative language aligned with the new spec (`SHALL` / `MUST` in spec; in `project.md` use clear imperatives: “search…”, “prefer…”).

## Risks / Trade-offs

- **Over-shortening** — Risk losing nuance (e.g. presenter as `Node2D` + child `Sprite2D`). Mitigation: when trimming, keep the non-obvious constraints that affect architecture decisions.
- **Doc drift** — Future edits might drop the new norms. Mitigation: `openspec-project-context` spec gives verify/archive a checklist.

## Migration Plan

Not applicable: edit one markdown file; no deployment or rollback beyond reverting the commit.

## Open Questions

None for this scope.

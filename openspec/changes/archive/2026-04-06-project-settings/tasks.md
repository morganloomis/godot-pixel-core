## 1. Revise `openspec/project.md`

- [x] 1.1 Shorten Overview, Tech stack, and addon/test layout sections while keeping facts correct (engine 4.6, GDScript, GL Compatibility, paths, deployable vs test).
- [x] 1.2 Condense the **Domain concepts** table: one scannable line per row, preserving presenter vs body, animated/character/player entity, tiles vs scene props, and lit toggle semantics.
- [x] 1.3 Keep **Local Godot executable** as a single clear path line; keep **Conventions** minimal (addon path, no generated art, script warnings).
- [x] 1.4 Add a dedicated **Working with Godot** (or equivalent) section that states: search official docs and current web guidance for the best approach before coding; prefer native nodes, signals, resources, scenes, and editor workflows over fully custom solutions unless justified.
- [x] 1.5 Re-read the file against `openspec/changes/project-settings/specs/openspec-project-context/spec.md` and adjust wording until all ADDED requirements are clearly satisfied.

## 2. Verify

- [x] 2.1 Run `openspec validate project-settings --type change` after edits and fix any reported issues.

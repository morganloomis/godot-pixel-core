## Why

`openspec/project.md` is the shared context for OpenSpec and agents, but it is long and does not yet spell out how to stay aligned with Godot’s own patterns or how to validate approaches. Tightening the doc and adding explicit guidance reduces drift and avoids reinventing engine features.

## What Changes

- Rewrite `openspec/project.md` to be **shorter and easier to scan** while keeping essential facts (what Pixel Core is, stack, paths, domain terms, conventions).
- Add a strong expectation to **search the web** (official docs, issues, community guidance) for the current Godot-recommended way to solve a problem before coding.
- Add an explicit **native Godot first** rule: prefer built-in nodes, signals, resources, and editor workflows over fully custom frameworks unless there is a clear gap.

## Capabilities

### New Capabilities

- `openspec-project-context`: Requirements for the content and tone of `openspec/project.md` (concise structure, research expectation, native-first workflow guidance).

### Modified Capabilities

<!-- No delta to existing product specs; only project context documentation. -->

## Impact

- **Files**: `openspec/project.md` only (after tasks are applied).
- **Runtime / API**: None.

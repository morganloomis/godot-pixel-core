## Context

`AnimatedEntity` already exports `movement_speed` and `frame_rate`. `CharacterEntity` exposes health, `entity_name`, and a read-only `speed` getter that reads `animated_entity.movement_speed`. Authors asked to tune motion and animation timing from the **character** (and **player**) root in the inspector, matching how `entity_name` is forwarded.

## Goals / Non-Goals

**Goals:**

- Add `@export` properties on `CharacterEntity` that **get/set** the child `AnimatedEntity`’s `movement_speed` and `frame_rate` once `@onready` / `_ready` wiring is available.
- Preserve **one source of truth** on the presenter; root exports are thin forwards, not parallel fields.
- Ensure editor updates (e.g. `frame_rate` set) still invoke presenter side effects (timer `wait_time` via existing setter on `AnimatedEntity`).
- `PlayerEntity` gains the same inspector entries **via inheritance** (no duplicate declarations).

**Non-Goals:**

- Hiding or removing presenter exports (props and bare `AnimatedEntity` still need them).
- Changing default numeric values or units.
- Refactoring movement logic beyond wiring exports and documenting `speed` relative to forwarded movement speed.

## Decisions

1. **Forwarding implementation** — Use explicit `@export var movement_speed` / `@export var frame_rate` on `CharacterEntity` with getters and setters that delegate to `animated_entity` when valid; when the child is missing, getters return documented defaults (match `AnimatedEntity` defaults: 200.0 and 12.0) and setters no-op or cache—prefer **defer** via `_ready` + `_push_tuning_to_presenter()` mirroring `_push_entity_name_to_presenter()` so scene load order stays safe.

2. **Keep read-only `speed` property** — Retain `speed` as a getter reading `animated_entity.movement_speed` for existing `PlayerEntity` code (`velocity = input_direction * speed`). Document that it matches the forwarded export when the child exists. Optionally the export could be named `movement_speed` to align with the child (clearer than overloading `speed` as both export and legacy name).

3. **Scene files** — If packaged `.tscn` currently set values only on the child, optionally duplicate the same values on the root for discoverability; not strictly required if forwards read child on load. Prefer **minimal diff**: implementation ensures first `_ready` push copies are unnecessary if only child is set—getter reads child. When opening scenes, Godot may show root exports as default until child loads; use `_ready` on character to **pull** from child into... actually exported vars on parent don't auto-sync display from child in Godot without tool script refresh—acceptable trade-off: first inspector open may show defaults until dependency resolved; mitigated by pulling in `_ready` from child into export backing store if we use private backing fields. **Simpler approach**: no backing fields; getters always read child when `animated_entity != null`, setters always write child. Editor may show stale root export until child is ready—Godot 4 often evaluates getters in inspector. Verify in implementation task.

4. **Framerate export** — Mirror `AnimatedEntity`’s `@export_range` on the character forward for consistent inspector UX.

## Risks / Trade-offs

- **Duplicate inspector rows** (root + child) → Authors may edit either; both must stay in sync via single presenter state. Mitigation: document “prefer root for characters.”

- **@tool + child path** — Same as `entity_name`: ensure editor hint paths call into child when setting from root.

- **`speed` vs `movement_speed`** — Two ways to read speed (`speed` getter vs export). Mitigation: keep `speed` as alias getter only, no second export named `speed` if we add `movement_speed` export (avoid duplicate inspector entries for the same scalar).

## Migration Plan

- Implement forwards; existing scenes keep working (child retains values; root getters read child).
- No breaking API removal in this change.

## Open Questions

- None blocking; implementation can confirm Godot inspector behavior for forwarded getters in `@tool` mode.

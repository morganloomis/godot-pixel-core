## Context

`PlayerEntity` reads axis input and sets `velocity = input_direction * speed`, which yields **45°** diagonals. Pixel Core art uses **2:1** iso (~**26.6°**, `atan(0.5)`).

Movable characters in this addon are **`CharacterEntity`** bodies (player, future NPCs) with an **`AnimatedEntity`** child presenter. Movement is a **body** concern; the presenter only displays action/direction. Helpers belong on **`CharacterEntity`**, not `AnimatedEntity` or a new file.

Today `_vector_to_direction()` lives only on `PlayerEntity`; it should move to the shared body base.

## Goals / Non-Goals

**Goals:**

- One place (`CharacterEntity`) for iso input remap and vector→compass facing.
- **`PlayerEntity`** stays thin: read input, call inherited helpers, set velocity/action/direction.
- **2:1 diagonals**, unchanged cardinals, uniform speed after normalize.

**Non-Goals:**

- New scripts, exports, toggles, or README sections.
- `AnimatedEntity`, lookup, lighting, or tile changes.
- Grid snapping or camera transforms.

## Decisions

### Decision 1: Helpers on `CharacterEntity`, not a new class or presenter

Add to `character_entity.gd`:

- `const _ISO_DIAG_Y_RATIO := 0.5`
- `func remap_input_to_screen(input: Vector2) -> Vector2` — unit vector or zero
- `func _vector_to_direction(v: Vector2) -> String` — moved from `player_entity.gd` unchanged

Subclasses (`PlayerEntity`, future NPCs) call these directly.

**Rationale:** Matches body-vs-presenter architecture; all movable characters inherit the same standard motion without duplication.

**Alternatives rejected:** separate `IsoMovement` RefCounted (extra file); logic on `AnimatedEntity` (presenter must not own physics).

### Decision 2: Cardinal-preserving 2:1 remap

1. Near-zero input → `Vector2.ZERO`
2. Pure X → `(signf(x), 0)`; pure Y → `(0, signf(y))`
3. Both axes → `Vector2(signf(x), signf(y) * _ISO_DIAG_Y_RATIO).normalized()`

**SE** ≈ `(1, 0.5).normalized()` in Y-down space.

### Decision 3: `PlayerEntity` wiring

```gdscript
var move_dir := remap_input_to_screen(input_direction)
velocity = move_dir * speed
# ...
animated_entity.set_direction(_vector_to_direction(move_dir))
```

Remove local `_vector_to_direction` from `player_entity.gd`.

## Risks / Trade-offs

- **[Trade-off]** Combined-axis analog input snaps to full iso diagonals. → **Accepted** for eight-direction sprites.
- **[Trade-off]** Non-iso games using `CharacterEntity` get iso remap by default. → **Accepted**; Pixel Core is iso-first.

## Migration Plan

1. Add helpers to `character_entity.gd`.
2. Update `player_entity.gd` to use them; delete duplicate `_vector_to_direction`.
3. Manual test in `test/test_scene.tscn`.
4. **Rollback:** revert both entity scripts.

No scene migration.

## Open Questions

- *(None.)*

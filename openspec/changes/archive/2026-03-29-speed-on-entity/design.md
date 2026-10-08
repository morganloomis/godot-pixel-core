## Context

`AnimatedEntity` (`Node2D`) already drives sprite frames with a `Timer` and an exported `frame_rate` (frames per second). `CharacterEntity` (`CharacterBody2D`) owns `@export var speed` and is the parent of `AnimatedEntity`. `PlayerEntity` sets `velocity = input_direction * speed`. Authors currently tune motion on the body and animation on the child, which splits related tuning.

## Goals / Non-Goals

**Goals:**

- Expose **movement speed** on `AnimatedEntity` as an `@export` so the sprite node carries both animation timing and motion tuning.
- Keep **animation rate** as an exported property on `AnimatedEntity` (today `frame_rate`); ensure changing it at runtime or in the inspector updates the animation timer consistently (`_apply_frame_rate()` pattern).
- Have `CharacterEntity` (and thus `PlayerEntity`) derive movement magnitude from the child `AnimatedEntity`’s movement speed so there is a single source of truth for “how fast this character moves” in the default hierarchy.

**Non-Goals:**

- Changing input mapping, collision layers, or animation lookup/grid rules.
- Adding new actions or directions.
- Forcing non-hierarchy setups (e.g. `AnimatedEntity` without a `CharacterEntity` parent) to move automatically; movement speed on `AnimatedEntity` is consumed by the body when that pattern is used.

## Decisions

1. **Movement speed property on `AnimatedEntity`**  
   Add `@export var movement_speed: float` (default matching current `CharacterEntity.speed`, e.g. `200.0`). Units: same as today (pixels per second for `velocity` on `CharacterBody2D`).

2. **Single source for body motion**  
   Remove the exported `speed` from `CharacterEntity` and replace it with a read API the physics code already uses: e.g. a `speed` getter that returns `animated_entity.movement_speed` when `animated_entity` is non-null, with a safe fallback if the node is missing (matches previous default). This avoids duplicating two exports and keeps `PlayerEntity`’s `velocity = input_direction * speed` valid.

3. **Animation framerate naming**  
   Keep the existing exported name `frame_rate` to avoid breaking saved scene values and to match current `_apply_frame_rate()` usage. Treat “framerate” in user language as this property; optionally add a brief class doc or `@export` hint string in implementation if the inspector should read “Animation framerate (FPS)”. Renaming to `animation_framerate` was considered but rejected here due to `.tscn` migration cost unless the project explicitly prefers a one-time rename.

4. **Scene defaults**  
   Update packaged entity scenes (`character_entity.tscn`, `player_entity.tscn`, lit variants if any) so `movement_speed` is set on `AnimatedEntity` where `speed` was previously authored on the root, preserving play feel out of the box.

## Risks / Trade-offs

- **[Risk] Breaking external projects** that set `CharacterEntity.speed` in the inspector → **Mitigation**: document in migration; grep shows in-repo scenes can be updated in the same change.
- **[Risk] Custom subclasses** that assumed `speed` was settable on the body → **Mitigation**: expose setter on body that forwards to `animated_entity.movement_speed` if desired, or document that tuning moves to the child; simplest implementation is getter-only `speed` to avoid split truth—subclasses should set `animated_entity.movement_speed`.
- **[Trade-off] Child-first tuning** requires selecting `AnimatedEntity` in the inspector for speed → aligns with the stated goal of colocating with the sprite.

## Migration Plan

1. Add `movement_speed` to `AnimatedEntity`; ensure `frame_rate` changes still call `_apply_frame_rate()` (e.g. `set` notifier if not already reactive in editor).
2. Change `CharacterEntity` to read speed from `$AnimatedEntity`.
3. Open addon entity scenes: move previous root `speed` value onto the child’s `movement_speed`; remove root `speed` property from serialized scene if present.
4. Run test scene; confirm walk/idle still behave and animation speed matches prior defaults.

## Open Questions

- None for the default addon hierarchy; forked setups that omit `AnimatedEntity` should keep fallback default in the getter until a child is attached.

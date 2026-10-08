## Why

When a character turns sharply — for example from **W** to **E** — the presenter currently snaps to the new facing on the next sprite update. That instant jump skips intermediate compass rows and looks stiff on pre-rendered eight-direction art. Smooth stepping through the shortest arc (one facing per animation frame) keeps turns readable without new art or sheet layout changes.

## What Changes

- Add **direction transition** behavior on the animated sprite **presenter** (`AnimatedEntity`): when the requested facing differs from the **currently displayed** facing by more than one step on the eight-direction ring, advance **one compass step per animation frame** along the shortest path until the target is reached.
- Use the canonical ring **S → SE → E → NE → N → NW → W → SW** (counter-clockwise index order from `SpriteSheetLookupBase.DIRECTIONS`). Shortest path = fewer steps clockwise vs counter-clockwise; when both paths are equal (**180°** opposition, e.g. **W** ↔ **E**), pick **clockwise or counter-clockwise at random**.
- Apply transitions for **every action** that uses facing rows (walk, idle, attack, etc.) — not only locomotion clips.
- If a new target facing arrives **mid-transition**, **restart** from the **current displayed** facing toward the new target (recompute shortest path; re-roll random tie-break on 180° pairs).
- Adjacent facings (one step on the ring) and unchanged targets SHALL update immediately with **no** transition delay.
- Expose a small presenter API for setting target direction (e.g. `set_direction`) so bodies keep assigning intent without duplicating transition logic; direct `direction` assignment behavior SHALL be defined in design (likely equivalent to immediate snap or delegated to the same path).
- Add a **test-scene scenario** (or extend an existing one) that reproduces a sharp reversal so the stepped turn is visible during manual play.

## Capabilities

### New Capabilities

- `animated-direction-transition`: Presenter-side shortest-path stepping through the eight-direction ring, one facing per animation frame, random path on 180° ties, restart-on-interrupt, and scope across all facing-based actions.

### Modified Capabilities

- `sprite-presentation`: Presenter requirements SHALL include direction-transition behavior, separation of target vs displayed facing during transitions, and the public API for requesting a new facing.
- `player-entity`: SHALL document that the player body sets **target** facing on the presenter; visible facing MAY lag by transition steps while input changes sharply (displayed direction during movement still ends at the input-derived target).
- `test-scene`: Add or extend a scenario that exercises a sharp direction reversal with stepped facings.

## Impact

- **Addon** (`addons/godot-pixel-core/`): primary change in **`entity/animated_entity.gd`** (transition state, per-frame direction advance tied to existing animation timer). **`entity/player_entity.gd`** and any other bodies that set `direction` may switch to the new setter; **no** change to lookup classes, sheet layout, lighting, or tile systems.
- **Test** (`test/`): scenario wiring for manual verification of W↔E (or similar) turns; no art edits required beyond existing sheets.
- **OpenSpec**: new capability spec plus deltas for `sprite-presentation`, `player-entity`, and `test-scene`.
- **Consumers**: behavior change is visible whenever direction jumps by two or more ring steps; adjacent turns unchanged. No new exports required unless design adds tuning (e.g. disable flag) — defer to `design.md`.

## Non-goals

- Changing the eight-row sheet order or direction name set (`sprite-sheet-facing` stays as-is).
- Per-body transition logic; bodies only request target facings.
- Custom easing, duration caps, or multi-frame holds per intermediate facing (strictly one ring step per animation frame).
- Tile map facings, static sprites, or lookup/cache changes.
- New transition art or blend frames between facings.

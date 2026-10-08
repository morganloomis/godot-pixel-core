## Why

Action changes on animated entities currently snap instantly to the new clip, which looks abrupt for states like idle→walk. Artists can already author dedicated bridge animations as separate action folders; the presenter should discover and play them automatically so gameplay code stays unchanged.

## What Changes

- When `set_action(new_action)` is called and the current logical action differs, the presenter SHALL look up a transition clip named `{previous}-{new}` (e.g. `idle-walk`) under the entity's animated sheet root.
- If the transition clip exists (valid `diffuse.png` with at least one frame), play it **once** through all frames at the current `frame_rate`, then begin the target action from frame 0.
- If no transition clip exists, switch to the target action immediately (current behavior).
- Transition clips always use play-once semantics regardless of `playback_modes`.
- If `set_action` is called again while a transition clip is playing, abandon the in-flight transition and jump straight to the newly requested action (no `{current_visual}-{new}` lookup from a half-played bridge).
- Direction transitions (`set_direction`, multi-step ring turns) continue independently and are unaffected.
- The public `action` property SHALL reflect the **target/logical** action (what gameplay requested), not the internal transition folder name, so bodies like `PlayerEntity` do not re-trigger `set_action` mid-bridge.
- `animation_finished` SHALL **not** emit when a transition clip completes; it remains for explicit one-shot **logical** actions only (e.g. attack, die). Transition clips are internal playback detail.

## Capabilities

### New Capabilities

- `animated-action-transition`: Presenter-side discovery, playback, and interrupt rules for `{from}-{to}` transition clips between logical actions.

### Modified Capabilities

- `sprite-presentation`: Document `set_action` transition behavior, logical vs playback action state, and that `animation_finished` excludes transition bridges.
- `sprite-sheet-layout`: Document optional transition action folders named `{from}-{to}` using the same per-action pass layout as any other animated action.

## Impact

- **Shipped addon**: `AnimatedEntity` (`set_action`, animation timer loop, internal transition state); possibly minor README note on folder naming.
- **Lookup**: No API change — existing `get_frame_count` / `get_texture` resolve transition folders by action name like any other action.
- **Bodies / gameplay**: No changes required; `PlayerEntity` and similar callers keep comparing `action` to desired state.
- **Tests**: Add or extend presenter tests for transition present, absent, and interrupt paths.
- **Non-goals**: Reverse/symmetric clip inference, transitions from arbitrary mid-frame poses, editor preview of transition clips, changes to direction transition spec.

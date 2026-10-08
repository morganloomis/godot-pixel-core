## Why

Isometric billboard sprites benefit from **ground contact shadows** that stretch with light angle and preserve leg separation — without 3D casters or full-body silhouette shadows. Artists already ship per-pass sheets (`diffuse.png`, `normal.png`, etc.); an optional **height / contact field** pass, smeared at runtime along the light direction, may deliver that look cheaply in 2D.

Prior in-flight work (`sprite-shadows`, `rebase-sprite-shadows-on-per-pass-layout`) explored the same idea under `contact.png` naming and fuller integration. This change is a **deliberately lightweight spike**: prove the technique in the current `AnimatedEntity` + per-pass layout, keep it **opt-in and isolated**, and accept that the result may be **kept, reworked, merged into `sprite-shadows`, or removed**.

## What Changes

- Add an **experimental, default-off** ground-shadow path on `AnimatedEntity`: a child `Sprite2D` with a custom `canvas_item` shader, separate from engine 2D normal lighting on the body sprite.
- Introduce an **optional** per-action spritesheet pass (filename TBD in design — `shadow.png`, `height.png`, or `contact.png`) on the same 8-direction × N-frame grid as `diffuse.png`, encoding **ground-plane height / contact** (bright = planted feet, dimmer = higher body).
- Extend `SpriteSheetLookupBase.SpriteSheetPass` with a new enum value for the pass; missing file = no shadow, no error (same rules as `normal.png`).
- Prototype shader: sample the pass and **gather or smear** darkness along a 2D `smear_dir` uniform with **height-dependent length and blur**; shadow draws **unshaded** under the character (`blend_mul` or equivalent) and does **not** use `CanvasTexture` or `LightOccluder2D`.
- Wire `smear_dir` and shadow length from a scene `DirectionalLight2D` (with optional manual override); one directional “sun” is sufficient for the spike.
- Add a minimal **test-scene scenario** with one placeholder frame so rotating the light visibly changes shadow direction and length.
- Document encoding convention, draw-order notes, and spike limitations in `design.md`.

## Capabilities

### New Capabilities

- `sprite-height-shadow-spike`: Experimental optional height/contact pass, lookup enum, default-off `AnimatedEntity` shadow child, directional smear shader, and test-scene validation criteria. Explicitly **provisional** — not a committed long-term rendering contract.

### Modified Capabilities

- `test-scene`: Add scenarios that exercise the spike when enabled; existing scenarios unchanged when disabled.

## Impact

- **Addon** (`addons/godot-pixel-core/`): small additive surface — new pass enum, optional shadow child + shader, exports gated behind `use_ground_shadow` (or equivalent). **No change** to default lit/unlit sprite behavior when the flag is off.
- **OpenSpec**: new change only; does not archive or merge `sprite-shadows` yet. Outcome may inform or supersede that work.
- **Test** (`test/`): optional placeholder pass art and test-scene wiring for manual visual check; code-only tasks otherwise.
- **Consumers** (e.g. Untombed): **no integration required**; submodule update only after explicit approval.
- **Verification**: existing test scene / smoke path must pass with spike **disabled**; enabled path is manual visual validation.

## Non-goals

- Tight integration into consumer game scenes or gameplay systems.
- Full art pipeline across all entities, actions, directions, and frames.
- `PointLight2D` or multi-light shadow fusion.
- Modifying the lit `CanvasTexture` / normal-map path or tile lighting.
- Production y-sort tuning, floor-shader compositing, or final art-direction tuning.
- Committing to this technique long-term; all spike code should be **easy to delete**.
- Resolving naming overlap with `sprite-shadows` / `contact.png` in this proposal — deferred to `design.md`.
- Replacing Godot `LightOccluder2D` shadows or implementing crisp full-body cast shadows.

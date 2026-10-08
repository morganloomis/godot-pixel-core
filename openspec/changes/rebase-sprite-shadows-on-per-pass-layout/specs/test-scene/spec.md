# Spec Delta: test-scene

## MODIFIED Requirements

### Requirement: Foot-shadow demonstrator on the player

When the foot-shadow feature lands, the test scene SHALL exercise it on the existing `PlayerEntity` instance using the `"player"` test entity (consistent with the `align-test-scene-with-player-art` change). A `contact.png` sample MAY live under `test/art/sprite/player/{action}/contact.png` to drive the demo; if no contact art is available, the test scene SHALL still load and the foot-shadow node SHALL gracefully render nothing (consistent with `sprite-contact-shadow-mask` → "Missing contact file disables mask").

#### Scenario: Foot-shadow attached without breaking existing tests

- **WHEN** the test scene runs after foot shadows are implemented
- **THEN** the existing `PlayerEntity` walk/idle scenarios SHALL still pass (the body sprite still resolves from `res://test/art/sprite/player/...` and reacts to `DirectionalLight2D` and `PointLight2D`)

#### Scenario: Smear direction derived from scene light

- **WHEN** the test scene runs with one `DirectionalLight2D` and at least one foot-shadow consumer
- **THEN** the shader's `smear_dir` SHALL track that light's rotation, projected onto the canvas plane per `sprite-directional-foot-shadow`

#### Scenario: Contact art optional

- **WHEN** no `contact.png` exists under `test/art/sprite/player/{action}/` for an action the player can enter
- **THEN** the scene SHALL still load and the foot-shadow node SHALL behave as documented for the "missing contact" case, without errors or `_ERROR` logs

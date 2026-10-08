## ADDED Requirements

### Requirement: Presenter exposes set_action with optional transition bridge

The animated sprite presenter (`AnimatedEntity` or documented successor) SHALL expose `set_action(new_action: String)` for gameplay and body scripts to request a **logical** action change. When a `{previous}-{new_action}` transition clip exists per `animated-action-transition`, the presenter SHALL play that bridge once before beginning `new_action`; otherwise it SHALL switch immediately. Bodies SHALL NOT implement transition discovery themselves.

#### Scenario: Body requests action via set_action

- **WHEN** a parent body calls `set_action("walk")` on the presenter at runtime while the logical action was `idle`
- **THEN** the presenter SHALL apply `animated-action-transition` rules and SHALL begin showing `walk` (directly or after an optional `idle-walk` bridge)

#### Scenario: Body code unchanged when transitions added

- **WHEN** `PlayerEntity` compares `animated_entity.action` to a desired action and calls `set_action` only on mismatch
- **THEN** no body script changes SHALL be required for transition clips to work

---

### Requirement: action property reflects logical target action

The public `action` property SHALL reflect the **logical/target** action requested by gameplay (e.g. `walk`, `idle`, `die`), not the internal transition folder name (e.g. `idle-walk`) while a bridge is on screen. Texture lookup during a bridge MAY use an internal playback action name; that internal name SHALL NOT be exposed via `action`.

#### Scenario: action reads target during bridge

- **WHEN** an `idle-walk` bridge is visible and the logical target is `walk`
- **THEN** reading `action` SHALL return `walk`

#### Scenario: Gameplay avoids re-entrant set_action

- **WHEN** a body holds the player on `walk` while an `idle-walk` bridge is playing
- **THEN** comparing `animated_entity.action == "walk"` SHALL be true so the body does not call `set_action("walk")` every frame

---

### Requirement: Sprite lookup uses playback action during action transitions

`update_sprite()` and lit-mode normal alignment SHALL resolve `get_texture` using the presenter's **playback** action (logical action normally, or `{from}-{to}` during a bridge) together with the **displayed** facing and current frame index. Each action-transition frame advance SHALL trigger a sprite refresh.

#### Scenario: Bridge folder supplies diffuse during transition

- **WHEN** an `idle-walk` bridge is playing at frame 1 and displayed facing is **SE**
- **THEN** the child `Sprite2D` SHALL show the **SE** row, frame 1, from the `idle-walk` action folder

#### Scenario: Handoff uses target action folder

- **WHEN** an `idle-walk` bridge completes and logical `action` is `walk`
- **THEN** the next `update_sprite()` SHALL resolve textures from the `walk` action folder at frame 0

---

### Requirement: animation_finished applies to terminal logical actions only

The presenter signal `animation_finished(action_name: String)` SHALL emit only when a **logical** action configured with `PlaybackMode.PLAY_ONCE` completes. It SHALL NOT emit when an internal `{from}-{to}` transition clip completes.

#### Scenario: Transition bridge does not emit

- **WHEN** an `idle-walk` transition clip finishes and hands off to looping `walk`
- **THEN** `animation_finished` SHALL NOT emit

#### Scenario: Terminal logical action emits

- **WHEN** logical action `die` uses `PlaybackMode.PLAY_ONCE` and the last frame of `die` is reached
- **THEN** `animation_finished` SHALL emit with `die` as the action name

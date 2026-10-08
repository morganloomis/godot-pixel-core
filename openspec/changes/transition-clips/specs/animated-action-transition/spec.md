## ADDED Requirements

### Requirement: Transition clip discovery by from-to naming

When `set_action(new_action)` is called at runtime and the previous **logical** action differs from `new_action`, the presenter SHALL construct a transition name `{previous}-{new_action}` (e.g. `idle-walk`) and SHALL treat the clip as available when `get_frame_count(entity, transition_name) > 0` for the presenter's entity id. The `{previous}` value SHALL be the logical action immediately before the call, never an internal transition folder name.

#### Scenario: Transition clip found and queued

- **WHEN** the logical action is `idle`, `set_action("walk")` is called, and `{entity}/idle-walk/diffuse.png` yields a valid frame count
- **THEN** the presenter SHALL begin playback using the `idle-walk` folder before starting the `walk` logical action

#### Scenario: Missing transition clip falls through

- **WHEN** the logical action is `idle`, `set_action("walk")` is called, and `get_frame_count(entity, "idle-walk")` is 0
- **THEN** the presenter SHALL begin `walk` immediately from frame 0 with no bridge clip

---

### Requirement: Transition clip plays once then hands off to target

While playing a transition clip, the presenter SHALL advance one frame per animation timer tick at the current `frame_rate`. When the last frame of the transition clip is shown, the presenter SHALL start the **logical** target action from frame 0 and SHALL continue the animation timer according to that action's `playback_modes` entry.

#### Scenario: Bridge completes into looping target

- **WHEN** an `idle-walk` transition with three frames finishes on frame index 2 and the logical action is `walk` with default LOOP mode
- **THEN** the presenter SHALL show `walk` frame 0 on the next timer tick and SHALL continue looping `walk` frames

#### Scenario: Each transition frame shown once

- **WHEN** a transition clip has N frames and no interrupt occurs
- **THEN** the presenter SHALL display frames 0 through N−1 exactly once in order before handoff

---

### Requirement: Transition playback is not terminal PLAY_ONCE

Transition clip playback SHALL NOT use `PlaybackMode.PLAY_ONCE` semantics. Completing a transition clip SHALL NOT stop the animation timer, SHALL NOT set terminal clip-finished state, and SHALL NOT emit `animation_finished`. `PLAY_ONCE` remains reserved for **logical** actions that permanently end animation (e.g. death).

#### Scenario: Transition completion keeps timer running

- **WHEN** the last frame of an `idle-walk` transition is displayed
- **THEN** the animation timer SHALL remain running and `animation_finished` SHALL NOT emit for `idle-walk`

#### Scenario: Terminal logical action still stops after bridge

- **WHEN** `set_action("die")` is called from `walk`, a `walk-die` transition plays, and logical `die` uses `PlaybackMode.PLAY_ONCE`
- **THEN** the presenter SHALL play `walk-die` once without terminal side effects, then play `die` under `PLAY_ONCE` rules including timer stop and `animation_finished` emission when `die` completes

---

### Requirement: Interrupt during transition skips new transition lookup

If `set_action` is called while a transition clip is playing, the presenter SHALL abandon the in-flight bridge immediately, SHALL NOT look up a transition name from the partial bridge toward the new target, and SHALL begin the newly requested logical action from frame 0.

#### Scenario: Mid-bridge action change snaps to new action

- **WHEN** an `idle-walk` transition is playing and `set_action("run")` is called before the bridge completes
- **THEN** the presenter SHALL show `run` frame 0 on the next update without playing `idle-run` or resuming `idle-walk`

---

### Requirement: Direction transitions remain independent

Action transition playback SHALL NOT disable or reset direction transition state. Direction steps per `animated-direction-transition` SHALL continue on the same animation timer ticks during action transition clips.

#### Scenario: Facing steps during action bridge

- **WHEN** an action transition clip is playing and a multi-step direction transition is active
- **THEN** the presenter SHALL advance the displayed facing on timer ticks while showing transition-clip frames for the current frame index

#### Scenario: Action change preserves direction transition

- **WHEN** a multi-step direction transition is active and `set_action` triggers an action transition clip
- **THEN** displayed and target facings SHALL be unchanged and direction stepping SHALL continue until the target facing is reached

---

### Requirement: Redundant set_action to same logical target is a no-op during bridge

If `set_action(new_action)` is called while an action transition is in progress toward the same logical `new_action` already stored in `action`, the presenter SHALL NOT restart the bridge or reset the frame index.

#### Scenario: Repeated walk request during idle-walk bridge

- **WHEN** logical `action` is already `walk`, an `idle-walk` bridge is playing, and `set_action("walk")` is called again
- **THEN** the presenter SHALL continue the current bridge from its current frame without restarting `idle-walk` from frame 0

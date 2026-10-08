## ADDED Requirements

### Requirement: Multi-step turns use shortest ring path

When the presenter’s **displayed** facing and a newly requested **target** facing differ by **two or more steps** on the canonical eight-direction ring (**S, SE, E, NE, N, NW, W, SW** per `sprite-sheet-facing`), the presenter SHALL advance the displayed facing **one ring step per animation frame** along the **shortest** clockwise or counter-clockwise arc until the displayed facing equals the target. Ring distance SHALL be measured as the minimum of clockwise and counter-clockwise step counts between direction indices 0–7.

#### Scenario: Sharp turn steps through intermediates

- **WHEN** the displayed facing is **W** and `set_direction("E")` is called at runtime
- **THEN** the presenter SHALL show each intermediate facing along the chosen shortest arc (e.g. **W → SW → S → SE → E** or **W → NW → N → NE → E**) for at least one animation frame each before settling on **E**

#### Scenario: Adjacent facing updates immediately

- **WHEN** the displayed facing is **E** and `set_direction("NE")` is called
- **THEN** the displayed facing SHALL become **NE** on the same update with no multi-frame transition

#### Scenario: Unchanged target is a no-op

- **WHEN** `set_direction` is called with the same facing as the current displayed facing
- **THEN** the presenter SHALL not start a transition and SHALL keep the current displayed facing

---

### Requirement: One hundred eighty degree ties choose a random path

When clockwise and counter-clockwise distances from the displayed facing to the target facing are **equal** (four steps each way on the eight-direction ring, e.g. **W** to **E**), the presenter SHALL choose **clockwise or counter-clockwise at random** for that transition and SHALL follow the chosen path one step per animation frame until the target is reached.

#### Scenario: Opposed facings use a random arc

- **WHEN** the displayed facing is **W**, the target facing is **E**, and `set_direction("E")` is called
- **THEN** the presenter SHALL follow either the clockwise or counter-clockwise four-step arc (not an instant snap) and SHALL use only one of those two arcs for that transition

---

### Requirement: Transition advances on the animation timer

Direction steps during a transition SHALL occur on the presenter’s existing animation frame timer (same cadence as `frame_rate`), advancing **at most one** ring step per timer tick. Transition speed SHALL therefore scale with animation framerate.

#### Scenario: Turn step aligns with frame tick

- **WHEN** a multi-step transition is active and the animation timer fires
- **THEN** the displayed facing SHALL advance by exactly one ring step (or complete the transition if the next step reaches the target) and `update_sprite()` SHALL reflect the new displayed facing for the current action and frame index

---

### Requirement: Interrupt restarts from displayed facing

If `set_direction` is called with a new target while a transition is in progress, the presenter SHALL abandon the previous arc, treat the **current displayed** facing as the new origin, recompute the shortest path (and re-roll random choice on 180° ties) toward the latest target, and continue stepping one facing per animation frame.

#### Scenario: Mid-turn input change retargets from current sprite facing

- **WHEN** the displayed facing is mid-arc between **W** and **E** (e.g. currently showing **SW**) and `set_direction("NE")` is called before **E** is reached
- **THEN** the presenter SHALL recompute the path from **SW** toward **NE** and SHALL not snap back to **W** or continue toward **E** unless **E** is later requested again

---

### Requirement: Transitions apply to all facing-based actions

Direction transition behavior SHALL apply regardless of the current `action` (e.g. walk, idle, or any other action that uses eight-direction sheet rows). Changing `action` during a transition SHALL NOT reset displayed or target facing; the transition SHALL continue on the new action’s rows at the same facings.

#### Scenario: Idle action participates in transition

- **WHEN** the presenter is on action `idle`, a multi-step transition is requested, and the animation timer advances
- **THEN** intermediate facings SHALL be read from the `idle` action rows until the target facing is reached

#### Scenario: Action change preserves transition state

- **WHEN** a multi-step transition is active and `set_action("walk")` is called before the target facing is reached
- **THEN** the displayed and target facings SHALL be unchanged and the transition SHALL continue using `walk` sheet rows on subsequent timer ticks

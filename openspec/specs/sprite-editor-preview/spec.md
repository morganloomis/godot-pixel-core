# Spec: Sprite editor preview

## Purpose

Define editor-only static sprite placeholder behavior on the animated presenter: which cell and action are shown, diffuse-only preview, refresh when `entity_name` changes (including character forwarding), and coexistence with play mode.

## Requirements

### Requirement: Editor-only static placeholder

The addon SHALL show a **static** sprite-sheet placeholder on the animated presenter’s child **`Sprite2D`** when running **in the Godot editor** (e.g. `Engine.is_editor_hint()` or documented equivalent). The placeholder SHALL **not** advance frames for preview purposes and SHALL **not** cycle **direction** for preview purposes. While the scene runs in **play mode**, visible sprite updates SHALL follow existing presenter runtime rules; this capability SHALL **not** override normal playback there.

#### Scenario: Play mode unchanged

- **WHEN** the scene runs in play mode (editor hint false)
- **THEN** the presenter SHALL update the drawable per existing action, direction, frame, and lit/unlit rules without the editor placeholder semantics replacing that behavior

#### Scenario: Editor shows one fixed cell

- **WHEN** the presenter is displayed in the editor viewport and a valid preview sheet is resolved for the entity
- **THEN** the drawable SHALL show a **single** cell image (no editor-time animation loop required for this capability)

---

### Requirement: Preview action selection

Editor preview SHALL choose an **action** by trying **`idle` first**: if **`idle`** yields a **valid animated diffuse grid** for the resolved entity, that action SHALL be used. If **`idle`** is not valid, the implementation SHALL choose the **first action name in alphabetical order (A→Z)** among action folders under that entity that yields a valid diffuse grid. Preview selection SHALL **not** depend on the presenter’s runtime **`action`** property.

#### Scenario: Idle preferred when valid

- **WHEN** the entity has a valid **`idle`** diffuse sheet per animated layout rules
- **THEN** the editor preview SHALL use the **`idle`** action for the placeholder cell

#### Scenario: Alphabetical fallback when idle is invalid

- **WHEN** **`idle`** is missing or invalid but at least one other action folder has a valid diffuse grid
- **THEN** the editor preview SHALL use the **first** such action name in **A→Z** order

---

### Requirement: Preview cell geometry

The editor placeholder SHALL use the **top-left** cell of the chosen diffuse sheet: the **south (S)** direction row and **frame index zero**, consistent with **`SpriteSheetLookupBase`** direction ordering and animated **`compute_rect_animated`** semantics used at runtime.

#### Scenario: Cell matches animated grid origin

- **WHEN** a valid preview diffuse sheet is loaded for the chosen action
- **THEN** the placeholder SHALL show the atlas region for **S** and frame **0** per project animated sheet layout

---

### Requirement: Diffuse-only preview in editor

For the editor placeholder path, the presenter SHALL assign **diffuse-only** presentation to the child **`Sprite2D`** (e.g. an **`AtlasTexture`** from **`diffuse.png`**). It SHALL **not** be required to bind normal, height or other pass sheets, or to apply engine-lit materials, **for this editor preview**.

#### Scenario: Lit export does not require lit editor preview

- **WHEN** the presenter has runtime **lit mode** enabled
- **THEN** the editor placeholder MAY still use diffuse-only atlas for the viewport unless a future spec extends this requirement

---

### Requirement: Entity identifier and refresh scope (v1)

Editor preview SHALL resolve the entity folder using the same **entity_name** rules as **`AnimatedEntity`** (exported **`entity_name`**, with fallback to the presenter node’s name when documented). The preview SHALL update when **`entity_name`** changes on **`AnimatedEntity`**. When **`CharacterEntity.entity_name`** is set and forwarded to the child presenter, the child’s preview SHALL update accordingly. For v1, the implementation SHALL **not** be required to subscribe to **EditorFileSystem** or similar solely to refresh when sheet files change on disk.

#### Scenario: Presenter export drives preview

- **WHEN** the author changes **`entity_name`** on **`AnimatedEntity`** in the editor
- **THEN** the editor preview SHALL re-resolve sheets and update if valid art exists

#### Scenario: Character forwarding drives preview

- **WHEN** the author changes **`entity_name`** on **`CharacterEntity`** and the value is forwarded to the child **`AnimatedEntity`**
- **THEN** the child presenter’s editor preview SHALL update to match the new entity when valid sheets exist

#### Scenario: Disk-only change without property change

- **WHEN** a diffuse or other sheet file changes on disk and **`entity_name`** (and forwarding path) is unchanged
- **THEN** the implementation MAY leave the editor preview stale until the author retriggers refresh (e.g. nudging **`entity_name`**, reloading the scene, or another documented trigger); this SHALL be acceptable for v1

---

### Requirement: Graceful failure when no valid sheet

If **no** action yields a valid animated diffuse grid for the resolved entity, the editor preview path SHALL **not** require blocking error UI; the drawable MAY keep its previous texture or appear empty.

#### Scenario: Missing or invalid entity art

- **WHEN** no action folder under the entity produces a valid diffuse grid
- **THEN** the preview logic SHALL no-op or fail silently without mandatory error dialogs

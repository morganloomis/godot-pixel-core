## 1. Setup

- [x] 1.1 Create animated entity script (e.g. `animated_entity.gd`) under `addons/entity/` extending Node2D with class_name
- [x] 1.2 Add child Sprite2D and Timer node references (by path or @onready); ensure script expects or creates them

## 2. Animation state and display

- [x] 2.1 Add exported entity_id (String), defaulting to node name; add readable/writable action and direction (String or compatible)
- [x] 2.2 Create or accept sprite-sheet lookup in _ready(); default to AnimatedSpriteSheetLookup, allow override for tests/subclasses
- [x] 2.3 Implement update_sprite(): resolve texture from lookup (entity_id, action, direction, frame) and set sprite texture; call when state or frame changes
- [x] 2.4 Expose current frame as readable (getter or var) for debugging/sync

## 3. Frame rate and timer

- [x] 3.1 Add exported frame_rate (float), default 12.0; wire timer wait_time to 1.0 / frame_rate (or equivalent)
- [x] 3.2 Start timer in _ready() and connect timeout to frame-advance handler
- [x] 3.3 In timeout handler: get frame count from lookup for current entity and action; advance frame according to playback mode (see 4.x), then call update_sprite()

## 4. Playback modes

- [x] 4.1 Define playback mode enum or constants: Loop, PlayOnce, HoldLastFrame
- [x] 4.2 Add per-action playback mode config (e.g. dictionary action name → mode); default to Loop when action has no entry
- [x] 4.3 In frame-advance logic: if at last frame and mode is Loop, set frame to 0; if mode is PlayOnce or HoldLastFrame, do not advance past last frame (stop timer or no-op)
- [x] 4.4 Add signal animation_finished(action_name); emit when PlayOnce reaches last frame (and optionally when HoldLastFrame reaches last frame, per design)
- [x] 4.5 When action changes, reset frame to 0 and (if PlayOnce/HoldLastFrame was stopped) restart timer for the new action

## 5. Base scene (optional)

- [x] 5.1 Create optional base scene (e.g. `animated_entity.tscn`) with root Node2D using the base script, child Sprite2D, and child Timer
- [x] 5.2 Ensure scene node paths match what the script expects (e.g. "Sprite2D", "Timer")

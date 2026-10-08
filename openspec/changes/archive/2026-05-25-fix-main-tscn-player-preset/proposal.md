## Why

`addons/godot-pixel-core/entity/characters/player.tscn` is documented in `README.md` as an optional preset that instances `player_entity.tscn` with tuned collision and sprite offsets. In practice the scene looks like this:

```10:19:addons/godot-pixel-core/entity/characters/player.tscn
[node name="player" unique_id=1365215088 instance=ExtResource("1_player")]
entity_name = "player"
movement_speed = 35.0
frame_rate = 18.0

[node name="player#AnimatedEntity" parent="." index="0" unique_id=1959227215 instance=ExtResource("2_gb0fi")]
```

The second `[node ...]` re-instances a fresh `animated_entity.tscn` next to the inherited `AnimatedEntity` child (or replaces it, depending on how Godot 4.6 interprets the `player#AnimatedEntity` name and `index="0"`). The override does not carry `use_2d_normal_lighting = true` or `entity_name = "player"`, so a consumer who instances this preset gets:

- a presenter that may not be lit even though the parent `player_entity.tscn` baked it lit, and
- a presenter that may resolve `res://sprite/animated/AnimatedEntity/...` instead of `.../player/...` if the inherited child has been replaced.

`main.tscn` uses this preset for its `Player`, which is why the dev harness's tile demo currently does not show a working character beside the lit `LitTileMapLayer`.

The fix is small but worth specifying: either remove the second `[node ...]` block and rely on the inherited child, or convert it to a proper editable-instance override (no second `instance=`). At the same time, `sprite-presentation` should pick up a sentence explicitly forbidding re-instancing the inherited presenter in addon preset scenes.

## What Changes

- Repair `addons/godot-pixel-core/entity/characters/player.tscn` so it edits the inherited `AnimatedEntity` child via overrides rather than re-instancing `animated_entity.tscn`. The preset SHALL keep its tuned `CollisionShape2D` offset and capsule values.
- Add a clarifying scenario under `sprite-presentation` → "Non-character reuse" (or a new requirement nearby) that addon preset scenes built on `player_entity.tscn` must not introduce a second `AnimatedEntity` instance alongside the inherited one.
- After the preset is repaired, verify `main.tscn` shows the player rendered with lit mode under the existing `DirectionalLight2D` + `CanvasModulate`.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `sprite-presentation`: add a "Single presenter child per preset" requirement so character preset scenes that inherit `player_entity.tscn` (or `character_entity.tscn`) must not re-instance the inherited `AnimatedEntity` child.

## Impact

- **Addon**: `addons/godot-pixel-core/entity/characters/player.tscn` rewritten as a clean inherited scene with property overrides only.
- **Dev harness**: `main.tscn` not edited by this change — it consumes the preset and benefits transitively.
- **Risk**: low. Behavior of `player_entity.tscn` itself is unaffected; only the preset overlay changes. The new spec scenario formalizes existing intent.

extends SceneTree

## Headless checks for AnimatedEntity action transition clips. Run:
## Godot --headless --path . --script res://test/animated_entity_transition_test.gd

const AnimatedEntityScene := preload("res://addons/godot-pixel-core/entity/animated_entity.tscn")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_transition_present()
	_test_fall_through()
	_test_interrupt()
	_test_bridge_does_not_emit_finished()
	_test_play_once_emits_finished()
	_test_same_target_during_bridge_is_noop()

	if _failures.is_empty():
		print("animated_entity_transition_test: all passed")
		quit(0)
	else:
		for msg in _failures:
			push_error(msg)
		print("animated_entity_transition_test: %d failure(s)" % _failures.size())
		quit(1)


func _fail(message: String) -> void:
	_failures.append(message)


func _lookup(overrides: Dictionary) -> AnimatedSpriteSheetLookup:
	var lookup := AnimatedSpriteSheetLookup.new()
	lookup.frame_count_override = overrides
	return lookup


func _spawn(lookup: AnimatedSpriteSheetLookup) -> AnimatedEntity:
	var entity := AnimatedEntityScene.instantiate() as AnimatedEntity
	entity.sprite_lookup = lookup
	entity.entity_name = "test_entity"
	entity.action = "idle"
	root.add_child(entity)
	return entity


func _test_transition_present() -> void:
	var entity := _spawn(_lookup({
		"test_entity:idle": 4,
		"test_entity:walk": 6,
		"test_entity:idle-walk": 3,
	}))
	entity.set_action("walk")
	if entity.action != "walk":
		_fail("transition present: action should be walk, got %s" % entity.action)
	if entity._playback_action != "idle-walk":
		_fail("transition present: _playback_action should be idle-walk, got %s" % entity._playback_action)
	if not entity._in_action_transition:
		_fail("transition present: _in_action_transition should be true")
	entity.free()


func _test_fall_through() -> void:
	var entity := _spawn(_lookup({
		"test_entity:idle": 4,
		"test_entity:walk": 6,
	}))
	entity.set_action("walk")
	if entity.action != "walk":
		_fail("fall-through: action should be walk")
	if entity._playback_action != "walk":
		_fail("fall-through: _playback_action should be walk immediately, got %s" % entity._playback_action)
	if entity._in_action_transition:
		_fail("fall-through: _in_action_transition should be false")
	entity.free()


func _test_interrupt() -> void:
	var entity := _spawn(_lookup({
		"test_entity:idle": 4,
		"test_entity:walk": 6,
		"test_entity:run": 4,
		"test_entity:idle-walk": 3,
	}))
	entity.set_action("walk")
	entity._on_animation_timeout()
	if entity._playback_action != "idle-walk":
		_fail("interrupt setup: expected idle-walk playback")
	entity.set_action("run")
	if entity.action != "run":
		_fail("interrupt: action should be run")
	if entity._playback_action != "run":
		_fail("interrupt: _playback_action should be run, got %s" % entity._playback_action)
	if entity._in_action_transition:
		_fail("interrupt: _in_action_transition should be false")
	if entity.frame != 0:
		_fail("interrupt: frame should reset to 0")
	entity.free()


func _test_bridge_does_not_emit_finished() -> void:
	var entity := _spawn(_lookup({
		"test_entity:idle": 4,
		"test_entity:walk": 6,
		"test_entity:idle-walk": 3,
	}))
	var finished_actions: Array[String] = []
	entity.animation_finished.connect(func(action_name: String) -> void:
		finished_actions.append(action_name)
	)
	entity.set_action("walk")
	for _i in 3:
		entity._on_animation_timeout()
	if not finished_actions.is_empty():
		_fail("bridge complete: animation_finished should not emit, got %s" % str(finished_actions))
	if entity._in_action_transition:
		_fail("bridge complete: should hand off to walk")
	if entity._playback_action != "walk":
		_fail("bridge complete: _playback_action should be walk, got %s" % entity._playback_action)
	if entity.animation_timer.is_stopped():
		_fail("bridge complete: timer should keep running into walk loop")
	entity.free()


func _test_play_once_emits_finished() -> void:
	var entity := _spawn(_lookup({
		"test_entity:idle": 4,
		"test_entity:die": 2,
	}))
	entity.set_playback_mode("die", AnimatedEntity.PlaybackMode.PLAY_ONCE)
	var finished_actions: Array[String] = []
	entity.animation_finished.connect(func(action_name: String) -> void:
		finished_actions.append(action_name)
	)
	entity.set_action("die")
	entity._on_animation_timeout()
	entity._on_animation_timeout()
	if finished_actions.size() != 1 or finished_actions[0] != "die":
		_fail("PLAY_ONCE: expected animation_finished('die'), got %s" % str(finished_actions))
	if not entity.animation_timer.is_stopped():
		_fail("PLAY_ONCE: timer should stop after terminal clip")
	entity.free()


func _test_same_target_during_bridge_is_noop() -> void:
	var entity := _spawn(_lookup({
		"test_entity:idle": 4,
		"test_entity:walk": 6,
		"test_entity:idle-walk": 3,
	}))
	entity.set_action("walk")
	entity._on_animation_timeout()
	var frame_before := entity.frame
	entity.set_action("walk")
	if entity.frame != frame_before:
		_fail("same target during bridge: frame should not reset")
	if entity._playback_action != "idle-walk":
		_fail("same target during bridge: should still play idle-walk")
	if not entity._in_action_transition:
		_fail("same target during bridge: transition should continue")
	entity.free()

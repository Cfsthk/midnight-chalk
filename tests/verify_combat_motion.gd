extends SceneTree

const BossArt = preload("res://ui/boss_art.gd")
const CombatFX = preload("res://ui/combat_fx.gd")

var _failed := false


func _initialize() -> void:
	call_deferred("_check")


func _expect(value: bool, description: String) -> void:
	if not value:
		_failed = true
		push_error(description)


func _check() -> void:
	var art := BossArt.new()
	var fx := CombatFX.new()
	root.add_child(art)
	root.add_child(fx)
	art.set_process(false)
	art.on_hit(false)
	var normal: float = art._ink.get_shader_parameter("impact")
	_expect(normal > 0.70 and art._hit_offset().x == 0.0, "The normal hit immediately lights the sprite")
	art._process(art.NORMAL_HIT_TIME * 0.7)
	_expect(float(art._ink.get_shader_parameter("impact")) < normal, "The normal tint fades")
	art._process(art.NORMAL_HIT_TIME)
	_expect(is_zero_approx(art._ink.get_shader_parameter("impact")), "The original palette is restored")

	art.on_hit(true)
	_expect(float(art._ink.get_shader_parameter("impact")) > normal, "The heavy flash has a stronger peak")
	var first := art._hit_offset()
	art._process(art.HEAVY_HIT_TIME * 0.16)
	var second := art._hit_offset()
	_expect(first.x * second.x < 0.0 and absf(second.x) < absf(first.x), "A heavy hit shakes sideways and settles")
	art.on_hit(false)
	_expect(art._heavy_hit, "A rapid normal follow-up preserves the heavy reaction")
	art.set_frozen(true)
	art._process(1.0)
	_expect(second == art._hit_offset(), "Hit motion freezes when paused")
	art.set_frozen(false)

	art.reset_combat_pose()
	art.on_fire(true, Vector2(8, 3))
	_expect(art._aim.is_equal_approx(Vector2(8, 3).normalized()), "Shooting aims at the current player location")
	art._process(art.FIRE_TIME * 0.24)
	_expect(art._fire_offset() > 0.99, "The firing foe lunges forward")
	art._process(art.FIRE_TIME * 0.46)
	_expect(art._fire_offset() < -0.20, "The firing pose recoils behind its resting position")
	art._process(art.FIRE_TIME)
	_expect(is_zero_approx(art._fire_offset()), "Recoil returns to rest")

	art.on_hit(true)
	art.on_defeat()
	_expect(art._heavy_hit and art._impact_left == art.HEAVY_HIT_TIME, "Defeat preserves the lethal shot's impact")
	art._process(art.BREAK_START + 0.05)
	var breakup: float = art._defeat_elapsed
	art.on_defeat()
	art.on_fire(true)
	art.set_frozen(true)
	art._process(1.0)
	_expect(art._defeat_elapsed == breakup and art._fire_left == 0.0, "A paused breakup cannot replay or shoot")
	art.set_frozen(false)
	art._process(art.DEFEAT_DURATION)
	_expect(art._defeat_elapsed == art.DEFEAT_DURATION, "The short shatter reaches its empty final frame")
	art.reset_combat_pose()
	_expect(art._defeat_elapsed < 0.0 and art._hit_offset() == Vector2.ZERO, "A rematch starts with a clean sprite")

	fx.set_player_region(Rect2(540, 210, 220, 340))
	fx.impact(true, true, 0)
	fx.impact(true, true, 3)
	_expect(fx._impacts[0].blocked and not fx._impacts[1].blocked, "A shield intercept and an HP hit have different impact effects")
	fx.advance(0.5)
	_expect(fx._impacts.is_empty(), "The local damage flash ends with the heavy impact")
	art.free()
	fx.free()
	print("Combat motion: ", "FAIL" if _failed else "PASS")
	quit(1 if _failed else 0)

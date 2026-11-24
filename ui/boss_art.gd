extends Control

const SPRITE_SIZE := Vector2(100, 74)
const HIT_TINT := preload("res://ui/boss_hit.gdshader")
const NORMAL_HIT_TIME := 0.24
const HEAVY_HIT_TIME := 0.37
const FIRE_TIME := 0.39
const DEFEAT_DURATION := 0.68
const BREAK_START := 0.16
const SHAKE_X := [5.0, -4.6, 3.8, -2.8, 1.8, -1.0, 0.5, 0.0]

var family := ""
var stage_form := 0
var _sprite: Texture2D

var _idle_time := 0.0
var _animation_frame := -1
var _impact_left := 0.0
var _fire_left := 0.0
var _heavy_fire := false
var _heavy_hit := false
var _aim := Vector2(0.8, 0.6)
var _defeat_elapsed := -1.0
var _frozen := false
var _ink: ShaderMaterial


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink = ShaderMaterial.new()
	_ink.shader = HIT_TINT
	material = _ink


func show_form(family_id: String, form: int) -> void:
	if family_id != family or form != stage_form:
		family = family_id
		stage_form = form
		var path := "res://assets/bosses/stages/%s/s%d.png" % [family, stage_form]
		_sprite = load(path) as Texture2D
	reset_combat_pose()


func set_frozen(value: bool) -> void:
	_frozen = value


func reset_combat_pose() -> void:
	_idle_time = 0.0
	_animation_frame = -1
	_impact_left = 0.0
	_fire_left = 0.0
	_heavy_hit = false
	_heavy_fire = false
	_defeat_elapsed = -1.0
	_refresh_tint()
	queue_redraw()


func on_hit(heavy: bool = false) -> void:
	if _defeat_elapsed >= 0.0:
		return
	# A normal follow-up must not cut short a stronger hit already on screen.
	if _heavy_hit and not heavy and _impact_left > NORMAL_HIT_TIME:
		return
	_heavy_hit = heavy
	_impact_left = HEAVY_HIT_TIME if heavy else NORMAL_HIT_TIME
	_refresh_tint()
	queue_redraw()


func on_fire(heavy: bool, aim_direction := Vector2(0.8, 0.6)) -> void:
	if _defeat_elapsed >= 0.0:
		return
	if not aim_direction.is_zero_approx():
		_aim = aim_direction.normalized()
	_fire_left = FIRE_TIME
	_heavy_fire = heavy
	queue_redraw()


func on_defeat() -> void:
	if _defeat_elapsed >= 0.0:
		return
	# Keep the lethal hit's flash before the sprite breaks into its own coloured chips.
	if _impact_left <= 0.0:
		on_hit(false)
	_defeat_elapsed = 0.0
	_fire_left = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if _frozen or not is_visible_in_tree() or _defeat_elapsed >= DEFEAT_DURATION:
		return
	var reacting := _impact_left > 0.0 or _fire_left > 0.0 or _defeat_elapsed >= 0.0
	if _defeat_elapsed >= 0.0:
		_defeat_elapsed = minf(DEFEAT_DURATION, _defeat_elapsed + delta)
	else:
		_idle_time += delta
	_impact_left = maxf(0.0, _impact_left - delta)
	_fire_left = maxf(0.0, _fire_left - delta)
	var frame := floori(_idle_time * 12.0)
	if reacting or frame != _animation_frame:
		_animation_frame = frame
		_refresh_tint()
		queue_redraw()


func _refresh_tint() -> void:
	if not _ink:
		return
	var duration := HEAVY_HIT_TIME if _heavy_hit else NORMAL_HIT_TIME
	var t := 1.0 - _impact_left / duration
	var strength := (0.96 if _heavy_hit else 0.78) * (1.0 - smoothstep(0.26, 1.0, t))
	_ink.set_shader_parameter("impact", strength)
	_ink.set_shader_parameter("hit_color", Color("#fff0bd") if _heavy_hit else Color("#dbfff1"))


func _fire_offset() -> float:
	if _fire_left <= 0.0:
		return 0.0
	var t := 1.0 - _fire_left / FIRE_TIME
	if t < 0.24:
		return 1.0 - pow(1.0 - t / 0.24, 2.0)
	if t < 0.70:
		return lerpf(1.0, -0.24, smoothstep(0.24, 0.70, t))
	return -0.24 * (1.0 - smoothstep(0.70, 1.0, t))


func _hit_offset() -> Vector2:
	if _impact_left <= 0.0:
		return Vector2.ZERO
	if not _heavy_hit:
		return Vector2.UP * 1.4 * _impact_left / NORMAL_HIT_TIME
	var phase := 1.0 - _impact_left / HEAVY_HIT_TIME
	var step := mini(SHAKE_X.size() - 1, floori(phase * SHAKE_X.size()))
	return Vector2(SHAKE_X[step], -2.2 * (1.0 - phase))


func _draw() -> void:
	if not _sprite or size.x < 4.0 or size.y < 4.0 or _defeat_elapsed >= DEFEAT_DURATION:
		return
	# Keep fractional viewports filled, with nearest-neighbour sampling on the pixel grid.
	var unit := minf(size.x / SPRITE_SIZE.x, size.y / (SPRITE_SIZE.y + 5.0))
	var tick := floorf(_idle_time * 12.0) / 12.0
	var centre := size * Vector2(0.5, 0.47)
	var pose := Vector2.ZERO
	var stretch := Vector2.ONE
	match family:
		"armour":
			pose.y = roundf(0.85 * sin(tick * 2.5))
			stretch.y += 0.012 * sin(tick * 2.5)
		"bell":
			pose = Vector2(roundf(1.1 * sin(tick * 2.7)), roundf(1.6 * sin(tick * 2.2)))
		"ink_fox":
			pose = Vector2(roundf(sin(tick * 1.9)), roundf(sin(tick * 2.3)))
			stretch.y += 0.015 * sin(tick * 2.3)
		"lantern_koi":
			pose = Vector2(roundf(2.1 * sin(tick * 2.1)), roundf(1.8 * cos(tick * 2.1)))
			stretch.x += 0.020 * sin(tick * 2.1)
		_:
			pose = Vector2(roundf(1.8 * sin(tick * 1.9)), roundf(2.2 * sin(tick * 2.6)))
			stretch.x += 0.037 * sin(tick * 3.0)
	var thrust := _fire_offset()
	pose += _aim * thrust * (13.0 if _heavy_fire else 9.0)
	stretch += Vector2(0.05, -0.045) * thrust
	pose += _hit_offset()

	var breakup := clampf((_defeat_elapsed - BREAK_START) / (DEFEAT_DURATION - BREAK_START), 0.0, 1.0)
	var shadow_centre := Vector2(size.x * 0.5 + pose.x * unit * 0.20, centre.y + unit * 37.5).round()
	var shadow_radius := (17.0 + pose.y * 0.32) * unit * (1.0 - breakup)
	draw_rect(Rect2(shadow_centre - Vector2(shadow_radius, unit), Vector2(shadow_radius * 2.0, unit * 2.0)), Color("#262130"))
	draw_rect(Rect2(shadow_centre - Vector2(shadow_radius * 0.66, unit * 1.5), Vector2(shadow_radius * 1.32, unit * 3.0)), Color("#342b3c"))
	var drawn := (SPRITE_SIZE * unit * stretch).round()
	var rect := Rect2((centre + pose * unit - drawn * 0.5).round(), drawn)
	if breakup <= 0.0:
		draw_texture_rect(_sprite, rect, false)
	else:
		_draw_chips(_sprite, rect, breakup)


func _draw_chips(sprite: Texture2D, rect: Rect2, t: float) -> void:
	# Radial travel and shrink are sampled in sprite pixels so even the armoured
	# rematch keeps its own outline and palette as it crumbles.
	var zoom := rect.size / SPRITE_SIZE
	var travel := 1.0 - pow(1.0 - t, 2.0)
	var shrink := 1.0 - smoothstep(0.05, 1.0, t)
	var tint := Color(1.0, 1.0, 1.0, 1.0 - smoothstep(0.57, 1.0, t))
	for y in range(0, int(SPRITE_SIZE.y), 10):
		for x in range(0, int(SPRITE_SIZE.x), 10):
			var region := Rect2(Vector2(x, y), Vector2(minf(10, SPRITE_SIZE.x - x), minf(10, SPRITE_SIZE.y - y)))
			var tile := region.get_center()
			var variation := sin(float(x * 3 + y * 7))
			var outward := (tile - SPRITE_SIZE * 0.5).normalized()
			var drift := outward * Vector2(18.0, 6.0) * (1.0 + 0.24 * variation) * travel
			drift.y += 8.0 * t * t - 5.0 * travel
			var chip_size := (region.size * zoom * shrink).round()
			if chip_size.x < 1.0 or chip_size.y < 1.0:
				continue
			var corner := (rect.position + (tile + drift) * zoom - chip_size * 0.5).round()
			draw_texture_rect_region(sprite, Rect2(corner, chip_size), region, tint)

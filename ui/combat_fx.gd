extends Control

# The run owns shot travel and damage. Auxiliary spark clocks advance only with battle time.
const CHALK := Color("#fffdf1")
const JADE := Color("#a3f6e0")
const JADE_SHADE := Color("#388272")
const GOLD := Color("#ffcc59")
const GOLD_SHADE := Color("#ad752d")
const ROSE := Color("#ff768c")
const ROSE_SHADE := Color("#a63f65")
const PINK := Color("#ffafcc")
const VIOLET := Color("#deacff")
const VIOLET_SHADE := Color("#8853b4")
const FIRE_EDGE := Color("#e99b24")
const FIRE_CORE := Color("#fff583")
const FLAME_STRIP := preload("res://assets/ready-flame.png")
const FLAME_HEIGHTS := [7, 6, 7, 8, 6, 8, 7, 6]
const CHARGE_FLIGHT := 0.48
const CHARGE_LIFE := 0.90

var _player_source := Vector2.ZERO
var _foe := Vector2.ZERO
var _player_target := Vector2.ZERO
var _player_region := Rect2()
var ink_target := Vector2.ZERO
var fire_target := Vector2.ZERO
var _reject_centre := Vector2.ZERO
var _energy_gauge := Rect2()
var _foe_gauge := Rect2()
var _special_button := Rect2()
var _heavy_ready := false
var _flame_time := 0.0
var _shots: Array[Dictionary] = []
var _impacts: Array[Dictionary] = []
var _transfers: Array[Dictionary] = []
var _had_projectiles := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func set_anchors(player_source: Vector2, foe: Vector2, player_target: Vector2) -> void:
	_player_source = player_source
	_foe = foe
	_player_target = player_target
	queue_redraw()


func set_player_region(rect: Rect2) -> void:
	_player_region = rect
	queue_redraw()


func set_charge_anchors(reject_centre: Vector2, gauge_rect: Rect2, foe_gauge: Rect2, special_button: Rect2) -> void:
	_reject_centre = reject_centre
	_energy_gauge = gauge_rect
	_foe_gauge = foe_gauge
	_special_button = special_button
	queue_redraw()


func sync_shots(projectiles: Array[Dictionary]) -> void:
	_shots = projectiles
	if _had_projectiles or not _shots.is_empty():
		queue_redraw()
	_had_projectiles = not _shots.is_empty()


func impact(from_foe: bool, heavy: bool, damage: int = 1) -> void:
	var blocked := from_foe and damage <= 0
	_impacts.append({"foe": from_foe, "heavy": heavy, "blocked": blocked,
		"age": 0.0, "life": 0.44 if heavy else 0.22})
	queue_redraw()


func charge_transfer() -> void:
	_transfers.append({"foe": false, "reject": true, "portion": 0.0, "age": 0.0})
	queue_redraw()


func foe_charge_transfer(from_reject: bool, portion: float) -> void:
	_transfers.append({"foe": true, "reject": from_reject, "portion": portion, "age": 0.0})
	queue_redraw()


func set_heavy_ready(ready: bool) -> void:
	if _heavy_ready == ready:
		return
	_heavy_ready = ready
	_flame_time = 0.0
	queue_redraw()


func advance(delta: float) -> void:
	var show_next_flame_frame := false
	if _heavy_ready:
		var last_frame := floori(_flame_time * 9.0)
		_flame_time = fmod(_flame_time + delta, 8.0)
		show_next_flame_frame = floori(_flame_time * 9.0) != last_frame
	if _impacts.is_empty() and _transfers.is_empty() and not show_next_flame_frame:
		return
	for index in range(_impacts.size() - 1, -1, -1):
		_impacts[index]["age"] += delta
		if _impacts[index]["age"] >= _impacts[index]["life"]:
			_impacts.remove_at(index)
	for index in range(_transfers.size() - 1, -1, -1):
		_transfers[index].age += delta
		if _transfers[index].age >= CHARGE_LIFE:
			_transfers.remove_at(index)
	queue_redraw()


func clear() -> void:
	_shots = []
	_impacts.clear()
	_transfers.clear()
	set_heavy_ready(false)
	_had_projectiles = false
	queue_redraw()


func _draw() -> void:
	var unit := clampf(minf(size.x / 390.0, size.y / 265.0), 1.45, 3.75)
	if _heavy_ready:
		_draw_flame_border()
	for transfer in _transfers:
		_draw_transfer(transfer, unit)
	for shot in _shots:
		var t := clampf(1.0 - float(shot["remaining"]) / maxf(0.001, float(shot["duration"])), 0.0, 1.0)
		var incoming := str(shot["source"]) != "player"
		if bool(shot["heavy"]):
			if incoming and shot.get("effect", {}).get("kind", "") == "ink":
				_draw_ink_drop(t, unit)
			elif incoming and shot.get("effect", {}).get("kind", "") == "incinerate":
				_draw_dragon_flame(t, unit)
			elif incoming and shot.get("effect", {}).is_empty():
				var centre := _path(t, true)
				for echo in range(3):
					var radius := (4 + echo * 3 + 2 * t) * unit
					_ring(centre, radius, unit, GOLD if echo % 2 == 0 else CHALK)
			elif incoming:
				_draw_enemy_heavy(t, unit)
			else:
				_draw_player_heavy(t, unit)
		else:
			_draw_dart(t, incoming, unit)
			if shot.get("empowered", false):
				var head := _path(t, incoming)
				_ring(head, 5.0 * unit, 1.2 * unit, GOLD)
				_diamond(head, 2.8 * unit, FIRE_CORE, unit)
	for hit in _impacts:
		var t := float(hit["age"]) / float(hit["life"])
		if hit.blocked:
			_ring(_player_target, (3.0 + t * 9.0) * unit, unit, Color(JADE, 1.0 - t))
			continue
		if hit.foe and hit.heavy:
			_draw_player_hit(t, unit)
		_draw_impact(t, bool(hit["foe"]), bool(hit["heavy"]), unit)


func _path(t: float, incoming: bool) -> Vector2:
	var start := _foe if incoming else _player_source
	var finish := _player_target if incoming else _foe
	var delta := finish - start
	var bend := delta.orthogonal().normalized() * clampf(delta.length() * 0.085, 6.0, 42.0)
	return start.lerp(finish, t) + bend * sin(PI * t)


func _draw_dart(t: float, incoming: bool, unit: float) -> void:
	var head := _path(t, incoming)
	var direction := (_path(t + 0.008, incoming) - head).normalized()
	var side := direction.orthogonal()
	var tint := ROSE if incoming else JADE
	var shade := ROSE_SHADE if incoming else JADE_SHADE
	for i in range(1, 5):
		var trail_t := t - 0.026 * i
		if trail_t > 0.0:
			_pixel(_path(trail_t, incoming), unit * (2.6 - i * 0.4), shade)
	# An ordinary strike is a single slim nib. The foe's has two small barbs.
	_stroke(head - direction * 6.0 * unit, head + direction * 3.0 * unit, unit * 2.2, tint)
	_stroke(head - direction * 1.3 * unit, head + direction * 4.0 * unit, unit * 1.15, CHALK)
	if incoming:
		for sign_value: float in [-1.0, 1.0]:
			_stroke(head, head + (side * sign_value * 2.2 - direction * 3.0) * unit, unit * 1.2, ROSE)


func _draw_player_heavy(t: float, unit: float) -> void:
	var head := _path(t, false)
	var direction := (_path(t + 0.008, false) - head).normalized()
	var side := direction.orthogonal()
	# Three separate gold lances flare along the sides of the white spearhead.
	for sign_value: float in [-1.0, 1.0]:
		for i in range(1, 9):
			var trail_t := t - i * 0.025
			if trail_t <= 0.0:
				continue
			var wake := _path(trail_t, false)
			var spread := (1.8 + sin(PI * i / 9.0) * 4.0) * unit * sign_value
			_pixel(wake + side * spread, unit * (3.7 - i * 0.24), GOLD if i < 5 else GOLD_SHADE)
		var fin_tip := head + (side * sign_value * 6.0 - direction * 3.0) * unit
		_stroke(fin_tip, head + direction * 7.0 * unit, unit * 2.9, GOLD)
	_stroke(head - direction * 12.0 * unit, head + direction * 8.0 * unit, unit * 4.9, GOLD_SHADE)
	_stroke(head - direction * 8.0 * unit, head + direction * 10.0 * unit, unit * 3.0, CHALK)
	_ring(head - direction * 9.0 * unit, (6.0 + fposmod(t * 13.0, 3.0)) * unit, unit, GOLD)


func _draw_ink_drop(t: float, unit: float) -> void:
	for i in range(4, -1, -1):
		var progress := maxf(0.0, t - i * 0.055)
		var pos := _foe.lerp(ink_target, progress)
		pos.y -= sin(progress * PI) * 32.0 * unit
		var side := maxf(1.0, 6.0 - i) * unit
		var color := VIOLET_SHADE if i > 0 else VIOLET
		draw_rect(Rect2(pos.round() - Vector2.ONE * side / 2.0, Vector2.ONE * side), color)
		if i == 0:
			draw_rect(Rect2(pos.round(), Vector2.ONE * unit * 2.0), CHALK)


func _draw_dragon_flame(t: float, unit: float) -> void:
	var heading := (fire_target - _foe).normalized()
	for i in range(14, -1, -1):
		var progress := maxf(0.0, t - i * 0.016)
		var centre := _foe.lerp(fire_target, progress) + Vector2.UP * sin(progress * PI) * 14.0 * unit
		var size_px := (8.0 - i * 0.42) * unit
		var wav := heading.orthogonal() * sin(progress * 17.0 + i * 0.4) * size_px * 0.50
		_diamond(centre + wav, size_px, Color("#a64d91"), unit)
		_diamond(centre + wav * 0.5, size_px * 0.67, Color("#ff9755"), unit)
		if i % 3 == 0:
			_pixel(centre, size_px * 0.70, Color("#fff0af"))


func _draw_enemy_heavy(t: float, unit: float) -> void:
	var head := _path(t, true)
	# A rotating, hollow eight-spoked mace remains recognizable against either HUD.
	for i in range(1, 6):
		var trail_t := t - i * 0.040
		if trail_t > 0.0:
			_diamond(_path(trail_t, true), (6.1 - i * 0.95) * unit, ROSE_SHADE, unit)
	var angle := floorf(t * 10.0) * PI / 16.0
	for ray in range(8):
		var direction := Vector2.from_angle(angle + ray * TAU / 8.0)
		var radius := (12.0 if ray % 2 == 0 else 8.0) * unit
		_stroke(head + direction * 3.8 * unit, head + direction * radius, unit * 2.5, ROSE)
		_pixel(head + direction * radius, unit * 1.3, PINK)
	_ring(head, unit * 5.1, unit * 2.0, PINK)
	_diamond(head, unit * 2.2, CHALK, unit)
	# The narrowing marker shows the target before the spiked shot arrives.
	if t < 0.88:
		var radius := (14.5 - t * 6.0) * unit
		for i in range(4):
			var d := Vector2.from_angle(PI / 4.0 + i * PI / 2.0)
			_pixel(_player_target + d * radius, unit * 2.4, ROSE)


func _draw_player_hit(t: float, unit: float) -> void:
	if not _player_region.has_area():
		return
	# One rose pulse within the player's gauges. Its edges fade with the HP hit.
	var strength := 1.0 - smoothstep(0.08, 0.93, t)
	var panel := _player_region.grow(-2.0 * unit)
	draw_rect(panel, Color(ROSE, 0.19 * strength))
	draw_rect(panel.grow(-unit), Color(PINK, 0.9 * strength), false, 2.0 * unit)


func _draw_impact(t: float, incoming: bool, heavy: bool, unit: float) -> void:
	var centre := _player_target if incoming else _foe
	var accent := ROSE if incoming else (GOLD if heavy else JADE)
	var rays := 12 if heavy else 4
	var reach := (3.0 + (1.0 - pow(1.0 - t, 2.0)) * (22.0 if heavy else 6.0)) * unit
	if heavy:
		_ring(centre, reach * 0.76, maxf(unit * 0.75, unit * 2.2 * (1.0 - t)), accent)
		if t > 0.16 and t < 0.78:
			_ring(centre, reach * (t + 0.2) * 0.60, unit, CHALK)
	for index in range(rays):
		var direction := Vector2.from_angle(TAU * index / rays - PI * 0.5)
		var outer := centre + reach * direction * (0.78 if index % 2 else 1.0)
		if heavy and t < 0.85:
			_stroke(outer - direction * unit * (5.0 - t * 3.0), outer, unit * 1.65, accent)
		_pixel(outer, unit * (2.2 - t), CHALK if index % 3 == 0 else accent)
	if t < 0.42:
		_diamond(centre, (1.0 - t / 0.42) * (7.0 if heavy else 2.6) * unit, CHALK, unit)


func _draw_flame_border() -> void:
	var rect := _special_button
	if not rect.has_area():
		return
	var p := maxf(1.0, floorf(minf(rect.size.x, rect.size.y) / 17.0))
	var frame := floori(_flame_time * 9.0)
	# All flames rise. Side tongues wrap the casing while the chosen icon stays clear.
	draw_rect(rect.grow(p * 1.5), FIRE_EDGE, false, p * 2.0)
	draw_rect(rect.grow(p * 0.5), FIRE_CORE, false, p)
	for i in range(4):
		var root := Vector2(rect.position.x + (i + 0.5) * rect.size.x / 4.0, rect.position.y + p)
		_draw_flame(root, p, frame, i, false)
	for side: int in [-1, 1]:
		var edge_x := rect.get_center().x + side * (rect.size.x * 0.5 + p * 1.6)
		for j in range(3):
			var root := Vector2(edge_x, rect.position.y + (j + 0.8) * rect.size.y / 3.0)
			_draw_flame(root, p, frame, j * 2 + side + 9, true)


func _draw_flame(root: Vector2, p: float, frame: int, index: int, side: bool) -> void:
	var phase := frame + index * 3
	var height := float(FLAME_HEIGHTS[phase % FLAME_HEIGHTS.size()]) * p
	var width := (3.7 if side else 5.7) * p
	var destination := Rect2((root - Vector2(width * 0.5, height)).round(), Vector2(width, height).round())
	var sprite := Rect2((phase % 4) * 8, 0, 8, 10)
	draw_texture_rect_region(FLAME_STRIP, destination, sprite)
	if phase % 7 == 0:
		_pixel(Vector2(root.x + p, destination.position.y - p * 1.5), p, FIRE_CORE)


func _draw_transfer(transfer: Dictionary, unit: float) -> void:
	var foe_charge := bool(transfer.foe)
	var gauge := _foe_gauge if foe_charge else _energy_gauge
	if not gauge.has_area():
		return
	var age := float(transfer.age)
	var origin := _reject_centre if transfer.reject else _player_source
	var finish := Vector2(gauge.position.x + gauge.size.x * float(transfer.portion), gauge.get_center().y)
	var bend := minf(56.0 * unit, origin.distance_to(finish) * 0.12)
	var bright := VIOLET if foe_charge else GOLD
	var shade := VIOLET_SHADE if foe_charge else GOLD_SHADE
	for index in range(5):
		var t := (age - index * 0.033) / CHARGE_FLIGHT
		if t < 0.0 or t > 1.0:
			continue
		var lane := (float(index % 3) - 1.0) * unit * 3.0
		var centre := origin.lerp(finish, t)
		centre.y += sin(PI * t) * (-bend + lane)
		for j in range(1,4):
			var behind := maxf(0.0, t - j * 0.017)
			var tail := origin.lerp(finish, behind)
			tail.y += sin(PI * behind) * (-bend + lane)
			_pixel(tail, unit * (2.4 - j * 0.42), shade)
		if index == 0:
			_diamond(centre, unit * 3.1, bright, unit)
			_pixel(centre, unit * 2, CHALK)
		else:
			_pixel(centre, unit * 2.5, bright)
	if age < CHARGE_FLIGHT:
		return
	var pulse := clampf((age - CHARGE_FLIGHT) / (CHARGE_LIFE - CHARGE_FLIGHT), 0.0, 1.0)
	var box := gauge.grow((1.5 + pulse * 2.5) * unit)
	var tint := bright.lerp(Color(bright, 0.0), pulse)
	if foe_charge:
		_diamond(finish, (1.0 - pulse) * unit * 4.5, CHALK, unit)
	draw_rect(box, tint, false, maxf(1.0, (2.35 - pulse * 1.2) * unit))
	for edge in [box.position, box.end, Vector2(box.position.x, box.end.y), Vector2(box.end.x, box.position.y)]:
		_pixel(edge, unit * (3.3 - pulse), tint)


func _ring(centre: Vector2, radius: float, width: float, tint: Color) -> void:
	var previous := centre + Vector2.UP * radius
	for i in range(1, 9):
		var tip := centre + Vector2.UP.rotated(i * TAU / 8.0) * radius
		_stroke(previous, tip, width, tint)
		previous = tip


func _stroke(a: Vector2, b: Vector2, width: float, tint: Color) -> void:
	var steps := maxi(1, ceili(a.distance_to(b) / maxf(1.0, width * 0.82)))
	for i in range(steps + 1):
		_pixel(a.lerp(b, float(i) / steps), width, tint)


func _diamond(centre: Vector2, radius: float, tint: Color, unit: float) -> void:
	var rows := maxi(1, ceili(radius / unit))
	for row in range(1 - rows, rows):
		var half_width := (rows - absi(row) - 0.45) * unit
		draw_rect(Rect2((centre + Vector2(-half_width, (row - 0.5) * unit)).round(), Vector2(ceilf(2.0 * half_width), ceilf(unit))), tint)


func _pixel(centre: Vector2, side: float, tint: Color) -> void:
	var width := maxf(1.0, roundf(side))
	draw_rect(Rect2((centre - Vector2.ONE * width * 0.5).round(), Vector2.ONE * width), tint)

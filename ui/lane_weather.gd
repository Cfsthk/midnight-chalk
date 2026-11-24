extends Control

const SCORCH_LIFE := 0.46
var ink_height := 0.0
var rock_height := 0.0
var wind := false
var frozen := false
var clock := 0.0
var current_age := 0.38
var scorch_age := SCORCH_LIFE
var scorched: Array[Rect2] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	hide()


func show_effects(coverage: float, accelerated: bool, battle_time: float,
		rock_coverage: float, frosted: bool) -> void:
	ink_height = coverage
	rock_height = rock_coverage
	wind = accelerated
	frozen = frosted
	clock = battle_time
	_refresh()


func incinerate(tile_rects: Array[Rect2]) -> void:
	scorched.clear()
	for rect in tile_rects:
		scorched.append(Rect2((rect.position - position) / size, rect.size / size))
	scorch_age = 0.0
	_refresh()


func start_current() -> void:
	current_age = 0.0
	_refresh()


func advance(delta: float) -> void:
	if current_age < 0.38:
		current_age = minf(0.38, current_age + delta)
		_refresh()
	if scorch_age >= SCORCH_LIFE:
		return
	scorch_age = minf(SCORCH_LIFE, scorch_age + delta)
	if scorch_age == SCORCH_LIFE:
		scorched.clear()
	_refresh()


func clear() -> void:
	current_age = 0.38
	scorched.clear()
	scorch_age = SCORCH_LIFE
	show_effects(0.0, false, 0.0, 0.0, false)


func _refresh() -> void:
	visible = ink_height > 0.0 or rock_height > 0.0 or wind or frozen or not scorched.is_empty() or current_age < 0.38
	if visible:
		queue_redraw()


func _draw() -> void:
	var px := maxf(1.0, roundf(size.x / 150.0))
	if wind:
		for i in range(10):
			var phase := fmod(clock * 0.95 + i * 0.137, 1.0)
			var x := (0.025 if i % 2 == 0 else 0.975) * size.x
			var point := Vector2(x, phase * size.y).round()
			var tail := px * (5.0 + (i % 3) * 2.0)
			draw_rect(Rect2(point, Vector2(px, tail)), Color("#94d9d5"))
			draw_rect(Rect2(point + Vector2(-px, tail - px), Vector2(3 * px, px)), Color("#e4fff5"))
	if current_age < 0.38:
		var phase := current_age / 0.38
		for band in range(3):
			var y := size.y * (0.21 + band * 0.28)
			for i in range(7):
				var p := Vector2(fposmod((i + phase * 2) * size.x / 6.0, size.x), y + sin(i * 3.0 + phase * 5.5) * px * 4)
				var tint := Color(0.49, 0.86, 1.0, (1.0 - phase) * 0.88)
				draw_rect(Rect2(p - Vector2(8,0)*px,Vector2(9,1)*px),tint)
				draw_rect(Rect2(p - Vector2(2,1)*px,Vector2(2,3)*px),tint)
	if frozen:
		_draw_frost(px)
	if ink_height > 0.0:
		_draw_ink(px)
	if rock_height > 0.0:
		_draw_rock_wall(px)
	if not scorched.is_empty():
		_draw_scorch()


func _draw_ink(px: float) -> void:
	var bottom := roundf(size.y * ink_height)
	draw_rect(Rect2(0.0, 0.0, size.x, bottom), Color("#201a32"))
	for i in range(26):
		var x := floorf(i * size.x / 26.0)
		var width := ceilf((i + 1) * size.x / 26.0) - x
		var ridge := px * (1.0 + roundf((1.0 + sin(i * 1.38 + clock * 4.0)) * 1.5))
		draw_rect(Rect2(x, bottom - ridge, width, ridge), Color("#514168"))
		if i % 6 == 1:
			draw_rect(Rect2(x, bottom - ridge - 3.0 * px, width * 0.65, px), Color("#79628f"))


func _draw_rock_wall(px: float) -> void:
	var height := roundf(size.y * rock_height)
	var top := size.y - height
	draw_rect(Rect2(0.0, top, size.x, height), Color("#302b31"))
	var brick := Vector2(22 * px, 11 * px)
	for row in range(ceili(height / brick.y)):
		var y := top + row * brick.y
		var offset := -brick.x * 0.5 if row % 2 else 0.0
		for col in range(ceili(size.x / brick.x) + 1):
			var pos := Vector2(col * brick.x + offset, y)
			var fill := Color("#67616c") if (col * 3 + row) % 4 < 2 else Color("#53515c")
			draw_rect(Rect2(pos + Vector2(px, px), brick - Vector2(px, px) * 2.0), fill)
			draw_rect(Rect2(pos + Vector2(px, px), Vector2(brick.x - px * 3, px * 1.5)), Color("#a9a59f"))
			draw_rect(Rect2(pos + Vector2(px, 2 * px), Vector2(px, 5 * px)), Color("#85847f"))
			if (col + row) % 2 == 0:
				draw_rect(Rect2(pos + Vector2(13, 4) * px, Vector2(3, 1) * px), Color("#46434b"))


func _draw_frost(px: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#bceefa40"), false, px * 2)
	for i in range(10):
		var edge := size.x - 6.0 * px if i % 2 else 6.0 * px
		var point := Vector2(edge, (0.08 + 0.19 * floorf(i / 2.0)) * size.y).round()
		var glow := Color("#c3f6ff") if i % 3 else Color("#72badd")
		draw_rect(Rect2(point - Vector2(3, 0.5) * px, Vector2(6, 1) * px), glow)
		draw_rect(Rect2(point - Vector2(0.5, 3) * px, Vector2(1, 6) * px), glow)
		for arm in [Vector2(-1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1)]:
			draw_rect(Rect2(point + arm * 1.65 * px, Vector2.ONE * px), glow)


func _draw_scorch() -> void:
	var t := scorch_age / SCORCH_LIFE
	for i in range(scorched.size()):
		var area := scorched[i]
		var rect := Rect2(area.position * size, area.size * size)
		var px := maxf(1.0, rect.size.x / 20.0)
		# A strip of the old card blackens from top to bottom under the flame.
		var char_height := rect.size.y * (1.0 - smoothstep(0.0, 0.70, t))
		if char_height > px:
			var charred := Rect2(rect.position.x + px, rect.end.y - char_height,
				rect.size.x - 2.0 * px, char_height)
			draw_rect(charred, Color("#482936"))
			draw_rect(Rect2(charred.position, Vector2(charred.size.x, px)), Color("#ffb162"))
			for crack in range(4):
				var start := charred.position + Vector2((2 + crack * 4) * px, char_height * 0.32)
				draw_rect(Rect2(start, Vector2(px, char_height * 0.3)), Color("#9d543e"))
		var fade := 1.0 - smoothstep(0.55, 0.95, t)
		if fade > 0.0:
			var base := rect.get_center() + Vector2(0, (6.0 - 8.0 * t) * px)
			var rise := (0.77 + 0.23 * sin(PI * t)) * (1.0 - 0.46 * smoothstep(0.50, 0.92, t))
			for col in range(17):
				var x := col - 8
				# Three uneven peaks make a flame even at the smallest phone scale.
				var left := 13.0 - absf(x + 4.0 - t * 0.9) * 2.6
				var centre := 18.0 - absf(x - 0.5 + sin(t * 7 + i) * 1.1) * 3.6
				var right := 11.5 - absf(x - 5.0 - t * 0.8) * 2.8
				var height := maxf(2.0, roundf(maxf(left, maxf(centre, right)) * rise))
				var bottom := base + Vector2(x * px, -roundf(absf(x) * 0.18) * px)
				var width := ceilf(px + 0.05)
				draw_rect(Rect2((bottom - Vector2(0,height*px)).round(),Vector2(width,height*px)),
					Color(0.93,0.30,0.19,fade))
				var amber_height := maxf(0.0, height - 2.0 - absf(x) * 0.25)
				if amber_height > 0.0:
					draw_rect(Rect2((bottom - Vector2(0,amber_height*px)).round(),Vector2(width,amber_height*px)),
						Color(1.0,0.59,0.20,fade))
				var core := minf(amber_height - 1.0, maxf(7.0 - absf(x + 1.0)*1.35, 4.0 - absf(x - 3.0)*1.6)) * rise
				if core > 0.0:
					draw_rect(Rect2((bottom - Vector2(0,core*px)).round(),Vector2(width,core*px)),
						Color(1.0,0.91,0.59,fade))
		for spark in range(8):
			var side := 2.0 if spark % 3 == 0 else 1.0
			var x := ((spark * 7 + i * 3) % 17 - 8) + sin(t * 4.0 + spark) * t * 2
			var y := 1.0 - (spark * 7 % 9) - t * (8 + spark % 4 * 3)
			var ember := rect.get_center() + Vector2(x,y) * px
			var tint := Color(1.0,0.80,0.39,1.0-t) if spark % 2 == 0 else Color(0.83,0.39,0.67,1.0-t)
			draw_rect(Rect2(ember.round(),Vector2(1.0,side)*px),tint)

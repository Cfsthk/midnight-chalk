extends Control

signal finished
const DURATION := 2.1
const PALETTE := [Color("#ffdb89"), Color("#baeed7"), Color("#d9bcff"), Color("#fff3d3")]
var elapsed := DURATION


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hide()


func play() -> void:
	elapsed = 0.0
	show()
	queue_redraw()


func advance(delta: float) -> void:
	if not visible:
		return
	elapsed = minf(DURATION, elapsed + delta)
	queue_redraw()
	if elapsed >= DURATION:
		hide()
		finished.emit()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#101019"))
	var unit := maxf(1.0, minf(size.x, size.y) / 210.0)
	var center := (size * 0.5).round()
	for i in range(5):
		var reveal := clampf((elapsed - 0.11 * i) * 3.8, 0.0, 1.0)
		if reveal <= 0.0:
			continue
		var x := (i - 2) * 18.0 * unit
		var y := (1.0 - reveal) * 9.0 * unit
		var p := center + Vector2(x, y)
		var side := 5.0 * unit * reveal
		draw_colored_polygon(PackedVector2Array([p + Vector2.UP * side, p + Vector2.RIGHT * side,
			p + Vector2.DOWN * side, p + Vector2.LEFT * side]), PALETTE[i % PALETTE.size()])
		draw_rect(Rect2(p - Vector2.ONE * unit, Vector2.ONE * unit * 2.0), Color.WHITE)
	for burst in range(8):
		var age := (elapsed - 0.12 - burst * 0.145) / 0.87
		if age < 0.0 or age >= 1.0:
			continue
		var origin := center + Vector2(cos(burst * 2.4) * 0.30 * size.x, sin(burst * 2.4) * 0.32 * size.y)
		var tint: Color = PALETTE[burst % PALETTE.size()]
		tint.a = 1.0 - age * age
		for ray in range(12):
			var direction := Vector2.from_angle(TAU * ray / 12.0 + burst * 0.29)
			var r := (2.0 + (1.0 - pow(1.0 - age, 2.0)) * (14.0 + 7.0 * (ray % 2))) * unit
			var point := (origin + direction * r + Vector2.DOWN * age * age * 6.0 * unit).round()
			draw_rect(Rect2(point, Vector2.ONE * unit * (2.6 - age)), tint)
	var font := get_theme_default_font()
	var text_size := roundi(unit * 8.0)
	var tint: Color = PALETTE[3]
	tint.a = smoothstep(0.35, 0.8, elapsed)
	draw_string(font, Vector2(0, center.y + 24 * unit), "黑龍已敗", HORIZONTAL_ALIGNMENT_CENTER, size.x, text_size, tint)

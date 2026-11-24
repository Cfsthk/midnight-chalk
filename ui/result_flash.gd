extends Control

const WebKai := preload("res://ui/local_kai_web.gd")
const SCHOOL_KAI: Font = preload("res://assets/MidnightKai.ttf")
const SYSTEM_KAI := ["BiauKaiHK", "標楷體-港澳", "BiauKaiTC", "BiauKai", "DFKai-SB", "KaiU", "標楷體"]
const SAMPLE_SIZE := 512
const DURATION := 0.48
const START_ALPHA := 0.62
const INK := Color("#9ce2b2")

var ink := INK
var glyph := ""
var elapsed := 0.0
var _font: Font = SCHOOL_KAI
static var _web_kai: WebKai
var _local_mask: Texture2D
var _ink_bounds := Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(queue_redraw)
	if OS.has_feature("web"):
		if not _web_kai:
			_web_kai = WebKai.new()
	else:
		var installed := OS.get_system_fonts()
		for family: String in SYSTEM_KAI:
			if installed.has(family):
				var system_font := SystemFont.new()
				system_font.font_names = PackedStringArray([family])
				system_font.fallbacks = [SCHOOL_KAI]
				_font = system_font
				break
	hide()


func play(text: String) -> void:
	if text.is_empty():
		clear()
		return
	glyph = text
	elapsed = 0.0
	_local_mask = _web_kai.mask_for(text, SAMPLE_SIZE) if _web_kai else null
	_ink_bounds = Rect2(Vector2.ZERO, _local_mask.get_size()) if _local_mask else _measure_ink()
	show()
	queue_redraw()


func _measure_ink() -> Rect2:
	var server := TextServerManager.get_primary_interface()
	var raster_size := Vector2i(SAMPLE_SIZE, 0)
	if glyph.length() == 1:
		for rid: RID in _font.get_rids():
			var index := server.font_get_glyph_index(rid, SAMPLE_SIZE, glyph.unicode_at(0), 0)
			if index == 0:
				continue
			server.font_render_glyph(rid, raster_size, index)
			var ink_size := server.font_get_glyph_size(rid, raster_size, index)
			if ink_size.x > 0.0 and ink_size.y > 0.0:
				return Rect2(server.font_get_glyph_offset(rid, raster_size, index), ink_size)
	var text_size := _font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, SAMPLE_SIZE)
	return Rect2(Vector2(0.0, -_font.get_ascent(SAMPLE_SIZE)), text_size)


func advance(delta: float) -> void:
	if glyph.is_empty():
		return
	elapsed = minf(DURATION, elapsed + maxf(0.0, delta))
	if elapsed >= DURATION:
		clear()
	else:
		queue_redraw()


func clear() -> void:
	glyph = ""
	_local_mask = null
	elapsed = DURATION
	hide()


func ink_rect() -> Rect2:
	var scale_factor := minf(size.x / maxf(_ink_bounds.size.x, 1.0), size.y / maxf(_ink_bounds.size.y, 1.0))
	# Sample Godot's easing on the battle clock so pause and tile changes remain synchronous.
	var spread: float = Tween.interpolate_value(0.0, 1.0, elapsed, DURATION, Tween.TRANS_SINE, Tween.EASE_OUT)
	var extent := _ink_bounds.size * scale_factor * lerpf(0.22, 0.90, spread)
	return Rect2((size - extent) * 0.5, extent)


func opacity() -> float:
	if glyph.is_empty():
		return 0.0
	return START_ALPHA * (1.0 - pow(elapsed / DURATION, 1.35))


func board_opacity() -> float:
	if glyph.is_empty() or not visible:
		return 1.0
	var t := elapsed / DURATION
	var emphasis := smoothstep(0.0, 0.15, t) * (1.0 - smoothstep(0.42, 1.0, t))
	return lerpf(1.0, 0.14, emphasis)


func _draw() -> void:
	if glyph.is_empty() or size.x < 1.0 or size.y < 1.0:
		return
	var rect := ink_rect()
	var zoom := rect.size.x / maxf(_ink_bounds.size.x, 1.0)
	var baseline := rect.position - _ink_bounds.position * zoom
	draw_set_transform(baseline, 0.0, Vector2.ONE * zoom)
	var alpha := opacity()
	# A thin, drifting trace softens the edge while keeping the brush strokes legible.
	var drift := pow(elapsed / DURATION, 1.25) * 12.0
	_draw_ink(Vector2(drift * 0.6, -drift), alpha * 0.12)
	_draw_ink(Vector2.ZERO, alpha)


func _draw_ink(at: Vector2, alpha: float) -> void:
	if _local_mask:
		draw_texture(_local_mask, at, Color(ink, alpha))
	else:
		draw_string(_font, at, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, SAMPLE_SIZE, Color(ink, alpha))

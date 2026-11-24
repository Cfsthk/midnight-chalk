extends Control

const InkIcon = preload("res://ui/ink_icon.gd")
const LIFE := 0.65
var _boss: Rect2
var _energy: Rect2
var _slots: Array[Rect2] = []
var _stolen := InkIcon.new()
var _slot_index := -1
var _impact_kind := ""
var _time := LIFE
var guard := 0
var empowered := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stolen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stolen)
	_stolen.hide()


func set_layout(boss: Rect2, energy: Rect2, slots: Array[Button]) -> void:
	_boss = boss
	_energy = energy
	_slots.clear()
	for slot in slots:
		_slots.append(slot.get_rect())
	_move_stolen_item()
	queue_redraw()


func show_stance(armour: int, hits: int) -> void:
	if guard != armour or empowered != hits:
		guard = armour
		empowered = hits
		queue_redraw()


func impact(effect: Dictionary) -> void:
	var kind := str(effect.get("kind", ""))
	if kind not in ["steal", "drain", "restore"] or int(effect.value) <= 0:
		return
	_impact_kind = kind
	_time = 0.0
	if kind == "steal":
		_slot_index = int(effect.slot)
		_stolen.icon = "item_" + str(effect.item.kind)
		_stolen.show()
		_move_stolen_item()
	queue_redraw()


func advance(delta: float) -> void:
	if _time >= LIFE:
		return
	_time = minf(LIFE, _time + delta)
	if _stolen.visible:
		_move_stolen_item()
		if _time == LIFE:
			_stolen.hide()
	queue_redraw()


func clear() -> void:
	_stolen.hide()
	_time = LIFE
	_slot_index = -1
	show_stance(0, 0)
	queue_redraw()


func _move_stolen_item() -> void:
	if not _stolen.visible or _slot_index < 0 or _slot_index >= _slots.size():
		return
	var t := _time / LIFE
	var origin := _slots[_slot_index]
	var pos := origin.get_center().lerp(_boss.get_center(), smoothstep(0.0, 1.0, t))
	pos.y -= sin(t * PI) * _boss.size.y * 0.22
	_stolen.size = origin.size * (0.7 - 0.3 * t)
	_stolen.position = (pos - _stolen.size * 0.5).round()
	_stolen.modulate.a = 1.0 - smoothstep(0.68, 1.0, t)


func _draw() -> void:
	var px := maxf(1.5, minf(_boss.size.x, _boss.size.y) / 92.0)
	var centre := _boss.get_center()
	if guard > 0 or empowered > 0:
		var amount := guard if guard > 0 else empowered
		var origin := centre + Vector2(0.0, _boss.size.y * 0.36)
		for i in range(amount):
			var p := origin + Vector2((i - (amount - 1) * 0.5) * 10.0 * px, 0.0)
			if guard > 0:
				draw_colored_polygon(PackedVector2Array([p + Vector2(-3,-3)*px, p + Vector2(3,-3)*px,
					p + Vector2(3,1)*px, p + Vector2(0,4)*px, p + Vector2(-3,1)*px]), Color("#b7d5de"))
				draw_rect(Rect2(p + Vector2(-1,-2)*px,Vector2(1,4)*px),Color("#617a96"))
			else:
				draw_colored_polygon(PackedVector2Array([p + Vector2(-3,2)*px,p + Vector2(-2,-2)*px,
					p + Vector2(0,0)*px,p + Vector2(2,-5)*px,p + Vector2(4,1)*px,p + Vector2(1,4)*px]), Color("#ff9650"))
				draw_rect(Rect2(p, Vector2(2,2)*px),Color("#ffe29b"))
	if _time >= LIFE:
		return
	var t := _time / LIFE
	var fade := 1.0 - smoothstep(0.60, 1.0, t)
	if _impact_kind == "restore":
		for i in range(5):
			var p := centre + Vector2((i - 2) * 8 * px, -(5 + (i * 7) % 11 + t * 13) * px)
			var tint := Color(0.56, 1.0, 0.75, fade)
			draw_rect(Rect2(p - Vector2(0.5,2) * px, Vector2(1,4) * px),tint)
			draw_rect(Rect2(p - Vector2(2,0.5) * px, Vector2(4,1) * px),tint)
	elif _impact_kind == "drain":
		for i in range(5):
			var p := clampf(t * 1.36 - i * 0.075, 0.0, 1.0)
			var orb := _energy.get_center().lerp(centre, p) + Vector2.UP * sin(PI * p) * 13.0 * px
			draw_rect(Rect2(orb.round(), Vector2.ONE * px * 2.5), Color(0.81, 0.63, 1.0, fade))
	elif _impact_kind == "steal" and _slot_index >= 0 and _slot_index < _slots.size():
		draw_rect(_slots[_slot_index].grow(px), Color(1.0, 0.52, 0.54, fade), false, px)

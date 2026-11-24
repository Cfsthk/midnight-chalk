extends Control

const InkIcon = preload("res://ui/ink_icon.gd")
const RunState = preload("res://game/run_state.gd")
const TRACK := Color("#514e48")
const CHARGE := Color("#ffdc73")
const MARKS := {
	"power_mark": "追字印", "power_mirror": "反照鏡", "power_slow": "緩流掌",
	"power_reject_flame": "辨形火印", "item_calm": "安心符", "item_umbrella": "防擾傘",
	"item_lantern": "尋字燈", "item_bounty": "賞金袋",
}
var _spent := InkIcon.new()
var _spent_until := 0.0
var _icons: Dictionary[String, Control] = {}
var _meters: Dictionary[String, float] = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id: String in MARKS:
		var mark := InkIcon.new()
		mark.name = id
		mark.icon = id
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.accessibility_name = MARKS[id]
		add_child(mark)
		_icons[id] = mark
		mark.hide()
	_spent.name = "Spent"
	_spent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_spent)
	_spent.hide()
	resized.connect(_arrange)


func sync(run: RunState) -> void:
	visible = run.phase == "battle"
	if not visible:
		_spent_until = 0.0
		_spent.hide()
		return
	if _spent.visible:
		var remaining := _spent_until - run.active_seconds
		_spent.visible = remaining > 0.0
		_spent.modulate.a = clampf(remaining / 0.32, 0.0, 1.0)
		if not _spent.visible:
			_arrange()
	_set_meter("power_mark", run.marked_hits, 3)
	_set_meter("power_mirror", run.effect_seconds("mirror"), 5.0)
	_set_meter("power_slow", run.effect_seconds("slow"), 4.0)
	_set_meter("power_reject_flame", run.effect_seconds("reject_flame"), 5.0)
	_set_meter("item_calm", run.calm_charges, 2)
	_set_meter("item_umbrella", float(run.umbrella_ready), 1)
	_set_meter("item_lantern", float(run.lantern_waiting or run.hinted_tile_id != -1), 1)
	_set_meter("item_bounty", run.bounty_coins, maxi(1, run.bounty_coins))


# An expiring charm stays visible briefly when it catches a mistake or a hit.
func signal_used(id: String, now: float) -> void:
	_spent.icon = id
	_spent.accessibility_name = "%s已發動" % MARKS[id]
	_spent.modulate.a = 1.0
	_spent_until = now + 0.55
	_spent.show()
	_arrange()


func _set_meter(id: String, value: float, capacity: float) -> void:
	var mark := _icons[id]
	var fill := clampf(value / capacity, 0.0, 1.0)
	if mark.visible != (fill > 0):
		mark.visible = fill > 0
		_arrange()
	if not is_equal_approx(_meters.get(id, 0.0), fill):
		_meters[id] = fill
		queue_redraw()


func _arrange() -> void:
	var count := int(_spent.visible)
	for mark in _icons.values():
		if mark.visible:
			count += 1
	if count == 0:
		return
	var gap := 3.0
	var side := maxf(1.0, floorf(minf(size.y * 0.8, (size.x - gap * (count - 1)) / count)))
	var x := size.x - (side + gap) * count + gap
	if _spent.visible:
		_spent.position = Vector2(roundf(x), roundf((size.y - side) * 0.35))
		_spent.size = Vector2.ONE * side
		x += side + gap
	for mark in _icons.values():
		if mark.visible:
			mark.position = Vector2(roundf(x), roundf((size.y - side) * 0.35))
			mark.size = Vector2.ONE * side
			x += side + gap
	queue_redraw()


func _draw() -> void:
	for id: String in _icons:
		var mark := _icons[id]
		if mark.visible:
			var width := roundf(mark.size.x * 0.78)
			var origin := (mark.position + Vector2((mark.size.x - width) * 0.5, mark.size.y)).round()
			var meter := Rect2(origin, Vector2(width, maxf(1, roundf(mark.size.x / 14))))
			draw_rect(meter, TRACK)
			meter.size.x = ceilf(width * _meters.get(id, 0.0))
			draw_rect(meter, CHARGE)

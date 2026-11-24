extends Control

const FRAME := Color("#f4f4ef")
const TRACK := Color("#17171a")
const SOCKET := Color("#020203")

var fill_color := Color("#eb8291")
var vertical := false
var value := 0.0:
	set(next):
		value = next
		queue_redraw()
var trail := 0.0:
	set(next):
		trail = next
		queue_redraw()

var _animation: Tween
var _target := -1.0
var _frozen := false


func set_frozen(frozen: bool) -> void:
	_frozen = frozen
	if _animation and _animation.is_valid():
		if frozen:
			_animation.pause()
		else:
			_animation.play()


func set_fill(amount: float, animated: bool = false) -> void:
	var target := clampf(amount, 0.0, 1.0)
	if animated and is_equal_approx(target, _target):
		return
	if not animated and target == _target and value == target and trail == target:
		return
	_target = target
	if _animation and _animation.is_valid():
		_animation.kill()
	if not animated:
		value = target
		trail = target
		return
	trail = maxf(trail, value)
	_animation = create_tween().set_parallel()
	_animation.tween_property(self, "value", target, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_animation.tween_property(self, "trail", target, 0.23).set_delay(0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _frozen:
		_animation.pause()


func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	var rim := clampf(floorf(minf(size.x, size.y) * 0.1), 1.0, 3.0)
	var inner := bounds.grow(-rim - 1.0)
	if inner.size.x < 1.0 or inner.size.y < 1.0:
		return
	draw_rect(bounds, FRAME)
	draw_rect(bounds.grow(-rim), SOCKET)
	draw_rect(inner, TRACK)
	_draw_fill(inner, trail, fill_color.lightened(0.55))
	_draw_fill(inner, value, fill_color)


func _draw_fill(inner: Rect2, amount: float, tint: Color) -> void:
	if amount <= 0.0:
		return
	var area := inner
	if vertical:
		area.size.y = floorf(inner.size.y * amount)
		area.position.y = inner.end.y - area.size.y
	else:
		area.size.x = floorf(inner.size.x * amount)
	if area.size.x < 1.0 or area.size.y < 1.0:
		return
	draw_rect(area, tint)
	# A continuous highlight lets the small secondary gauges keep a readable silhouette.
	if vertical and area.size.x >= 7.0:
		draw_rect(Rect2(area.position, Vector2(2.0, area.size.y)), tint.lightened(0.30))
	elif not vertical and area.size.y >= 5.0:
		draw_rect(Rect2(area.position, Vector2(area.size.x, 1.0)), tint.lightened(0.32))

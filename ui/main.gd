extends Control

const RunState = preload("res://game/run_state.gd")
const Gauge = preload("res://ui/gauge.gd")
const InkIcon = preload("res://ui/ink_icon.gd")
const LoadoutStatus = preload("res://ui/loadout_status.gd")
const BossStatus = preload("res://ui/boss_status.gd")
const BossArt = preload("res://ui/boss_art.gd")
const CombatFX = preload("res://ui/combat_fx.gd")
const CombatSounds = preload("res://ui/combat_sounds.gd")
const ResultFlash = preload("res://ui/result_flash.gd")
const LaneWeather = preload("res://ui/lane_weather.gd")
const FinishCelebration = preload("res://ui/finish_celebration.gd")

const PAPER := Color("#fffdf6")
const NIGHT := Color("#060606")
const PANEL := Color("#090909")
const BORDER := Color("#e2e1db")
const RULE := Color("#5e5e5b")
const MUTED := Color("#c8c8c3")
const VIOLET := Color("#e4d7f8")
const GOLD := Color("#ffdd42")
const ROSE := Color("#f08b9c")
const MISS_INK := Color("#ff747e")
const MINT := Color("#87deb2")
const ICE := Color("#a6d7e4")
const FONT_PATH := "res://assets/NotoSansHK-Regular.ttf"
const SLOT_NAMES := {"top": "上", "right": "右", "bottom": "下", "left": "左"}
const SLOT_DIRECTIONS := {
	"top": Vector2.UP, "right": Vector2.RIGHT,
	"bottom": Vector2.DOWN, "left": Vector2.LEFT,
}

var run := RunState.new()
var _u := 1.0
var _button_border := 2
var _arena: Rect2
var _left: Rect2
var _lane: Rect2
var _status: Rect2
var _fall_start := 0.0
var _fall_end := 0.0
var _fall_size := 70.0
var _modal: PanelContainer
var _overlay: ColorRect
var _count_label: Label
var _stage_label: Label
var _boss_name: Label
var _chest_time: Label
var _chest_icon: InkIcon
var _wallet_icon: InkIcon
var _wallet: Label
var _pause_face: Panel
var _pause_button: Button
var _pause_shade: ColorRect
var _resume: Button
var _pause_restart: Button
var _music_toggle: Button
var _loadout_status: LoadoutStatus
var _boss_status: BossStatus
var _boss_art: BossArt
var _effects: CombatFX
var _result_flash: ResultFlash
var _miss_flash: ResultFlash
var _weather: LaneWeather
var _celebration: FinishCelebration
var _boss_bar: Gauge
var _foe_charge: Gauge
var _foe_clock: Gauge
var _foe_icons: Array[InkIcon] = []
var _player_bar: Gauge
var _energy_bar: Gauge
var _anchor: Label
var _base_anchor_style: StyleBoxFlat
var _active_tile_style: StyleBoxFlat
var _idle_tile_style: StyleBoxFlat
var _cards: Array[Button] = []
var _glyph_faces: Array[Label] = []
var _anchor_masked := false
var _slots: Dictionary[String, Button] = {}
var _reject: Button
var _special: Button
var _special_icon: InkIcon
var _health_icon: InkIcon
var _bag_icon: InkIcon
var _item_buttons: Array[Button] = []
var _item_icons: Array[InkIcon] = []
var _sounds: CombatSounds
var _voice: AudioStreamPlayer
var _audio: Dictionary[String, AudioStream] = {}
var _voice_queue: Array[AudioStream] = []
var _countdown := -1.0
var _feedback := 0.0
var _feedback_colour := ROSE
var _finish_delay := -1.0
var _user_paused := false
var _application_paused := false
var _overlay_open := true
var _previous_focus: Control


func _ready() -> void:
	clip_contents = true
	var skin := Theme.new()
	if ResourceLoader.exists(FONT_PATH):
		skin.default_font = load(FONT_PATH) as Font
	skin.default_font_size = 22
	skin.set_stylebox("normal", "Button", _plate(PANEL, BORDER, 2))
	skin.set_stylebox("hover", "Button", _plate(Color("#262624"), PAPER, 2))
	skin.set_stylebox("pressed", "Button", _plate(Color("#383831"), VIOLET, 2))
	skin.set_stylebox("disabled", "Button", _plate(PANEL, Color("#787875"), 2))
	skin.set_stylebox("focus", "Button", _plate(Color.TRANSPARENT, ICE, 2))
	theme = skin
	_build_battle()
	get_viewport().size_changed.connect(_update_button_borders)
	_update_button_borders()
	resized.connect(_layout)
	_layout()
	_start_run()


func _exit_tree() -> void:
	if is_instance_valid(_voice):
		_voice.stop()
		_voice.stream = null


func _build_battle() -> void:
	_boss_art = BossArt.new()
	_boss_art.name = "BossArt"
	_boss_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_boss_art)
	_boss_name = _make_label("BossName", 36, PAPER)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_stage_label = _make_label("Stage", 22, PAPER)
	_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var bold := FontVariation.new()
	bold.base_font = get_theme_default_font()
	bold.variation_embolden = 0.7
	_stage_label.add_theme_font_override("font", bold)
	_loadout_status = LoadoutStatus.new()
	_loadout_status.name = "ActiveLoadout"
	add_child(_loadout_status)
	_chest_time = _make_label("ChestClock", 25, PAPER)
	_chest_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_chest_icon = _make_icon("ChestIcon", "chest", self)
	_wallet_icon = _make_icon("WalletMark", "coin", self)
	_wallet = _make_label("Wallet", 24, GOLD)
	_wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_wallet.text = "0"
	_set_accessible(_wallet, "持有金幣")
	_boss_bar = _make_gauge("BossHealth", false, ROSE)
	_foe_charge = _make_gauge("FoeCharge", false, VIOLET)
	_foe_clock = _make_gauge("FoeCooldown", false, ICE)
	var marks := ["health", "foe_charge", "cooldown"]
	var gauges := [_boss_bar, _foe_charge, _foe_clock]
	for i in range(marks.size()):
		var icon := _make_icon("FoeMark%d" % i, marks[i], self)
		icon.mouse_filter = Control.MOUSE_FILTER_PASS
		_foe_icons.append(icon)
		gauges[i].mouse_filter = Control.MOUSE_FILTER_PASS
	_anchor = _make_label("Anchor", 50, NIGHT)
	_anchor.draw.connect(_draw_anchor_mask)
	_base_anchor_style = _plate(PAPER, PAPER, 2)
	_anchor.add_theme_stylebox_override("normal", _base_anchor_style)
	for action: String in SLOT_NAMES:
		var slot := _make_button("Place" + action.capitalize(), "", self)
		_set_accessible(slot, SLOT_NAMES[action])
		slot.pressed.connect(_commit.bind(action))
		slot.draw.connect(_draw_slot_mark.bind(slot, action))
		_slots[action] = slot
	_reject = _make_button("Incompatible", "", self)
	_set_accessible(_reject, "不相配")
	_reject.pressed.connect(_commit.bind("reject"))
	_inset_icon(_make_icon("MismatchMark", "reject", _reject), 8)
	_energy_bar = _make_gauge("SpecialMeter", true, GOLD)
	_player_bar = _make_gauge("PlayerHealth", true, ROSE)
	_special = _make_button("Special", "", self)
	_special.pressed.connect(_use_special)
	_special_icon = _make_icon("SpecialMark", "bolt", _special)
	_inset_icon(_special_icon, 3)
	_health_icon = _make_icon("HealthMark", "health", self)
	_bag_icon = _make_icon("BagMark", "bag", self)
	_player_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	_energy_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	_set_accessible(_player_bar, "生命值")
	_set_accessible(_energy_bar, "必殺技能量")
	for index in range(3):
		var item := _make_button("Item%d" % (index + 1), "", self)
		var icon := _make_icon("ItemMark", "", item)
		_inset_icon(icon, 7)
		item.draw.connect(_draw_empty_item.bind(item, index))
		item.pressed.connect(_use_item.bind(index))
		_item_buttons.append(item)
		_item_icons.append(icon)
	_active_tile_style = _plate(PAPER, GOLD, 4)
	_idle_tile_style = _plate(Color("#d4d4d4"), MUTED, 3)
	for lane in range(3):
		var card := _make_button("FallingTile%d" % (lane + 1), "", self)
		card.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		card.clip_text = true
		card.pressed.connect(_select_lane.bind(lane))
		card.draw.connect(_draw_card_mark.bind(card))
		for state in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]:
			card.add_theme_color_override(state, NIGHT)
		var face := _make_label("TurnedGlyph", 24, NIGHT, card)
		face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		face.hide()
		for badge: String in ["item_lantern", "item_clip"]:
			var backing := ColorRect.new()
			backing.name = badge
			backing.color = NIGHT
			backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(backing)
			_inset_icon(_make_icon("Mark", badge, backing), 0)
			backing.hide()
		_glyph_faces.append(face)
		_cards.append(card)
		card.hide()
	_weather = LaneWeather.new()
	_weather.name = "LaneWeather"
	add_child(_weather)
	_result_flash = ResultFlash.new()
	_result_flash.name = "FormedCharacter"
	add_child(_result_flash)
	_miss_flash = ResultFlash.new()
	_miss_flash.name = "MissedCharacter"
	_miss_flash.ink = MISS_INK
	add_child(_miss_flash)
	_effects = CombatFX.new()
	_effects.name = "CombatFX"
	_effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_effects)
	_effects.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_boss_status = BossStatus.new()
	_boss_status.name = "BossStatus"
	add_child(_boss_status)
	_boss_status.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sounds = CombatSounds.new()
	_sounds.name = "CombatSounds"
	add_child(_sounds)
	_voice = AudioStreamPlayer.new()
	_voice.bus = &"Speech"
	_voice.name = "Cantonese"
	_voice.volume_db = -3.0
	_voice.finished.connect(_play_next_answer)
	add_child(_voice)
	_overlay = ColorRect.new()
	_overlay.name = "Menu"
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_button = _make_button("Pause", "", self)
	_set_accessible(_pause_button, "暫停")
	for state in ["normal", "pressed", "hover"]:
		_pause_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_pause_face = Panel.new()
	_pause_face.name = "PauseFace"
	_pause_face.add_theme_stylebox_override("panel", _plate(PANEL, MUTED, 2))
	_pause_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_button.add_child(_pause_face)
	_inset_icon(_make_icon("PauseMark", "pause", _pause_face), 3)
	_pause_button.pressed.connect(_toggle_pause)
	_build_pause_menu()
	_celebration = FinishCelebration.new()
	_celebration.name = "FinishCelebration"
	add_child(_celebration)
	_celebration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_celebration.finished.connect(_show_completed_run)
	_sync_actions()


func _inset_icon(icon: InkIcon, inset: int) -> void:
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = inset
	icon.offset_top = inset
	icon.offset_right = -inset
	icon.offset_bottom = -inset


func _build_pause_menu() -> void:
	_pause_shade = ColorRect.new()
	_pause_shade.name = "PauseMenu"
	_pause_shade.color = Color("#000000e6")
	add_child(_pause_shade)
	_pause_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_pause_shade.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := PanelContainer.new()
	center.add_child(card)
	var style := _plate(PANEL, PAPER, 4)
	card.draw.connect(_draw_dialog_corners.bind(card))
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", style)
	var options := VBoxContainer.new()
	options.add_theme_constant_override("separation", 15)
	card.add_child(options)
	var title := _make_label("Paused", 29, PAPER, options)
	title.text = "暫停"
	_resume = _menu_button(options, "Resume", "繼續對戰", _toggle_pause)
	_music_toggle = _menu_button(options, "MusicToggle", "音樂　開", _toggle_music)
	_pause_restart = _menu_button(options, "PauseRestart", "重新開始", _restart_from_pause)
	_link_menu_buttons([_resume, _music_toggle, _pause_restart], false)
	_resume.custom_minimum_size = Vector2(190, 52)
	_pause_shade.hide()


func _make_label(node_name: String, point_size: int, tint: Color, parent: Node = null) -> Label:
	var label := Label.new()
	label.name = node_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", point_size)
	label.add_theme_color_override("font_color", tint)
	(self if parent == null else parent).add_child(label)
	return label


func _make_button(node_name: String, title: String, parent: Node) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = title
	button.pressed.connect(_button_click)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_focus_color", PAPER)
	button.add_theme_color_override("font_hover_color", PAPER)
	button.add_theme_color_override("font_pressed_color", PAPER)
	parent.add_child(button)
	return button


func _button_click() -> void:
	_sounds.play_click()


func _toggle_music() -> void:
	var enabled := AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music"))
	_sounds.set_music_enabled(enabled)
	_music_toggle.text = "音樂　開" if enabled else "音樂　關"


func _update_button_borders() -> void:
	# A thin logical line may fall between physical pixels on a portrait Web canvas.
	var scale_factor := get_viewport().get_final_transform().get_scale()
	# Cap the stroke when the entire window is reduced to a thumbnail.
	var width := clampi(ceili(1.25 / maxf(0.01, minf(scale_factor.x, scale_factor.y))), 2, 6)
	if width == _button_border:
		return
	_button_border = width
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		var style := theme.get_stylebox(state, &"Button") as StyleBoxFlat
		style.set_border_width_all(width)


func _plate(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.anti_aliasing = false
	return box


func _make_gauge(node_name: String, vertical: bool, tint: Color) -> Gauge:
	var gauge := Gauge.new()
	gauge.name = node_name
	gauge.vertical = vertical
	gauge.fill_color = tint
	gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gauge)
	return gauge


func _make_icon(node_name: String, kind: String, parent: Node) -> InkIcon:
	var icon := InkIcon.new()
	icon.name = node_name
	icon.icon = kind
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	return icon


func _set_accessible(control: Control, title: String) -> void:
	control.tooltip_text = title
	for property: Dictionary in control.get_property_list():
		if property.name == "accessibility_name":
			control.set("accessibility_name", title)
			break


func _layout() -> void:
	if not is_instance_valid(_effects):
		return
	_u = clampf(minf(size.x / 1152.0, size.y / 648.0), 0.48, 2.0)
	var margin := roundf(16.0 * _u)
	var gap := roundf(9.0 * _u)
	var tall := size.y > size.x * 0.82
	var top := roundf(size.y * (0.395 if tall else 0.414))
	_arena = Rect2(margin, margin, size.x - margin * 2.0, top - margin - gap)
	var content_h := size.y - top - margin
	var available := size.x - 2.0 * margin - 2.0 * gap
	var board_w := roundf(available * 0.407)
	var lane_w := roundf(available * 0.348)
	_left = Rect2(margin, top, board_w, content_h)
	_lane = Rect2(_left.end.x + gap, top, lane_w, content_h)
	_status = Rect2(_lane.end.x + gap, top, available - board_w - lane_w, content_h)
	_place(_result_flash, _left)
	_place(_miss_flash, _lane)
	_place(_weather, _lane.grow(-maxf(3.0, 5.0 * _u)))
	_layout_arena(tall)
	var padding := _left.size.x * 0.053
	var header_height := clampf(_left.size.y * 0.095, 34.0 * _u, 50.0 * _u)
	var spacing := roundf(maxf(4.0 * _u, board_w * 0.012))
	var footer_space := clampf(content_h * 0.13, 49.0 * _u, 75.0 * _u)
	var box := floorf(minf((board_w - 2.0 * padding - 2.0 * spacing) / 3.0,
		(content_h - header_height - footer_space * 0.30 - 20.0 * _u - 2.0 * spacing) / 3.0))
	var centre := _left.get_center() + Vector2(0.0, (header_height - footer_space * 0.55) * 0.5)
	var anchor_rect := Rect2(centre - Vector2.ONE * box * 0.5, Vector2.ONE * box)
	_place(_anchor, anchor_rect)
	for action: String in _slots:
		_place(_slots[action], Rect2(anchor_rect.position + SLOT_DIRECTIONS[action] * (box + spacing), anchor_rect.size))
	_place(_reject, Rect2(_left.end - anchor_rect.size - Vector2.ONE * 10.0 * _u, anchor_rect.size))
	_fall_size = floorf(minf(lane_w * 0.278, content_h * 0.23))
	_fall_start = _lane.position.y + 8.0 * _u
	_fall_end = _lane.end.y - 6.0 * _u
	_layout_status()
	_scale_fonts()
	_update_cards()
	_effects.set_anchors(_anchor.get_rect().get_center(), _boss_art.get_rect().get_center(),
		_player_bar.get_rect().get_center())
	_effects.set_player_region(_status)
	_boss_status.set_layout(_boss_art.get_rect(), _energy_bar.get_rect(), _item_buttons)
	_effects.fire_target = _lane.get_center()
	_effects.ink_target = Vector2(_lane.get_center().x, _lane.position.y + 0.1 * _lane.size.y)
	_effects.set_charge_anchors(_reject.get_rect().get_center(), _energy_bar.get_rect(),
		_foe_charge.get_rect(), _special.get_rect())
	_center_modal()
	queue_redraw()


func _layout_arena(tall: bool) -> void:
	var inset := _arena.size.x * 0.022
	var header_h := clampf(_arena.size.y * 0.19, 46.0 * _u, (92.0 if tall else 70.0) * _u)
	var head_y := _arena.position.y + 1.0 * _u
	# Reserve three digits for the purse so the chest clock holds still as coins accumulate.
	var scale_factor := maxf(_u, minf(2.1, size.x / 680.0)) if tall else _u
	var points := maxi(14, roundi(22.0 * scale_factor))
	var mark_size := floorf(minf(header_h * 0.64, 25.0 * scale_factor))
	var icon_gap := roundf(3.0 * scale_factor)
	var group_gap := roundf(14.0 * scale_factor)
	for label: Label in [_stage_label, _wallet, _chest_time]:
		label.add_theme_font_size_override("font_size", points)
	var bold := _stage_label.get_theme_font("font")
	var font := _wallet.get_theme_font("font")
	var level_w := ceilf(bold.get_string_size("關卡 5-5", HORIZONTAL_ALIGNMENT_LEFT, -1, points).x) + 2.0
	var purse_w := ceilf(font.get_string_size("000", HORIZONTAL_ALIGNMENT_LEFT, -1, points).x) + 2.0
	var clock_w := ceilf(font.get_string_size("00:00", HORIZONTAL_ALIGNMENT_LEFT, -1, points).x) + 2.0
	var mark_y := head_y + (header_h - mark_size) * 0.5
	_place(_stage_label, Rect2(_arena.position.x + inset, head_y, level_w, header_h))
	_place(_wallet_icon, Rect2(_stage_label.get_rect().end.x + group_gap, mark_y, mark_size, mark_size))
	_place(_wallet, Rect2(_wallet_icon.get_rect().end.x + icon_gap, head_y, purse_w, header_h))
	_place(_chest_icon, Rect2(_wallet.get_rect().end.x + group_gap, mark_y, mark_size, mark_size))
	_place(_chest_time, Rect2(_chest_icon.get_rect().end.x + icon_gap, head_y, clock_w, header_h))
	for label: Label in [_stage_label, _wallet, _chest_time]:
		label.position.y = roundf(head_y + (header_h - label.size.y) * 0.5)
	var pause_size := minf(header_h - 4.0 * _u, (82.0 if tall else 52.0) * _u)
	_place(_pause_button, Rect2(_arena.end.x - inset - pause_size, head_y + (header_h - pause_size) * 0.5, pause_size, pause_size))
	var loadout_x := _chest_time.get_rect().end.x + group_gap
	var loadout_width := maxf(0.0, _pause_button.position.x - loadout_x - group_gap)
	_place(_loadout_status, Rect2(loadout_x, head_y + header_h * 0.14, loadout_width, header_h * 0.72))
	var face_size := roundf(pause_size * 0.55)
	_place(_pause_face, Rect2(Vector2.ONE * ((pause_size - face_size) * 0.5), Vector2.ONE * face_size))
	var body_top := head_y + header_h
	var body_height := _arena.end.y - body_top - 6.0 * _u
	var art_w := _arena.size.x * (0.48 if tall else 0.40)
	var art_left := _arena.position.x + _arena.size.x * (0.030 if tall else 0.080)
	_place(_boss_art, Rect2(art_left, body_top, art_w, body_height))
	var info_w := _arena.size.x * (0.405 if tall else 0.337)
	var info_x := _arena.position.x + _arena.size.x * (0.54 if tall else 0.535)
	var title_h := minf(body_height * 0.245, 53.0 * _u)
	var row_h := minf(body_height * 0.182, (54.0 if tall else 41.0) * _u)
	var info_top := body_top + (body_height - title_h - 3.0 * row_h) * 0.5
	_place(_boss_name, Rect2(info_x, info_top, info_w, title_h))
	var gauges := [_boss_bar, _foe_charge, _foe_clock]
	var icon := minf(row_h * 0.62, 25.0 * _u)
	for i in range(gauges.size()):
		var row_y := info_top + title_h + row_h * i
		_place(_foe_icons[i], Rect2(info_x, row_y + (row_h - icon) * 0.5, icon, icon))
		var bar_x := info_x + icon + 12.0 * _u
		var bar_h := clampf(row_h * 0.43, 10.0 * _u, 19.0 * _u)
		_place(gauges[i], Rect2(bar_x, row_y + (row_h - bar_h) * 0.5, info_x + info_w - bar_x, bar_h))


func _layout_status() -> void:
	var w := _status.size.x
	var h := _status.size.y
	var cells := [0.191, 0.477, 0.799]
	var gap := maxf(3.0 * _u, w * 0.023)
	var item_size := floorf(minf(w * 0.274, h * 0.231))
	var track_h := 3.0 * item_size + 2.0 * gap
	if size.y > size.x * 0.82:
		track_h = maxf(track_h, h * 0.565)
	var item_gap := (track_h - 3.0 * item_size) * 0.5
	var icon_size := minf(item_size, maxf(36.0 * _u, item_size * 0.69))
	var top := _status.get_center().y - (track_h + icon_size + gap) * 0.5
	var track_y := top + icon_size + gap
	var meter_w := floorf(w * 0.143)
	var marks := [_special, _health_icon, _bag_icon]
	for i in range(3):
		var x := _status.position.x + w * float(cells[i])
		_place(marks[i], Rect2(x - icon_size * 0.5, top, icon_size, icon_size))
		if i < 2:
			_place(_energy_bar if i == 0 else _player_bar, Rect2(x - meter_w * 0.5, track_y, meter_w, track_h))
		else:
			for j in range(3):
				_place(_item_buttons[j], Rect2(x - item_size * 0.5, track_y + (item_size + item_gap) * j, item_size, item_size))


func _scale_fonts() -> void:
	_boss_name.add_theme_font_size_override("font_size", int(_boss_name.size.y * 0.67))
	_anchor.add_theme_font_size_override("font_size", maxi(20, int(_anchor.size.y * 0.64)))
	var glyph_size := maxi(20, int(_fall_size * 0.59))
	for lane in range(_cards.size()):
		_cards[lane].add_theme_font_size_override("font_size", glyph_size)
		_glyph_faces[lane].add_theme_font_size_override("font_size", glyph_size)


func _place(control: Control, box: Rect2) -> void:
	control.position = box.position.round()
	control.size = box.size.round()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), NIGHT)
	if _arena.size.x <= 0.0:
		return
	var stroke := maxi(3, roundi(4.0 * _u))
	for zone: Rect2 in [_arena, _left, _lane, _status]:
		var tint := PAPER
		var fill := NIGHT if zone == _arena else PANEL
		if zone == _left and _feedback > 0.0:
			tint = _feedback_colour
			fill = PANEL.lerp(tint, 0.13)
		draw_style_box(_plate(fill, tint, stroke), zone)
		_draw_corners(self, zone, tint, maxf(2.0, roundf(stroke * 0.55)))


func _draw_dialog_corners(panel: PanelContainer) -> void:
	_draw_corners(panel, Rect2(Vector2.ZERO, panel.size), PAPER, maxf(2.0, roundf(_u * 2.0)))


func _draw_corners(canvas: CanvasItem, area: Rect2, tint: Color, pixel: float) -> void:
	# Mirrored key corners meet the stepped rails on all four sides.
	var dim := tint.darkened(0.42)
	for axis: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		var corner := Vector2(area.position.x if axis.x > 0 else area.end.x, area.position.y if axis.y > 0 else area.end.y)
		for mark: Rect2 in [Rect2(3, 3, 12, 1), Rect2(3, 3, 1, 9), Rect2(3, 11, 5, 1),
				Rect2(7, 6, 1, 5), Rect2(6, 6, 1, 1), Rect2(10, 5, 3, 1)]:
			canvas.draw_rect(Rect2(corner + mark.position * axis * pixel, mark.size * axis * pixel).abs(), tint)
		canvas.draw_rect(Rect2(corner + Vector2(17, 3) * axis * pixel, Vector2(4, 1) * axis * pixel).abs(), dim)
	_edge_band(canvas, area.position, Vector2.RIGHT, Vector2.DOWN, area.size.x, pixel, tint)
	_edge_band(canvas, Vector2(area.position.x, area.end.y), Vector2.RIGHT, Vector2.UP, area.size.x, pixel, tint)
	_edge_band(canvas, area.position, Vector2.DOWN, Vector2.RIGHT, area.size.y, pixel, tint)
	_edge_band(canvas, Vector2(area.end.x, area.position.y), Vector2.DOWN, Vector2.LEFT, area.size.y, pixel, tint)


func _edge_band(canvas: CanvasItem, start: Vector2, tangent: Vector2, inward: Vector2, length: float, pixel: float, tint: Color) -> void:
	var span := length / pixel - 46.0
	if span < 13.0:
		return
	# A continuous narrow rail steps in and out around alternating square knots.
	# Keep the ornament within six pixels of the frame, clear of cards and HUD icons.
	var count := maxi(1, 2 * roundi((span / 34.0 - 1.0) / 2.0) + 1)
	var step := span / count
	var shade := Color("#a39a83").lerp(tint, 0.20)
	var stone := Color("#ffdb87") if tint == PAPER else tint
	var rail_start := start + tangent * 23.0 * pixel + inward * 2.5 * pixel
	for i in range(count):
		var centre := rail_start + tangent * (i + 0.5) * step * pixel
		var half := tangent * roundf(step * 0.5) * pixel
		var along := tangent * pixel
		var down := inward * pixel
		if i == (count >> 1):
			var point := centre + down * 2
			canvas.draw_line(centre - half, centre + half, shade, pixel)
			canvas.draw_colored_polygon(PackedVector2Array([point - along * 5, point - down * 2,
				point + along * 5, point + down * 3]), tint)
			canvas.draw_rect(Rect2((point - along).round(), along * 2 + down * 2).abs(), stone.darkened(0.45))
			continue
		var path := PackedVector2Array([centre - half, centre - 6 * along,
			centre - 6 * along + down * 2, centre - 3 * along + down * 2,
			centre - 3 * along + down * 3, centre + 3 * along + down * 3,
			centre + 3 * along + down * 2, centre + 6 * along + down * 2,
			centre + 6 * along, centre + half])
		canvas.draw_polyline(path, shade, pixel)
		canvas.draw_rect(Rect2((centre - along + down * 0.5).round(), (along * 2 + down * 2)).abs(),
			stone if i % 2 == 0 else tint)


func _draw_slot_mark(slot: Button, action: String) -> void:
	if not slot.text.is_empty():
		return
	var normal: Vector2 = SLOT_DIRECTIONS[action]
	var side := Vector2(-normal.y, normal.x)
	var origin := slot.size * 0.5 + normal * slot.size.x * 0.15
	var r := maxf(4, roundf(slot.size.x * 0.085))
	var line := maxf(1, roundf(r / 4.0))
	slot.draw_polyline(PackedVector2Array([origin - side * r - normal * r * 0.8,
		origin, origin + side * r - normal * r * 0.8]), Color("#a29f97"), line)


func _draw_card_mark(card: Button) -> void:
	if not card.get_meta("selected", false):
		return
	var unit := maxf(2, roundf(card.size.x * 0.045))
	for i in range(3):
		card.draw_rect(Rect2(2 * unit + i * unit, 2 * unit, unit, (3 - i) * unit), Color("#74630d"))
	if card.get_meta("shuffling", false):
		var p := card.size - Vector2.ONE * 3 * unit
		card.draw_rect(Rect2(p - Vector2(3,0)*unit, Vector2(4,1)*unit),Color("#906321"))
		card.draw_rect(Rect2(p - Vector2(1,3)*unit, Vector2(1,4)*unit),Color("#906321"))


func _draw_anchor_mask() -> void:
	if not _anchor_masked:
		return
	var px := maxf(1.0, _anchor.size.x / 23.0)
	var centre := (_anchor.size * 0.5).round()
	for i in range(3):
		var y := (i - 1) * 4 * px
		var x := (-5.0 + (1 if i == 1 else 0)) * px
		_anchor.draw_rect(Rect2(centre + Vector2(x, y - px), Vector2(10, 2) * px), Color("#597a54"))
		_anchor.draw_rect(Rect2(centre + Vector2(x + (3 + i) * px, y - px), Vector2(1, 2) * px), Color("#a5b182"))


func _draw_empty_item(item: Button, index: int) -> void:
	if run.items.size() > index:
		return
	var dot := maxf(2, floorf(item.size.x * 0.065))
	var middle := (item.size * 0.5).round()
	item.draw_rect(Rect2(middle - Vector2(dot * 1.5, dot * 0.5), Vector2(dot * 3, dot)), RULE)


func _update_cards() -> void:
	var playing := run.phase == "battle"
	_loadout_status.sync(run)
	_weather.show_effects(run.ink_fraction if playing else 0.0, playing and run.haste_seconds > 0.0,
		run.active_seconds, run.rock_fraction if playing else 0.0, playing and run.effect_seconds("freeze") > 0.0)
	_boss_status.show_stance(run.armour_drops if playing else 0, run.bonus_hits if playing else 0)
	var masked := playing and run.effect_seconds("mask") > 0.0
	if masked != _anchor_masked:
		_anchor_masked = masked
		_anchor.text = "" if masked else str(run.deck.get("anchor", ""))
		_set_accessible(_anchor, "部件被遮蓋" if masked else _anchor.text)
		_anchor.queue_redraw()
	var shuffling := playing and run.effect_seconds("shuffle") > 0.0
	var dimming := playing and run.effect_seconds("dim") > 0.0
	var visible_lanes: Array[int] = []
	for tile: Dictionary in run.active_tiles:
		var lane := int(tile.lane)
		var card := _cards[lane]
		visible_lanes.append(lane)
		var selected := int(tile.id) == run.tile_id
		var hinted := int(tile.id) == run.hinted_tile_id
		var pinned := int(tile.id) == run.pinned_tile_id
		if card.get_meta("id", -1) != int(tile.id) or card.get_meta("selected", false) != selected or card.get_meta("hinted", false) != hinted or card.get_meta("pinned", false) != pinned:
			card.set_meta("id", int(tile.id))
			card.set_meta("selected", selected)
			card.set_meta("hinted", hinted)
			card.set_meta("pinned", pinned)
			var description := "%d · %s" % [lane + 1, tile.glyph]
			if hinted:
				description += "，可組字"
			if pinned:
				description += "，已夾住"
			_set_accessible(card, description)
			var style := _active_tile_style if selected else _idle_tile_style
			for state in ["normal", "hover", "pressed", "disabled"]:
				card.add_theme_stylebox_override(state, style)
			card.queue_redraw()
		if bool(card.get_meta("shuffling", false)) != shuffling:
			card.set_meta("shuffling", shuffling)
			card.queue_redraw()
		_place(card, _tile_rect(tile))
		var badge_side := roundf(card.size.x * 0.32)
		var badge_x := card.size.x - badge_side
		var lamp: Control = card.get_node("item_lantern")
		var clip: Control = card.get_node("item_clip")
		lamp.visible = hinted
		clip.visible = pinned
		if hinted:
			_place(lamp, Rect2(badge_x, 0, badge_side, badge_side))
		if pinned:
			_place(clip, Rect2(badge_x, card.size.y - badge_side, badge_side, badge_side))
		var angle := run.tile_rotation_degrees(int(tile.id)) if playing else 0.0
		var face := _glyph_faces[lane]
		face.visible = not is_zero_approx(angle) or dimming
		var glyph := str(tile.glyph)
		card.text = "" if face.visible else glyph
		if face.visible:
			face.text = glyph
			face.pivot_offset = card.size * 0.5
			face.rotation_degrees = angle
			var pulse := 0.5 + 0.5 * sin(run.active_seconds * 4.5 + lane * 2.09)
			face.self_modulate.a = 0.47 + 0.53 * pulse if dimming else 1.0
		else:
			face.text = ""
			face.rotation = 0.0
		card.show()
	for i in range(_cards.size()):
		if i not in visible_lanes:
			_cards[i].hide()


func _tile_rect(tile: Dictionary) -> Rect2:
	var p := clampf(float(tile.age) / run.fall_duration, 0.0, 1.0)
	var lane_w := (_lane.size.x - 8.0 * _u) / 3.0
	var x := _lane.position.x + 4.0 * _u + lane_w * (int(tile.lane) + 0.5) - _fall_size * 0.5
	if run.gust_drops > 0:
		x += sin(p * TAU * 1.5 + int(tile.lane)) * maxf(0.0, (lane_w - _fall_size) * 0.46)
	return Rect2(x, lerpf(_fall_start, _fall_end - _fall_size, p), _fall_size, _fall_size)


func _process(delta: float) -> void:
	if _application_paused or _user_paused:
		return
	if _celebration.visible:
		_celebration.advance(delta)
		return
	if _countdown >= 0.0:
		_countdown -= delta
		if _countdown <= 0.0:
			_countdown = -1.0
			_hide_menu()
			run.begin_fight()
			_set_foe_visible(true)
			_update_cards()
			_sync_hud(false)
			get_viewport().gui_release_focus()
		else:
			_count_label.text = str(ceili(_countdown))
		return
	if _overlay_open:
		return
	if not _result_flash.glyph.is_empty() or not _miss_flash.glyph.is_empty():
		_result_flash.advance(delta)
		_miss_flash.advance(delta)
		_sync_board_opacity()
	_effects.advance(delta)
	_weather.advance(delta)
	_boss_status.advance(delta)
	if _feedback > 0.0:
		_feedback = maxf(0.0, _feedback - delta)
		if _feedback == 0.0:
			_clear_feedback()
	if _finish_delay >= 0.0:
		_finish_delay -= delta
		if _finish_delay <= 0.0:
			_finish_delay = -1.0
			if run.phase == "won":
				if run.encounter_index + 1 == run.route.size():
					_advance()
				else:
					_show_victory()
			else:
				_show_defeat()
		return
	if run.phase != "battle":
		return
	var events := run.advance_time(delta)
	for event: Dictionary in events:
		match str(event.kind):
			"expiry":
				_show_tile_outcome(event)
			"foe_launch":
				_sounds.play_cue("foe_heavy" if bool(event.shot.heavy) else "foe_shot")
				var target := _player_bar.get_rect().get_center()
				match event.shot.effect.get("kind", ""):
					"ink": target = _effects.ink_target
					"incinerate": target = _effects.fire_target
				_boss_art.on_fire(bool(event.shot.heavy), target - _boss_art.get_rect().get_center())
			"impact":
				var foe := str(event.source) == "foe"
				if foe:
					_show_boss_effect(event.effect)
					if event.get("effect_blocked", false):
						_loadout_status.signal_used("item_umbrella", run.active_seconds)
						_sounds.play_cue("shield_block")
					if not event.get("counter_shot", {}).is_empty():
						_loadout_status.signal_used("power_mirror", run.active_seconds)
						_sounds.play_cue("player_heavy")
				_sounds.impact(event)
				if int(event.damage) > 0 or bool(event.shielded):
					_effects.impact(foe, bool(event.heavy), int(event.damage))
				if not foe and int(event.damage) > 0:
					_boss_art.on_hit(bool(event.heavy))
	_effects.sync_shots(run.projectiles)
	_update_cards()
	if not events.is_empty():
		_sync_hud(true)
	else:
		_update_clocks()
	_sync_item_availability()
	if run.phase == "won":
		_boss_art.on_defeat()
		_finish_delay = BossArt.DEFEAT_DURATION
		_sync_actions()
	elif run.phase == "defeat":
		_finish_delay = 0.45
		_sync_actions()


func _show_boss_effect(effect: Dictionary) -> void:
	match effect.get("kind", ""):
		"incinerate":
			var destroyed: Array[Rect2] = []
			for tile: Dictionary in effect.tiles:
				destroyed.append(_tile_rect(tile))
			_weather.incinerate(destroyed)
		"current":
			_weather.start_current()
		"steal", "restore", "drain":
			_boss_status.impact(effect)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_application_paused = true
			_refresh_frozen()
		NOTIFICATION_WM_WINDOW_FOCUS_IN, NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_application_paused = false
			_refresh_frozen()


func _can_pause() -> bool:
	return _countdown >= 0.0 or run.phase == "battle" or _finish_delay >= 0.0


func _toggle_pause() -> void:
	if not _user_paused and not _can_pause():
		return
	_user_paused = not _user_paused
	_pause_shade.visible = _user_paused
	if _user_paused:
		_previous_focus = get_viewport().gui_get_focus_owner()
		_resume.grab_focus()
	else:
		if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
			_previous_focus.grab_focus()
	_refresh_frozen()


func _refresh_frozen() -> void:
	if not is_instance_valid(_voice):
		return
	var frozen := _user_paused or _application_paused
	for gauge: Gauge in [_boss_bar, _foe_charge, _foe_clock, _energy_bar, _player_bar]:
		gauge.set_frozen(frozen)
	_boss_art.set_frozen(frozen)
	_voice.stream_paused = frozen
	_sounds.set_frozen(frozen)
	_result_flash.visible = not _user_paused and not _result_flash.glyph.is_empty()
	_miss_flash.visible = not _user_paused and not _miss_flash.glyph.is_empty()
	_sync_board_opacity()
	_sync_actions()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode in [KEY_ESCAPE, KEY_P] and (_user_paused or _can_pause()):
		get_viewport().set_input_as_handled()
		var button := _resume if _user_paused else _pause_button
		button.pressed.emit()
		return
	if not _can_act():
		return
	var direction := ""
	match event.keycode:
		KEY_UP: direction = "top"
		KEY_RIGHT: direction = "right"
		KEY_DOWN: direction = "bottom"
		KEY_LEFT: direction = "left"
		KEY_X: direction = "reject"
		KEY_1, KEY_2, KEY_3:
			var card := _cards[int(event.keycode) - KEY_1]
			if card.visible:
				card.pressed.emit()
		_:
			return
	get_viewport().set_input_as_handled()
	if not direction.is_empty():
		var slot: Button = _reject if direction == "reject" else _slots[direction]
		slot.pressed.emit()


func _select_lane(lane: int) -> void:
	if _can_act() and _cards[lane].visible and run.select_tile(int(_cards[lane].get_meta("id", -1))):
		_update_cards()


func _can_act() -> bool:
	return run.phase == "battle" and not _overlay_open and not _user_paused and not _application_paused


func _commit(action: String) -> void:
	if not _can_act():
		return
	var previous_foe_charge := run.boss_charge
	var outcome := run.resolve_tile(action, run.tile_id)
	if str(outcome.get("kind", "ignored")) == "ignored":
		return
	if outcome.get("error_protected", false):
		_loadout_status.signal_used("item_calm", run.active_seconds)
	_show_tile_outcome(outcome)
	if int(outcome.energy_gained) > 0:
		_effects.charge_transfer()
		_sounds.charge("player", run.energy >= run.energy_cost)
	if run.boss_charge > previous_foe_charge:
		var portion := float(run.boss_charge) / run.boss_charge_max
		_effects.foe_charge_transfer(action == "reject", portion)
		_sounds.charge("foe", run.boss_charge >= run.boss_charge_max)
	_effects.sync_shots(run.projectiles)
	_update_cards()
	_sync_hud(true)


func _show_tile_outcome(outcome: Dictionary) -> void:
	var kind := str(outcome.kind)
	if kind == "expiry":
		if bool(outcome.valid_tile):
			_miss_flash.ink = MISS_INK
			_miss_flash.play(str(outcome.result))
		return
	_clear_feedback()
	var direction := str(outcome.get("answer_slot", ""))
	var answer := str(outcome.get("result", ""))
	if kind == "hit":
		_result_flash.play(answer)
		_play_answer(str(outcome.audio))
		_sounds.play_cue("player_shot")
		return
	if kind == "correct_reject":
		if not outcome.get("shot", {}).is_empty():
			_loadout_status.signal_used("power_reject_flame", run.active_seconds)
			_sounds.play_cue("player_heavy")
		return
	_feedback = 0.93
	_feedback_colour = PAPER if kind == "unscored" else ROSE
	if not answer.is_empty():
		_miss_flash.ink = PAPER if kind == "unscored" else MISS_INK
		_miss_flash.play(answer)
	if not direction.is_empty():
		var slot := _slots[direction]
		slot.text = str(outcome.glyph)
		var highlighted := _plate(PANEL.lerp(_feedback_colour, 0.24), _feedback_colour, maxi(3, _button_border))
		for state in ["normal", "hover", "pressed"]:
			slot.add_theme_stylebox_override(state, highlighted)
		slot.add_theme_font_size_override("font_size", maxi(20, int(slot.size.y * 0.57)))
	queue_redraw()


func _play_answer(path: String) -> void:
	var clip: AudioStream = _audio.get(path)
	if not clip:
		return
	_voice_queue.append(clip)
	if not _voice.playing:
		_play_next_answer()


func _play_next_answer() -> void:
	_sounds.set_speech_active(not _voice_queue.is_empty())
	if not _voice_queue.is_empty():
		_voice.stream = _voice_queue.pop_front()
		_voice.play()


func _reset_speech() -> void:
	_sounds.set_speech_active(false)
	_voice.stop()
	_voice_queue.clear()
	_voice.stream = null


func _sync_board_opacity() -> void:
	var alpha := _result_flash.board_opacity()
	_anchor.self_modulate.a = alpha
	for slot: Button in _slots.values():
		slot.self_modulate.a = alpha
	var lane_alpha := _miss_flash.board_opacity()
	for card: Button in _cards:
		card.self_modulate.a = lane_alpha


func _clear_feedback() -> void:
	_result_flash.clear()
	_sync_board_opacity()
	_feedback = 0.0
	for slot: Button in _slots.values():
		if slot.text.is_empty():
			continue
		slot.text = ""
		for state: StringName in [&"normal", &"hover", &"pressed"]:
			if slot.has_theme_stylebox_override(state):
				slot.remove_theme_stylebox_override(state)
	queue_redraw()


func _use_special() -> void:
	if _can_act() and str(run.use_special().kind) == "special":
		_sounds.play_cue("player_heavy")
		_effects.sync_shots(run.projectiles)
		_update_cards()
		_sync_hud(true)


func _use_item(index: int) -> void:
	if not _can_act() or index < 0 or index >= run.items.size():
		return
	var kind := str(run.items[index].kind)
	if run.use_item(index):
		_sounds.play_cue("item_" + kind)
		if kind == "energy" and run.energy == run.energy_cost:
			_sounds.charge("player", true)
		_update_cards()
		_sync_hud(true)


func _sync_hud(animate: bool) -> void:
	_boss_bar.set_fill(float(run.boss_hp) / maxf(1.0, run.boss_max_hp), animate)
	_player_bar.set_fill(float(run.hp) / maxf(1.0, run.max_hp), animate)
	_energy_bar.set_fill(float(run.energy) / maxf(1.0, run.energy_cost), animate)
	_foe_charge.set_fill(float(run.boss_charge) / maxf(1.0, run.boss_charge_max), animate)
	_set_foe_hint(0, _boss_bar, "生命 %d/%d" % [run.boss_hp, run.boss_max_hp])
	_set_foe_hint(1, _foe_charge, "重擊蓄力 %d/%d" % [run.boss_charge, run.boss_charge_max])
	_wallet.text = str(run.coins)
	for i in range(_item_buttons.size()):
		var item: Dictionary = run.items[i] if i < run.items.size() else {}
		_item_icons[i].icon = "" if item.is_empty() else "item_" + str(item.kind)
		var hint := "空道具格" if item.is_empty() else "%s　%s" % [item.get("name", ""), item.get("description", "")]
		_set_accessible(_item_buttons[i], hint)
		_item_buttons[i].queue_redraw()
	_update_clocks()
	_sync_actions()


func _update_clocks() -> void:
	var remaining := maxi(0, ceili(run.chest_budget - run.active_seconds))
	if not run.coin_award.is_empty():
		# At victory show the settled whole seconds that earned the time bonus.
		remaining = int(run.coin_award.seconds_left)
	_chest_time.text = "%02d:%02d" % [remaining / 60, remaining % 60]
	_chest_time.modulate = Color.WHITE if remaining > 0 else MUTED
	_foe_clock.set_fill(1.0 - run.boss_cooldown_left / maxf(0.01, run.boss_cooldown_duration))
	_set_foe_hint(2, _foe_clock, "下次出招 %d 秒" % ceili(run.boss_cooldown_left))


func _set_foe_hint(index: int, gauge: Gauge, hint: String) -> void:
	if gauge.tooltip_text != hint:
		_set_accessible(gauge, hint)
		_set_accessible(_foe_icons[index], hint)


func _sync_actions() -> void:
	var active := _can_act()
	for slot: Button in _slots.values():
		slot.disabled = not active
	_reject.disabled = not active
	_special.disabled = not active or run.energy < run.energy_cost
	_effects.set_heavy_ready(run.phase == "battle" and not _overlay_open and run.energy >= run.energy_cost)
	_special_icon.modulate = Color.WHITE if not _special.disabled else Color("#aba9a1")
	_sync_item_availability()
	for card: Button in _cards:
		card.disabled = not active
	_pause_button.visible = not _user_paused and _can_pause()


func _sync_item_availability() -> void:
	for i in range(_item_buttons.size()):
		_item_buttons[i].disabled = not _can_act() or not run.can_use_item(i)
		_item_icons[i].modulate = MUTED.darkened(0.4) if _item_buttons[i].disabled else Color.WHITE


func _restart_from_pause() -> void:
	if not _user_paused:
		return
	_user_paused = false
	_pause_shade.hide()
	_previous_focus = null
	_sounds.stop_music()
	_start_run()
	_refresh_frozen()


func _start_run() -> void:
	_countdown = -1.0
	_finish_delay = -1.0
	_reset_speech()
	_sounds.stop_all()
	_effects.clear()
	_boss_status.clear()
	_weather.clear()
	run.start_run(int(Time.get_ticks_usec() ^ randi()))
	_set_foe_visible(false)
	_stage_label.hide()
	_anchor.text = ""
	_special_icon.icon = "bolt"
	_update_cards()
	_sync_hud(false)
	var options := _show_menu("選擇必殺技")
	var hand := _make_card_row(options, "PowerDraw")
	for offer: Dictionary in run.offers:
		_add_power_card(hand, offer)
	_focus_menu(options)


func _set_foe_visible(shown: bool) -> void:
	for part: Control in [_boss_art, _boss_name, _boss_bar, _foe_charge, _foe_clock]:
		part.visible = shown
	for icon: InkIcon in _foe_icons:
		icon.visible = shown


func _make_card_row(options: VBoxContainer, node_name: String) -> HBoxContainer:
	var hand := HBoxContainer.new()
	hand.name = node_name
	hand.add_theme_constant_override("separation", 9)
	options.add_child(hand)
	return hand


func _make_choice_card(hand: HBoxContainer, node_name: String, hint: String, action: Callable) -> VBoxContainer:
	var card := _make_button(node_name, "", hand)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 146)
	card.set_meta("menu_card", true)
	card.add_theme_stylebox_override("focus", _plate(Color.TRANSPARENT, GOLD, 3))
	_set_accessible(card, hint)
	card.pressed.connect(action)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 5)
	center.add_child(stack)
	return stack


func _add_power_card(hand: HBoxContainer, offer: Dictionary) -> void:
	var stack := _make_choice_card(hand, "Power" + str(offer.id).capitalize(),
		"%s　%s" % [offer.name, offer.description], _choose_power.bind(str(offer.id)))
	var icon := _make_icon("PowerMark", "power_" + str(offer.id), stack)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.set_meta("menu_icon", 48)
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.add_theme_constant_override("separation", 8)
	stack.add_child(stats)
	_add_metric(stats, "Damage", "attack", str(offer.damage), "")
	var strength := int(offer.effect_value)
	match str(offer.id):
		"mark": _add_metric(stats, "Effect", "power_mark", "×%d" % strength, "")
		"break_charge": _add_metric(stats, "Effect", "foe_charge", "−%d" % strength, "")
		"mirror", "reject_flame":
			_add_metric(stats, "Effect", "attack", "+%d" % strength, "")
			_add_metric(stack, "Window", "clock", "5", "")
		"slow":
			_add_metric(stats, "Effect", "power_slow", "−%d%%" % strength, "")
			_add_metric(stack, "Window", "clock", "4", "")
		"cleanse": _add_metric(stats, "Effect", "power_cleanse", "×%d" % strength, "")
		"comeback": _add_metric(stats, "Effect", "health", "½→%d" % strength, "")
		"stars": _add_metric(stats, "Effect", "power_stars", "+0–%d" % strength, "")
		"ward": _add_metric(stats, "Effect", "shield", str(int(offer.effect_value)), "")
		"heal": _add_metric(stats, "Effect", "health", "+%d" % int(offer.effect_value), "")
		"delay": _add_metric(stats, "Effect", "clock", "%d%%" % roundi(float(offer.effect_value) * 100.0), "")


func _choose_power(action: String) -> void:
	if run.phase != "power":
		return
	run.choose_special(action)
	if run.phase == "ready":
		_sounds.start_music()
		_special_icon.icon = "power_" + action
		_prepare_encounter()


func _prepare_encounter() -> void:
	_reset_speech()
	_sounds.stop_all()
	_countdown = -1.0
	_finish_delay = -1.0
	_clear_feedback()
	_effects.clear()
	_boss_status.clear()
	_weather.clear()
	_update_cards()
	_set_foe_visible(false)
	_boss_name.text = str(run.boss.name)
	_boss_art.show_form(str(run.boss.family), int(run.boss.stage_form))
	_stage_label.text = "最終戰" if run.is_dragon else "關卡 %d-%d" % [run.stage, run.foe_in_stage]
	_set_accessible(_stage_label, "最終戰" if run.is_dragon else "第 %d 關，第 %d 位對手" % [run.stage, run.foe_in_stage])
	_stage_label.show()
	_anchor.text = str(run.deck.anchor)
	_set_accessible(_anchor, _anchor.text)
	_set_accessible(_special, run.special_name)
	_preload_deck_audio()
	_sync_hud(false)
	_start_countdown()


func _start_countdown() -> void:
	if run.phase != "ready" or _countdown >= 0.0:
		return
	var menu := _show_menu("")
	_count_label = _make_label("Countdown", 63, PAPER, menu)
	_count_label.custom_minimum_size.y = 98.0 * _u
	_count_label.text = "3"
	_countdown = 3.0
	_sync_actions()


func _hide_menu() -> void:
	_overlay.hide()
	_overlay_open = false


func _preload_deck_audio() -> void:
	for tile: Dictionary in run.deck.get("tiles", []):
		var placements: Dictionary = tile.get("placements", {})
		for entry: Dictionary in placements.values():
			var path := str(entry.get("audio", ""))
			if not path.is_empty() and not _audio.has(path) and ResourceLoader.exists(path):
				var clip := load(path) as AudioStream
				if clip:
					_audio[path] = clip


func _show_victory() -> void:
	var has_chest := run.chest_earned and not run.rewards.is_empty()
	var menu := _show_menu("" if has_chest else "戰鬥勝利")
	if has_chest:
		var chest := _make_icon("ChestReward", "chest_open", menu)
		chest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		chest.set_meta("menu_icon", 44)
		_set_accessible(chest, "戰鬥勝利，選一件寶箱道具")
	_show_payout(menu)
	if has_chest:
		var hand := _make_card_row(menu, "RewardDraw")
		for reward: Dictionary in run.rewards:
			var stack := _make_choice_card(hand, "Reward" + str(reward.id).capitalize(),
				"%s　%s" % [reward.name, reward.description], _claim_item.bind(str(reward.id)))
			var icon := _make_icon("RewardMark", "item_" + str(reward.kind), stack)
			icon.set_meta("menu_icon", 66)
	else:
		_menu_button(menu, "Continue", "繼續", _advance)
	_focus_menu(menu)


func _show_payout(menu: VBoxContainer) -> void:
	if run.coin_award.is_empty():
		return
	var prize := HBoxContainer.new()
	prize.name = "Payout"
	prize.alignment = BoxContainer.ALIGNMENT_CENTER
	prize.add_theme_constant_override("separation", 20)
	menu.add_child(prize)
	var total := _add_metric(prize, "Earned", "coin", "+%d" % run.coin_award.total, "本場金幣")
	total.get_node("Mark").set_meta("menu_icon", 32)
	total.get_node("Value").set_meta("menu_points", 29)
	total.get_node("Value").add_theme_color_override("font_color", GOLD)
	var balance := _make_label("WalletTotal", 17, MUTED, prize)
	balance.text = "持有 %d" % run.coins
	balance.set_meta("menu_points", 17)
	var awards := HBoxContainer.new()
	awards.name = "Breakdown"
	awards.alignment = BoxContainer.ALIGNMENT_CENTER
	awards.add_theme_constant_override("separation", 19)
	menu.add_child(awards)
	_add_metric(awards, "Base", "reward_boss", "+%d" % run.coin_award.base, "擊敗怪物")
	_add_metric(awards, "Time", "reward_time", "+%d" % run.coin_award.time, "剩餘時間獎勵")
	_add_metric(awards, "Vitality", "reward_health", "+%d" % run.coin_award.vitality, "剩餘生命獎勵")
	if run.coin_award.get("bounty", 0) > 0:
		_add_metric(awards, "Bounty", "item_bounty", "+%d" % run.coin_award.bounty, "賞金袋獎勵")
	if run.coin_award.get("stage_clear", 0) > 0:
		_add_metric(awards, "StageClear", "stage_clear", "+%d" % run.coin_award.stage_clear, "過關金幣獎勵")


func _add_metric(parent: Container, node_name: String, kind: String, value: String, hint: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = node_name
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE if hint.is_empty() else Control.MOUSE_FILTER_PASS
	parent.add_child(row)
	if not hint.is_empty():
		_set_accessible(row, "%s　%s" % [hint, value])
	var mark := _make_icon("Mark", kind, row)
	mark.set_meta("menu_icon", 21)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var label := _make_label("Value", 18, PAPER, row)
	label.set_meta("menu_points", 18)
	label.text = value
	return row


func _claim_item(id: String) -> void:
	if run.phase != "won" or not run.rewards.any(func(item: Dictionary) -> bool: return str(item.id) == id):
		return
	run.claim_reward(id)
	_sync_hud(false)
	if run.phase != "replace":
		_advance()
		return
	var menu := _show_menu("")
	menu.accessibility_name = "道具已滿，從四件道具中選一件放棄"
	var discard := _make_icon("DiscardMark", "discard", menu)
	discard.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	discard.set_meta("menu_icon", 46)
	var hand := _make_card_row(menu, "DiscardDraw")
	var choices := run.items.duplicate()
	choices.append(run.pending_item)
	for index in choices.size():
		var item: Dictionary = choices[index]
		var source := "新寶箱道具" if index == choices.size() - 1 else "背包第%d格" % (index + 1)
		var stack := _make_choice_card(hand, "Replace%d" % (index + 1), "", _replace_item.bind(index))
		var button := hand.get_child(index) as Button
		button.accessibility_name = "放棄%s：%s，%s" % [source, item.name, item.description]
		button.add_theme_stylebox_override("focus", _plate(Color.TRANSPARENT, ROSE, 3))
		var mark := _make_icon("ItemMenuMark", "item_" + str(item.kind), stack)
		mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		mark.set_meta("menu_icon", 60)
		var origin := _make_icon("OriginMark", "chest" if index == choices.size() - 1 else "bag", stack)
		origin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		origin.set_meta("menu_icon", 20)
	_focus_menu(menu)


func _replace_item(index: int) -> void:
	if run.phase != "replace":
		return
	run.choose_replacement(index)
	_sync_hud(false)
	_advance()


func _advance() -> void:
	if run.phase != "won" or not run.rewards.is_empty():
		return
	run.advance_stage()
	if run.phase == "complete":
		_hide_menu()
		_sync_actions()
		_celebration.play()
	elif run.phase == "shop":
		_show_shop()
	elif run.phase == "ready":
		_prepare_encounter()


func _show_completed_run() -> void:
	var menu := _show_menu("黑龍已敗", "已擊敗 %d 位對手" % run.route.size())
	_show_payout(menu)
	_menu_button(menu, "Restart", "再玩一次", _start_run)
	_focus_menu(menu)


func _show_shop() -> void:
	var menu := _show_menu("")
	menu.accessibility_name = "補給商店"
	var header := HBoxContainer.new()
	header.name = "ShopHeader"
	menu.add_child(header)
	var stall := _make_icon("ShopMark", "shop", header)
	stall.set_meta("menu_icon", 38)
	stall.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_BEGIN
	stall.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_add_metric(header, "RunWallet", "coin", str(run.coins), "")
	var hand := _make_card_row(menu, "ShopDraw")
	var icons := {"vitality": "health", "attack": "shop_attack", "defense": "item_shield", "charge": "bolt", "chest": "chest_time"}
	for offer: Dictionary in run.shop_offers:
		var id := str(offer.id)
		var stack := _make_choice_card(hand, "Buy" + id.capitalize(), "", _purchase_upgrade.bind(id, run.stage))
		var mark := _make_icon("UpgradeMark", icons[id], stack)
		mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		mark.set_meta("menu_icon", 48)
		var delta := _make_label("Delta", 21, PAPER, stack)
		delta.text = "%+d" % (-int(offer.amount) if id == "charge" else int(offer.amount))
		delta.set_meta("menu_points", 21)
		_add_metric(stack, "Price", "coin", str(run.shop_price), "")
		var sold := _make_icon("Sold", "purchased", stack)
		sold.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		sold.set_meta("menu_icon", 24)
	var leave := _menu_button(menu, "LeaveShop", "", _leave_shop.bind(run.stage))
	leave.accessibility_name = "前往第 %d 關" % (run.stage + 1)
	var arrow := _make_icon("ContinueMark", "continue", leave)
	arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var available := _update_shop(menu)
	_focus_menu_button.call_deferred(available.front())


func _update_shop(menu: VBoxContainer) -> Array[Button]:
	var balance: HBoxContainer = menu.get_node("ShopHeader/RunWallet")
	balance.get_node("Value").text = str(run.coins)
	balance.accessibility_name = "持有 %d 金幣" % run.coins
	var available: Array[Button] = []
	for offer: Dictionary in run.shop_offers:
		var id := str(offer.id)
		var button: Button = menu.get_node("ShopDraw/Buy" + id.capitalize())
		var bought: bool = run.shop_purchases.has(id)
		button.disabled = not run.can_buy_upgrade(id)
		button.focus_mode = Control.FOCUS_NONE if button.disabled else Control.FOCUS_ALL
		button.find_child("UpgradeMark", true, false).modulate.a = 0.45 if button.disabled else 1.0
		button.find_child("Price", true, false).visible = not bought
		button.find_child("Sold", true, false).visible = bought
		var status := "，已購買" if bought else ("，金幣不足" if button.disabled else "")
		button.accessibility_name = "%s，%d 金幣%s" % [offer.description, run.shop_price, status]
		if not button.disabled:
			available.append(button)

	var leave: Button = menu.get_node("LeaveShop")
	_link_menu_buttons(available, true)
	for button: Button in available:
		var exit_path := button.get_path_to(leave)
		button.focus_neighbor_top = exit_path
		button.focus_neighbor_bottom = exit_path
	available.append(leave)
	var first: Button = available.front()
	var last_card: Button = leave if available.size() == 1 else available[-2]
	leave.focus_previous = leave.get_path_to(last_card)
	leave.focus_next = leave.get_path_to(first)
	leave.focus_neighbor_top = leave.focus_previous
	leave.focus_neighbor_bottom = leave.focus_next
	leave.focus_neighbor_left = ^"."
	leave.focus_neighbor_right = ^"."
	first.focus_previous = first.get_path_to(leave)
	last_card.focus_next = last_card.get_path_to(leave)
	return available


func _purchase_upgrade(id: String, shop_stage: int) -> void:
	if run.stage != shop_stage or not run.buy_upgrade(id):
		return
	var menu: VBoxContainer = _modal.get_node("Options")
	var available := _update_shop(menu)
	_sync_hud(false)
	available.front().grab_focus()


func _leave_shop(shop_stage: int) -> void:
	if run.phase == "shop" and run.stage == shop_stage:
		run.leave_shop()
		_prepare_encounter()


func _show_wallet(menu: VBoxContainer) -> void:
	_add_metric(menu, "RunWallet", "coin", str(run.coins), "本輪金幣")


func _show_defeat() -> void:
	var menu := _show_menu("本輪結束")
	_show_wallet(menu)
	_menu_button(menu, "Restart", "再玩一次", _start_run)
	_focus_menu(menu)


func _show_menu(title: String, subtitle: String = "") -> VBoxContainer:
	_overlay.color = NIGHT if run.phase in ["shop", "replace"] else Color("#000000db")
	_miss_flash.clear()
	_clear_feedback()
	if is_instance_valid(_modal):
		_overlay.remove_child(_modal)
		_modal.queue_free()
	_modal = PanelContainer.new()
	_modal.name = "MenuCard"
	_modal.resized.connect(_position_menu)
	var style := _plate(Color("#0c0c0b"), PAPER, 4)
	_modal.draw.connect(_draw_dialog_corners.bind(_modal))
	style.content_margin_left = 25.0
	style.content_margin_right = 25.0
	style.content_margin_top = 19.0
	style.content_margin_bottom = 22.0
	_modal.add_theme_stylebox_override("panel", style)
	_overlay.add_child(_modal)
	var content := VBoxContainer.new()
	content.name = "Options"
	content.add_theme_constant_override("separation", 9)
	_modal.add_child(content)
	if not title.is_empty():
		var heading := _make_label("MenuTitle", 29, PAPER, content)
		heading.text = title
	if not subtitle.is_empty():
		var helper := _make_label("MenuHelp", 16, Color("#d5d5cc"), content)
		helper.text = subtitle
		helper.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overlay_open = true
	_overlay.show()
	_sync_actions()
	_center_modal.call_deferred()
	return content


func _menu_button(content: VBoxContainer, node_name: String, title: String, pressed: Callable) -> Button:
	var button := _make_button(node_name, title, content)
	button.custom_minimum_size = Vector2(0.0, 44.0)
	button.add_theme_font_size_override("font_size", 18)
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.pressed.connect(pressed)
	return button


func _focus_menu(menu: VBoxContainer) -> void:
	var buttons := menu.find_children("*", "Button", true, false)
	if not buttons.is_empty():
		_link_menu_buttons(buttons, buttons[0].has_meta("menu_card"))
		_focus_menu_button.call_deferred(buttons[0])


func _link_menu_buttons(buttons: Array, horizontal: bool) -> void:
	# Keep a placement arrow held at the moment of victory inside the reward menu.
	for index in range(buttons.size()):
		var button: Button = buttons[index]
		var previous := button.get_path_to(buttons[posmod(index - 1, buttons.size())])
		var following := button.get_path_to(buttons[(index + 1) % buttons.size()])
		button.focus_previous = previous
		button.focus_next = following
		button.focus_neighbor_left = previous if horizontal else ^"."
		button.focus_neighbor_right = following if horizontal else ^"."
		button.focus_neighbor_top = ^"." if horizontal else previous
		button.focus_neighbor_bottom = ^"." if horizontal else following


func _focus_menu_button(button: Button) -> void:
	if is_instance_valid(button) and button.is_inside_tree() and _overlay_open:
		button.grab_focus()


func _center_modal() -> void:
	# In a tall browser Godot expands the logical canvas vertically. Keep the choices
	# and the resume control readable at the smaller physical window width.
	var scale_factor := clampf(_u, 1.0, 1.35)
	if size.y > size.x * 0.82:
		scale_factor = clampf(size.x / 660.0, 1.0, 2.5)
	if is_instance_valid(_resume):
		var canvas_scale := maxf(0.1, get_viewport().get_final_transform().get_scale().y)
		var tap_height := ceilf(44.0 / canvas_scale)
		var type_size := maxi(roundi(18.0 * scale_factor), ceili(16.0 / canvas_scale))
		for control: Button in [_resume, _music_toggle, _pause_restart]:
			var height := 52.0 if control == _resume else 44.0
			control.custom_minimum_size = Vector2(190.0 * scale_factor, maxf(height * scale_factor, tap_height))
			control.add_theme_font_size_override("font_size", type_size)
		var pause_title: Label = _resume.get_parent().get_node("Paused")
		pause_title.add_theme_font_size_override("font_size", roundi(29.0 * scale_factor))
	if not is_instance_valid(_modal):
		return
	var options: VBoxContainer = _modal.get_node("Options")
	options.add_theme_constant_override("separation", roundi(9.0 * scale_factor))
	for entry: Control in options.get_children():
		if entry is Button:
			entry.custom_minimum_size.y = 46.0 * scale_factor
			entry.add_theme_font_size_override("font_size", roundi(18.0 * scale_factor))
			if run.phase in ["shop", "complete"]:
				var physical_scale := maxf(0.1, get_viewport().get_final_transform().get_scale().y)
				entry.custom_minimum_size.y = maxf(entry.custom_minimum_size.y, ceilf(44.0 / physical_scale))
				entry.add_theme_font_size_override("font_size", maxi(roundi(18.0 * scale_factor), ceili(14.0 / physical_scale)))
		elif entry is Label:
			var points := 29.0 if entry.name == &"MenuTitle" else 16.0
			if entry.name == &"Countdown":
				points = 63.0
				entry.custom_minimum_size.y = 98.0 * scale_factor
			entry.add_theme_font_size_override("font_size", roundi(points * scale_factor))
	for element: Control in options.find_children("*", "Control", true, false):
		if element.has_meta("menu_card"):
			element.custom_minimum_size.y = 146.0 * scale_factor
		elif element.has_meta("menu_icon"):
			element.custom_minimum_size = Vector2.ONE * roundf(float(element.get_meta("menu_icon")) * scale_factor)
		elif element.has_meta("menu_points"):
			element.add_theme_font_size_override("font_size", roundi(float(element.get_meta("menu_points")) * scale_factor))

	var width := minf(475.0 * scale_factor, size.x - 28.0 * _u)
	if run.phase == "replace":
		width = minf(538.0 * scale_factor, size.x - 28.0 * _u)
	_modal.size = Vector2(width, _modal.get_combined_minimum_size().y)
	_position_menu()


func _position_menu() -> void:
	_modal.position = ((size - _modal.size) * 0.5).round()



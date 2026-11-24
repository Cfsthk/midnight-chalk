extends SceneTree

const RunModel = preload("res://game/run_state.gd")
# These are the reviewed distractors. Withdrawing a real match never turns it into one.
const INCOMPATIBLE := {
	"青": "礻牜攵爫耂自且辛申完", "包": "冫彳彡卩宀廾禾舟耳刃",
	"口": "雨羽矛首友右芳究冒冇", "木": "印受芽穹松初晚姿幻宮",
	"氵": "早冊昂孔等案枝社扇坊", "扌": "在向禾雀香成松村晚雁",
	"艹": "命皮星四景勇另岳所茂", "日": "耳矛朵次左函考自也奇",
	"女": "字才冰本象晏反曲夂乞", "土": "士舟先奴刀酉妹冊粟命",
	"火": "臼頂虜自松司首蔚聞舍", "禾": "矢貝隼烏刃卯帚受全甬",
}
const WITHDRAWN_RESULTS := "靖鯖倩靛菁凊婧掅箐綪腈錆鶄棈碃崝郬輤靘靝㕲枷棊薔昇昱昊旰昭昕暉姀娵妮娟婷堢秌炏秄稾"
# These pairs also have an everyday answer, so the component remains in the draw.
const RETIRED_POSITIONS := {
	"口": {"木": ["right"]},
	"木": {"口": ["left"], "加": ["right"], "其": ["top"]},
	"日": {"立": ["bottom"], "干": ["right"], "軍": ["right"]},
	"女": {"禾": ["right"], "取": ["right"]},
	"土": {"保": ["right"]},
	"火": {"禾": ["right"], "火": ["left", "right"]},
	"禾": {"火": ["left"], "女": ["left"], "子": ["right"], "高": ["top"]},
}
const HUD_FONT := preload("res://assets/NotoSansHK-Regular.ttf")
const ANSWER_FONT := preload("res://assets/MidnightKai.ttf")

var failed := false
var readings: Dictionary = {}
var visible_glyphs: Dictionary = {}
var outcomes_checked := 0
var tiles_checked := 0


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var inventory: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RunModel.CONTENT_PATH))
	var families: Dictionary = {}
	for deck: Dictionary in inventory.decks:
		var anchor: String = deck.anchor
		if not _expect(INCOMPATIBLE.has(anchor) and not families.has(anchor), "Unexpected or repeated anchor " + anchor):
			continue
		families[anchor] = _check_family(deck)
	_expect(families.size() == INCOMPATIBLE.size(), "Every expected anchor loads")
	_check_position_pairs(families)
	for glyph: String in visible_glyphs:
		_expect(_font_contains(HUD_FONT, glyph), "Tile font covers " + glyph)
	for result: String in readings:
		_expect(_font_contains(ANSWER_FONT, result), "Answer font covers " + result)
	var visited: Dictionary = {}
	for seed_value: int in range(256):
		var run := RunModel.new()
		run.start_run(seed_value)
		if not _expect(run.offers.size() == 3, run.content_error):
			break
		run.choose_special(run.offers[0].id)
		var anchor: String = run.deck.anchor
		if not families.has(anchor) or visited.has(anchor):
			continue
		visited[anchor] = true
		run.begin_fight()
		_check_live_draws(run, families[anchor])
		_check_feedback(run)
		if visited.size() == families.size():
			break
	_expect(visited.size() == INCOMPATIBLE.size(), "Every family can appear in the opening encounter")
	_expect(readings.get("鮑") == "baau1" and readings.get("泡") == "pou5", "Use the readings in 鮑魚 and 氣泡")
	_expect(readings.get("茄") == "ke2" and readings.get("妖") == "jiu2" and readings.get("坡") == "bo1",
		"The selected readings agree with the reviewed Hong Kong primary vocabulary examples")
	if not failed:
		print("PASS — ", visited.size(), " families, ", tiles_checked, " tiles, ", outcomes_checked, " accepted directional answers, ", readings.size(), " spoken characters")
	quit(1 if failed else 0)


func _check_family(deck: Dictionary) -> Dictionary:
	var pending: Dictionary = {}
	var matches := 0
	var incompatible := 0
	var distinct: Dictionary = {}
	var reviewed_positions: Dictionary = RETIRED_POSITIONS.get(deck.anchor, {})
	visible_glyphs[deck.anchor] = true
	for tile: Dictionary in deck.tiles:
		tiles_checked += 1
		var glyph: String = tile.glyph
		_expect(glyph.length() == 1 and not distinct.has(glyph), str(deck.anchor) + " duplicate or empty tile " + glyph)
		distinct[glyph] = true
		visible_glyphs[glyph] = true
		if tile.has("preferred_slot"):
			_expect(tile.placements.has(tile.preferred_slot), "Teaching position is a valid answer for " + glyph)
		var excluded_slots: Array = tile.get("unscored_slots", [])
		for position: String in reviewed_positions.get(glyph, []):
			_expect(position in excluded_slots, "Retired genuine placement is neutral: " + str(deck.anchor) + glyph + position)
		for position: Variant in excluded_slots:
			_expect(position in RunModel.POSITIONS and not tile.placements.has(position)
				and not tile.placements.is_empty() and excluded_slots.count(position) == 1,
				"Each unscored position is a separate direction on a matchable tile: " + str(deck.anchor) + glyph)
		if tile.placements.is_empty():
			_expect(glyph in INCOMPATIBLE[deck.anchor], "Only screened distractors can earn rejection charge: " + str(deck.anchor) + glyph)
			incompatible += 1
			pending[glyph + "/reject"] = {}
			continue
		matches += 1
		for slot: String in tile.placements:
			var answer: Dictionary = tile.placements[slot]
			var result: String = answer.result
			_expect(result not in WITHDRAWN_RESULTS, "Retired character re-entered the bank: " + result)
			_expect(slot in RunModel.POSITIONS and result.length() == 1, "Invalid position or result " + result)
			_expect(answer.audio == "res://content/audio/%x.wav" % result.unicode_at(0), "Audio path for " + result)
			if not readings.has(result):
				_expect(ResourceLoader.exists(answer.audio, "AudioStream"), "Bundled speech for " + result)
				readings[result] = answer.jyutping
			_expect(not str(answer.jyutping).is_empty() and readings[result] == answer.jyutping, "Consistent reading for " + result)
			visible_glyphs[result] = true
			pending[glyph + "/" + slot] = answer
			outcomes_checked += 1
	for glyph: String in reviewed_positions:
		_expect(distinct.has(glyph), "Tile still offers a reviewed classroom alternative: " + str(deck.anchor) + glyph)
	_expect(matches > 0 and incompatible == INCOMPATIBLE[deck.anchor].length(), "Incorrect number of components for " + str(deck.anchor))
	return pending


func _check_position_pairs(families: Dictionary) -> void:
	var examples := {
		"口": {"今/top": "含", "今/right": "吟", "隹/top": "售", "隹/right": "唯"},
		"木": {"甘/top": "某", "甘/right": "柑", "隹/top": "集", "口/top": "呆", "口/bottom": "杏"},
		"日": {"軍/bottom": "暈"},
		"包": {"火/left": "炮"},
		"火": {"林/top": "焚", "火/top": "炎", "火/bottom": "炎", "禾/left": "秋", "頁/right": "煩"},
		"禾": {"火/right": "秋", "子/bottom": "季"},
	}
	for anchor: String in examples:
		for action: String in examples[anchor]:
			var answer: Dictionary = families.get(anchor, {}).get(action, {})
			_expect(answer.get("result") == examples[anchor][action], "Positional example " + anchor + " " + action)


func _check_feedback(run: RunModel) -> void:
	var remaining := {}
	var source_tiles := {}
	for tile: Dictionary in run.deck.tiles:
		source_tiles[tile.glyph] = tile
		var actions: Array[String] = ["expire"]
		if not tile.placements.is_empty():
			actions.append("reject")
		for slot: String in RunModel.POSITIONS:
			if not tile.placements.has(slot):
				actions.append(slot)
		remaining[tile.glyph] = actions
	for draw: int in range(600):
		if remaining.is_empty():
			return
		var glyph: String = run.tile.glyph
		var tile_id := run.tile_id
		if not remaining.has(glyph):
			run.resolve_tile("expire", tile_id)
			continue
		var tile: Dictionary = source_tiles[glyph]
		var action: String = remaining[glyph].pop_back()
		var unscored: bool = action in tile.get("unscored_slots", [])
		if unscored:
			# Unsaturated meters expose an accidental penalty or reward.
			run.boss_charge = 1
			run.energy = 0
		var shots_before := run.projectiles.size()
		var boss_hp_before := run.boss_hp
		var hp_before := run.hp
		var event := run.resolve_tile(action, tile_id)
		var example: String = "%s + %s / %s" % [run.deck.anchor, glyph, action]
		if unscored:
			_expect(event.kind == "unscored" and run.boss_charge == 1 and run.energy == 0
				and run.projectiles.size() == shots_before and event.shot.is_empty()
				and run.boss_hp == boss_hp_before and run.hp == hp_before,
				"A real placement outside the lesson is neutral: " + example)
		elif action == "expire":
			_expect(event.kind == "expiry", "Expiry: " + example)
		else:
			_expect(event.kind == "wrong", "Incorrect action: " + example)
		if tile.placements.is_empty():
			_expect(event.result.is_empty() and event.answer_slot.is_empty() and event.audio.is_empty(),
				"Incompatible tile has no correction to read: " + example)
		else:
			var answer: Dictionary = tile.placements.get(event.answer_slot, {})
			_expect(not answer.is_empty() and answer.get("result") == event.result
				and answer.get("audio") == event.audio and answer.get("jyutping") == event.jyutping,
				"Feedback contains an approved placement and reading: " + example)
			if tile.has("preferred_slot"):
				_expect(event.answer_slot == tile.preferred_slot, "Preferred classroom answer: " + example)
		_expect(run.resolve_tile(action, tile_id).kind == "ignored", "Submitted tile is spent: " + example)
		if remaining[glyph].is_empty():
			remaining.erase(glyph)
	_expect(remaining.is_empty(), "Unexercised feedback in " + str(run.deck.anchor) + ": " + str(remaining))


func _check_live_draws(run: RunModel, expected: Dictionary) -> void:
	var pending := expected.duplicate()
	for draw: int in range(600):
		if pending.is_empty():
			return
		var glyph: String = run.tile.glyph
		var action := "reject"
		if not run.tile.placements.is_empty():
			action = str(run.tile.placements.keys()[0])
			for slot: String in run.tile.placements:
				if pending.has(glyph + "/" + slot):
					action = slot
					break
		var key := glyph + "/" + action
		if not _expect(expected.has(key), str(run.deck.anchor) + " drew an unexpected tile " + key):
			return
		var event := run.resolve_tile(action, run.tile_id)
		if action == "reject":
			_expect(event.kind == "correct_reject", "Correct rejection for " + glyph)
		else:
			var lesson: Dictionary = expected[key]
			_expect(event.kind == "hit" and event.result == lesson.result and event.audio == lesson.audio, "Placement and reading for " + key)
		pending.erase(key)
	_expect(pending.is_empty(), "Unreachable answers in " + str(run.deck.anchor) + ": " + str(pending.keys()))


func _font_contains(font: FontFile, glyph: String) -> bool:
	var text_server := TextServerManager.get_primary_interface()
	return text_server.font_get_glyph_index(font.get_rids()[0], 64, glyph.unicode_at(0), 0) != 0


func _expect(ok: bool, message: String) -> bool:
	if not ok:
		failed = true
		push_error(message)
	return ok

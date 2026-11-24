extends RefCounted

const BossCatalogue = preload("res://game/boss_catalogue.gd")
const CONTENT_PATH := "res://content/decks.json"
const POSITIONS: Array[String] = ["top", "bottom", "left", "right"]
const PLAYER_HP := 12
const ENERGY_COST := 3
const INVENTORY_CAPACITY := 3
const MATCHES_PER_PACKET := 8
const DECOYS_PER_PACKET := 4
const MIN_INTERVENING_DROPS := 3
const STAGE_COUNT := 5
const FOES_PER_STAGE := 2
const FALL_SPEED_FACTOR := 1.1
const FALL_TIMES: Array[float] = [
	12.0 / FALL_SPEED_FACTOR, 11.5 / FALL_SPEED_FACTOR, 11.0 / FALL_SPEED_FACTOR,
	10.5 / FALL_SPEED_FACTOR, 10.0 / FALL_SPEED_FACTOR,
]
const BASE_COINS: Array[int] = [5, 8, 11, 15, 20]
const STAGE_CLEAR_BASE_MULTIPLIER := 3
const SHOP_PRICES: Array[int] = [10, 15, 20, 25]
const CHEST_BUDGET := 45.0
const MAX_FALLING_TILES := 3
const PROJECTILE_DURATION := 0.42
const CLOCK_EPSILON := 0.000001
const BOSS_CHARGE_COST := 3
const INCINERATION_REFILL_DELAY := 0.45
const ENRAGED_SHOTS := 2
const FIELD_EFFECTS: Array[String] = ["ink", "rocks", "mask", "rotate", "dim", "shuffle", "haste", "freeze", "gust"]

const SHOP_UPGRADES: Array[Dictionary] = [
	{"id": "vitality", "kind": "vitality", "name": "生命上限", "description": "生命上限 +2", "amount": 2},
	{"id": "attack", "kind": "attack", "name": "攻擊力", "description": "攻擊力 +1", "amount": 1},
	{"id": "defense", "kind": "defense", "name": "防禦力", "description": "防禦力 +1", "amount": 1},
	{"id": "charge", "kind": "charge", "name": "必殺技蓄能", "description": "必殺技所需能量 −1", "amount": 1},
	{"id": "chest", "kind": "chest", "name": "寶箱限時", "description": "寶箱限時 +5 秒", "amount": 5},
]

const SPECIALS: Array[Dictionary] = [
	{"id": "heavy", "kind": "heavy", "name": "重擊", "damage": 4, "effect_value": 1,
		"effect": "造成 4 點傷害", "description": "造成 4 點傷害"},
	{"id": "ward", "kind": "ward", "name": "護身擊", "damage": 3, "effect_value": 1,
		"effect": "抵擋 1 次攻擊", "description": "造成 3 點傷害，抵擋 1 次攻擊"},
	{"id": "delay", "kind": "delay", "name": "斷招", "damage": 3, "effect_value": 0.5,
		"effect": "出招進度倒退最多 50%", "description": "造成 3 點傷害，出招進度倒退最多 50%"},
	{"id": "heal", "kind": "heal", "name": "回復擊", "damage": 3, "effect_value": 1,
		"effect": "回復 1 點生命", "description": "造成 3 點傷害，回復 1 點生命"},
	{"id": "mark", "kind": "mark", "name": "追字印", "damage": 2, "effect_value": 3,
		"effect": "下三次組字攻擊各加 1 點", "description": "造成 2 點傷害，下三次組字攻擊各加 1 點"},
	{"id": "break_charge", "kind": "break_charge", "name": "破勢雷", "damage": 3, "effect_value": 1,
		"effect": "削減敵方 1 格蓄能", "description": "造成 3 點傷害，削減敵方 1 格蓄能"},
	{"id": "mirror", "kind": "mirror", "name": "反照鏡", "damage": 2, "effect_value": 3,
		"effect": "5 秒內受傷時反擊 3 點", "description": "造成 2 點傷害，5 秒內首次受傷時再反擊 3 點"},
	{"id": "slow", "kind": "slow", "name": "緩流掌", "damage": 2, "effect_value": 30,
		"effect": "部件減速 30%，維持 4 秒", "description": "造成 2 點傷害，部件減速 30%，維持 4 秒"},
	{"id": "cleanse", "kind": "cleanse", "name": "破障筆", "damage": 3, "effect_value": 1,
		"effect": "清除場上干擾", "description": "造成 3 點傷害，清除場上干擾"},
	{"id": "comeback", "kind": "comeback", "name": "逆風斬", "damage": 3, "effect_value": 6,
		"effect": "生命剩一半或以下時造成 6 點", "description": "造成 3 點傷害，生命剩一半或以下時造成 6 點"},
	{"id": "stars", "kind": "stars", "name": "三星落雷", "damage": 2, "effect_value": 3,
		"effect": "場上每個部件加 1 點，最多加 3 點", "description": "造成 2 點傷害，場上每個部件加 1 點，最多加 3 點"},
	{"id": "reject_flame", "kind": "reject_flame", "name": "辨形火印", "damage": 2, "effect_value": 3,
		"effect": "5 秒內正確分辨不相配的部件，追加 3 點", "description": "造成 2 點傷害，5 秒內首次正確分辨不相配的部件時再攻擊 3 點"},
]

const ITEM_CATALOGUE: Array[Dictionary] = [
	{"id": "shield", "kind": "shield", "name": "護盾", "description": "擋住下一次攻擊"},
	{"id": "attack", "kind": "attack", "name": "強擊石", "description": "下一次組字攻擊增加 1 點傷害"},
	{"id": "energy", "kind": "energy", "name": "蓄能晶", "description": "增加 1 點能量"},
	{"id": "heal", "kind": "heal", "name": "回復藥", "description": "回復最多 3 點生命"},
	{"id": "hourglass", "kind": "hourglass", "name": "添時沙漏", "description": "本場寶箱限時增加 8 秒"},
	{"id": "fan", "kind": "fan", "name": "換牌扇", "description": "換走所選部件，新部件來自同一字族"},
	{"id": "lantern", "kind": "lantern", "name": "尋字燈", "description": "照亮一個可組字的部件"},
	{"id": "clip", "kind": "clip", "name": "定字夾", "description": "讓所選部件停在原位 5 秒"},
	{"id": "calm", "kind": "calm", "name": "安心符", "description": "下兩次放錯或誤判不會增加敵方蓄能"},
	{"id": "umbrella", "kind": "umbrella", "name": "防擾傘", "description": "抵擋下一次敵方干擾，仍會承受傷害"},
	{"id": "bell", "kind": "bell", "name": "延招鈴", "description": "敵方下次出招延遲 3 秒"},
	{"id": "bounty", "kind": "bounty", "name": "賞金袋", "description": "本場獲勝時額外獲得 5 枚金幣"},
]

var phase: String = "power"
var encounter_index: int = 0
var stage: int:
	get:
		@warning_ignore("integer_division")
		return mini(STAGE_COUNT, encounter_index / FOES_PER_STAGE + 1)
var foe_in_stage: int:
	get:
		return FOES_PER_STAGE + 1 if is_dragon else encounter_index % FOES_PER_STAGE + 1
var is_dragon: bool:
	get:
		return encounter_index == STAGE_COUNT * FOES_PER_STAGE
var coins: int = 0
var coin_award: Dictionary = {}
var boss: Dictionary = {}
var deck: Dictionary = {}
var tile: Dictionary = {}
var tile_id: int = -1
var active_tiles: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var active_seconds: float = 0.0
var boss_charge: int = 0
var boss_charge_max: int = BOSS_CHARGE_COST
var boss_cooldown_left: float = 0.0
var boss_cooldown_duration: float = 0.0
var hp: int = PLAYER_HP
var max_hp: int = PLAYER_HP
var player_attack_bonus: int = 0
var player_defense: int = 0
var boss_hp: int = 0
var boss_max_hp: int = 0
var energy: int = 0
var energy_cost: int = ENERGY_COST
var items: Array[Dictionary] = []
var offers: Array[Dictionary] = []
var shop_offers: Array[Dictionary] = []
var shop_purchases: Array[String] = []
var shop_price: int:
	get:
		return SHOP_PRICES[stage - 1] if stage <= SHOP_PRICES.size() else 0
var rewards: Array[Dictionary] = []
var pending_item: Dictionary = {}
var special_name: String = ""
var chest_earned: bool = false
var gust_drops: int = 0
var armour_drops: int = 0
var ink_fraction: float = 0.0
var ink_seconds: float:
	get:
		return effect_seconds("ink")
var haste_bonus: float = 0.0
var haste_seconds: float:
	get:
		return effect_seconds("haste")
var rock_fraction: float = 0.0
var bonus_hits: int = 0
var fall_duration: float = FALL_TIMES[0]
var chest_budget: float = CHEST_BUDGET
var hinted_tile_id: int = -1
var lantern_waiting: bool = false
var pinned_tile_id: int = -1
var marked_hits: int = 0
var calm_charges: int = 0
var umbrella_ready: bool = false
var bounty_coins: int = 0
var route: Array[Dictionary] = []
var content_error: String = ""

var _run_seed: int = 0
var _special: Dictionary = {}
var _shield_ready: bool = false
var _boost_ready: bool = false
var _chest_upgrade_seconds: float = 0.0
var _tile_rng: RandomNumberGenerator
var _effect_rng: RandomNumberGenerator
var _effect_clocks: Dictionary[String, float] = {}
var _jump_interval: float = 0.0
var _jump_left: float = 0.0
var _rotation_seed: int = 0
var _bonus_damage: int = 0
var _playable_tiles: Array[Dictionary] = []
var _decoy_tiles: Array[Dictionary] = []
var _packet_kinds: Array[bool] = []
var _packet_decoys: Dictionary = {}
var _recent_glyphs: Array[String] = []
var _charged_decoys: Dictionary = {}
var _glyph_draw_counts: Dictionary = {}
var _next_tile_id: int = 0
var _next_shot_id: int = 0
var _next_lane: int = 0
var _spawn_left: float = 0.0
var _last_tile_was_decoy: bool = false


func start_run(seed_value: int) -> void:
	_run_seed = seed_value
	phase = "power"
	encounter_index = 0
	coins = 0
	coin_award = {}
	hp = PLAYER_HP
	max_hp = PLAYER_HP
	player_attack_bonus = 0
	player_defense = 0
	_chest_upgrade_seconds = 0.0
	chest_budget = CHEST_BUDGET
	energy = 0
	energy_cost = ENERGY_COST
	items.clear()
	rewards.clear()
	pending_item.clear()
	boss = {}
	deck = {}
	_clear_field()
	boss_hp = 0
	boss_max_hp = 0
	boss_charge = 0
	active_seconds = 0.0
	boss_cooldown_duration = 0.0
	boss_cooldown_left = 0.0
	chest_earned = false
	_reset_encounter_effects()
	fall_duration = FALL_TIMES[0]
	special_name = ""
	_special = {}
	offers.clear()
	shop_offers.clear()
	shop_purchases.clear()
	route.clear()
	content_error = ""

	var decks: Array[Dictionary] = _read_decks()
	if decks.is_empty():
		phase = "defeat"
		return
	_build_route(decks)
	offers = _sample_definitions(SPECIALS, _rng_for("specials"))


func choose_special(id: String) -> void:
	if phase != "power" or route.is_empty():
		return
	var chosen: Dictionary = _find_definition(offers, id)
	if chosen.is_empty():
		return
	_special = chosen
	special_name = str(chosen["name"])
	_prepare_encounter()


func begin_fight() -> void:
	if phase != "ready":
		return
	phase = "battle"
	# Open in motion with a lower and an upper component, both independently actionable.
	_draw_tile(fall_duration * 0.34)
	_draw_tile(fall_duration * 0.08)
	_spawn_left = fall_duration * 0.24


func select_tile(id: int) -> bool:
	if phase != "battle":
		return false
	for card: Dictionary in active_tiles:
		if card["id"] == id:
			tile = card
			tile_id = id
			if effect_seconds("shuffle") > 0.0:
				_jump_left = _jump_interval
			return true
	return false


func resolve_tile(action: String, expected_tile_id: int, _elapsed: float = 0.0) -> Dictionary:
	if phase != "battle" or (action not in POSITIONS and action not in ["reject", "expire"]):
		return _outcome("ignored")
	var index: int = -1
	for i: int in range(active_tiles.size()):
		if active_tiles[i]["id"] == expected_tile_id:
			index = i
			break
	if index < 0:
		return _outcome("ignored")

	var card: Dictionary = active_tiles.pop_at(index)
	_release_tile_effects(expected_tile_id)
	var placements: Dictionary = card["placements"]
	var glyph: String = card["glyph"]
	var outcome: Dictionary = _outcome("wrong")
	outcome["valid_tile"] = not placements.is_empty()
	outcome["glyph"] = glyph
	outcome["tile_id"] = expected_tile_id
	if action == "expire":
		outcome["kind"] = "expiry"
	elif placements.has(action):
		outcome["kind"] = "hit"
		_record_answer(outcome, action, placements[action])
		var hit_damage: int = (1 if armour_drops > 0 else 2) + player_attack_bonus
		if marked_hits > 0:
			hit_damage += 1
			marked_hits -= 1
		if _boost_ready:
			hit_damage += 1
			_boost_ready = false
		outcome["shot"] = _launch("player", hit_damage, false)
	elif action in card.get("unscored_slots", []):
		# A real construction outside this lesson. Show the classroom form and spend the tile.
		outcome["kind"] = "unscored"
	elif action == "reject" and placements.is_empty():
		outcome["kind"] = "correct_reject"
		if not _charged_decoys.has(glyph):
			_charged_decoys[glyph] = true
			var previous_energy: int = energy
			energy = mini(energy_cost, energy + 1)
			outcome["energy_gained"] = energy - previous_energy
		if effect_seconds("reject_flame") > 0.0:
			_effect_clocks.erase("reject_flame")
			outcome["shot"] = _launch("player", 3, true)

	if outcome["kind"] == "wrong":
		if calm_charges > 0:
			calm_charges -= 1
			outcome["error_protected"] = true
		else:
			boss_charge = mini(boss_charge_max, boss_charge + 1)
	if outcome["kind"] in ["wrong", "expiry", "unscored"] and not placements.is_empty():
		var preferred_slot: String = card.get("preferred_slot", "")
		if preferred_slot.is_empty():
			for slot: String in POSITIONS:
				if placements.has(slot):
					preferred_slot = slot
					break
		_record_answer(outcome, preferred_slot, placements[preferred_slot])

	gust_drops = maxi(0, gust_drops - 1)
	armour_drops = maxi(0, armour_drops - 1)
	if expected_tile_id == tile_id:
		tile = {} if active_tiles.is_empty() else active_tiles.front()
		tile_id = int(tile.get("id", -1))
	if active_tiles.size() < 2:
		if effect_seconds("freeze") > 0.0:
			_spawn_left = 0.0
		else:
			_draw_tile()
	return outcome


func use_special(_elapsed: float = 0.0) -> Dictionary:
	if phase != "battle" or energy < energy_cost:
		return _outcome("ignored")
	energy -= energy_cost
	armour_drops = 0
	var damage: int = _special["damage"]
	match _special["id"]:
		"ward":
			_shield_ready = true
		"delay":
			# Rewind this cooldown by half a cycle without exceeding the empty meter.
			var rewound := minf(boss_cooldown_duration, boss_cooldown_left + boss_cooldown_duration * float(_special["effect_value"]))
			boss_cooldown_left = maxf(boss_cooldown_left, rewound)
		"heal":
			hp = mini(max_hp, hp + int(_special["effect_value"]))
		"mark":
			marked_hits = 3
		"break_charge":
			boss_charge = maxi(0, boss_charge - 1)
		"mirror", "reject_flame":
			_effect_clocks[_special.id] = 5.0
		"slow":
			_effect_clocks["slow"] = 4.0
		"cleanse":
			for kind: String in FIELD_EFFECTS:
				_effect_clocks.erase(kind)
			ink_fraction = 0.0
			rock_fraction = 0.0
			haste_bonus = 0.0
			gust_drops = 0
		"comeback":
			if hp * 2 <= max_hp:
				damage = 6
		"stars":
			damage += mini(3, active_tiles.size())
	var outcome: Dictionary = _outcome("special")
	outcome["shot"] = _launch("player", damage + player_attack_bonus, true)
	return outcome


func advance_time(delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var remaining := maxf(0.0, delta)
	while phase == "battle" and remaining > 0.0:
		# Stop at each deadline so a long frame and several short frames give the same result.
		var frozen := effect_seconds("freeze") > 0.0
		var fall_rate := 0.0 if frozen else 1.0 + haste_bonus
		if effect_seconds("slow") > 0.0:
			fall_rate *= 0.7
		var step := minf(remaining, boss_cooldown_left)
		for deadline: float in _effect_clocks.values():
			step = minf(step, deadline)
		if effect_seconds("shuffle") > 0.0:
			step = minf(step, _jump_left)
		if not frozen:
			if active_tiles.size() < MAX_FALLING_TILES:
				step = minf(step, _spawn_left / fall_rate)
			for card: Dictionary in active_tiles:
				if card.id != pinned_tile_id:
					step = minf(step, (fall_duration - float(card["age"])) / fall_rate)
		for shot: Dictionary in projectiles:
			step = minf(step, float(shot["remaining"]))
		step = maxf(0.0, step)
		active_seconds += step
		remaining -= step
		boss_cooldown_left = maxf(0.0, boss_cooldown_left - step)
		_spawn_left = maxf(0.0, _spawn_left - step * fall_rate)
		for card: Dictionary in active_tiles:
			if card.id != pinned_tile_id:
				card["age"] += step * fall_rate
		for shot: Dictionary in projectiles:
			shot["remaining"] -= step
		_advance_effect_clocks(step)

		# Settle simultaneous hits in launch order before starting any new actions.
		for shot: Dictionary in projectiles.duplicate():
			if float(shot["remaining"]) <= CLOCK_EPSILON:
				projectiles.erase(shot)
				events.append(_impact(shot))
				if phase != "battle":
					return events
		for card: Dictionary in active_tiles.duplicate():
			if card.id != pinned_tile_id and effect_seconds("freeze") == 0.0 and float(card["age"]) >= fall_duration - CLOCK_EPSILON:
				events.append(resolve_tile("expire", card["id"]))
		if boss_cooldown_left <= CLOCK_EPSILON:
			var heavy := boss_charge >= boss_charge_max
			if heavy:
				boss_charge = 0
			var damage: int = boss["heavy_damage"] if heavy else boss["damage"]
			var effect: Dictionary = boss["heavy_effect"] if heavy else boss["normal_effect"]
			var empowered := not heavy and bonus_hits > 0
			if empowered:
				damage += _bonus_damage
				bonus_hits -= 1
			events.append({"kind": "foe_launch", "shot": _launch("foe", damage, heavy, effect, empowered)})
			boss_cooldown_left = boss_cooldown_duration
		if effect_seconds("freeze") == 0.0 and active_tiles.size() < MAX_FALLING_TILES and _spawn_left <= CLOCK_EPSILON:
			_draw_tile()
			_spawn_left = fall_duration * 0.30
	return events


func _launch(source: String, amount: int, heavy: bool, effect: Dictionary = {}, empowered: bool = false) -> Dictionary:
	_next_shot_id += 1
	var shot := {"id": _next_shot_id, "source": source, "amount": amount, "heavy": heavy, "empowered": empowered,
		"duration": PROJECTILE_DURATION, "remaining": PROJECTILE_DURATION, "effect": effect}
	projectiles.append(shot)
	return shot


func _impact(shot: Dictionary) -> Dictionary:
	var impact := {"kind": "impact", "source": shot["source"], "shot_id": shot["id"],
		"heavy": shot["heavy"], "damage": 0, "shielded": false, "effect": {},
		"effect_blocked": false, "counter_shot": {}}
	if shot["source"] == "player":
		impact["damage"] = _damage_boss(shot["amount"])
		return impact
	var incoming_damage: int = maxi(0, int(shot["amount"]) - player_defense)
	if _shield_ready and incoming_damage > 0:
		_shield_ready = false
		impact["shielded"] = true
	else:
		var damage_to_player := mini(hp, incoming_damage)
		hp -= damage_to_player
		impact["damage"] = damage_to_player
	var effect: Dictionary = shot["effect"]
	if umbrella_ready and not effect.is_empty() and _is_disruption(effect.kind):
		umbrella_ready = false
		impact["effect_blocked"] = true
	elif not effect.is_empty():
		impact["effect"] = _apply_boss_effect(effect)
	if hp == 0:
		phase = "defeat"
		_clear_field()
		_reset_encounter_effects()
	elif impact.damage > 0 and effect_seconds("mirror") > 0.0:
		_effect_clocks.erase("mirror")
		impact["counter_shot"] = _launch("player", 3, true)
	return impact


func _is_disruption(kind: String) -> bool:
	match kind:
		"steal": return not items.is_empty()
		"drain": return energy > 0
		"incinerate", "current": return not active_tiles.is_empty()
	return kind in FIELD_EFFECTS


func _apply_boss_effect(effect: Dictionary) -> Dictionary:
	var value := float(effect["value"])
	var applied := effect.duplicate()
	var kind: String = effect["kind"]
	var duration := float(effect.get("duration", 0.0))
	if duration > 0.0:
		_effect_clocks[kind] = duration
	match kind:
		"gust":
			gust_drops = int(value)
		"armour":
			armour_drops = int(value)
		"ink":
			ink_fraction = value
		"haste":
			haste_bonus = value
		"rocks":
			rock_fraction = value
		"rotate":
			_rotation_seed = _effect_rng.randi()
		"shuffle":
			_jump_interval = value
			_jump_left = _jump_interval
			_jump_selection()
		"enrage":
			_bonus_damage = int(value)
			bonus_hits = ENRAGED_SHOTS
		"steal":
			var slot := -1 if items.is_empty() else _effect_rng.randi_range(0, items.size() - 1)
			applied["slot"] = slot
			applied["item"] = {} if slot < 0 else items.pop_at(slot)
			applied["value"] = 0 if slot < 0 else 1
		"current":
			var moved: Array[Dictionary] = []
			for card: Dictionary in active_tiles:
				var previous_lane := int(card.lane)
				card.lane = (previous_lane + 1) % MAX_FALLING_TILES
				moved.append({"id": card.id, "glyph": card.glyph, "age": card.age,
					"previous_lane": previous_lane, "lane": card.lane})
			applied["tiles"] = moved
		"incinerate":
			var burned: Array[Dictionary] = []
			for card: Dictionary in active_tiles:
				burned.append({"id": card.id, "lane": card.lane, "glyph": card.glyph, "age": card.age})
			applied["tiles"] = burned
			applied["value"] = burned.size()
			_clear_tiles()
			_spawn_left = INCINERATION_REFILL_DELAY
		"drain":
			var drained: int = mini(energy, int(value))
			energy -= drained
			applied["value"] = drained
		"restore":
			var restored: int = mini(boss_max_hp - boss_hp, int(value))
			boss_hp += restored
			applied["value"] = restored
	return applied


func effect_seconds(kind: String) -> float:
	return _effect_clocks.get(kind, 0.0)


func tile_rotation_degrees(id: int) -> float:
	if effect_seconds("rotate") <= 0.0:
		return 0.0
	var angle: float = [-90.0, 90.0, 180.0][hash(Vector2i(id, _rotation_seed)) % 3]
	# Ease every glyph back to its original orientation in the last quarter second.
	return angle * smoothstep(0.0, 0.25, effect_seconds("rotate"))


func _jump_selection() -> void:
	var others: Array[Dictionary] = active_tiles.filter(func(card: Dictionary) -> bool: return card.id != tile_id)
	if not others.is_empty():
		select_tile(others[_effect_rng.randi_range(0, others.size() - 1)].id)
	_jump_left = _jump_interval


func _advance_effect_clocks(step: float) -> void:
	if _effect_clocks.is_empty():
		return
	if effect_seconds("shuffle") > 0.0:
		_jump_left = maxf(0.0, _jump_left - step)
	for kind: String in _effect_clocks.keys():
		var left: float = _effect_clocks[kind] - step
		if left > CLOCK_EPSILON:
			_effect_clocks[kind] = left
			continue
		_effect_clocks.erase(kind)
		match kind:
			"ink": ink_fraction = 0.0
			"haste": haste_bonus = 0.0
			"rocks": rock_fraction = 0.0
			"clip": pinned_tile_id = -1
	if effect_seconds("shuffle") > 0.0 and _jump_left <= CLOCK_EPSILON:
		_jump_selection()


func _reset_encounter_effects() -> void:
	_effect_clocks.clear()
	gust_drops = 0
	armour_drops = 0
	ink_fraction = 0.0
	haste_bonus = 0.0
	rock_fraction = 0.0
	bonus_hits = 0
	_bonus_damage = 0
	_jump_interval = 0.0
	_jump_left = 0.0
	_shield_ready = false
	_boost_ready = false
	lantern_waiting = false
	marked_hits = 0
	calm_charges = 0
	umbrella_ready = false
	bounty_coins = 0


func _clear_tiles() -> void:
	active_tiles.clear()
	tile = {}
	tile_id = -1
	hinted_tile_id = -1
	pinned_tile_id = -1
	_effect_clocks.erase("clip")


func _release_tile_effects(id: int) -> void:
	if id == hinted_tile_id:
		hinted_tile_id = -1
	if id == pinned_tile_id:
		pinned_tile_id = -1
		_effect_clocks.erase("clip")


func _clear_field() -> void:
	_clear_tiles()
	projectiles.clear()


func can_use_item(index: int) -> bool:
	if phase != "battle" or index < 0 or index >= items.size():
		return false
	match items[index]["kind"]:
		"shield": return not _shield_ready
		"attack": return not _boost_ready
		"energy": return energy < energy_cost
		"heal": return hp < max_hp
		"fan": return tile_id != -1
		"lantern": return hinted_tile_id == -1 and not lantern_waiting
		"clip": return tile_id != -1 and pinned_tile_id == -1
		"calm": return calm_charges == 0
		"umbrella": return not umbrella_ready
		"hourglass", "bell", "bounty": return true
	return false


func use_item(index: int) -> bool:
	if not can_use_item(index):
		return false
	match items[index]["kind"]:
		"shield":
			_shield_ready = true
		"attack":
			_boost_ready = true
		"energy":
			energy += 1
		"heal":
			hp = mini(max_hp, hp + 3)
		"hourglass":
			chest_budget = maxf(chest_budget, active_seconds) + 8.0
		"fan":
			var old_card := tile
			active_tiles.erase(old_card)
			_release_tile_effects(tile_id)
			_draw_tile(old_card.age, old_card.glyph, old_card.lane)
			select_tile(_next_tile_id)
		"lantern":
			lantern_waiting = true
			for card: Dictionary in active_tiles:
				if not card.placements.is_empty():
					hinted_tile_id = card.id
					lantern_waiting = false
					break
		"clip":
			pinned_tile_id = tile_id
			_effect_clocks["clip"] = 5.0
		"calm":
			calm_charges = 2
		"umbrella":
			umbrella_ready = true
		"bell":
			boss_cooldown_left += 3.0
		"bounty":
			bounty_coins += 5
	items.remove_at(index)
	return true


func claim_reward(id: String) -> void:
	if phase != "won":
		return
	var item: Dictionary = _find_definition(rewards, id)
	if item.is_empty():
		return
	rewards.clear()
	if items.size() == INVENTORY_CAPACITY:
		pending_item = item
		phase = "replace"
	else:
		items.append(item)


func choose_replacement(index: int) -> void:
	if phase != "replace" or index < 0 or index > INVENTORY_CAPACITY:
		return
	if index < INVENTORY_CAPACITY:
		items[index] = pending_item
	pending_item = {}
	phase = "won"


func advance_stage() -> void:
	if phase != "won" or not rewards.is_empty():
		return
	if encounter_index + 1 == route.size():
		phase = "complete"
	elif foe_in_stage == FOES_PER_STAGE and stage < STAGE_COUNT:
		var stock: Array[Dictionary] = []
		for upgrade: Dictionary in SHOP_UPGRADES:
			if upgrade.id != "charge" or energy_cost > 1:
				stock.append(upgrade)
		shop_offers = _sample_definitions(stock, _rng_for("shop/%d" % stage))
		phase = "shop"
	else:
		encounter_index += 1
		_prepare_encounter()


func can_buy_upgrade(id: String) -> bool:
	return phase == "shop" and coins >= shop_price and not shop_purchases.has(id) and not _find_definition(shop_offers, id).is_empty() \
		and (id != "charge" or energy_cost > 1)


func buy_upgrade(id: String) -> bool:
	if not can_buy_upgrade(id):
		return false
	var upgrade: Dictionary = _find_definition(shop_offers, id)
	var amount := int(upgrade["amount"])
	coins -= shop_price
	shop_purchases.append(id)
	match id:
		"vitality":
			max_hp += amount
			hp = mini(max_hp, hp + amount)
		"attack":
			player_attack_bonus += amount
		"defense":
			player_defense += amount
		"charge":
			energy_cost -= amount
			energy = mini(energy, energy_cost)
		"chest":
			_chest_upgrade_seconds += amount
			chest_budget += amount
	return true


func leave_shop() -> void:
	if phase != "shop":
		return
	shop_offers.clear()
	shop_purchases.clear()
	encounter_index += 1
	_prepare_encounter()


func _read_decks() -> Array[Dictionary]:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTENT_PATH))
	if not parsed is Dictionary or not parsed.get("decks") is Array:
		content_error = "未能載入組字牌組。"
		return []
	var decks: Array[Dictionary] = []
	var family_ids: Dictionary = {}
	var anchor_glyphs: Dictionary = {}
	for entry: Variant in parsed["decks"]:
		if not entry is Dictionary or not _valid_deck(entry):
			content_error = "組字牌組內容不完整。"
			return []
		var family: String = str(entry.get("family_id", entry["id"]))
		var anchor: String = entry["anchor"]
		if family_ids.has(family) or anchor_glyphs.has(anchor):
			content_error = "組字牌組有重複部件。"
			return []
		family_ids[family] = true
		anchor_glyphs[anchor] = true
		decks.append(entry)
	if decks.size() < 3:
		content_error = "需要最少三組部件。"
		return []
	decks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["id"]) < str(b["id"]))
	return decks


func _valid_deck(entry: Dictionary) -> bool:
	if str(entry.get("id", "")).is_empty() or str(entry.get("anchor", "")).is_empty():
		return false
	if not entry.get("tiles") is Array:
		return false
	var glyphs: Dictionary = {}
	var matches: int = 0
	var decoys: int = 0
	for card: Variant in entry["tiles"]:
		if not card is Dictionary or not card.get("placements") is Dictionary:
			return false
		var glyph: String = str(card.get("glyph", ""))
		if glyph.is_empty() or glyphs.has(glyph):
			return false
		glyphs[glyph] = true
		var placements: Dictionary = card["placements"]
		if card.has("preferred_slot") and not placements.has(card["preferred_slot"]):
			return false
		var unscored: Variant = card.get("unscored_slots", [])
		if not unscored is Array:
			return false
		for slot: Variant in unscored:
			if placements.is_empty() or slot not in POSITIONS or placements.has(slot):
				return false
		if placements.is_empty():
			decoys += 1
			continue
		for slot: Variant in placements:
			var answer: Variant = placements[slot]
			if slot not in POSITIONS or not answer is Dictionary:
				return false
			if str(answer.get("result", "")).is_empty() or str(answer.get("audio", "")).is_empty():
				return false
		matches += 1
	# A fan draw may exclude three recent glyphs, two other live glyphs and the one being swapped.
	var minimum_pool := MIN_INTERVENING_DROPS + MAX_FALLING_TILES + 1
	return matches >= minimum_pool and decoys >= minimum_pool


func _build_route(decks: Array[Dictionary]) -> void:
	var boss_rng := _rng_for("bosses")
	var deck_rng := _rng_for("families")
	var last_boss_family: String = ""
	var last_anchor: String = ""
	var seen_families: Dictionary = {}
	for stage_number in range(1, STAGE_COUNT + 1):
		for foe_number in range(1, FOES_PER_STAGE + 1):
			var rematch := stage_number > 1 and foe_number == FOES_PER_STAGE
			var opponents: Array[Dictionary] = []
			for family: Dictionary in BossCatalogue.FAMILIES:
				var family_id: String = family["family"]
				if family_id != last_boss_family and seen_families.has(family_id) == rematch:
					opponents.append(family)
			var opponent: Dictionary = opponents[boss_rng.randi_range(0, opponents.size() - 1)]
			last_boss_family = opponent["family"]
			seen_families[last_boss_family] = true

			var chosen := _next_deck(decks, last_anchor, deck_rng)
			last_anchor = chosen["anchor"]
			route.append({"stage": stage_number, "foe_in_stage": foe_number,
				"boss": BossCatalogue.form(opponent, stage_number, rematch), "deck": chosen})
	route.append({"stage": STAGE_COUNT, "foe_in_stage": FOES_PER_STAGE + 1,
		"boss": BossCatalogue.DARK_DRAGON, "deck": _next_deck(decks, last_anchor, deck_rng)})


func _next_deck(decks: Array[Dictionary], last_anchor: String, deck_rng: RandomNumberGenerator) -> Dictionary:
	var available := decks.filter(func(candidate: Dictionary) -> bool: return candidate.anchor != last_anchor)
	return available[deck_rng.randi_range(0, available.size() - 1)]


func _prepare_encounter() -> void:
	boss = route[encounter_index]["boss"]
	deck = route[encounter_index]["deck"]
	coin_award = {}
	phase = "ready"
	boss_max_hp = int(boss["max_hp"])
	boss_hp = boss_max_hp
	boss_cooldown_duration = float(boss["cooldown"])
	boss_cooldown_left = boss_cooldown_duration
	boss_charge = 0
	active_seconds = 0.0
	chest_earned = false
	chest_budget = CHEST_BUDGET + _chest_upgrade_seconds
	_reset_encounter_effects()
	fall_duration = FALL_TIMES[stage - 1]
	_clear_field()
	rewards.clear()
	pending_item = {}
	_tile_rng = _rng_for("tiles/%d" % encounter_index)
	_effect_rng = _rng_for("effects/%d" % encounter_index)
	_playable_tiles.clear()
	_decoy_tiles.clear()
	_packet_kinds.clear()
	_packet_decoys.clear()
	_recent_glyphs.clear()
	_charged_decoys.clear()
	_glyph_draw_counts.clear()
	_next_lane = 0
	_spawn_left = 0.0
	_last_tile_was_decoy = false
	for card: Dictionary in deck["tiles"]:
		var placements: Dictionary = card["placements"]
		if placements.is_empty():
			_decoy_tiles.append(card)
		else:
			_playable_tiles.append(card)


func _draw_tile(initial_age: float = 0.0, excluded_glyph: String = "", preferred_lane: int = -1) -> void:
	if _packet_kinds.is_empty():
		_prepare_packet()
	var wants_match: bool = _packet_kinds.front()
	var pool: Array[Dictionary] = _playable_tiles if wants_match else _decoy_tiles
	var eligible: Array[Dictionary] = []
	var preferred: Array[Dictionary] = []
	var live_glyphs: Array[String] = []
	var occupied_lanes: Array[int] = []
	for live: Dictionary in active_tiles:
		live_glyphs.append(live["glyph"])
		occupied_lanes.append(live["lane"])
	for card: Dictionary in pool:
		var glyph: String = card["glyph"]
		if glyph == excluded_glyph or glyph in _recent_glyphs or glyph in live_glyphs:
			continue
		eligible.append(card)
		if not wants_match and not _packet_decoys.has(glyph):
			preferred.append(card)
	var choice_pool: Array[Dictionary] = preferred if not preferred.is_empty() else eligible
	if choice_pool.is_empty():
		return
	_packet_kinds.pop_front()
	var card: Dictionary = _pick_least_dealt(choice_pool).duplicate()
	if preferred_lane >= 0:
		_next_lane = preferred_lane
	while _next_lane in occupied_lanes:
		_next_lane = (_next_lane + 1) % MAX_FALLING_TILES
	_next_tile_id += 1
	card["id"] = _next_tile_id
	card["age"] = initial_age
	card["lane"] = _next_lane
	_next_lane = (_next_lane + 1) % MAX_FALLING_TILES
	active_tiles.append(card)
	if lantern_waiting and wants_match:
		hinted_tile_id = card.id
		lantern_waiting = false
	if tile.is_empty():
		select_tile(_next_tile_id)
	var chosen_glyph: String = card["glyph"]
	if not wants_match:
		_packet_decoys[chosen_glyph] = true
	_glyph_draw_counts[chosen_glyph] = int(_glyph_draw_counts.get(chosen_glyph, 0)) + 1
	_recent_glyphs.append(chosen_glyph)
	if _recent_glyphs.size() > MIN_INTERVENING_DROPS:
		_recent_glyphs.pop_front()
	_last_tile_was_decoy = not wants_match


func _prepare_packet() -> void:
	# Each gap can contain one decoy. Skip the first gap when the last packet ended with one.
	var gaps: Array[int] = []
	var first_gap: int = 1 if _last_tile_was_decoy else 0
	for gap: int in range(first_gap, MATCHES_PER_PACKET + 1):
		gaps.append(gap)
	var chosen_gaps: Array[int] = []
	for draw_index: int in range(DECOYS_PER_PACKET):
		chosen_gaps.append(gaps.pop_at(_tile_rng.randi_range(0, gaps.size() - 1)))
	for gap: int in range(MATCHES_PER_PACKET + 1):
		if gap in chosen_gaps:
			_packet_kinds.append(false)
		if gap < MATCHES_PER_PACKET:
			_packet_kinds.append(true)
	_packet_decoys.clear()


func _pick_least_dealt(eligible: Array[Dictionary]) -> Dictionary:
	# Shuffle equally exposed glyphs. A missed tile returns through the normal rotation.
	var fewest: int = _glyph_draw_counts.get(eligible.front()["glyph"], 0)
	var candidates: Array[Dictionary] = []
	for card: Dictionary in eligible:
		var count: int = _glyph_draw_counts.get(card["glyph"], 0)
		if count < fewest:
			candidates.clear()
			fewest = count
		if count == fewest:
			candidates.append(card)
	return candidates[_tile_rng.randi_range(0, candidates.size() - 1)]


func _damage_boss(amount: int) -> int:
	if phase != "battle" or boss_hp <= 0:
		return 0
	var damage_to_boss: int = mini(boss_hp, amount)
	boss_hp -= damage_to_boss
	if boss_hp == 0:
		phase = "won"
		_clear_field()
		var base := BASE_COINS[stage - 1]
		var seconds_left := maxi(0, floori(chest_budget - active_seconds + CLOCK_EPSILON))
		@warning_ignore("integer_division")
		var time_bonus := mini(4, seconds_left / 10)
		@warning_ignore("integer_division")
		var vitality_bonus := mini(3, hp / 4)
		var stage_clear := base * STAGE_CLEAR_BASE_MULTIPLIER if foe_in_stage == FOES_PER_STAGE and stage < STAGE_COUNT else 0
		var total := base + time_bonus + vitality_bonus + stage_clear + bounty_coins
		coin_award = {"base": base, "time": time_bonus, "vitality": vitality_bonus, "stage_clear": stage_clear, "bounty": bounty_coins, "total": total,
			"seconds_left": seconds_left, "hp_left": hp}
		coins += total
		_reset_encounter_effects()
		hp = max_hp
		chest_earned = encounter_index + 1 < route.size() and active_seconds <= chest_budget + CLOCK_EPSILON
		if chest_earned:
			rewards = _sample_definitions(ITEM_CATALOGUE, _rng_for("loot/%d" % encounter_index))
	return damage_to_boss


func _record_answer(outcome: Dictionary, slot: String, answer: Dictionary) -> void:
	outcome["answer_slot"] = slot
	outcome["result"] = answer["result"]
	outcome["audio"] = answer["audio"]
	outcome["jyutping"] = str(answer.get("jyutping", ""))


func _outcome(kind: String) -> Dictionary:
	return {
		"kind": kind, "result": "", "answer_slot": "", "audio": "", "jyutping": "",
		"shot": {}, "valid_tile": false, "energy_gained": 0, "glyph": "", "tile_id": -1, "error_protected": false,
	}


func _find_definition(definitions: Array[Dictionary], id: String) -> Dictionary:
	for definition: Dictionary in definitions:
		if definition["id"] == id:
			return definition.duplicate()
	return {}


func _sample_definitions(definitions: Array[Dictionary], rng: RandomNumberGenerator) -> Array[Dictionary]:
	var remaining: Array[Dictionary] = definitions.duplicate()
	var selected: Array[Dictionary] = []
	for draw_index: int in range(3):
		var chosen: Dictionary = remaining.pop_at(rng.randi_range(0, remaining.size() - 1))
		selected.append(chosen.duplicate())
	return selected


func _rng_for(purpose: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = ("%d/%s" % [_run_seed, purpose]).hash()
	return rng

extends SceneTree

const RunModel = preload("res://game/run_state.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var first_pairs: Dictionary = {}
	var first_stage_families: Dictionary = {}
	var directions: Dictionary = {}
	for seed_value: int in range(72):
		var run := RunModel.new()
		run.start_run(seed_value)
		if not _check(run.route.size() == 11 and run.offers.size() == 3, "Ten regular encounters, a final dragon and three special offers: " + run.content_error):
			break
		var seen_families := {}
		for index: int in range(run.route.size()):
			var fight: Dictionary = run.route[index]
			var foe: Dictionary = fight.boss
			if index > 0:
				_check(run.route[index - 1].boss.family != foe.family, "Adjacent bosses have different families")
				_check(run.route[index - 1].deck.anchor != fight.deck.anchor, "The anchor changes at every transition, including the dragon")
			if index == 10:
				_check(foe.family == "dark_dragon" and not foe.rematch, "Only the finale is the dark dragon")
				continue
			_check(int(foe.stage_form) == int(fight.stage), "Boss form follows the current stage")
			if int(fight.stage) == 1:
				first_stage_families[foe.family] = true
			var should_rematch: bool = fight.stage > 1 and fight.foe_in_stage == 2
			_check(foe.rematch == should_rematch and seen_families.has(foe.family) == should_rematch,
				"Stage 1 draws two new foes; later stages introduce one new family and bring back an earlier opponent")
			seen_families[foe.family] = true
		first_pairs[str(run.route[0]["boss"]["id"]) + str(run.route[0]["deck"]["id"])] = true
		for encounter: Dictionary in run.route:
			for card: Dictionary in encounter["deck"]["tiles"]:
				for direction: String in card["placements"]:
					directions[direction] = true
					_check(ResourceLoader.exists(card["placements"][direction]["audio"], "AudioStream"), "Audio for every accepted direction")
		run.choose_special(run.offers[0]["id"])
		var expected_purse: int = 0
		for encounter: int in range(run.route.size()):
			var final_fight := encounter == 10
			var expected_stage := mini(5, floori(encounter / 2.0) + 1)
			if not _check(run.phase == "ready" and run.encounter_index == encounter and run.stage == expected_stage
					and run.foe_in_stage == (3 if final_fight else encounter % 2 + 1) and run.is_dragon == final_fight, "HUD progresses through five stages and then the dragon"):
				break
			_check(run.coin_award.is_empty() and run.coins == expected_purse, "New foe clears only the previous reward breakdown")
			_check(is_equal_approx(run.fall_duration * 1.1, 12.0 - (expected_stage - 1) * 0.5), "Tiles move ten percent faster in each stage")
			var expected_hits := 75 if final_fight else expected_stage * 10 + (1 if run.boss.rematch else 0)
			_check(run.boss_max_hp == expected_hits * 2, "Base enemies take ten more ordinary hits per stage; rematches take one extra")
			run.begin_fight()
			var impacts := 0
			var recent: Array[String] = []
			var last_decoy := false
			for drop: int in range(expected_hits * 2 + 16):
				if run.phase != "battle":
					break
				var glyph: String = run.tile["glyph"]
				var placements: Dictionary = run.tile["placements"]
				_check(glyph not in recent, "Tile recurrence has at least three intervening drops")
				_check(not (last_decoy and placements.is_empty()), "Two adjacent drops offer a match")
				recent.append(glyph)
				if recent.size() > 3:
					recent.pop_front()
				last_decoy = placements.is_empty()
				var action: String = "reject" if last_decoy else str(placements.keys()[0])
				var current_id: int = run.tile_id
				var outcome: Dictionary = run.resolve_tile(action, current_id, float(drop + 1))
				_check(outcome["kind"] == ("correct_reject" if last_decoy else "hit"), "Correct resolution")
				_check(run.active_tiles.size() >= 2 and run.tile_id != current_id, "A placement or rejection immediately leaves two selectable components")
				if not last_decoy:
					_check(ResourceLoader.exists(outcome["audio"], "AudioStream"), "Bundled speech for " + outcome["result"])
					_check(outcome["shot"].source == "player", "Matching launches a projectile")
				_check(run.resolve_tile(action, current_id)["kind"] == "ignored", "Each tile resolves once")
				# Submit in short intervals to exercise overlapping projectiles over the whole run.
				for event: Dictionary in run.advance_time(0.045):
					if event.kind == "impact" and event.source == "player":
						impacts += 1
			_check(impacts == expected_hits, "Unboosted normal impacts meet the stage hit target")
			if not _check(run.phase == "won" and run.chest_earned == not final_fight, "Timed clears grant a chest before the final fight"):
				break
			var base := [5, 8, 11, 15, 20]
			var seconds_left := floori(run.chest_budget - run.active_seconds + RunModel.CLOCK_EPSILON)
			var time_coins := mini(4, floori(seconds_left / 10.0))
			var hp_coins := mini(3, floori(run.hp / 4.0))
			var stage_clear: int = 3 * base[expected_stage - 1] if encounter % 2 == 1 and expected_stage < 5 else 0
			var addition: int = base[expected_stage - 1] + time_coins + hp_coins + stage_clear
			var breakdown := {"base": base[expected_stage - 1], "time": time_coins, "vitality": hp_coins, "stage_clear": stage_clear,
				"bounty": 0, "total": addition, "seconds_left": seconds_left, "hp_left": run.hp}
			expected_purse += addition
			_check(run.coins == expected_purse and run.coin_award == breakdown, "Coins awarded before inspecting the chest")
			if final_fight:
				_check(run.rewards.is_empty(), "Final payout has no unusable chest items")
			else:
				run.claim_reward(run.rewards[0]["id"])
			if run.phase == "replace":
				run.choose_replacement(3)
			run.advance_stage()
			if encounter % 2 == 1 and expected_stage < 5:
				_check(run.phase == "shop" and run.shop_offers.size() == 3, "Shop opens after an intermediate stage's second fight")
				_check(run.shop_price == 5 + expected_stage * 5 and run.stage == expected_stage, "Shop uses the cleared stage's price")
				run.leave_shop()
			_check(run.coins == expected_purse, "Reward screens never re-award fight coins")
		_check(run.phase == "complete" and run.hp > 0, "Cleared all ten regular encounters and the dragon")
	_check(first_stage_families.size() == 15 and first_pairs.size() > 15, "All 15 families can appear in stage 1 with independently paired anchors")
	_check(directions.size() == 4, "The demo contains valid left, right, top and bottom answers")
	for test: String in ["_verify_family_draws", "_verify_falling_and_charging", "_verify_hits_and_cooldown", "_verify_catalogue", "_verify_boss_effects", "_verify_signatures", "_verify_dragon", "_verify_shops", "_verify_shop_funding", "_verify_specials", "_verify_terminals_and_inventory", "_verify_coins", "_verify_clock_equivalence"]:
		_check(call(test) == true, test + " completed")
	if failures == 0:
		print("PASS — 72 complete 11-foe runs, 16 distinct heavy attacks, timed effects, inventory, four shops, dragon incineration and finale")
	quit(0 if failures == 0 else 1)


func _battle(seed_value: int) -> RunModel:
	var run := RunModel.new()
	run.start_run(seed_value)
	run.choose_special(run.offers[0]["id"])
	run.begin_fight()
	return run


func _verify_family_draws() -> bool:
	# Each pair compares a match with a plausible, independently screened distractor.
	var comparisons := {
		"青": [["忄", "礻", "left", "情"], ["目", "自", "left", "睛"]],
		"包": [["氵", "冫", "left", "泡"], ["月", "舟", "left", "胞"]],
		"口": [["及", "友", "right", "吸"], ["古", "右", "right", "咕"]],
	}
	var families: Dictionary = {}
	var sample := RunModel.new()
	var decks := sample._read_decks()
	for selected: Dictionary in decks:
		var run := _battle(72)
		run.route[0].deck = selected
		run._prepare_encounter()
		run.begin_fight()
		var family: Dictionary = {}
		var placements: Dictionary = {}
		var available_counts := [0, 0]
		for card: Dictionary in run.deck.tiles:
			_check(not family.has(card.glyph), "Each component has one card per anchor")
			family[card.glyph] = true
			placements[card.glyph] = card.placements
			available_counts[int(card.placements.is_empty())] += 1
		for pair: Array in comparisons.get(run.deck.anchor, []):
			var answer: Dictionary = placements.get(pair[0], {}).get(pair[2], {})
			_check(answer.get("result", "") == pair[3], "Matched neighbour forms " + str(pair[3]))
			_check(placements.has(pair[1]) and placements[pair[1]].is_empty(), "Contrasting component can be identified as incompatible")
		_check(available_counts[0] >= 7 and available_counts[1] >= 7, "Each anchor supports nonrepeating draws, including replacements")
		for earlier: Dictionary in families.values():
			_check(family != earlier, "Each anchor has a distinct component inventory")
		families[run.deck.id] = family
		var seen: Array[Dictionary] = [{}, {}]
		# Every twelve draws have four decoys, enough to see either pool in three deck lengths.
		for draw_index: int in range(family.size() * 3):
			var kind := int(run.tile.placements.is_empty())
			var glyph: String = run.tile.glyph
			_check(family.has(glyph), "A live tile comes from the active anchor")
			if seen[kind].size() < available_counts[kind]:
				_check(not seen[kind].has(glyph), "Unseen alternatives arrive before repeats within a pool")
			seen[kind][glyph] = true
			# Expiring every tile also verifies that misses cannot crowd fresh cards out of the rotation.
			run.resolve_tile("expire", run.tile_id)
		_check(seen[0].size() + seen[1].size() == family.size(), "Every component is reachable through play")
	return families.size() == decks.size() and families.size() >= 3


func _playable(run: RunModel) -> Dictionary:
	for card: Dictionary in run.active_tiles:
		if not card.placements.is_empty():
			return card
	return {}


func _find_event(events: Array[Dictionary], kind: String, source: String = "") -> Dictionary:
	for event: Dictionary in events:
		if event.kind == kind and (source.is_empty() or event.get("source", "") == source):
			return event
	return {}


func _verify_falling_and_charging() -> bool:
	var run := _battle(193)
	_check(run.active_tiles.size() == 2 and run.tile == run.active_tiles.front(), "Two components start, oldest selected")
	var first: Dictionary = run.active_tiles[0]
	var second: Dictionary = run.active_tiles[1]
	_check(first.age > second.age and first.lane != second.lane, "Opening tiles are staggered in time and position")
	_check(run.select_tile(second.id) and run.tile_id == second.id, "A later component can be selected")
	run.advance_time(run.fall_duration * 0.25)
	_check(run.active_tiles.size() == 3 and run.tile_id == second.id, "A third tile falls without stealing selection")
	var glyphs := {}
	var lanes := {}
	for card: Dictionary in run.active_tiles:
		glyphs[card.glyph] = true
		lanes[card.lane] = true
	_check(glyphs.size() == 3 and lanes.size() == 3, "Active tiles have separate glyphs and lanes")
	var resolution: Dictionary = run.resolve_tile("expire", first.id)
	_check(resolution.valid_tile == not first.placements.is_empty(), "Expiry indicates whether this component was compatible")
	_check(run.tile_id == second.id, "Expiring an unselected tile keeps the current selection")
	_check(not run.select_tile(first.id) and run.resolve_tile("reject", first.id).kind == "ignored", "Expired IDs cannot be selected or scored again")
	var card: Dictionary = _playable(run)
	if card.is_empty():
		run.resolve_tile("reject", run.tile_id)
		card = _playable(run)
	var wrong_slot: String = ""
	for slot: String in RunModel.POSITIONS:
		if not card.placements.has(slot):
			wrong_slot = slot
			break
	var original_charge: int = run.boss_charge
	var wrong: Dictionary = run.resolve_tile(wrong_slot, card.id)
	_check(wrong.kind == "wrong" and not wrong.result.is_empty() and run.boss_charge == original_charge + 1, "Wrong position supplies a model answer and heavy charge")

	for choice: String in ["reject", "expire", "left"]:
		var attempt := _battle(22)
		var found_legal := false
		var found_illegal := false
		for action_index: int in range(20):
			var legal: bool = not attempt.tile.placements.is_empty()
			if legal and found_legal or not legal and found_illegal:
				attempt.resolve_tile("reject" if not legal else str(attempt.tile.placements.keys()[0]), attempt.tile_id)
				continue
			var old_charge: int = attempt.boss_charge
			var result: Dictionary = attempt.resolve_tile(choice, attempt.tile_id)
			var expected_boost: bool = result.kind == "wrong"
			if choice == "expire" and legal:
				_check(not result.result.is_empty() and not result.answer_slot.is_empty(), "Missed match retains its learning feedback")
			_check(attempt.boss_charge == old_charge + (1 if expected_boost else 0), "Only student errors charge a foe: " + choice)
			if legal:
				found_legal = true
			else:
				found_illegal = true
			if found_legal and found_illegal:
				break
		_check(found_legal and found_illegal, "Exercised both compatibility classes")

	var expiring := _battle(47)
	var oldest: Dictionary = expiring.tile
	var elapsed: float = expiring.fall_duration - float(oldest.age)
	var auto_expiry: Dictionary = _find_event(expiring.advance_time(elapsed), "expiry")
	_check(auto_expiry.get("tile_id") == oldest.id and not expiring.select_tile(oldest.id), "Falling out expires independently once")
	_check(expiring.boss_charge == 0, "Passively expired tiles never charge the foe")
	return true


func _verify_hits_and_cooldown() -> bool:
	var run := _battle(65)
	var card: Dictionary = _playable(run)
	var old_boss_hp: int = run.boss_hp
	var hit: Dictionary = run.resolve_tile(str(card.placements.keys()[0]), card.id)
	_check(hit.kind == "hit" and hit.shot.source == "player" and run.boss_hp == old_boss_hp, "Player projectile leaves before damage")
	run.advance_time(RunModel.PROJECTILE_DURATION * 0.5)
	_check(run.boss_hp == old_boss_hp and run.projectiles.size() == 1, "Player damage waits through flight")
	var landed: Dictionary = _find_event(run.advance_time(RunModel.PROJECTILE_DURATION * 0.5), "impact", "player")
	_check(landed.get("damage") == 2 and run.boss_hp == old_boss_hp - 2, "Visible impact applies normal damage")

	# Fill the charge meter using three rejected legitimate cards without advancing time.
	while run.boss_charge < run.boss_charge_max:
		card = _playable(run)
		if card.is_empty():
			run.resolve_tile("reject", run.tile_id)
		else:
			run.resolve_tile("reject", card.id)
	var saved_hp: int = run.hp
	var before_launch: float = run.boss_cooldown_left
	_check(before_launch > 0 and run.projectiles.is_empty(), "Three errors prime the foe for its next timed shot")
	var launches := run.advance_time(before_launch)
	var launch: Dictionary = _find_event(launches, "foe_launch")
	_check(launch.get("shot", {}).get("heavy") == true and run.boss_charge == 0 and run.hp == saved_hp, "Timed launch spends the full heavy gauge before deducting HP")
	_check(is_equal_approx(run.boss_cooldown_left, run.boss_cooldown_duration), "Firing resets the independent cooldown")
	var shot: Dictionary = launch.shot
	var heavy_hit: Dictionary = _find_event(run.advance_time(shot.duration), "impact", "foe")
	_check(heavy_hit.get("damage") == int(run.boss.heavy_damage) and run.hp == saved_hp - int(heavy_hit.damage), "Heavy applies the current boss form's damage on impact")

	var shield_run := _battle(65)
	var normal_launch: Dictionary = _find_event(shield_run.advance_time(shield_run.boss_cooldown_left), "foe_launch")
	_check(normal_launch.get("shot", {}).get("heavy") == false, "Independent cooldown fires even without tile input")
	shield_run.items.append(RunModel.ITEM_CATALOGUE[0])
	_check(shield_run.use_item(0), "A shield may intercept a projectile already in flight")
	var block: Dictionary = _find_event(shield_run.advance_time(RunModel.PROJECTILE_DURATION), "impact", "foe")
	_check(block.get("shielded") == true and shield_run.hp == shield_run.max_hp, "Shield absorbs the impact")
	return true


func _verify_catalogue() -> bool:
	var names := {}
	var families := {}
	var signature_owners := {}
	for family: Dictionary in RunModel.BossCatalogue.FAMILIES:
		families[family.family] = true
		var signature: String = family.get("heavy_effect", {}).get("kind", "damage")
		_check(not signature_owners.has(signature), "One heavy signature belongs to precisely one family: " + signature)
		signature_owners[signature] = family.family
		var previous_cooldown := INF
		for stage in range(1, RunModel.STAGE_COUNT + 1):
			var form := RunModel.BossCatalogue.form(family, stage)
			_check(not str(form.name).is_empty() and not names.has(form.name), "Every stage form has a distinct display name")
			_check(form.stage_form == stage and form.cooldown < previous_cooldown, "Every family fires faster in later stages")
			previous_cooldown = form.cooldown
			names[form.name] = true
			var rematch := RunModel.BossCatalogue.form(family, stage, true)
			_check(rematch.id == form.id and rematch.name == form.name, "Rematch uses the same stage form")
	return families.size() == 15 and names.size() == 75 and signature_owners.size() == 15 \
		and not signature_owners.has(RunModel.BossCatalogue.DARK_DRAGON.heavy_effect.kind)


func _battle_as(family_id: String, stage_number: int) -> RunModel:
	var run := RunModel.new()
	run.start_run(371)
	run.encounter_index = (stage_number - 1) * RunModel.FOES_PER_STAGE
	for family: Dictionary in RunModel.BossCatalogue.FAMILIES:
		if family.family == family_id:
			run.route[run.encounter_index].boss = RunModel.BossCatalogue.form(family, stage_number)
			break
	run.choose_special(run.offers[0].id)
	run.begin_fight()
	return run


func _enemy_impact(run: RunModel, heavy: bool) -> Dictionary:
	if heavy:
		run.boss_charge = run.boss_charge_max
	var events := run.advance_time(run.boss_cooldown_left + RunModel.PROJECTILE_DURATION)
	return _find_event(events, "impact", "foe")


func _verify_boss_effects() -> bool:
	for stage_number in range(1, RunModel.STAGE_COUNT + 1):
		var fox := _battle_as("ink_fox", stage_number)
		var ink := _enemy_impact(fox, true)
		var expected_ink: float = [0.20, 0.30, 0.40, 0.55, 0.70][stage_number - 1]
		_check(ink.damage == [1, 1, 2, 2, 3][stage_number - 1] and ink.effect.kind == "ink", "Fox ink deals its stage damage and applies the screen effect together")
		_check(is_equal_approx(fox.ink_fraction, expected_ink) and is_equal_approx(fox.ink_seconds, 3.0), "Ink covers the current stage's fraction for three seconds")
		fox.advance_time(2.99)
		_check(fox.ink_fraction > 0.0, "Ink persists up to its battle-time deadline")
		fox.advance_time(0.01)
		_check(fox.ink_fraction == 0.0 and fox.ink_seconds == 0.0, "Ink clears at three seconds")
		fox.items.append(RunModel.ITEM_CATALOGUE[0])
		fox.use_item(0)
		var shielded := _enemy_impact(fox, true)
		_check(shielded.shielded and shielded.damage == 0 and fox.ink_fraction == expected_ink, "Shield absorbs the fox damage while its ink still covers the board")

		var wind := _battle_as("wind", stage_number)
		var accelerated := _enemy_impact(wind, true)
		var expected_haste: float = [0.30, 0.40, 0.50, 0.65, 0.80][stage_number - 1]
		_check(accelerated.get("damage") == 3 and is_equal_approx(wind.haste_bonus, expected_haste), "Paper swallow heavy stays at 3 damage and scales acceleration by stage")
		var card: Dictionary = wind.active_tiles.back()
		var initial_age: float = card.age
		wind.advance_time(0.125)
		_check(is_equal_approx(card.age - initial_age, 0.125 * (1.0 + expected_haste)), "Acceleration changes real falling tile age")
		wind.advance_time(2.875)
		_check(wind.haste_seconds == 0.0 and wind.haste_bonus == 0.0, "The fall rate returns to baseline at three seconds")

		var bell := _battle_as("bell", stage_number)
		var bell_hit := _enemy_impact(bell, true)
		_check(bell_hit.get("damage") == [4, 4, 5, 6, 7][stage_number - 1], "Bell heavy scales from 4 to 7 damage")

	var armoured := _battle_as("armour", 1)
	armoured.player_defense = 1
	var armour := _enemy_impact(armoured, false)
	_check(armour.get("damage") == 0 and armoured.armour_drops == 1, "Defense can prevent HP damage while preserving boss effects")
	var playable := _playable(armoured)
	var normal := armoured.resolve_tile(str(playable.placements.keys()[0]), playable.id)
	_check(normal.shot.amount == 1 and armoured.armour_drops == 0, "Armour reduces applicable shot and expires after that tile resolves")
	var beetle := _battle_as("citrus_beetle", 5)
	beetle.energy = 1
	var drain := _enemy_impact(beetle, true)
	_check(beetle.energy == 0 and drain.effect.value == 1, "Beetle energy drain reports the actual loss")
	var koi := _battle_as("lantern_koi", 5)
	koi.boss_hp -= 2
	var restore := _enemy_impact(koi, true)
	_check(koi.boss_hp == koi.boss_max_hp and restore.effect.value == 2, "Boss healing is capped by maximum HP")
	return true


func _verify_signatures() -> bool:
	var crab := _battle_as("clockwork_crab", 1)
	var shuffle := _enemy_impact(crab, true)
	_check(shuffle.effect.kind == "shuffle" and is_equal_approx(crab.effect_seconds("shuffle"), 3.0), "Crab starts three seconds of selection jumps")
	crab.advance_time(0.55)
	var chosen: Dictionary = crab.active_tiles.back()
	crab.select_tile(chosen.id)
	crab.advance_time(0.55)
	_check(crab.tile_id == chosen.id, "Manual targeting gets a full interval to commit")
	crab.advance_time(0.06)
	_check(crab.tile_id != chosen.id, "The next shuffle moves to another live tile")
	crab.advance_time(1.84)
	_check(crab.effect_seconds("shuffle") == 0.0, "Shuffle expires at three seconds")

	var cat := _battle_as("porcelain_cat", 1)
	cat.items.assign(RunModel.ITEM_CATALOGUE.slice(0, 3))
	var held := cat.items.duplicate()
	var theft := _enemy_impact(cat, true)
	_check(cat.items.size() == 2 and theft.effect.value == 1 and theft.effect.item == held[theft.effect.slot], "Cat removes precisely the item identified in its impact")
	held.remove_at(theft.effect.slot)
	_check(cat.items == held, "Remaining inventory keeps its original order")
	cat.items.clear()
	theft = _enemy_impact(cat, true)
	_check(theft.effect.slot == -1 and theft.effect.value == 0 and theft.effect.item.is_empty(), "An empty inventory has nothing to steal")

	var snake := _battle_as("bamboo_snake", 1)
	var anchor: String = snake.deck.anchor
	_enemy_impact(snake, true)
	_check(is_equal_approx(snake.effect_seconds("mask"), 3.0) and snake.deck.anchor == anchor, "Snake conceals the anchor without changing the lesson")
	snake.advance_time(3.0)
	_check(snake.effect_seconds("mask") == 0.0 and snake.deck.anchor == anchor, "The original anchor returns at three seconds")

	var tortoise := _battle_as("jade_tortoise", 1)
	_enemy_impact(tortoise, true)
	var frozen_card: Dictionary = tortoise.tile
	var age: float = frozen_card.age
	tortoise.advance_time(0.8)
	_check(tortoise.tile.age == age and is_equal_approx(tortoise.effect_seconds("freeze"), 1.2), "Tile age stops while the rest of battle time advances")
	for card: Dictionary in tortoise.active_tiles.duplicate():
		var action: String = str(card.placements.keys()[0]) if not card.placements.is_empty() else "reject"
		_check(tortoise.resolve_tile(action, card.id).kind in ["hit", "correct_reject"], "Frozen cards remain selectable and actionable")
	tortoise.advance_time(1.19)
	_check(tortoise.active_tiles.is_empty(), "Freeze suspends replacement spawning as well as motion")
	tortoise.advance_time(0.02)
	_check(tortoise.effect_seconds("freeze") == 0.0 and not tortoise.active_tiles.is_empty() and tortoise.tile.age > 0.0, "Fresh pieces resume falling when freeze ends")

	var lion := _battle_as("paper_lion", 1)
	lion.player_defense = 10
	_enemy_impact(lion, true)
	for i: int in range(3):
		var launch := _find_event(lion.advance_time(lion.boss_cooldown_left), "foe_launch")
		_check(launch.shot.amount == lion.boss.damage + (2 if i < 2 else 0) and launch.shot.empowered == (i < 2), "Lion empowers exactly the next two normal shots")
		lion.advance_time(RunModel.PROJECTILE_DURATION)
	_check(lion.bonus_hits == 0, "Lion returns to baseline after using both boosts")

	var rabbit := _battle_as("cloud_rabbit", 2)
	_enemy_impact(rabbit, true)
	var id := rabbit.tile_id
	var angle := rabbit.tile_rotation_degrees(id)
	_check(absf(angle) in [90.0, 180.0] and angle == rabbit.tile_rotation_degrees(id), "Each rotated glyph has a stable non-upright orientation")
	rabbit.advance_time(1.875)
	_check(absf(rabbit.tile_rotation_degrees(id)) < absf(angle) and rabbit.tile_rotation_degrees(id) != 0.0, "Rotated glyphs ease back toward upright")
	rabbit.advance_time(0.125)
	_check(rabbit.tile_rotation_degrees(id) == 0.0, "Rotation clears exactly at two seconds")

	var otter := _battle_as("river_otter", 2)
	otter.advance_time(otter.fall_duration * 0.25)
	var previous_id := otter.tile_id
	var previous := otter.active_tiles.duplicate(true)
	otter.boss_cooldown_left = 0.01
	var current := _enemy_impact(otter, true)
	_check(otter.tile_id == previous_id and current.effect.tiles.size() == previous.size(), "Current moves all live pieces and preserves selection")
	for i: int in range(previous.size()):
		var moved: Dictionary = otter.active_tiles[i]
		_check(moved.id == previous[i].id and moved.glyph == previous[i].glyph and moved.lane == (previous[i].lane + 1) % 3, "Current shifts every tile one lane with wrap-around")
		_check(is_equal_approx(moved.age, previous[i].age + RunModel.PROJECTILE_DURATION + 0.01) and current.effect.tiles[i].previous_lane == previous[i].lane, "Current retains age and reports the old lane for the animation")

	var moth := _battle_as("moon_moth", 1)
	_enemy_impact(moth, true)
	_check(is_equal_approx(moth.effect_seconds("dim"), 2.0) and moth.ink_fraction == 0.0, "Moth dims individual tiles independently of the ink curtain")
	moth.advance_time(2.0)
	_check(moth.effect_seconds("dim") == 0.0, "Moth dimming ends after two seconds")
	for n in range(1, 6):
		var elephant := _battle_as("stone_elephant", n)
		_enemy_impact(elephant, true)
		_check(is_equal_approx(elephant.rock_fraction, 0.05 + n * 0.05) and is_equal_approx(elephant.effect_seconds("rocks"), 3.0), "Elephant covers the stage-specific lower fraction")
		elephant.advance_time(3.0)
		_check(elephant.rock_fraction == 0.0 and elephant.effect_seconds("rocks") == 0.0, "Rock curtain clears on schedule")
	return true


func _verify_dragon() -> bool:
	var run := _battle(832)
	run.encounter_index = 9
	run._prepare_encounter()
	run.begin_fight()
	run.energy = 2
	run.hp = 1
	run._damage_boss(run.boss_max_hp)
	_check(run.phase == "won" and run.chest_earned and run.hp == run.max_hp, "5-2 restores health and earns its timely chest")
	run.claim_reward(run.rewards[0].id)
	run.advance_stage()
	_check(run.phase == "ready" and run.is_dragon and run.boss.family == "dark_dragon" and run.boss_max_hp == 150 and run.energy == 2, "The dragon follows 5-2 at full health and carried energy")
	_check(run.boss.damage == 3 and run.boss.heavy_damage == 5 and run.boss_cooldown_duration == 6.0 and run.shop_offers.is_empty(), "The dragon's attacks have their fixed stats")
	run.begin_fight()
	run.boss_cooldown_left = 0.1
	run.boss_charge = run.boss_charge_max
	run.advance_time(0.1)
	run.advance_time(0.2)
	var target := _playable(run)
	var shot := run.resolve_tile(str(target.placements.keys()[0]), target.id)
	var marked: Array = run.active_tiles.map(func(card: Dictionary) -> int: return card.id)
	var time_to_hit := RunModel.PROJECTILE_DURATION - 0.2
	run.tile.age = run.fall_duration - time_to_hit
	var events := run.advance_time(time_to_hit)
	var burned := _find_event(events, "impact", "foe")
	_check(burned.damage == 5 and burned.effect.tiles.size() == marked.size(), "Dragon heavy deals five HP and marks every current tile at impact")
	var burned_ids: Array = burned.effect.tiles.map(func(card: Dictionary) -> int: return card.id)
	_check(burned_ids == marked and run.active_tiles.is_empty() and run.tile_id == -1 and _find_event(events, "expiry").is_empty(), "Burn wins simultaneous expiry without false learning feedback")
	for old_id: int in marked:
		_check(run.resolve_tile("reject", old_id).kind == "ignored", "Burned tiles cannot grant a reward or be committed")
	_check(run.boss_charge == 0 and run.energy == 2 and run.projectiles[0].id == shot.shot.id, "Incineration preserves energy and already-launched player fire")
	run.advance_time(0.43)
	_check(run.active_tiles.is_empty() and run.boss_hp == 148, "Existing player attacks still land and no new tile appears in the flames")
	run.advance_time(0.03)
	_check(not run.active_tiles.is_empty() and run.tile_id not in marked, "Normal spawning resumes with a fresh selected tile")
	run.hp = 1
	run._damage_boss(run.boss_hp)
	_check(run.phase == "won" and not run.chest_earned and run.rewards.is_empty() and run.coin_award.hp_left == 1, "Dragon awards final coins without an unusable chest")
	run.advance_stage()
	_check(run.phase == "complete", "Only defeating the dragon completes the campaign")
	return true


func _verify_shops() -> bool:
	var run := _battle(931)
	var history: Dictionary = {}
	run.coins = 300
	run.energy = run.energy_cost
	var balance := run.coins
	# Exercise the real hand and buy all its distinct cards across all four shops.
	for shop_stage in range(1, 5):
		run.encounter_index = shop_stage * RunModel.FOES_PER_STAGE - 1
		run.phase = "won"
		run.advance_stage()
		var shown: Array[String] = []
		for offer: Dictionary in run.shop_offers:
			_check(not shown.has(offer.id), "A shop draws three different options")
			shown.append(offer.id)
		_check(shown.size() == 3 and run.shop_purchases.is_empty(), "The new shop opens with a fresh hand and purchase record")
		var unoffered: String = ""
		for upgrade: Dictionary in RunModel.SHOP_UPGRADES:
			if not shown.has(upgrade.id):
				unoffered = upgrade.id
		_check(not run.buy_upgrade(unoffered) and run.coins == balance, "Only a displayed upgrade can spend coins")
		for id in shown:
			var saved := run.coins
			run.coins = run.shop_price - 1
			_check(not run.can_buy_upgrade(id) and not run.buy_upgrade(id) and not run.shop_purchases.has(id),
				"An unaffordable selection stays available when funds return")
			run.coins = saved
			_check(run.can_buy_upgrade(id) and run.buy_upgrade(id), "Each of the three displayed purchases succeeds")
			history[id] = int(history.get(id, 0)) + 1
			balance -= run.shop_price
			_check(not run.can_buy_upgrade(id) and not run.buy_upgrade(id) and run.coins == balance,
				"An already purchased card cannot charge twice")
		_check(run.shop_purchases.size() == 3 and run.shop_offers.size() == 3, "Buying all three keeps the sold cards visible")
		run.leave_shop()
		_check(run.phase == "ready" and run.stage == shop_stage + 1 and run.foe_in_stage == 1 and run.shop_offers.is_empty() and run.shop_purchases.is_empty(),
			"Leaving the shop clears the per-visit state and advances exactly once")
		_check(not run.buy_upgrade(shown[0]) and run.coins == balance, "A stale shop action cannot buy during countdown")

	_check(balance == 90 and history.size() >= 3, "Twelve distinct per-shop purchases use the four prices")
	_check(run.max_hp == 12 + 2 * history.get("vitality", 0) and run.hp == run.max_hp, "HP upgrades stack between shops")
	_check(run.player_attack_bonus == history.get("attack", 0) and run.player_defense == history.get("defense", 0), "Combat upgrades stack between shops")
	_check(run.energy_cost == 3 - history.get("charge", 0) and run.energy == run.energy_cost and run.chest_budget == 45 + 5 * history.get("chest", 0), "Special and chest upgrades accumulate between stages")
	run.begin_fight()
	var card := _playable(run)
	var hit := run.resolve_tile(str(card.placements.keys()[0]), card.id)
	var special := run.use_special()
	var primary_damage: int = run._special.damage + (run.active_tiles.size() if run._special.id == "stars" else 0)
	_check(hit.shot.amount == 2 + run.player_attack_bonus and special.shot.amount == primary_damage + run.player_attack_bonus,
		"Shop attack gains apply to both normal and special shots")

	var capped := _battle(244)
	capped.energy_cost = 1
	capped.encounter_index = RunModel.FOES_PER_STAGE - 1
	capped.coins = 30
	capped.phase = "won"
	capped.advance_stage()
	for offer: Dictionary in capped.shop_offers:
		_check(offer.id != "charge" and capped.buy_upgrade(offer.id), "All three cards in a capped shop can still be purchased")
	_check(capped.coins == 0 and not capped.can_buy_upgrade("charge"), "The cost floor never wastes a purchase")
	capped.start_run(4)
	_check(capped.max_hp == 12 and capped.player_attack_bonus == 0 and capped.player_defense == 0 and capped.energy_cost == 3 and capped.chest_budget == 45.0
		and capped.shop_offers.is_empty() and capped.shop_purchases.is_empty(), "Starting over in a shop resets upgrades and stock")
	return true


func _verify_shop_funding() -> bool:
	# Buy out each shop in one continuous run using only coins earned from fights.
	var run := RunModel.new()
	run.start_run(931)
	run.choose_special(run.offers[0].id)
	_check(run.coins == 0, "Purchase funds begin at zero")
	for expected_stage in range(1, RunModel.STAGE_COUNT):
		for fight in range(RunModel.FOES_PER_STAGE):
			run.begin_fight()
			for move in range(160):
				if run.phase != "battle":
					break
				var layouts: Dictionary = run.tile.placements
				var action := "reject" if layouts.is_empty() else str(layouts.keys()[0])
				run.resolve_tile(action, run.tile_id)
				run.advance_time(0.25)
			if not _check(run.phase == "won", "Normal placement attacks win the short campaign's shop stages"):
				return false
			if not run.rewards.is_empty():
				run.claim_reward(run.rewards[0].id)
				if run.phase == "replace":
					run.choose_replacement(RunModel.INVENTORY_CAPACITY)
			run.advance_stage()
		if not _check(run.phase == "shop" and run.coins >= run.shop_price * 3, "A strong two-fight stage funds all three offers"):
			return false
		for offer: Dictionary in run.shop_offers:
			_check(run.buy_upgrade(offer.id), "Buy every offer with earned coins")
		run.leave_shop()
	return true


func _verify_specials() -> bool:
	var checked := {}
	for seed_value: int in range(72):
		var sample := _battle(seed_value)
		for choice: Dictionary in sample.offers:
			if checked.has(choice.id):
				continue
			checked[choice.id] = true
			_check(choice.damage > 0 and choice.effect_value > 0 and not str(choice.effect).is_empty(), "Drawn cards expose numerical damage and effect")
			var run := RunModel.new()
			run.start_run(seed_value)
			run.choose_special(choice.id)
			run.begin_fight()
			run.advance_time(2.0)
			run.energy = run.energy_cost
			run.hp -= 2
			var before_cooldown: float = run.boss_cooldown_left
			var before_hp: int = run.boss_hp
			var special: Dictionary = run.use_special()
			_check(special.kind == "special" and special.shot.heavy and run.boss_hp == before_hp, "Each special launches a charged projectile")
			_check(run.energy == 0 and run.use_special().kind == "ignored", "A special consumes energy exactly once")
			if choice.id == "delay":
				_check(run.boss_cooldown_left > before_cooldown, "Delay rewinds the enemy timer")
			if choice.id == "heal":
				_check(run.hp == run.max_hp - 1, "Healing special grants a health point")
			var impact: Dictionary = _find_event(run.advance_time(RunModel.PROJECTILE_DURATION), "impact")
			var expected_damage: int = choice.damage + (run.active_tiles.size() if choice.id == "stars" else 0)
			_check(impact.get("damage") == expected_damage, "Each special deals its correct damage on arrival")
	_check(checked.size() == RunModel.SPECIALS.size(), "All special abilities exercised")
	return true


func _verify_terminals_and_inventory() -> bool:
	for offset: float in [0.0, 0.01]:
		var run := _battle(4)
		run.boss_hp = 1
		run.active_seconds = run.chest_budget - RunModel.PROJECTILE_DURATION + offset
		var card := _playable(run)
		run.resolve_tile(str(card.placements.keys()[0]), card.id)
		_check(run.phase == "battle", "Lethal shots wait for impact")
		run.advance_time(RunModel.PROJECTILE_DURATION)
		_check(run.phase == "won" and run.chest_earned == (offset == 0.0), "Chest cutoff uses lethal impact time")
		_check(run.active_tiles.is_empty() and run.projectiles.is_empty(), "Incoming projectiles and active tiles clear on victory")
		_check(run.coins == 8 and run.coin_award.time == 0 and run.coin_award.hp_left == 12, "A full-health late or exact-deadline win pays 5 base plus 3 vitality")
		if offset > 0.0:
			_check(run.rewards.is_empty(), "Late fight clears without a bonus")
			continue
		run.items.assign([RunModel.ITEM_CATALOGUE[0], RunModel.ITEM_CATALOGUE[1], RunModel.ITEM_CATALOGUE[2]])
		var before: Array[Dictionary] = run.items.duplicate()
		run.claim_reward(run.rewards[0]["id"])
		_check(run.phase == "replace" and run.items == before, "Fourth item requires a choice")
		run.advance_stage()
		_check(run.phase == "replace", "Inventory choice blocks advancement")
		run.choose_replacement(3)
		_check(run.phase == "won" and run.items == before, "Declining the new item keeps the old inventory")
		run.advance_stage()
		_check(run.stage == 1 and run.foe_in_stage == 2 and run.phase == "ready" and run.boss_charge == 0, "Next encounter resets charge and clock")

	var lost := _battle(56)
	lost.hp = 1
	lost.advance_time(lost.boss_cooldown_duration)
	var response := _playable(lost)
	if not response.is_empty():
		lost.boss_hp = 1
		lost.resolve_tile(str(response.placements.keys()[0]), response.id)
	lost.advance_time(RunModel.PROJECTILE_DURATION)
	_check(lost.phase == "defeat" and lost.hp == 0 and lost.projectiles.is_empty(), "First lethal impact cancels in-flight retaliation")
	lost.start_run(999)
	_check(lost.stage == 1 and lost.hp == lost.max_hp and lost.items.is_empty() and lost.energy == 0 and lost.coins == 0 and lost.coin_award.is_empty(), "Fresh run resets combat and inventory")
	return true


func _verify_coins() -> bool:
	# Snapshot and reward calculations have separate units. Exercise the boundaries of both bonuses.
	var times := [44.50, 40.00, 39.99, 30.00, 29.99, 20.00, 19.99, 10.00, 9.99, 0.01, 0.00, -2.00]
	var time_coins := [4, 4, 3, 3, 2, 2, 1, 1, 0, 0, 0, 0]
	var health := [1, 3, 4, 7, 8, 11, 12]
	var hp_coins := [0, 0, 1, 1, 2, 2, 3]
	for t: int in range(times.size()):
		for h: int in range(health.size()):
			var run := _battle(31)
			var time_left: float = times[t]
			run.hp = health[h]
			run.boss_hp = 1
			run.active_seconds = run.chest_budget - time_left - RunModel.PROJECTILE_DURATION
			var card := _playable(run)
			run.resolve_tile(str(card.placements.keys()[0]), card.id)
			_check(run.coins == 0 and run.coin_award.is_empty(), "Launching a lethal hit does not pay early")
			run.advance_time(RunModel.PROJECTILE_DURATION)
			var expected: int = 5 + time_coins[t] + hp_coins[h]
			var breakdown := {"base": 5, "time": time_coins[t], "vitality": hp_coins[h], "stage_clear": 0, "bounty": 0, "total": expected,
				"seconds_left": maxi(0, floori(time_left)), "hp_left": health[h]}
			_check(run.coin_award == breakdown, "Settled snapshots retain their units while bonuses use 10-second and 4-HP bands")
			_check(run.coins == expected and run.chest_earned == (time_left >= 0.0), "Wallet settles regardless of chest eligibility")
			run.advance_time(90.0)
			run.use_special()
			run.resolve_tile("left", card.id)
			_check(run.coins == expected and run.coin_award == breakdown, "Duplicate events cannot re-award coins or change the snapshots")
			run.start_run(32)
			_check(run.coins == 0 and run.coin_award.is_empty(), "Fresh run discards previous purse and breakdown")
	return true


func _verify_clock_equivalence() -> bool:
	var slow_frame := _battle(193)
	var fast_frames := _battle(193)
	var all_events: Array[Dictionary] = slow_frame.advance_time(20.0)
	var separate_events: Array[Dictionary] = []
	for i: int in range(200):
		separate_events.append_array(fast_frames.advance_time(0.1))
	_check(all_events.size() == separate_events.size(), "Long frames preserve the event count")
	for index: int in range(mini(all_events.size(), separate_events.size())):
		_check(all_events[index].kind == separate_events[index].kind, "Frame rate preserves event order")
	_check(fast_frames.hp == slow_frame.hp and fast_frames.boss_charge == slow_frame.boss_charge, "Frame rate preserves damage and charge")
	_check(fast_frames.tile_id == slow_frame.tile_id and is_equal_approx(fast_frames.boss_cooldown_left, slow_frame.boss_cooldown_left), "Frame rate preserves selection and cooldown")
	return true


func _check(condition: bool, label: String) -> bool:
	if not condition:
		failures += 1
		push_error(label)
	return condition

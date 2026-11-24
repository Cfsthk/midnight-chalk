extends SceneTree

const Run = preload("res://game/run_state.gd")
var failures: int = 0


func _initialize() -> void:
	_test_drafts()
	_test_inventory_choice()
	_test_mark_and_charge()
	_test_mirror()
	_test_field_specials()
	_test_damage_specials()
	_test_flame()
	_test_field_items()
	_test_protections()
	_test_timers_and_rewards()
	if failures == 0:
		print("PASS — 12 opening powers, 12 chest items, projectile timing, tile tools, protections and one-fight rewards")
	quit(int(failures > 0))


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)


func _battle(power: String = "heavy") -> Run:
	var run := Run.new()
	for seed_value: int in range(200):
		run.start_run(seed_value)
		if not run._find_definition(run.offers, power).is_empty():
			run.choose_special(power)
			run.begin_fight()
			return run
	_check(false, "Power unreachable in opening draw: " + power)
	return run


func _give(run: Run, kind: String) -> void:
	run.items.append(run._find_definition(Run.ITEM_CATALOGUE, kind))


func _use(run: Run, kind: String) -> void:
	_give(run, kind)
	var index := run.items.size() - 1
	_check(run.can_use_item(index) and run.use_item(index), "Can consume " + kind)


func _cast(run: Run) -> Dictionary:
	run.energy = run.energy_cost
	return run.use_special().shot


func _card(run: Run, compatible: bool) -> Dictionary:
	for i: int in range(16):
		for card: Dictionary in run.active_tiles:
			if compatible == (not card.placements.is_empty()):
				return card
		run.resolve_tile("expire", run.tile_id)
	_check(false, "Could not find card of requested compatibility")
	return {}


func _place(run: Run) -> Dictionary:
	var card := _card(run, true)
	return run.resolve_tile(card.placements.keys()[0], card.id)


func _incoming(run: Run, damage: int, effect: Dictionary = {}) -> Dictionary:
	run._launch("foe", damage, true, effect)
	for event: Dictionary in run.advance_time(Run.PROJECTILE_DURATION):
		if event.kind == "impact" and event.source == "foe":
			return event
	return {}


func _test_drafts() -> void:
	var powers := {}
	var items := {}
	for seed_value: int in range(72):
		var run := Run.new()
		run.start_run(seed_value)
		var draw := {}
		for power: Dictionary in run.offers:
			draw[power.id] = true
			powers[power.id] = true
		_check(draw.size() == 3, "Opening offers are three distinct powers")
		run.choose_special(run.offers.front().id)
		run.begin_fight()
		run._damage_boss(run.boss_hp)
		draw.clear()
		for item: Dictionary in run.rewards:
			draw[item.id] = true
			items[item.id] = true
		_check(draw.size() == 3, "Timely chest offers three distinct items")
	_check(powers.size() == 12 and items.size() == 12, "All catalogue entries actually appear in player choices")


func _test_inventory_choice() -> void:
	for discard_index: int in range(Run.INVENTORY_CAPACITY + 1):
		var run := _battle()
		for held in ["fan", "clip", "lantern"]:
			_give(run, held)
		var previous := run.items.duplicate()
		run._damage_boss(run.boss_hp)
		var found: Dictionary = run.rewards.front()
		run.claim_reward(found.id)
		_check(run.phase == "replace" and run.pending_item == found, "Fourth item remains pending until the discard choice")
		run.choose_replacement(-1)
		run.choose_replacement(4)
		_check(run.phase == "replace" and run.items == previous, "Invalid choice cannot discard any item")
		run.choose_replacement(discard_index)
		var expected := previous.duplicate()
		if discard_index < Run.INVENTORY_CAPACITY:
			expected[discard_index] = found
		_check(run.items == expected and run.phase == "won" and run.pending_item.is_empty(), "Discarding one of four keeps precisely the other three")
		run.choose_replacement((discard_index + 1) % 4)
		_check(run.items == expected, "A stale click cannot discard another item")


func _test_mark_and_charge() -> void:
	var run := _battle("mark")
	var hp_before := run.boss_hp
	_check(_cast(run).amount == 2 and run.marked_hits == 3 and run.boss_hp == hp_before, "Mark fires for two and arms three correct placements")
	run.resolve_tile("reject", _card(run, true).id)
	run.resolve_tile("expire", run.tile_id)
	run.resolve_tile("reject", _card(run, false).id)
	_check(run.marked_hits == 3, "Errors, misses and correct rejects preserve the mark")
	_use(run, "attack")
	for expected in [4, 3, 3, 2]:
		_check(_place(run).shot.amount == expected, "Mark adds exactly one to each of the next three placements")
	run = _battle("break_charge")
	run.boss_charge = run.boss_charge_max
	_check(_cast(run).amount == 3 and run.boss_charge == run.boss_charge_max - 1, "Break removes one pip before a primed foe launches")
	var events := run.advance_time(run.boss_cooldown_left)
	_check(events.any(func(e: Dictionary) -> bool: return e.kind == "foe_launch" and not e.shot.heavy), "Decharging a primed foe changes its next shot")
	run.boss_charge = 0
	_cast(run)
	_check(run.boss_charge == 0, "Charge cannot become negative")


func _test_mirror() -> void:
	var run := _battle("mirror")
	var hp_before := run.boss_hp
	_cast(run)
	_use(run, "shield")
	var blocked := _incoming(run, 2)
	_check(blocked.counter_shot.is_empty() and blocked.shielded and run.effect_seconds("mirror") > 0.0, "A shielded shot does not spend the mirror")
	var reflected := _incoming(run, 2)
	_check(reflected.damage == 2 and run.hp == run.max_hp - 2 and reflected.counter_shot.amount == 3, "Mirror retaliates once while the player takes damage")
	_check(run.effect_seconds("mirror") == 0.0 and run.boss_hp == hp_before - 2, "Reflected damage waits for its own projectile")
	run.advance_time(Run.PROJECTILE_DURATION)
	_check(run.boss_hp == hp_before - 5 and _incoming(run, 1).counter_shot.is_empty(), "One mirror grants only one counter")
	run = _battle("mirror")
	_cast(run)
	run.advance_time(5.0)
	_check(_incoming(run, 1).counter_shot.is_empty(), "No counter after five seconds")


func _test_field_specials() -> void:
	var run := _battle("slow")
	_cast(run)
	var card := run.tile
	var age: float = card.age
	var cooldown := run.boss_cooldown_left
	run.advance_time(5.0)
	_check(is_equal_approx(card.age - age, 3.8), "Slow affects four seconds of movement and ends before the fifth")
	_check(is_equal_approx(cooldown - run.boss_cooldown_left, 5.0) and run.active_seconds == 5.0, "Slow preserves enemy and chest clocks")
	run = _battle("cleanse")
	for kind in ["ink", "rocks", "mask", "rotate", "dim", "shuffle"]:
		run._apply_boss_effect({"kind": kind, "value": 0.6, "duration": 3.0})
	_use(run, "clip")
	_cast(run)
	for kind in ["ink", "rocks", "mask", "rotate", "dim", "shuffle"]:
		_check(run.effect_seconds(kind) == 0.0, "Cleanse clears " + kind)
	_check(run.ink_fraction == 0.0 and run.rock_fraction == 0.0 and run.effect_seconds("clip") == 5.0, "Cleanse restores the field and preserves friendly items")


func _test_damage_specials() -> void:
	var run := _battle("comeback")
	for hp in [7, 6, 1]:
		run.hp = hp
		_check(_cast(run).amount == (3 if hp > 6 else 6), "Comeback threshold includes exactly half HP")
	run = _battle("stars")
	_check(_cast(run).amount == 4, "Stars counts the two visible starting tiles")
	run.advance_time(run.fall_duration * 0.25)
	var before := run.active_tiles.duplicate(true)
	_check(_cast(run).amount == 5 and run.active_tiles == before, "Three-star maximum leaves the live tiles intact")
	run._clear_tiles()
	_check(_cast(run).amount == 2, "Empty field still produces the base hit")


func _test_flame() -> void:
	var run := _battle("reject_flame")
	_check(_cast(run).amount == 2, "Reject flame first launches its two-point shot")
	run.resolve_tile("reject", _card(run, true).id)
	_check(run.effect_seconds("reject_flame") == 5.0, "A wrong reject leaves the effect available")
	var decoy := _card(run, false)
	var answer := run.resolve_tile("reject", decoy.id)
	_check(answer.shot.amount == 3 and answer.energy_gained == 1 and run.effect_seconds("reject_flame") == 0.0, "A correct reject fires once and retains normal energy")
	decoy = _card(run, false)
	_check(run.resolve_tile("reject", decoy.id).shot.is_empty(), "Only one extra shot per cast")
	_cast(run)
	decoy = _card(run, false)
	run._charged_decoys[decoy.glyph] = true
	answer = run.resolve_tile("reject", decoy.id)
	_check(answer.shot.amount == 3 and answer.energy_gained == 0, "Recognizing an already charged decoy fires but cannot grant a second energy point")
	run = _battle("reject_flame")
	_cast(run)
	run.advance_time(5.0)
	_check(run.resolve_tile("reject", _card(run, false).id).shot.is_empty(), "Flame window expires after five seconds")


func _test_field_items() -> void:
	var run := _battle()
	var old := run.tile
	var other: Dictionary = run.active_tiles.back()
	var shots := run.projectiles.size()
	_use(run, "fan")
	_check(run.tile_id != old.id and run.tile.glyph != old.glyph and run.tile.lane == old.lane and run.tile.age == old.age, "Fan exchanges the selected glyph in place")
	_check(run.active_tiles.has(other) and run.active_tiles.size() == 2 and run.projectiles.size() == shots and run.boss_charge == 0 and run.energy == 0, "Swapping is neutral and preserves other tiles")
	_check(run.resolve_tile("reject", old.id).kind == "ignored", "Swapped card cannot be submitted again")
	_use(run, "lantern")
	var hint := run.hinted_tile_id
	_check(hint != -1 and run.select_tile(hint) and not run.tile.placements.is_empty(), "Lantern highlights a current compatible target")
	run.resolve_tile("expire", hint)
	_check(run.hinted_tile_id == -1, "Removing its target clears the highlight")
	run._clear_tiles()
	_use(run, "lantern")
	_check(run.lantern_waiting and run.hinted_tile_id == -1, "Lantern waits if there's no compatible tile on the field")
	run._packet_kinds.assign([false, true])
	run._draw_tile()
	_check(run.lantern_waiting and run.hinted_tile_id == -1, "Pending hint ignores an incompatible arrival")
	run._draw_tile()
	_check(not run.lantern_waiting and run.hinted_tile_id == run.active_tiles.back().id, "First compatible arrival gets the pending hint")
	run = _battle()
	old = run.tile
	other = run.active_tiles.back()
	var age: float = old.age
	var other_age: float = other.age
	_use(run, "clip")
	run.select_tile(other.id)
	run.advance_time(4.5)
	_check(run.pinned_tile_id == old.id and old.age == age and is_equal_approx(other.age, other_age + 4.5), "Clip holds one tile while selection and other tiles continue")
	run.advance_time(1.0)
	_check(run.pinned_tile_id == -1 and is_equal_approx(old.age, age + 0.5), "Pinned tile resumes from the same place after five seconds")
	run.select_tile(old.id)
	_use(run, "clip")
	run.resolve_tile("expire", old.id)
	_check(run.pinned_tile_id == -1 and run.effect_seconds("clip") == 0.0, "A pinned tile remains actionable")


func _test_protections() -> void:
	var run := _battle()
	_use(run, "calm")
	_give(run, "calm")
	_check(not run.use_item(0) and run.items.size() == 1, "A second charm stays in inventory until the first is spent")
	run.resolve_tile("expire", run.tile_id)
	_place(run)
	run.resolve_tile("reject", _card(run, false).id)
	_check(run.calm_charges == 2, "Misses and correct play do not consume error protection")
	var wrong := run.resolve_tile("reject", _card(run, true).id)
	_check(wrong.error_protected and wrong.kind == "wrong" and not wrong.result.is_empty() and run.calm_charges == 1, "A protected wrong reject still teaches the correct answer")
	wrong = run.resolve_tile("left", _card(run, false).id)
	_check(wrong.error_protected and run.calm_charges == 0 and run.boss_charge == 0, "Second deliberate error spends the remaining protection")
	run.resolve_tile("reject", _card(run, true).id)
	_check(run.boss_charge == 1, "Subsequent errors charge the foe normally")
	for kind in ["ink", "steal", "incinerate"]:
		run = _battle()
		_use(run, "umbrella")
		_give(run, "heal")
		var undisturbed := run.active_tiles.duplicate()
		var quiet := _incoming(run, 1)
		_check(not quiet.effect_blocked and run.umbrella_ready, "A damage-only hit leaves the umbrella open")
		var attack := Run.BossCatalogue.DARK_DRAGON.heavy_effect if kind == "incinerate" else {"kind": kind, "value": 1.0, "duration": 3.0}
		var guarded := _incoming(run, 5, attack)
		_check(guarded.effect_blocked and guarded.effect.is_empty() and guarded.damage == 5 and run.hp == run.max_hp - 6, "Umbrella blocks " + kind + " while taking the hit")
		_check(not run.umbrella_ready and run.ink_fraction == 0.0 and run.items.size() == 1 and run.active_tiles == undisturbed, "Umbrella preserves inventory and live tiles")
		var unguarded := _incoming(run, 0, attack)
		_check(not unguarded.effect_blocked and unguarded.effect.kind == kind, "Only the first disruption is blocked")


func _test_timers_and_rewards() -> void:
	var run := _battle("delay")
	var clock_before := run.boss_cooldown_left
	_use(run, "hourglass")
	_check(run.chest_budget == Run.CHEST_BUDGET + 8.0 and run.boss_cooldown_left == clock_before, "Hourglass only extends the current chest")
	_use(run, "bell")
	_check(run.boss_cooldown_left == clock_before + 3.0, "Bell delays the next foe shot for three seconds")
	_cast(run)
	_check(run.boss_cooldown_left == clock_before + 3.0, "Rewinding the attack meter cannot undo a longer bell delay")
	var events := run.advance_time(clock_before + 2.9)
	_check(not events.any(func(e: Dictionary) -> bool: return e.kind == "foe_launch"), "Delayed foe stays idle until its extended deadline")
	run.advance_time(0.1)
	_check(is_equal_approx(run.boss_cooldown_left, run.boss_cooldown_duration), "Only the one cooldown is extended")
	run.active_seconds = run.chest_budget - 1.0
	_use(run, "bounty")
	_check(run.coins == 0 and run.bounty_coins == 5, "Bounty pays only on victory")
	run._damage_boss(run.boss_hp)
	_check(run.coin_award.bounty == 5 and run.coins == 13 and run.chest_earned, "Victory awards the bounty beside normal coins and uses the extended deadline")
	run.claim_reward(run.rewards.front().id)
	run.advance_stage()
	_check(run.chest_budget == Run.CHEST_BUDGET and run.bounty_coins == 0, "The next fight spends neither the old hourglass nor the old bounty")
	run.begin_fight()
	_use(run, "bounty")
	run.hp = 1
	_incoming(run, 2)
	_check(run.phase == "defeat" and run.coins == 13 and run.bounty_coins == 0, "Defeat cancels the outstanding victory bounty")

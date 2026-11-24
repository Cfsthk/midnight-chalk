extends SceneTree

const SCENE = preload("res://main.tscn")
var failed := false


func _initialize() -> void:
	_check.call_deferred()


func _expect(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failed = true


func _check() -> void:
	var screen := SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	# Drive simulation itself with deterministic deltas; real render tweens still run.
	screen.set_process(false)
	_expect(screen.run.phase == "power" and not screen.has_node("Menu/MenuCard/Options/Start"), "Opening the game goes directly to the special draw")
	_check_foe_visibility(screen, false)
	_expect(not screen._stage_label.visible, "Special selection does not show a previous level")
	var options: VBoxContainer = screen.get_node("Menu/MenuCard/Options")
	var hand: HBoxContainer = options.get_node("PowerDraw")
	_expect(hand.get_child_count() == 3, "Draw exactly three power cards")
	for offer: Dictionary in screen.run.offers:
		var pick: Button = hand.get_node("Power" + str(offer.id).capitalize())
		var effect_text := str(offer.description)
		var damage = pick.find_child("Damage", true, false)
		_expect(pick.tooltip_text.contains(effect_text) and pick.text.is_empty(), "Power details are available on hover")
		_expect(damage.get_node("Value").text == str(offer.damage), "Each card displays numeric damage")
		_expect(pick.find_child("PowerMark", true, false).icon == "power_" + str(offer.id), "Each special has a distinctive icon")
	var choice: Button = hand.get_child(0)
	choice.pressed.emit()
	_expect(not screen.has_node("Menu/MenuCard/Options/Ready") and screen._countdown == 3.0, "Choosing power starts countdown directly")
	_check_foe_visibility(screen, false)
	choice.pressed.emit()
	_expect(screen._countdown == 3.0 and screen.run.encounter_index == 0, "Repeated stale choice cannot restart countdown")
	var pause: Button = screen.get_node("Pause")
	_expect(pause.visible and screen._count_label.text == "3", "Pause is accessible during countdown")
	pause.pressed.emit()
	screen._process(4)
	_expect(screen.run.phase == "ready" and screen._countdown == 3, "Pause freezes countdown")
	_check_foe_visibility(screen, false)
	screen._resume.pressed.emit()
	screen._process(2.95)
	_check_foe_visibility(screen, false)
	screen._process(0.06)
	_expect(screen.run.phase == "battle", "Countdown opens battle")
	_check_foe_visibility(screen, true)
	_expect(screen._cards[0].visible and screen._cards[1].visible, "Two independently selectable cards appear at battle start")
	var first_id: int = screen.run.tile_id
	var second_lane := int(screen.run.active_tiles[1].lane)
	screen._cards[second_lane].pressed.emit()
	_expect(screen.run.tile_id != first_id and screen._cards[second_lane].get_meta("selected"), "Tap selects the other card")
	screen._process(screen.run.fall_duration * 0.25)
	_expect(screen._cards.all(func(card: Button) -> bool: return card.visible), "Three simultaneously visible cards")
	for viewport_size in [Vector2(1280, 720), Vector2(1024, 768), Vector2(1280, 960), Vector2(657, 748), Vector2(1280, 1457), Vector2(390, 844)]:
		screen.size = viewport_size
		_check_layout(screen, viewport_size)
	screen.size = Vector2(1280, 720)
	var valid: Dictionary = {}
	for tile: Dictionary in screen.run.active_tiles:
		if not tile.placements.is_empty():
			valid = tile
			break
	_expect(not valid.is_empty(), "At least one opening tile is valid")
	if valid.is_empty():
		quit(1)
		return
	var direction := str(valid.placements.keys()[0])
	screen._select_lane(valid.lane)
	var audio_path := str(valid.placements[direction].audio)
	var boss_health: int = screen.run.boss_hp
	screen._slots[direction].pressed.emit()
	_expect(screen._voice.playing, "Cantonese begins on a correct placement")
	screen._play_answer(audio_path)
	_expect(screen._voice_queue.size() == 1, "A second rapid match queues its word without interrupting the first")
	var result = screen._result_flash
	_expect(result.visible and result.glyph == str(valid.placements[direction].result), "Correct placement renders the formed character")
	_expect(screen._feedback == 0.0 and not screen.has_node("Outcome") and screen._slots[direction].text.is_empty(), "Correct matches leave the board header clear")
	_expect(result.mouse_filter == Control.MOUSE_FILTER_IGNORE and not screen._slots[direction].disabled, "Result is click-through")
	_expect(screen.run.boss_hp == boss_health and screen.run.projectiles.size() == 1, "Player's hit launches a projectile")
	var small: Vector2 = result.ink_rect().size
	var starting_alpha: float = result.opacity()
	_expect(starting_alpha > 0.0 and starting_alpha < 0.7, "Brush strokes start translucent")
	screen._process(0.12)
	var first_width: float = result.ink_rect().size.x
	var first_alpha: float = result.opacity()
	_expect(first_width > small.x * 1.8 and first_alpha > 0.0 and first_alpha < starting_alpha, "Kai glyph grows and dissolves together")
	screen._process(0.08)
	_expect(result.ink_rect().size.x > first_width and result.opacity() < first_alpha, "Expansion continues as the ink thins")
	_expect(absf(screen._anchor.self_modulate.a - 0.14) < 0.005, "Anchor recedes behind the formed character")
	for slot: Button in screen._slots.values():
		_expect(not slot.disabled and absf(slot.self_modulate.a - 0.14) < 0.005, "Directional squares recede while their hit areas stay active")
	_expect(is_equal_approx(screen._reject.self_modulate.a, 1.0), "Unrelated battle controls keep full opacity")
	var age_before_pause: float = result.elapsed
	var clock_before: float = screen.run.active_seconds
	var age: float = screen.run.active_tiles[0].age
	var flight: float = screen.run.projectiles[0].remaining
	var charge_left: float = screen.run.boss_cooldown_left
	pause.pressed.emit()
	screen._process(2)
	_expect(screen.run.active_seconds == clock_before and screen.run.boss_cooldown_left == charge_left, "Pause freezes chest and foe timer")
	_expect(screen.run.active_tiles[0].age == age and screen.run.projectiles[0].remaining == flight, "Pause freezes cards and airborne attack")
	_expect(screen._voice.stream_paused and screen._slots[direction].disabled, "Pause freezes speech and placement")
	_expect(not result.visible and result.elapsed == age_before_pause, "Pause freezes and conceals the result behind the menu")
	screen._resume.pressed.emit()
	_expect(result.visible and result.elapsed == age_before_pause, "Resume continues the same character animation")
	screen._process(flight + 0.01)
	_expect(result.visible and result.opacity() < 0.5, "Character fades at the end of its short sequence")
	_expect(screen._anchor.self_modulate.a > 0.70 and screen._anchor.self_modulate.a < 1.0, "Board pieces return gradually as the character fades")
	for test_size in [Vector2(657, 748), Vector2(1280, 720)]:
		screen.size = test_size
		var area: Rect2 = result.ink_rect()
		var relative := Rect2(Vector2.ZERO, result.size)
		_expect(result.get_rect() == screen._left and relative.encloses(area), "Resized result stays inside left battle panel")
		_expect(area.get_center().distance_to(relative.get_center()) < 0.01, "Result stays optically centred")
		_expect(maxf(area.size.x / relative.size.x, area.size.y / relative.size.y) >= 0.88, "Dissipating result approaches the board edges")
	screen._process(0.07)
	_expect(not result.visible and result.glyph.is_empty() and is_zero_approx(result.opacity()), "The reveal reaches zero alpha at full expansion within half a second")
	_expect(is_equal_approx(screen._anchor.self_modulate.a, 1.0) and screen._slots.values().all(func(slot: Button) -> bool: return is_equal_approx(slot.self_modulate.a, 1.0)), "Board pieces are fully restored at animation completion")
	_expect(screen.run.boss_hp < boss_health, "Model applies the hit on arrival")
	var boss_bar = screen.get_node("BossHealth")
	var desired := float(screen.run.boss_hp) / float(screen.run.boss_max_hp)
	_expect(boss_bar.value > desired, "HP drains after projectile impact")
	boss_bar._animation.pause()
	boss_bar._animation.custom_step(0.10)
	boss_bar._animation.play()
	_expect(boss_bar.value < 1 and boss_bar.value > desired, "Boss HP animates through intermediate fills")
	pause.pressed.emit()
	var frozen_fill: float = boss_bar.value
	await process_frame
	await process_frame
	_expect(not boss_bar._animation.is_running() and is_equal_approx(boss_bar.value, frozen_fill), "Visible HP tween freezes during pause")
	screen._resume.pressed.emit()
	var charge_before: int = screen.run.boss_charge
	# Two simultaneously retained decoys are possible after choosing a match out of order.
	var legal := false
	for step in range(5):
		for tile: Dictionary in screen.run.active_tiles:
			if not tile.placements.is_empty():
				screen._select_lane(tile.lane)
				legal = true
				break
		screen._commit("reject")
		if legal:
			break
	_expect(screen.run.boss_charge == charge_before + 1, "Rejecting a legal card fills the enemy charge")
	var foe_transfer: Dictionary = screen._effects._transfers.back()
	_expect(foe_transfer.foe and foe_transfer.reject and is_equal_approx(foe_transfer.portion, float(screen.run.boss_charge) / screen.run.boss_charge_max), "A genuine foe charge sends a spark to its new fill position")
	_expect(screen._effects._foe_gauge == screen._foe_charge.get_rect(), "Charge animation lands on the enemy heavy gauge")
	_expect(screen._feedback > 0.0 and not result.visible and screen._miss_flash.visible and screen._miss_flash.get_rect() == screen._lane, "Rejecting a legal tile reveals its red answer in the middle")
	_expect(screen._slots.values().any(func(slot: Button) -> bool: return not slot.text.is_empty()), "The correct answer is shown in its position")
	screen._process(1.1)
	_expect(screen._feedback == 0.0 and not screen._miss_flash.visible, "Result clears and controls remain live")
	screen._process(screen.run.boss_cooldown_left + 0.02)
	var foe_shot: bool = screen.run.projectiles.any(func(shot: Dictionary) -> bool: return shot.source == "foe")
	_expect(foe_shot, "A cooldown launches a foe projectile")
	var hp_before: int = screen.run.hp
	screen._process(0.45)
	_expect(screen.run.hp < hp_before, "Enemy projectile reduces player HP at target")
	var player_bar = screen.get_node("PlayerHealth")
	var player_target := float(screen.run.hp) / float(screen.run.max_hp)
	player_bar._animation.pause()
	player_bar._animation.custom_step(0.10)
	_expect(player_bar.value > player_target and player_bar.value < 1.0, "Player HP animates through intermediate fills")
	var previous_tween = player_bar._animation
	var previous_fill: float = player_bar.value
	screen.run.hp = maxi(0, screen.run.hp - 1)
	screen._sync_hud(true)
	_expect(not previous_tween.is_valid() and is_equal_approx(player_bar.value, previous_fill), "A second impact retargets HP from its displayed fill")
	player_bar._animation.pause()
	player_bar._animation.custom_step(0.40)
	_expect(is_equal_approx(player_bar.value, float(screen.run.hp) / float(screen.run.max_hp)), "Retargeted health reaches the model value")
	var speech_deadline := Time.get_ticks_msec() + 6000
	while (not screen._voice_queue.is_empty() or screen._voice.playing) and Time.get_ticks_msec() < speech_deadline:
		await process_frame
	_expect(screen._voice_queue.is_empty() and not screen._voice.playing, "Queued speech plays to completion")
	_verify_run_flow(screen)
	_check_loadout_feedback(screen)
	await _verify_canvas_borders(screen)
	screen.queue_free()
	await create_timer(1.20).timeout
	await process_frame
	print("Midnight Chalk UI: input, pause, impacts, payout, 11 encounters and six layouts: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)


func _check_foe_visibility(screen, shown: bool) -> void:
	for part in ["BossArt", "BossName", "BossHealth", "FoeCharge", "FoeCooldown", "FoeMark0", "FoeMark1", "FoeMark2"]:
		_expect(screen.get_node(part).is_visible_in_tree() == shown, "%s follows live fight visibility" % part)


func _verify_canvas_borders(screen) -> void:
	var original_size := root.size
	for window_size: Vector2i in [Vector2i(390, 844), Vector2i(1024, 768), Vector2i(1280, 720)]:
		root.size = window_size
		await process_frame
		var scale_factor := root.get_final_transform().get_scale().x
		for target: Button in [screen._slots["top"], screen._item_buttons[0]]:
			for state: StringName in [&"normal", &"disabled", &"focus"]:
				var style := target.get_theme_stylebox(state) as StyleBoxFlat
				_expect(style.border_width_left * scale_factor >= 1.25 and style.border_width_right == style.border_width_top and style.border_width_top == style.border_width_left and style.border_width_bottom == style.border_width_left, "All four target edges survive canvas downsampling")
				if window_size.x >= 1024:
					_expect(style.border_width_left == 2, "Desktop and tablet keep their original button stroke")
	root.size = original_size
	await process_frame


func _check_layout(screen, viewport_size: Vector2) -> void:
	for removed in ["BoardTitle", "LaneTitle", "FoeStat0", "FoeValue0", "Outcome"]:
		_expect(not screen.has_node(removed), "Redundant labels are removed from battle")
	var bounds := Rect2(Vector2.ZERO, viewport_size)
	var left: Rect2 = screen._left
	var lane: Rect2 = screen._lane
	var status: Rect2 = screen._status
	var reject: Button = screen.get_node("Incompatible")
	var note := " at %s" % viewport_size
	_expect(left.encloses(reject.get_rect()) and reject.position.x > left.get_center().x and reject.position.y > left.get_center().y, "Reject stays at board lower right" + note)
	_expect(lane.size.x < left.size.x and lane.size.y == left.size.y and screen._fall_end > lane.end.y - 10.0 * screen._u, "Lane uses full lower height" + note)
	for slot: Button in screen._slots.values():
		_expect(left.encloses(slot.get_rect()) and not slot.get_rect().intersects(reject.get_rect()), "Placement and reject hit areas stay separate" + note)
		_expect(slot.size == reject.size, "The incompatible button has the same square hit area as every placement button" + note)
	for card: Button in screen._cards:
		_expect(lane.encloses(card.get_rect()), "Cards stay inside lane" + note)
	var hp: Rect2 = screen._player_bar.get_rect()
	var energy: Rect2 = screen._energy_bar.get_rect()
	var item1: Rect2 = screen._item_buttons[0].get_rect()
	var item3: Rect2 = screen._item_buttons[2].get_rect()
	_expect(status.encloses(hp) and status.encloses(energy) and status.encloses(item3), "Resources fit in status column" + note)
	_expect(hp.size.y > hp.size.x and energy.size.y > energy.size.x and energy.end.x < hp.position.x and hp.end.x < item1.position.x, "Heavy, health and items are three adjacent vertical tracks" + note)
	_expect(absf(hp.position.y - item1.position.y) <= 1.0 and absf(hp.end.y - item3.end.y) <= 2.0, "Tops and bottoms of all three tracks align" + note)
	var header := [screen._stage_label, screen._wallet_icon, screen._wallet, screen._chest_icon, screen._chest_time]
	_expect(screen._stage_label.get_theme_font("font").variation_embolden > 0.0 and screen._stage_label.position.x < viewport_size.x * 0.12, "Bold level starts the upper-left HUD" + note)
	for i in range(1, header.size()):
		_expect(header[i - 1].get_rect().end.x <= header[i].position.x and absf(header[i - 1].get_rect().get_center().y - header[i].get_rect().get_center().y) <= 1.5, "Level, purse and chest share one row in reading order" + note)
	_expect(screen._chest_time.get_rect().end.x < viewport_size.x * 0.65 and screen._pause_button.position.x > viewport_size.x * 0.83, "HUD stays grouped on left, pause on right" + note)
	_expect(bounds.encloses(screen._boss_art.get_rect()) and screen._boss_art.get_rect().end.x <= screen._boss_name.position.x, "Boss art and readout fit apart" + note)
	_expect(screen._pause_button.size.x >= screen._pause_face.size.x * 1.66, "Pause keeps its generous invisible hit area")
	_expect(screen._wallet.get_rect().end.x <= screen._pause_button.position.x, "Wallet does not overlap pause" + note)
	for mark: Control in [screen._boss_bar, screen._foe_charge, screen._foe_clock]:
		_expect(not mark.tooltip_text.is_empty(), "Unlabelled enemy bars expose accessible descriptions")
		_expect(screen._arena.encloses(mark.get_rect()) and mark.size.x > mark.size.y, "Three distinct horizontal enemy gauges" + note)


func _verify_run_flow(screen) -> void:
	# Play through all stage transitions, shortening each foe's HP after the combat tests.
	var wallet := 0
	var carried_energy := 0
	for encounter in range(11):
		if encounter > 0:
			_expect(screen._countdown == 3.0 and screen.run.phase == "ready", "Next encounter has direct countdown")
			_check_foe_visibility(screen, false)
			_expect(screen.run.hp == screen.run.max_hp and screen.run.energy == carried_energy, "The next foe starts with restored health and the earned special charge")
			_expect(is_equal_approx(screen._player_bar.value, 1.0) and is_equal_approx(screen._energy_bar.value, float(carried_energy) / screen.run.energy_cost), "Both player gauges already agree during countdown")
			screen._process(3.1)
		_expect(screen.run.encounter_index == encounter, "Route advances one foe at a time")
		_check_foe_visibility(screen, true)
		if encounter == 10:
			_expect(screen.run.is_dragon and screen._stage_label.text == "最終戰" and screen._boss_art.family == "dark_dragon", "Final battle uses the dragon artwork and its own level title")
			_check_incineration(screen)
		else:
			_expect(screen._stage_label.visible and screen._stage_label.text == "關卡 %d-%d" % [1 + encounter / 2, 1 + encounter % 2], "HUD shows the level as stage-foe")
			_expect(screen._stage_label.accessibility_name == "第 %d 關，第 %d 位對手" % [1 + encounter / 2, 1 + encounter % 2], "HUD level is labelled for screen readers")
		if encounter == 0:
			_check_reject_transfer(screen)
		if encounter == 1:
			_check_expiry_feedback(screen)
		if encounter == 2:
			_check_lane_weather(screen)
		if encounter == 3:
			_check_signature_feedback(screen)
		# One late win exercises the no-chest path as well as the zero time bonus.
		if encounter == 4:
			screen.run.active_seconds = screen.run.chest_budget + 1
		screen.run.boss_hp = 1
		var landing: Dictionary = {}
		for attempt in range(8):
			for tile: Dictionary in screen.run.active_tiles:
				if not tile.placements.is_empty():
					landing = tile
					break
			if not landing.is_empty():
				break
			screen._commit("reject")
		_expect(not landing.is_empty(), "A matching tile is available")
		if landing.is_empty():
			return
		screen._select_lane(int(landing.lane))
		screen.run.hp = 5
		screen.run.energy = encounter % (screen.run.energy_cost + 1)
		carried_energy = screen.run.energy
		screen._commit(str(landing.placements.keys()[0]))
		screen._process(0.43)
		_expect(screen.run.phase == "won" and not screen._overlay_open and screen._slots.left.disabled, "The finishing hit starts the defeat animation before rewards and locks tile input")
		if encounter == 0:
			screen._toggle_pause()
			var remaining: float = screen._finish_delay
			screen._process(1.0)
			_expect(screen._finish_delay == remaining and not screen._overlay_open, "Pausing freezes the defeat sequence before the reward")
			screen._toggle_pause()
		screen._process(screen.BossArt.DEFEAT_DURATION * 0.5)
		_expect(not screen._overlay_open, "The foe finishes its animation before the chest or continuation appears")
		screen._process(screen._finish_delay + 0.01)
		var award: Dictionary = screen.run.coin_award
		_expect(screen.run.hp == screen.run.max_hp and award.hp_left == 5 and award.vitality == 1, "Vitality uses the five HP at victory before healing")
		wallet += int(award.total)
		if encounter == 10:
			_expect(screen.run.phase == "complete" and screen._celebration.visible and not screen._overlay_open, "Only the dragon opens the completion animation")
			_expect(screen.run.rewards.is_empty() and screen.run.shop_offers.is_empty(), "Final victory ends shopping and reward draws")
			screen._process(screen.FinishCelebration.DURATION / 2.0)
			_expect(screen._celebration.visible and screen._celebration.elapsed > 0.0, "Finish sequence plays before final wallet")
			screen._process(screen.FinishCelebration.DURATION)
			_expect(not screen._celebration.visible and screen._overlay_open, "Finish animation opens the final summary")
		var options: VBoxContainer = screen.get_node("Menu/MenuCard/Options")
		var seconds_left := int(award.seconds_left)
		_expect(screen._chest_time.text == "%02d:%02d" % [seconds_left / 60, seconds_left % 60], "Settled clock reports time in seconds")
		_expect(not screen._result_flash.visible, "Opening rewards clears the board result")
		_expect(options.get_node("Payout/Earned/Value").text == "+%d" % award.total, "Every foe shows its coin reward")
		_expect(options.get_node("Payout/WalletTotal").text == "持有 %d" % wallet and screen._wallet.text == str(wallet), "Payout and HUD agree on wallet")
		_expect(options.get_node("Breakdown/Base/Value").text == "+%d" % award.base and options.get_node("Breakdown/Time/Value").text == "+%d" % award.time and options.get_node("Breakdown/Vitality/Value").text == "+%d" % award.vitality, "Boss/time/health figures agree with awarded coins")
		var stage_bonus = options.get_node_or_null("Breakdown/StageClear/Value")
		if encounter % 2 == 1 and encounter < 9:
			_expect(stage_bonus != null and stage_bonus.text == "+%d" % award.stage_clear, "Stage clearing coins appear separately in the pre-shop payout")
		else:
			_expect(stage_bonus == null, "Non-shop victories do not show a stage clearance award")
		if encounter == 10:
			break
		if encounter == 4:
			_expect(not screen.run.chest_earned and int(award.time) == 0, "Late victory awards coins without chest")
			var next: Button = options.get_node("Continue")
			next.pressed.emit()
			next.pressed.emit()
		else:
			var reward_draw: HBoxContainer = options.get_node("RewardDraw")
			_expect(options.get_node("ChestReward").icon == "chest_open" and not options.has_node("ChestChoice"), "An open chest icon introduces the item draw")
			_expect(reward_draw.get_child_count() == screen.run.rewards.size(), "All chest items share a horizontal card row")
			for item: Dictionary in screen.run.rewards:
				var card: Button = reward_draw.get_node("Reward" + str(item.id).capitalize())
				_expect(card.text.is_empty() and card.find_children("*", "Label", true, false).is_empty(), "Reward card uses only its item symbol")
				_expect(card.find_child("RewardMark", true, false).icon == "item_" + str(item.kind), "Reward symbol matches the item being given")
				_expect(card.accessibility_name.contains(item.name) and card.tooltip_text.contains(item.description), "Each reward describes its item and effect on demand")
			var reward: Button = reward_draw.get_child(0)
			_expect(reward.get_node(reward.focus_neighbor_left) == reward_draw.get_child(-1) and reward.get_node(reward.focus_neighbor_right) == reward_draw.get_child(1), "Arrows traverse the chest row and wrap within it")
			reward.pressed.emit()
			if screen.run.phase == "replace":
				var pending: String = screen.run.pending_item.id
				var full: VBoxContainer = screen.get_node("Menu/MenuCard/Options")
				var draw: HBoxContainer = full.get_node("DiscardDraw")
				_expect(draw.get_child_count() == 4 and full.get_node("DiscardMark").icon == "discard", "Full inventory offers four items under a discard symbol")
				_expect(full.find_children("*", "Label", true, false).is_empty() and screen._overlay.color == screen.NIGHT, "The discard screen shows no text on the panel or around it")
				for i in 4:
					var pick := draw.get_child(i) as Button
					var represented: Dictionary = screen.run.pending_item if i == 3 else screen.run.items[i]
					_expect(pick.find_child("ItemMenuMark", true, false).icon == "item_" + str(represented.kind), "The discard icon matches its actual inventory slot")
					_expect(pick.find_child("OriginMark", true, false).icon == ("chest" if i == 3 else "bag"), "Only the incoming item has the chest mark")
					_expect(pick.text.is_empty() and pick.tooltip_text.is_empty() and pick.accessibility_name.contains("放棄") and pick.accessibility_name.contains(represented.name), "Discard is word-free and names its action to assistive technology")
					_expect(pick.get_node(pick.focus_neighbor_right) == draw.get_child((i + 1) % 4), "Keyboard navigation includes and wraps past the fourth choice")
				var keep_slot := 3 if encounter % 2 == 1 else 1
				var previous: String = screen.run.items[1].id
				var replace: Button = draw.get_node("Replace%d" % (keep_slot + 1))
				replace.pressed.emit()
				replace.pressed.emit()
				_expect(screen.run.items.size() == 3 and screen.run.items[1].id == (previous if keep_slot == 3 else pending), "Incoming item can replace carried gear or be declined")
			reward.pressed.emit()
		_expect(screen.run.coins == wallet, "Stale reward taps cannot grant or advance twice")
		if encounter % 2 == 1 and encounter < 9:
			var shop: VBoxContainer = screen.get_node("Menu/MenuCard/Options")
			var price := 10 + 5 * (encounter / 2)
			_expect(screen.run.phase == "shop" and screen.run.shop_price == price and screen.run.shop_offers.size() == 3, "Four shops each follow the second stage boss")
			var hand: HBoxContainer = shop.get_node("ShopDraw")
			_expect(not shop.has_node("MenuTitle") and not shop.has_node("MenuHelp") and hand.get_child_count() == 3, "Shop presents three pictorial offers in one row")
			for label: Label in shop.find_children("*", "Label", true, false):
				_expect(label.text.is_valid_int(), "Visible shop labels are numbers")
			var leave: Button = shop.get_node("LeaveShop")
			_expect(leave.text.is_empty() and leave.tooltip_text.is_empty() and leave.get_node("ContinueMark").icon == "continue", "The exit uses an accessible arrow")
			if encounter > 1:
				screen._purchase_upgrade(str(screen.run.shop_offers[0].id), screen.run.stage - 1)
				screen._leave_shop(screen.run.stage - 1)
				_expect(screen.run.phase == "shop" and screen.run.coins == wallet and screen.run.shop_purchases.is_empty(), "Callbacks from an earlier store cannot buy or advance the current one")
			screen.run.coins = price - 1
			var choices: Array = screen._update_shop(shop)
			_expect(choices.size() == 1 and choices[0] == leave and hand.get_child(0).disabled and not hand.get_child(0).find_child("Sold", true, false).visible, "An unaffordable card stays on the shelf and exit remains accessible")
			screen.run.coins = wallet
			screen._update_shop(shop)
			for offer: Dictionary in screen.run.shop_offers:
				var buy: Button = hand.get_node("Buy" + str(offer.id).capitalize())
				_expect(buy.text.is_empty() and buy.tooltip_text.is_empty() and buy.accessibility_name.contains(offer.description), "An icon card describes its upgrade to screen readers")
				_expect(not buy.disabled and buy.find_child("Price", true, false).get_node("Value").text == str(price), "Earned funds cover all three available cards at these speeds")
				_expect(buy.get_node(buy.focus_neighbor_bottom) == leave, "Down arrow reaches shop exit")
				buy.pressed.emit()
				wallet -= price
				_expect(buy.disabled and buy.find_child("Sold", true, false).visible and not buy.find_child("Price", true, false).visible, "Each purchase replaces the coin price with a check")
				_expect(screen.run.coins == wallet and shop.get_node("ShopHeader/RunWallet/Value").text == str(wallet), "The purse and model agree after spending coins")
				buy.pressed.emit()
				_expect(screen.run.coins == wallet, "Repeated activation of the sold offer cannot buy twice")
			carried_energy = screen.run.energy
			_expect(leave.has_focus(), "Buying all three cards leaves the exit focused")
			leave.pressed.emit()
	var end: VBoxContainer = screen.get_node("Menu/MenuCard/Options")
	_expect(screen.run.phase == "complete" and end.get_node("Payout/WalletTotal").text == "持有 %d" % wallet, "Final victory shows run earnings")
	_expect(end.get_node("MenuHelp").text.contains("11"), "The finale records all 11 fights")
	var restart: Button = end.get_node("Restart")
	restart.pressed.emit()
	_expect(screen.run.phase == "power" and screen.run.coins == 0 and screen.run.encounter_index == 0, "A new run clears run currency and route progress")
	_check_foe_visibility(screen, false)
	_expect(not screen._stage_label.visible and screen._wallet.text == "0", "Restart hides last level and resets the displayed purse")
	_check_pause_restart(screen)
	screen._reset_speech()


func _check_pause_restart(screen) -> void:
	for during_countdown in [true, false]:
		var hand: HBoxContainer = screen.get_node("Menu/MenuCard/Options/PowerDraw")
		hand.get_child(0).pressed.emit()
		if not during_countdown:
			screen._process(3.05)
			screen.run.coins = 48
			screen.run.energy = 2
			screen.run.items.append(screen.run.ITEM_CATALOGUE[0])
			var answer: Dictionary = screen.run.deck.tiles.filter(func(tile: Dictionary) -> bool: return not tile.placements.is_empty())[0].placements.values()[0]
			screen._play_answer(answer.audio)
			screen._play_answer(answer.audio)
		screen._pause_button.pressed.emit()
		_expect(screen._pause_restart.is_visible_in_tree() and screen._music_toggle.get_node(screen._music_toggle.focus_neighbor_bottom) == screen._pause_restart, "Restart is reachable in the pause menu")
		screen._pause_restart.pressed.emit()
		_expect(not screen._pause_shade.visible and not screen._user_paused and screen._countdown < 0 and screen.run.phase == "power", "One tap restarts a paused countdown or battle at the special draw")
		_expect(screen.run.energy == 0 and screen.run.coins == 0 and screen.run.items.is_empty() and screen.run.active_tiles.is_empty() and screen.run.projectiles.is_empty(), "Pause restart clears the previous run")
		_expect(not screen._voice.playing and screen._voice_queue.is_empty() and not screen._sounds._music_started and not screen._sounds._frozen, "Restart clears pending speech and score, and releases audio pause")
	_expect(screen.get_node("Menu/MenuCard/Options/PowerDraw").get_child_count() == 3, "Restart provides three selectable cards")


func _check_loadout_feedback(screen) -> void:
	screen._start_run()
	screen._choose_power(str(screen.run.offers[0].id))
	screen._process(3.01)
	var lit: Dictionary = screen.run.active_tiles.filter(func(card): return not card.placements.is_empty()).front()
	screen._select_lane(lit.lane)
	screen.run.items.assign([screen.run.ITEM_CATALOGUE[6], screen.run.ITEM_CATALOGUE[7], screen.run.ITEM_CATALOGUE[9]])
	screen._sync_hud(false)
	screen._item_buttons[0].pressed.emit()
	screen._item_buttons[0].pressed.emit()
	var card: Button = screen._cards[lit.lane]
	_expect(card.get_node("item_lantern").visible and card.get_node("item_clip").visible, "Lantern and clip can both mark one tile")
	_expect(card.accessibility_name.contains("可組字") and card.accessibility_name.contains("已夾住"), "The hint and pin are also announced")
	_expect(not card.get_node("item_lantern").get_rect().intersects(card.get_node("item_clip").get_rect()), "Pin and lantern have separate corners")
	var p := card.position
	screen._process(0.2)
	_expect(card.position == p, "A visibly pinned tile holds position")
	screen._item_buttons[0].pressed.emit()
	_expect(screen._loadout_status.get_node("item_umbrella").visible, "An armed umbrella remains visible after leaving inventory")
	screen.run._launch("foe", 1, true, {"kind": "mask", "duration": 3, "value": 1})
	screen._process(screen.run.PROJECTILE_DURATION + 0.01)
	_expect(not screen._loadout_status.get_node("item_umbrella").visible and not screen._anchor_masked, "The umbrella indicator is consumed with the blocked disruption")
	_expect(screen._loadout_status._spent.visible and screen._loadout_status._spent.icon == "item_umbrella", "A spent umbrella briefly flashes when it blocks a disruption")
	screen._select_lane(lit.lane)
	screen._commit(str(lit.placements.keys()[0]))
	_expect(screen.run.hinted_tile_id == -1 and screen.run.pinned_tile_id == -1 and not screen._loadout_status.get_node("item_lantern").visible, "Resolved tiles clear both protections and the lamp indicator")
	screen.run.marked_hits = 3
	screen.run.calm_charges = 2
	screen.run._effect_clocks["slow"] = 4.0
	screen._update_cards()
	_expect(screen._loadout_status.get_node("power_mark").visible and screen._loadout_status.get_node("item_calm").visible and screen._loadout_status.get_node("power_slow").visible, "Seal, calm and slow are distinguishable active effects")
	screen._process(0.4)
	_expect(screen._loadout_status._meters["power_slow"] < 1.0, "The slow icon counts down with simulation time")
	screen._start_run()
	_expect(not screen._loadout_status.visible, "Opening a fresh run clears old status marks")


func _check_lane_weather(screen) -> void:
	var initial_hp: int = screen.run.hp
	screen.run._launch("foe", 3, true, {"kind": "ink", "value": 0.70, "duration": 3.0})
	screen._process(screen.run.PROJECTILE_DURATION + 0.01)
	_expect(screen._weather.visible and is_equal_approx(screen._weather.ink_height, 0.70) and screen.run.hp == initial_hp - maxi(0, 3 - screen.run.player_defense), "Fox heavy damages HP and obscures the upper seventy percent on landing")
	_expect(screen._weather.get_index() > screen._cards[0].get_index() and screen._weather.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Ink covers the tiles while allowing touch selection")
	screen._toggle_pause()
	var clock: float = screen._weather.clock
	screen._process(5.0)
	_expect(screen._weather.clock == clock and screen._weather.visible, "Pause freezes the ink timer")
	screen._toggle_pause()
	screen._process(3.01)
	_expect(not screen._weather.visible, "The three-second ink clears completely")
	screen.run._launch("foe", 3, true, {"kind": "haste", "value": 0.80, "duration": 3.0})
	screen._process(screen.run.PROJECTILE_DURATION + 0.01)
	_expect(screen._weather.wind and is_equal_approx(screen.run.haste_bonus, 0.8) and screen.run.hp < initial_hp, "The swallow lands both a damaging hit and visible wind")
	screen._process(3.01)
	_expect(not screen._weather.visible, "Wind clears when its effect expires")


func _check_signature_feedback(screen) -> void:
	# Keep timed casts isolated from the randomly chosen opponent's cooldown.
	screen.run.boss_cooldown_left = 100.0
	for effect in [{"kind": "rocks", "value": 0.30, "duration": 3.0},
			{"kind": "freeze", "value": 1, "duration": 2.0},
			{"kind": "mask", "value": 1, "duration": 3.0},
			{"kind": "rotate", "value": 1, "duration": 2.0},
			{"kind": "enrage", "value": 2}, {"kind": "shuffle", "value": 0.5, "duration": 3.0}]:
		screen.run._launch("foe", 0, true, effect)
	screen._process(screen.run.PROJECTILE_DURATION + 0.01)
	_expect(screen._weather.frozen and is_equal_approx(screen._weather.rock_height, 0.30), "Frost and a bottom rock wall are rendered")
	_expect(screen._anchor.text.is_empty() and screen._anchor_masked and screen._anchor.tooltip_text == "部件被遮蓋", "The masked anchor is concealed in the artwork, tooltip and text")
	_expect(screen._boss_status.empowered == 2, "The foe displays both charged normal hits")
	var tile: Dictionary = screen.run.active_tiles.front()
	var face: Label = screen._glyph_faces[tile.lane]
	var button: Button = screen._cards[tile.lane]
	_expect(face.visible and face.text == tile.glyph and absf(face.rotation_degrees) >= 89.0 and is_zero_approx(button.rotation), "Only the glyph rotates while the touch square stays aligned")
	var held: Vector2 = button.position
	var selected: int = screen.run.tile_id
	screen._process(0.53)
	_expect(button.position == held and screen.run.tile_id != selected, "Frozen tile stays still while the shuffle visibly reselects another tile")
	screen._process(2.5)
	_expect(not screen._weather.visible and not screen._anchor_masked and screen._anchor.text == screen.run.deck.anchor and not face.visible, "Transient effects clear and upright ink and anchor return")
	screen.run._launch("foe", 0, true, {"kind": "dim", "value": 1, "duration": 2.0})
	screen.run._launch("foe", 0, true, {"kind": "current", "value": 1})
	screen._process(screen.run.PROJECTILE_DURATION + 0.01)
	var selected_lane := int(screen.run.tile.lane)
	_expect(screen._weather.current_age < 0.38 and screen._cards[selected_lane].get_meta("selected", false), "The river effect paints its current and moves selection with its tile")
	var shaded: Label = screen._glyph_faces[selected_lane]
	_expect(shaded.visible and shaded.self_modulate.a >= 0.46 and shaded.text == screen.run.tile.glyph, "Moth shadow preserves readable glyphs")
	var kept: Array = screen.run.items.duplicate()
	screen.run.items.clear()
	screen.run.items.append(screen.run.ITEM_CATALOGUE[0])
	screen.run._launch("foe", 0, true, {"kind": "steal", "value": 1})
	screen._process(screen.run.PROJECTILE_DURATION + 0.01)
	_expect(screen._boss_status._stolen.visible and screen._boss_status._stolen.icon.begins_with("item_"), "The stolen item animates out of its slot")
	screen.run.items.assign(kept)
	screen._process(2.01)
	_expect(not shaded.visible and not screen._boss_status._stolen.visible, "Temporary glyph and theft visuals clear")


func _check_incineration(screen) -> void:
	var count: int = screen.run.active_tiles.size()
	var hp: int = screen.run.hp
	screen.run._launch("foe", 5, true, {"kind": "incinerate", "value": 1})
	screen._process(screen.run.PROJECTILE_DURATION + 0.001)
	_expect(screen.run.hp < hp and screen.run.active_tiles.is_empty() and screen._weather.scorched.size() == count and not screen._miss_flash.visible, "Dragon fire burns every live tile on impact without a wrong-answer flash")
	var frozen_age: float = screen._weather.scorch_age
	screen._toggle_pause()
	screen._process(1.0)
	_expect(screen._weather.scorch_age == frozen_age, "Pause freezes the dragon fire burst")
	screen._toggle_pause()
	screen._process(0.50)
	_expect(screen._weather.scorched.is_empty() and not screen.run.active_tiles.is_empty(), "Fresh tiles appear after the flame clears")


func _check_reject_transfer(screen) -> void:
	# Use the last point needed to verify both the incoming charge and the ready state.
	screen.run.energy = 0
	screen.run._charged_decoys.clear()
	for attempt in range(12):
		for tile: Dictionary in screen.run.active_tiles:
			if tile.placements.is_empty():
				screen._select_lane(int(tile.lane))
				var before: int = screen._effects._transfers.size()
				screen.run.energy = screen.run.energy_cost - 1
				screen._sync_hud(false)
				_expect(not screen._effects._heavy_ready, "The flame waits for a full meter")
				screen._commit("reject")
				_expect(screen.run.energy == screen.run.energy_cost and screen._effects._transfers.size() == before + 1, "Genuine incompatibility sends energy to the meter")
				_expect(screen._feedback == 0.0 and not screen.has_node("Outcome"), "Marking a tile incompatible leaves the header empty")
				_expect(screen._effects._heavy_ready and screen._effects._special_button == screen._special.get_rect(), "Reaching full charge lights the special button")
				screen._process(0.14)
				var flame_age: float = screen._effects._flame_time
				_expect(flame_age > 0.0, "The ready flame flickers on battle time")
				screen._toggle_pause()
				screen._process(0.5)
				_expect(is_equal_approx(flame_age, screen._effects._flame_time), "Pause freezes the ready flame")
				screen._toggle_pause()
				screen._use_special()
				_expect(not screen._effects._heavy_ready, "Spending the charge extinguishes the flame")
				screen._process(0.51)
				var anchor = screen._effects._reject_centre
				_expect(anchor.distance_to(screen._reject.get_rect().get_center()) < 1, "Transfer originates at reject control")
				return
		# Recycle a card without launching damage or switching encounters.
		screen._commit("reject")
	_expect(false, "Expected a decoy for energy transfer")



func _check_expiry_feedback(screen) -> void:
	var legal: Dictionary = {}
	for card: Dictionary in screen.run.active_tiles:
		if not card.placements.is_empty():
			legal = card
			break
	_expect(not legal.is_empty(), "Each fresh pair includes at least one playable tile")
	if legal.is_empty():
		return
	var charge: int = screen.run.boss_charge
	var energy: int = screen.run.energy
	screen._result_flash.play("清")
	legal.age = screen.run.fall_duration - 0.01
	screen._process(0.02)
	var reveal = screen._miss_flash
	var result: String = reveal.glyph
	_expect(screen.run.boss_charge == charge and screen.run.energy == energy, "Missing a valid tile costs no charge or energy")
	_expect(legal.placements.values().any(func(entry: Dictionary) -> bool: return entry.result == result), "Expiry reveals a valid completed character")
	_expect(reveal.visible and reveal.ink.r > reveal.ink.g and reveal.get_rect() == screen._lane, "The missed character is red and centred on the falling lane")
	_expect(screen._result_flash.glyph == "清" and screen._feedback == 0.0 and screen._slots.values().all(func(slot: Button) -> bool: return slot.text.is_empty()), "A missed tile leaves the left panel's feedback alone")
	_expect(reveal.mouse_filter == Control.MOUSE_FILTER_IGNORE, "The missed character allows selection through the effect")
	var initial: Vector2 = reveal.ink_rect().size
	var alpha: float = reveal.opacity()
	screen._process(0.16)
	_expect(reveal.ink_rect().size.x > initial.x and reveal.opacity() < alpha, "Red Kai expands and thins like green Kai")
	screen._toggle_pause()
	var elapsed: float = reveal.elapsed
	screen._process(1.0)
	_expect(not reveal.visible and reveal.elapsed == elapsed, "Pausing freezes and conceals the missed character")
	screen._toggle_pause()
	_expect(reveal.visible and reveal.glyph == result, "The same red character resumes")
	screen._show_tile_outcome({"kind": "expiry", "valid_tile": false})
	_expect(reveal.glyph == result and reveal.elapsed == elapsed, "An expired decoy leaves no new result")
	screen._process(reveal.DURATION - elapsed + 0.01)
	_expect(not reveal.visible and screen._cards.all(func(card: Button) -> bool: return is_equal_approx(card.self_modulate.a, 1.0)), "The lane restores at the end of its red flash")
	var cue_index: int = screen._sounds._next
	screen._show_tile_outcome({"kind": "unscored", "answer_slot": "right", "glyph": "火", "result": "秋"})
	_expect(reveal.visible and reveal.glyph == "秋" and reveal.ink == screen.PAPER
		and screen._feedback_colour == screen.PAPER and screen._slots.right.text == "火"
		and screen._sounds._next == cue_index, "An alternate outside the lesson shows only the familiar answer in neutral ink")
	screen._show_tile_outcome({"kind": "wrong", "answer_slot": "left", "glyph": "氵", "result": "清"})
	_expect(reveal.ink == screen.MISS_INK and screen._feedback_colour == screen.ROSE, "An ordinary mistake after neutral feedback uses its usual colours")
	_expect(reveal.visible and reveal.glyph == "清" and not screen._result_flash.visible and screen._slots.left.text == "氵", "Misplacing a valid tile reveals the completed character only in the falling lane")
	screen._process(1.0)
	screen._show_tile_outcome({"kind": "wrong", "result": ""})
	_expect(not reveal.visible and not screen._result_flash.visible, "A genuinely incompatible pair has no character to reveal")

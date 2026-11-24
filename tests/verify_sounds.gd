extends SceneTree

const GAME = preload("res://main.tscn")
const TONES = preload("res://ui/combat_sounds.gd")
const RUN = preload("res://game/run_state.gd")

var failed := false


func _initialize() -> void:
	_check.call_deferred()


func _expect(ok: bool, explanation: String) -> void:
	if not ok:
		failed = true
		push_error(explanation)


func _last(sounds: Node) -> String:
	var latest: AudioStreamPlayer = sounds._channels[(sounds._next + TONES.VOICES - 1) % TONES.VOICES]
	return str(TONES.STREAMS.find_key(latest.stream))


func _check() -> void:
	var game := GAME.instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var tones: Node = game._sounds
	_expect(not tones._music.playing and not tones._click.playing, "The opening draw waits for an activation")
	var power: Button = game._modal.find_child("PowerDraw", true, false).get_child(0)
	_expect(power.pressed.is_connected(game._button_click), "The power draw has the same click as the board")
	power.pressed.emit()
	_expect(tones._music.playing, "Activating a power card starts the score")
	var written_duration: float = TONES.SCORE.beat_count * 60.0 / TONES.SCORE.bpm
	_expect(TONES.SCORE.loop and TONES.SCORE.beat_count == 128 and is_equal_approx(TONES.SCORE.bpm, 164.0) and absf(TONES.SCORE.get_length() - written_duration) < 0.02, "The 164 BPM theme loops after 32 bars")
	game._process(3.05)
	game._cards[0].pressed.emit()
	_expect(tones._click.playing, "Selecting a falling component clicks immediately")
	_expect(game._voice.bus == &"Speech" and tones._channels[0].bus == &"Effects" and tones._music.bus == &"Music", "Voice, effects and music resolve to their own buses")

	var cues: Dictionary = {}
	for cue: String in TONES.STREAMS:
		var sample: AudioStreamWAV = TONES.STREAMS[cue]
		_expect(sample.get_length() > 0.07 and sample.get_length() < 0.65 and not sample.stereo, "Short mono cue: " + cue)
		var content := hash(sample.data)
		_expect(not cues.has(content), "Each event has a distinct waveform: " + cue)
		cues[content] = true
	_expect(cues.size() == 25, "Complete original cue bank")

	for tile: Dictionary in game.run.active_tiles:
		if not tile.placements.is_empty():
			game._select_lane(int(tile.lane))
			game._commit(str(tile.placements.keys()[0]))
			break
	_expect(_last(tones) == "player_shot" and game._voice.playing, "Correct placement begins speech and fires a shot")
	_expect(tones._channels[0].volume_db == TONES.UNDER_SPEECH_DB, "Effects are quieter while the reading plays")
	await tones._duck.finished
	_expect(is_equal_approx(tones._music.volume_db, TONES.MUSIC_UNDER_SPEECH_DB), "The music ducks before the first syllable finishes")
	game._process(RUN.PROJECTILE_DURATION + 0.01)
	_expect(_last(tones) == "foe_hit", "Foe hit plays on actual normal impact")
	game._reset_speech()
	_expect(tones._channels[0].volume_db == TONES.LEVEL_DB, "Mix returns to its ordinary volume after speech")
	await tones._duck.finished
	_expect(is_equal_approx(tones._music.volume_db, TONES.MUSIC_DB), "The score recovers between readings")

	game.run.energy = game.run.energy_cost
	game._use_special()
	_expect(_last(tones) == "player_heavy", "Special shot has its own sound")
	game._process(RUN.PROJECTILE_DURATION + 0.01)
	_expect(_last(tones) == "foe_hit_heavy", "Heavy shot lands on foe")
	game.run._shield_ready = false
	game.run._effect_clocks.erase("mirror")
	# Bell emits damage on both attack types, so both impact cues are exercised.
	game.run.boss.heavy_damage = 4
	game.run.boss.heavy_effect = {}
	for heavy: bool in [false, true]:
		game.run.boss_charge = game.run.boss_charge_max if heavy else 0
		game.run.boss_cooldown_left = 0.01
		game._process(0.02)
		_expect(_last(tones) == ("foe_heavy" if heavy else "foe_shot"), "Foe launches a distinct charged or regular shot")
		game._process(RUN.PROJECTILE_DURATION + 0.01)
		_expect(_last(tones) == ("player_hit_heavy" if heavy else "player_hit"), "Pupil receives the corresponding impact")

	# Inject only the tile contents; selection, resolution, gauge caps and cues
	# all go through the same entry point as keyboard and touch placement.
	game.run.energy = 0
	game.run.boss_charge = 0
	for count in game.run.energy_cost:
		var decoy: Dictionary = game.run._decoy_tiles[count]
		game.run.tile.glyph = decoy.glyph
		game.run.tile.placements = {}
		game._commit("reject")
		var ready: bool = count + 1 == game.run.energy_cost
		_expect(_last(tones) == ("player_ready" if ready else "player_charge"), "Player charge and readiness sound on different steps")
	for count in game.run.boss_charge_max:
		game.run.tile.placements = game.run._playable_tiles[0].placements
		game._commit("reject")
		var ready: bool = count + 1 == game.run.boss_charge_max
		_expect(_last(tones) == ("foe_ready" if ready else "foe_charge"), "Opponent charge and readiness sound on different steps")
	var before_cap: int = tones._next
	game.run.tile.placements = game.run._playable_tiles[0].placements
	game._commit("reject")
	_expect(tones._next == before_cap, "Extra mistakes at full enemy charge do not repeat the ready motif")
	game.run._shield_ready = true
	game.run.boss_cooldown_left = 0.02
	game._process(0.03)
	game._process(RUN.PROJECTILE_DURATION + 0.01)
	_expect(_last(tones) == "shield_block", "Absorbed damage sounds different from losing HP")

	for item: Dictionary in RUN.ITEM_CATALOGUE:
		game.run.items.assign([item.duplicate()])
		game.run.energy = 0
		game.run.hp = 4
		game.run._shield_ready = false
		game.run._boost_ready = false
		game._use_item(0)
		_expect(_last(tones) == "item_" + str(item.kind), "Successful item use plays " + str(item.kind))
		var next: int = tones._next
		game._use_item(0)
		_expect(tones._next == next, "Empty slot stays silent")
	game.run.items.assign([{"kind": "energy"}])
	game.run.energy = game.run.energy_cost - 1
	game._use_item(0)
	_expect(_last(tones) == "player_ready", "Crystal reaching capacity signals heavy ready")

	game._toggle_pause()
	var paused: int = tones._next
	tones.play_cue("foe_shot")
	_expect(paused == tones._next and tones._channels.any(func(channel): return channel.stream_paused), "Pause freezes existing tones and blocks retriggers")
	_expect(tones._music.stream_paused, "The score pauses in place")
	game._music_toggle.pressed.emit()
	_expect(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music")) and not AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Speech")), "Pupil can silence the score independently of speech")
	game._music_toggle.pressed.emit()
	game._toggle_pause()
	_expect(tones._music.playing and not tones._music.stream_paused, "Resume continues the score")
	_expect(not tones._channels.any(func(channel): return channel.stream_paused), "Resume unfreezes tone players")
	var previous_position: float = tones._music.get_playback_position()
	game._start_run()
	_expect(tones._channels.all(func(channel): return channel.stream == null), "Restart clears old tones")
	_expect(previous_position > 0.0 and tones._music.get_playback_position() >= previous_position - 0.02, "The score keeps its playhead across runs")
	game.queue_free()
	# Allow the Dummy audio driver to dispose of its queued playbacks.
	await create_timer(1.20).timeout
	await process_frame
	if not failed:
		print("PASS — 164 BPM Inkbolt Rush theme, click, 25 distinct combat and item tones, speech ducking, mute and pause")
	quit(1 if failed else 0)

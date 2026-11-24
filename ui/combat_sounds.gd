extends Node

# The short samples have their own envelopes so Web Sample playback and native
# playback use the same timbre. Keep a pooled set of independent voices: a new
# launch can coincide with a previous projectile's impact or a gauge chime.
const STREAMS := {
	"player_shot": preload("res://assets/sfx/player_shot.wav"),
	"player_heavy": preload("res://assets/sfx/player_heavy.wav"),
	"foe_shot": preload("res://assets/sfx/foe_shot.wav"),
	"foe_heavy": preload("res://assets/sfx/foe_heavy.wav"),
	"foe_hit": preload("res://assets/sfx/foe_hit.wav"),
	"foe_hit_heavy": preload("res://assets/sfx/foe_hit_heavy.wav"),
	"player_hit": preload("res://assets/sfx/player_hit.wav"),
	"player_hit_heavy": preload("res://assets/sfx/player_hit_heavy.wav"),
	"shield_block": preload("res://assets/sfx/shield_block.wav"),
	"player_charge": preload("res://assets/sfx/player_charge.wav"),
	"foe_charge": preload("res://assets/sfx/foe_charge.wav"),
	"player_ready": preload("res://assets/sfx/player_ready.wav"),
	"foe_ready": preload("res://assets/sfx/foe_ready.wav"),
	"item_heal": preload("res://assets/sfx/item_heal.wav"),
	"item_shield": preload("res://assets/sfx/item_shield.wav"),
	"item_attack": preload("res://assets/sfx/item_attack.wav"),
	"item_energy": preload("res://assets/sfx/item_energy.wav"),
	"item_hourglass": preload("res://assets/sfx/item_hourglass.wav"),
	"item_fan": preload("res://assets/sfx/item_fan.wav"),
	"item_lantern": preload("res://assets/sfx/item_lantern.wav"),
	"item_clip": preload("res://assets/sfx/item_clip.wav"),
	"item_calm": preload("res://assets/sfx/item_calm.wav"),
	"item_umbrella": preload("res://assets/sfx/item_umbrella.wav"),
	"item_bell": preload("res://assets/sfx/item_bell.wav"),
	"item_bounty": preload("res://assets/sfx/item_bounty.wav"),
}
const LEVEL_DB := -5.0
const UNDER_SPEECH_DB := -16.0
const VOICES := 6
const SCORE := preload("res://assets/music/chalkstep.ogg")
const CLICK := preload("res://assets/sfx/ui_click.wav")
const MUSIC_DB := -10.5
const MUSIC_UNDER_SPEECH_DB := -24.5
const CLICK_DB := -11.0

var _channels: Array[AudioStreamPlayer] = []
var _next := 0
var _frozen := false
var _music := AudioStreamPlayer.new()
var _click := AudioStreamPlayer.new()
var _duck: Tween
var _speech_active := false
var _music_started := false
var _web_tail: AudioStreamOggVorbis
var _music_offset := 0.0
var _music_started_at := 0


func _ready() -> void:
	_music.name = "InkboltRush"
	_music.stream = SCORE
	_music.bus = &"Music"
	_music.volume_db = MUSIC_DB
	add_child(_music)
	if OS.has_feature("web"):
		# The browser sample backend repeats a seek offset on every loop. After
		# resuming, finish that phrase once, then rejoin the full loop at beat one.
		_web_tail = SCORE.duplicate() as AudioStreamOggVorbis
		_web_tail.loop = false
		_music.finished.connect(_play_music_from.bind(0.0))
	_click.name = "ButtonClick"
	_click.stream = CLICK
	_click.bus = &"Effects"
	_click.volume_db = CLICK_DB
	add_child(_click)
	for i in VOICES:
		var channel := AudioStreamPlayer.new()
		channel.name = "Tone%d" % (i + 1)
		channel.bus = &"Effects"
		channel.volume_db = LEVEL_DB
		add_child(channel)
		_channels.append(channel)


func start_music() -> void:
	if not _music_started:
		_music_started = true
		_play_music_from(0.0)


func stop_music() -> void:
	_music_started = false
	_music_offset = 0.0
	_music.stop()
	_music.stream_paused = false


func _play_music_from(offset: float) -> void:
	if _frozen or not _music_started:
		return
	_music.stream = _web_tail if _web_tail and offset > 0.0 else SCORE
	_music.play(offset)
	_music_offset = offset
	_music_started_at = Time.get_ticks_usec()


func play_click() -> void:
	_click.play()


func set_music_enabled(enabled: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), not enabled)


func play_cue(cue: String) -> void:
	if _frozen:
		return
	# Rotate through idle voices; when saturated, replace the oldest.
	for offset in _channels.size():
		var index := (_next + offset) % _channels.size()
		if not _channels[index].playing:
			_next = index
			break
	var channel := _channels[_next]
	_next = (_next + 1) % _channels.size()
	channel.stream = STREAMS[cue]
	channel.play()


func charge(side: String, ready: bool) -> void:
	play_cue(side + ("_ready" if ready else "_charge"))


func impact(event: Dictionary) -> void:
	if bool(event.shielded):
		play_cue("shield_block")
	elif int(event.damage) > 0:
		var target := "player" if str(event.source) == "foe" else "foe"
		play_cue(target + ("_hit_heavy" if bool(event.heavy) else "_hit"))


func set_speech_active(active: bool) -> void:
	if _speech_active == active:
		return
	_speech_active = active
	var level := UNDER_SPEECH_DB if active else LEVEL_DB
	for channel: AudioStreamPlayer in _channels:
		channel.volume_db = level
	_click.volume_db = CLICK_DB - 6.0 if active else CLICK_DB
	if _duck:
		_duck.kill()
	_duck = create_tween()
	_duck.tween_property(_music, "volume_db", MUSIC_UNDER_SPEECH_DB if active else MUSIC_DB, 0.022 if active else 0.32)


func set_frozen(frozen: bool) -> void:
	if _frozen == frozen:
		return
	_frozen = frozen
	if _music_started and _web_tail:
		if frozen:
			# Repeated native Web Sample unpauses count earlier paused time.
			var played := (Time.get_ticks_usec() - _music_started_at) / 1000000.0
			_music_offset = fposmod(_music_offset + played, SCORE.get_length())
			_music.stop()
		else:
			_play_music_from(_music_offset)
	elif _music_started:
		_music.stream_paused = frozen
	for channel: AudioStreamPlayer in _channels:
		if channel.playing or channel.stream_paused:
			channel.stream_paused = frozen


func stop_all() -> void:
	for channel: AudioStreamPlayer in _channels:
		channel.stop()
		channel.stream = null
	_next = 0

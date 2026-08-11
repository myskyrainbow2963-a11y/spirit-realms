extends Node

# Global music and SFX routing. Kept independent from individual scenes so a
# scene transition never leaves several tracks playing at once.
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var current_music := ""
var current_ambience := ""
var next_sfx := 0

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Master"
	add_child(music_player)
	music_player.finished.connect(_loop_music)
	ambience_player = AudioStreamPlayer.new()
	ambience_player.bus = &"Master"
	add_child(ambience_player)
	ambience_player.finished.connect(_loop_ambience)
	# Combo attacks, impact debris and ambience can overlap; keep enough channels so one cue never cuts another off.
	for i in 8:
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		sfx_players.append(player)

func play_music(path: String, volume_db: float = -17.0) -> void:
	if path == current_music and music_player.playing: return
	current_music = path
	music_player.stop()
	music_player.stream = load(path)
	music_player.volume_db = volume_db
	if music_player.stream: music_player.play()

func play_ambience(path: String, volume_db: float = -30.0) -> void:
	if path == current_ambience and ambience_player.playing: return
	current_ambience = path
	ambience_player.stop()
	ambience_player.stream = load(path)
	ambience_player.volume_db = volume_db
	if ambience_player.stream: ambience_player.play()

func stop_ambience() -> void:
	current_ambience = ""
	ambience_player.stop()

func play_sfx(path: String, volume_db: float = -10.0, pitch: float = 1.0) -> void:
	if sfx_players.is_empty(): return
	var player := sfx_players[next_sfx]
	next_sfx = (next_sfx + 1) % sfx_players.size()
	player.stop()
	player.stream = load(path)
	player.volume_db = volume_db
	player.pitch_scale = pitch
	if player.stream: player.play()

func _loop_music() -> void:
	if current_music != "" and music_player.stream: music_player.play()

func _loop_ambience() -> void:
	if current_ambience != "" and ambience_player.stream: ambience_player.play()

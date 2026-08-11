extends Node2D

const GameState = preload("res://game_state.gd")
const UISkin = preload("res://ui_skin.gd")

# Native Godot battle screen inspired by the reference flow:
# curved hand -> target selection -> enemy by enemy intent -> player's next turn.

const VIEW := Vector2(1920, 1080)
const CARD_SIZE := Vector2(212, 294)
const SURRENDER_BUTTON := Rect2(40, 170, 170, 54)
const ENEMY_POSITIONS := [Vector2(1050, 425), Vector2(1350, 430), Vector2(1645, 415)]
const PLAYER_STRIKE_DURATION := 1.08
const ART := {
	"player_idle": "res://picture/arena-player-idle.png",
	"player_strike": "res://picture/arena-player-strike.png",
	"ice_lion": "res://picture/card20.png",
	"bone_drake": "res://picture/card30.png",
	"moon_fox": "res://picture/card40.png",
	"void_spider": "res://picture/card50.png",
	"storm_panther": "res://picture/card59.png",
	"little_1": "res://picture/LittleMonster1-solid.png",
	"little_2": "res://picture/LittleMonster2-solid.png",
	"little_3": "res://picture/LittleMonster3-solid.png",
	"little_4": "res://picture/LittleMonster4-solid.png",
	"little_5": "res://picture/LittleMonster5-solid.png",
	"little_6": "res://picture/LittleMonster6-solid.png",
	"little_7": "res://picture/LittleMonster7-solid.png",
	"little_8": "res://picture/LittleMonster8-solid.png",
	"boss_ember": "res://picture/boss2-solid.png",
	"boss_tentacle": "res://picture/boss3-solid.png",
	"boss_4": "res://picture/boss4-solid.png"
}
const LITTLE_MONSTER_POOL := ["little_1", "little_2", "little_3", "little_4", "little_5", "little_6", "little_7", "little_8"]
const BOSS_POOL := ["boss_ember", "boss_tentacle", "boss_4"]

var world: Texture2D
var art: Dictionary = {}
var player_frames: Array[Texture2D] = []
var font: Font
var time := 0.0
var hover_card := -1
var chosen_card := -1
var hovered_enemy := -1
var player_hp := 100
var energy := 3
var block := 0
var turn := 1
var phase := "player"
var banner := "玩家回合"
var banner_until := 1.2
var damage_text := ""
var damage_pos := Vector2.ZERO
var damage_until := 0.0
var shake_until := 0.0
var shake_strength := 0.0
var master_deck: Array[Dictionary] = []
var draw_pile: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var cards: Array[Dictionary] = []
var player_reflect_percent := 0
var enemies := [
	{"name":"雷骨猎犬", "hp":48, "max_hp":48, "intent":"attack", "value":7, "art":"little_1", "block":0, "curse":0, "boss":false, "motion":"idle", "motion_until":0.0},
	{"name":"幽渊游魂", "hp":62, "max_hp":62, "intent":"debuff", "value":0, "art":"little_5", "block":0, "curse":0, "boss":false, "motion":"idle", "motion_until":0.0},
	{"name":"焚天炎角王", "hp":180, "max_hp":180, "intent":"defend", "value":12, "art":"boss_ember", "block":0, "curse":0, "boss":true, "motion":"idle", "motion_until":0.0}
]
var enemy_queue := []
var enemy_step := 0
var next_action_at := 0.0
var player_motion := "idle"
var player_motion_until := 0.0
var player_motion_started := 0.0
var player_attack_target := Vector2.ZERO
var pending_player_attack: Dictionary = {}
var impact_flash_until := 0.0
var impact_flash_position := Vector2.ZERO
var combo_sound_stage := 0
var interaction_notice := "点击攻击牌，再点击敌人。"
var interaction_notice_until := 0.0

func _ready() -> void:
	AudioDirector.play_music("res://music/Crimson Sky Duel.mp3", -16.0)
	AudioDirector.stop_ambience()
	set_process_input(true)
	set_process_unhandled_input(true)
	font = GameState.font_for(load("res://fonts/NotoSansSC-VF.ttf"))
	world = load("res://picture/four-realms-map.png")
	for key in ART:
		art[key] = load(ART[key])
	_load_player_sprite_sheet()
	_setup_player_deck()
	var mini_a := randi_range(0, LITTLE_MONSTER_POOL.size() - 1)
	var mini_b := (mini_a + randi_range(1, LITTLE_MONSTER_POOL.size() - 1)) % LITTLE_MONSTER_POOL.size()
	enemies[0].art = LITTLE_MONSTER_POOL[mini_a]
	enemies[1].art = LITTLE_MONSTER_POOL[mini_b]
	enemies[2].art = BOSS_POOL[randi_range(0, BOSS_POOL.size() - 1)]
	queue_redraw()

func _setup_player_deck() -> void:
	master_deck = GameState.build_battle_deck()
	for card in master_deck:
		_cache_card_art(card)
	draw_pile = master_deck.duplicate(true)
	discard_pile.clear()
	cards.clear()
	_draw_cards_to_hand(5)

func _load_player_sprite_sheet() -> void:
	# The supplied sheet is a 3x2 action board. Convert its black matte to alpha
	# once at startup, then render individual frames during the attack timeline.
	var source: Image = Image.load_from_file("res://picture/arena-player-actions.jpg")
	if source == null or source.is_empty():
		return
	var frame_width: int = source.get_width() / 3
	var frame_height: int = source.get_height() / 2
	for row in 2:
		for column in 3:
			var frame: Image = source.get_region(Rect2i(column * frame_width, row * frame_height, frame_width, frame_height))
			# JPGs are RGB-only; convert before writing alpha or the matte remains opaque.
			frame.convert(Image.FORMAT_RGBA8)
			_key_out_sprite_matte(frame)
			player_frames.append(ImageTexture.create_from_image(frame))
	if player_frames.size() != 6:
		player_frames.clear()

func _key_out_sprite_matte(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var pixel: Color = image.get_pixel(x, y)
			var luminance: float = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114
			var alpha: float = 1.0
			# Keep the dark steel/green armor; only remove the near-black JPEG matte.
			if luminance < 0.008:
				alpha = 0.0
			elif luminance < 0.045:
				alpha = (luminance - 0.008) / 0.037
			image.set_pixel(x, y, Color(pixel.r, pixel.g, pixel.b, alpha))

func _cache_card_art(card: Dictionary) -> void:
	var key := _card_art_key(card)
	if key != "" and not art.has(key):
		var texture := load(key)
		if texture:
			art[key] = texture

func _card_art_key(card: Dictionary) -> String:
	if card.has("art"):
		return str(card.art)
	return ""

func _draw_cards_to_hand(amount: int) -> void:
	for i in amount:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate(true)
			discard_pile.clear()
			draw_pile.shuffle()
		cards.append(draw_pile.pop_back())

func _process(delta: float) -> void:
	time += delta
	for i in enemies.size():
		var actor = enemies[i]
		if actor.motion != "idle" and actor.motion != "dead" and time >= actor.motion_until:
			actor.motion = "idle"
			enemies[i] = actor
	if not pending_player_attack.is_empty() and time >= pending_player_attack.impact_at:
		_resolve_player_attack()
	if player_motion == "strike":
		_update_combo_audio()
	if player_motion != "idle" and time >= player_motion_until:
		player_motion = "idle"
	if phase == "enemy" and time >= next_action_at:
		_run_enemy_step()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		GameState.admin_return_scene = get_tree().current_scene.scene_file_path
		get_tree().change_scene_to_file("res://admin.tscn")
		return
	if event is InputEventMouseMotion:
		var p: Vector2 = _arena_pointer(event.position)
		hover_card = _card_at(p)
		hovered_enemy = _enemy_at(p)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var p: Vector2 = _arena_pointer(event.position)
		if SURRENDER_BUTTON.has_point(p):
			_surrender()
			get_viewport().set_input_as_handled()
			return
		if phase == "player":
			var card_index := _card_at(p)
			if card_index >= 0:
				interaction_notice = "已点击：%s" % str(cards[card_index].get("name", "灵契卡牌"))
				interaction_notice_until = time + 1.2
				_select_card(card_index)
				return
			var enemy_index := _enemy_at(p)
			if enemy_index >= 0 and chosen_card >= 0:
				interaction_notice = "锁定目标：%s" % enemies[enemy_index].name
				interaction_notice_until = time + 1.2
				_play_attack(enemy_index)
				return
			if Rect2(1660, 872, 190, 70).has_point(p):
				_end_turn()
				get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo and phase == "player":
		if event.keycode == KEY_SPACE:
			_end_turn()
			get_viewport().set_input_as_handled()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
			var key_card := int(event.keycode - KEY_1)
			if key_card < cards.size(): _select_card(key_card)
			get_viewport().set_input_as_handled()

func _arena_pointer(pointer: Vector2) -> Vector2:
	# The editor's embedded 1280×720 preview can report physical pixels while a native
	# window reports the virtual 1920×1080 canvas. Test both to keep every hitbox usable.
	var raw := pointer
	var viewport_size := get_viewport_rect().size
	var scaled := pointer * (VIEW / viewport_size)
	if _is_interactive_point(raw): return raw
	if _is_interactive_point(scaled): return scaled
	return scaled

func _is_interactive_point(point: Vector2) -> bool:
	return _card_at(point) >= 0 or _enemy_at(point) >= 0 or Rect2(1660, 872, 190, 70).has_point(point) or SURRENDER_BUTTON.has_point(point)

func _surrender() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://spirit_codex.tscn")

func _card_center(index: int) -> Vector2:
	var count := cards.size()
	return Vector2(960 + (index - (count - 1) * 0.5) * 165, 894 + abs(index - (count - 1) * 0.5) * 13)

func _card_rect(index: int, raised := false) -> Rect2:
	var c := _card_center(index)
	if raised: c.y -= 135
	return Rect2(c - CARD_SIZE * 0.5, CARD_SIZE)

func _card_at(p: Vector2) -> int:
	for i in range(cards.size() - 1, -1, -1):
		if _card_rect(i, i == chosen_card or i == hover_card).grow(12).has_point(p): return i
	return -1

func _enemy_at(p: Vector2) -> int:
	for i in enemies.size():
		var is_boss: bool = enemies[i].boss
		var hit_size := Vector2(430, 350) if is_boss else Vector2(280, 300)
		if enemies[i].hp > 0 and Rect2(ENEMY_POSITIONS[i] - hit_size * 0.5, hit_size).has_point(p): return i
	return -1

func _select_card(index: int) -> void:
	if not pending_player_attack.is_empty(): return
	var card = cards[index]
	if int(card.get("cost", 1)) > energy:
		_flash("能量不足", _card_center(index) - Vector2(0, 120), Color("f07769"))
		return
	chosen_card = index
	banner = "选择灵契目标"
	banner_until = time + 0.55

func _play_attack(enemy_index: int) -> void:
	AudioDirector.play_sfx("res://music/发射元素火焰中.mp3", -13.0, 0.96 + randf() * 0.10)
	var card: Dictionary = cards[chosen_card]
	energy -= int(card.get("cost", 1))
	cards.remove_at(chosen_card)
	discard_pile.append(card)
	chosen_card = -1
	player_motion = "strike"
	player_motion_started = time
	player_motion_until = time + PLAYER_STRIKE_DURATION
	combo_sound_stage = 0
	player_attack_target = ENEMY_POSITIONS[enemy_index] - Vector2(0, 56)
	block += int(card.get("defense", 0))
	_apply_card_talent_on_play(card, enemy_index)
	# The hit lands on the finishing slash, not when the character merely starts moving.
	pending_player_attack = {"enemy":enemy_index, "damage":int(card.get("attack", 0)), "impact_at":time + 0.88}
	banner = str(card.get("name", "灵契出战"))
	banner_until = time + 0.88

func _apply_card_talent_on_play(card: Dictionary, enemy_index: int) -> void:
	var talent: Dictionary = card.get("talent", {})
	var key := str(talent.get("key", "none"))
	var value := int(talent.get("value", 0))
	if key == "heal":
		var healed := int(round(100.0 * float(value) / 100.0))
		player_hp = mini(100, player_hp + healed)
		_flash("治疗 +%d" % healed, Vector2(365, 360), Color("8ff0c4"))
	elif key == "reflect":
		player_reflect_percent = max(player_reflect_percent, value)
		_flash("反弹 %d%%" % value, Vector2(365, 430), Color("9be7ff"))
	elif key == "curse":
		var enemy = enemies[enemy_index]
		enemy.curse = maxi(int(enemy.get("curse", 0)), value)
		enemies[enemy_index] = enemy
		_flash("诅咒 %d%%" % value, ENEMY_POSITIONS[enemy_index] - Vector2(0, 155), Color("d79cff"))
	elif key == "endurance_boost" or key == "intelligence_boost":
		var atk_bonus := int(talent.get("attack_bonus", 0))
		var def_bonus := int(talent.get("defense_bonus", 0))
		_flash("攻 +%d%%  守 +%d%%" % [atk_bonus, def_bonus], Vector2(430, 560), Color("ffe08a"))

func _resolve_player_attack() -> void:
	AudioDirector.play_sfx("res://music/发射元素火焰强.mp3", -9.0, 0.98 + randf() * 0.08)
	AudioDirector.play_sfx("res://music/沉重.mp3", -12.0, 0.94 + randf() * 0.08)
	var enemy_index: int = pending_player_attack.enemy
	var enemy = enemies[enemy_index]
	var damage: int = pending_player_attack.damage
	var dealt: int = max(0, damage - enemy.block)
	enemy.block = max(0, enemy.block - damage)
	enemy.hp = max(0, enemy.hp - dealt)
	enemy.motion = "dead" if enemy.hp <= 0 else "hit"
	enemy.motion_started = time
	enemy.motion_until = time + 0.45
	enemies[enemy_index] = enemy
	pending_player_attack.clear()
	shake_until = time + 0.24
	shake_strength = 16.0
	impact_flash_position = ENEMY_POSITIONS[enemy_index] - Vector2(0, 34)
	impact_flash_until = time + 0.28
	_flash(str(dealt), ENEMY_POSITIONS[enemy_index] - Vector2(0, 120), Color("ffd879"))
	if enemy.hp <= 0:
		AudioDirector.play_sfx("res://music/岩石破碎.mp3" if enemy.boss else "res://music/废墟破碎.mp3", -11.0, 0.92 + randf() * 0.12)
		banner = "击破！"
		banner_until = time + 0.65

func _update_combo_audio() -> void:
	var progress := clampf((time - player_motion_started) / PLAYER_STRIKE_DURATION, 0.0, 1.0)
	if combo_sound_stage == 0 and progress >= 0.17:
		AudioDirector.play_sfx("res://music/挥剑声.mp3", -8.0, 0.94 + randf() * 0.10)
		combo_sound_stage = 1
	elif combo_sound_stage == 1 and progress >= 0.52:
		AudioDirector.play_sfx("res://music/挥空声.mp3", -10.0, 1.00 + randf() * 0.08)
		combo_sound_stage = 2
	elif combo_sound_stage == 2 and progress >= 0.72:
		AudioDirector.play_sfx("res://music/人跳声.mp3", -12.0, 1.08)
		combo_sound_stage = 3

func _end_turn() -> void:
	if phase != "player" or not pending_player_attack.is_empty(): return
	phase = "enemy"
	chosen_card = -1
	for card in cards:
		discard_pile.append(card)
	cards.clear()
	enemy_queue = []
	for i in enemies.size():
		if enemies[i].hp > 0: enemy_queue.append(i)
	enemy_step = 0
	banner = "敌方回合"
	banner_until = time + 0.8
	next_action_at = time + 0.9

func _run_enemy_step() -> void:
	if enemy_step >= enemy_queue.size():
		phase = "player"
		turn += 1
		energy = 3
		block = 0
		player_reflect_percent = 0
		_draw_cards_to_hand(5)
		banner = "玩家回合"
		banner_until = time + 0.9
		return
	var index: int = enemy_queue[enemy_step]
	var enemy = enemies[index]
	if enemy.intent == "attack":
		AudioDirector.play_sfx("res://music/挥空声.mp3", -17.0, 0.84 + randf() * 0.10)
		if enemy.boss:
			AudioDirector.play_sfx("res://music/怪物咆哮.mp3", -15.0, 0.92)
		var taken: int = max(0, enemy.value - block)
		block = max(0, block - enemy.value)
		player_hp = max(0, player_hp - taken)
		if taken > 0 and player_reflect_percent > 0:
			var reflected := int(round(float(taken) * float(player_reflect_percent) / 100.0))
			enemy.hp = max(0, enemy.hp - reflected)
			_flash("反弹 %d" % reflected, ENEMY_POSITIONS[index] - Vector2(0, 125), Color("9be7ff"))
		player_motion = "hit"
		player_motion_until = time + 0.34
		enemy.motion = "attack"
		enemy.motion_until = time + 0.46
		_flash(str(taken), Vector2(365, 385), Color("ff9575"))
		shake_until = time + 0.25
		shake_strength = 10.0
		if taken > 0:
			AudioDirector.play_sfx("res://music/跌地砰一声.mp3", -16.0, 0.96 + randf() * 0.08)
	elif enemy.intent == "defend":
		enemy.block += enemy.value
		enemy.motion = "charge"
		enemy.motion_until = time + 0.46
		_flash("格挡 +%d" % enemy.value, ENEMY_POSITIONS[index] - Vector2(0, 125), Color("8ee1d0"))
	else:
		enemy.motion = "charge"
		enemy.motion_until = time + 0.46
		var heal_amount := 10
		if int(enemy.get("curse", 0)) > 0:
			var curse_damage := int(round(float(heal_amount) * float(enemy.curse) / 100.0))
			enemy.hp = max(0, enemy.hp - curse_damage)
			_flash("诅咒 -%d" % curse_damage, ENEMY_POSITIONS[index] - Vector2(0, 125), Color("d79cff"))
		else:
			enemy.hp = mini(enemy.max_hp, enemy.hp + heal_amount)
			_flash("治疗 +%d" % heal_amount, ENEMY_POSITIONS[index] - Vector2(0, 125), Color("8ee1d0"))
	enemy.intent = ["attack", "defend", "debuff"][randi() % 3]
	enemy.value = 7 + randi() % 6 if enemy.intent == "attack" else 8
	enemies[index] = enemy
	enemy_step += 1
	next_action_at = time + 0.82

func _flash(text: String, position: Vector2, color: Color) -> void:
	damage_text = text
	damage_pos = position
	damage_until = time + 0.72

func _draw() -> void:
	var offset := Vector2.ZERO
	if time < shake_until: offset = Vector2(sin(time * 95.0) * shake_strength, cos(time * 76.0) * shake_strength * 0.35)
	draw_set_transform(offset)
	_draw_world()
	_draw_stage()
	_draw_impact_burst()
	_draw_hud()
	_draw_cards()
	draw_set_transform(Vector2.ZERO)

func _draw_world() -> void:
	if world: draw_texture_rect(world, Rect2(Vector2.ZERO, VIEW), false)
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.015, 0.055, 0.07, 0.56))
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.05, 0.16, 0.64, GameState.blue_tone * 0.25))
	draw_circle(Vector2(1060, 380), 570 + sin(time * 0.35) * 18, Color(0.06, 0.24, 0.22, 0.16))
	for i in 46:
		var x := fposmod(float(i * 137) + time * (9 + i % 5), VIEW.x)
		var y := fposmod(float(i * 79) + time * (5 + i % 3), 780.0)
		draw_circle(Vector2(x, y), 1.0 + i % 3, Color(0.93, 0.72, 0.33, 0.22 + sin(time + i) * 0.08))
	draw_rect(Rect2(0, 0, VIEW.x, 72), Color("081a20e8"))
	draw_line(Vector2(0, 72), Vector2(VIEW.x, 72), Color("cfad65"), 1.0)

func _draw_stage() -> void:
	_draw_player_actor(Vector2(360, 480))
	for i in enemies.size():
		_draw_enemy_actor(i)
	if player_motion == "strike":
		_draw_attack_projectile(Vector2(360, 480), player_attack_target)
		_draw_combo_target_pressure()
	if chosen_card >= 0:
		_draw_target_arrow(_card_center(chosen_card) - Vector2(0, 210), ENEMY_POSITIONS[hovered_enemy if hovered_enemy >= 0 else 0] - Vector2(0, 60))

func _draw_player_actor(base: Vector2) -> void:
	var bob := sin(time * 2.5) * 5.0
	var position := base + Vector2(0, bob)
	var rotation := sin(time * 2.5) * 0.012
	var scale := Vector2.ONE
	var texture: Texture2D = art.player_idle
	var sprite_rect := Rect2(-164, -255, 328, 492)
	var tint := Color.WHITE
	if player_motion == "strike":
		var progress := clampf((time - player_motion_started) / PLAYER_STRIKE_DURATION, 0.0, 1.0)
		var windup := clampf(progress / 0.20, 0.0, 1.0)
		var first_slash := _combo_pulse(progress, 0.17, 0.43)
		var reset := clampf((progress - 0.42) / 0.13, 0.0, 1.0)
		var second_slash := _combo_pulse(progress, 0.52, 0.76)
		var finisher := _combo_pulse(progress, 0.72, 0.98)
		# Three readable poses: pull back, a quick horizontal cut, reverse cut, then a heavy finishing thrust.
		position.x += -44.0 * sin(windup * PI * 0.5)
		position.x += first_slash * 108.0 + reset * 32.0 + second_slash * 94.0 + finisher * 86.0
		position.y += -first_slash * 12.0 - second_slash * 7.0 - finisher * 20.0
		rotation = -0.26 * (1.0 - windup)
		rotation += first_slash * 0.43 - reset * 0.50 + second_slash * 0.36 - finisher * 0.18
		scale = Vector2(1.0 + first_slash * 0.035 + finisher * 0.07, 1.0 - first_slash * 0.022 - finisher * 0.04)
		texture = _player_action_frame(progress)
		sprite_rect = Rect2(-178, -255, 356, 492)
		_draw_sword_afterimage(position, rotation, scale, progress, tint)
		_draw_spirit_slash(position + Vector2(118, -46), progress)
	elif player_motion == "hit":
		position.x -= 18.0
		rotation = -0.07
		tint = Color(1.0, 0.58, 0.58)
	# Soul ribbons and a breathing aura are independent Godot-drawn layers, not baked into the portrait.
	draw_circle(position + Vector2(0, 98), 114.0 + sin(time * 2.0) * 6.0, Color(0.15, 0.86, 0.75, 0.12))
	for i in 3:
		var arc_start := time * 1.3 + i * TAU / 3.0
		draw_arc(position + Vector2(0, 40), 125 + i * 9, arc_start, arc_start + 0.82, 18, Color(0.25, 0.95, 0.83, 0.42), 2.0)
	draw_set_transform(position, rotation, scale)
	draw_texture_rect(texture, sprite_rect, false, tint)
	draw_set_transform(Vector2.ZERO)
	_draw_text("灵契使 · 小澈", position + Vector2(-112, 220), 23, Color("fff3cb"), HORIZONTAL_ALIGNMENT_CENTER, 224)
	var hp_rect := Rect2(position + Vector2(-112, 242), Vector2(224, 15))
	draw_rect(hp_rect, Color("29131a"))
	draw_rect(Rect2(hp_rect.position, Vector2(hp_rect.size.x * float(player_hp) / 100.0, hp_rect.size.y)), Color("43b99a"))
	draw_rect(hp_rect, Color("e6d09b"), false, 1.0)
	_draw_text("%d/100" % player_hp, hp_rect.position + Vector2(0, -1), 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 224)
	if block > 0: _draw_pill(position + Vector2(-42, 266), "格挡 %d" % block, Color("3f9f96"))

func _player_action_frame(progress: float) -> Texture2D:
	if player_frames.is_empty():
		return art.player_strike
	var frame_index: int = 0
	if progress >= 0.14 and progress < 0.34:
		frame_index = 1
	elif progress < 0.54:
		frame_index = 2
	elif progress < 0.72:
		frame_index = 3
	elif progress < 0.90:
		frame_index = 4
	else:
		frame_index = 5
	return player_frames[frame_index]

func _draw_spirit_slash(pos: Vector2, progress: float) -> void:
	_draw_combo_arc(pos, _combo_pulse(progress, 0.17, 0.43), -2.92, 0.18, Color("52f6d1"), 1.0)
	_draw_combo_arc(pos + Vector2(20, -8), _combo_pulse(progress, 0.52, 0.76), 0.34, 3.34, Color("8ddcff"), -1.0)
	_draw_combo_arc(pos + Vector2(36, -24), _combo_pulse(progress, 0.72, 0.98), -2.74, 0.58, Color("ffe28a"), 1.0)

func _draw_combo_arc(pos: Vector2, pulse: float, start_angle: float, end_angle: float, color: Color, direction: float) -> void:
	if pulse <= 0.0: return
	var alpha := pulse * 0.92
	var sweep := lerpf(start_angle, end_angle, _ease_out_cubic(pulse))
	for i in 5:
		var radius := 70.0 + float(i) * 17.0 + pulse * 32.0
		var begin := start_angle + float(i) * 0.035 * direction
		var finish := sweep + float(i) * 0.018 * direction
		draw_arc(pos, radius, begin, finish, 30, Color(color, alpha * (1.0 - float(i) * 0.14)), 7.0 - float(i) * 0.76)
		draw_arc(pos + Vector2(7, -6), radius + 8.0, begin + 0.08, finish + 0.04, 30, Color("ffe39a", alpha * 0.38), 2.0)
	draw_circle(pos + Vector2(cos(sweep), sin(sweep)) * 118.0, 15.0 * alpha, Color(0.95, 1.0, 0.78, alpha * 0.72))

func _draw_sword_afterimage(position: Vector2, rotation: float, scale: Vector2, progress: float, tint: Color) -> void:
	var ghost_alpha := maxf(_combo_pulse(progress, 0.17, 0.43), maxf(_combo_pulse(progress, 0.52, 0.76), _combo_pulse(progress, 0.72, 0.98))) * 0.28
	if ghost_alpha <= 0.0: return
	var ghost_texture: Texture2D = _player_action_frame(progress)
	for i in 3:
		var offset := Vector2(-26.0 - i * 34.0, 8.0 + i * 7.0)
		draw_set_transform(position + offset, rotation - 0.025 * float(i + 1), scale)
		draw_texture_rect(ghost_texture, Rect2(-178, -255, 356, 492), false, Color(0.30, 1.0, 0.88, ghost_alpha * (1.0 - i * 0.24)))
	draw_set_transform(Vector2.ZERO)

func _draw_attack_projectile(from: Vector2, to: Vector2) -> void:
	var progress := clampf((time - player_motion_started) / PLAYER_STRIKE_DURATION, 0.0, 1.0)
	var flight := clampf((progress - 0.76) / 0.16, 0.0, 1.0)
	if flight <= 0.0: return
	var head := from.lerp(to, _ease_out_cubic(flight)) + Vector2(120, -42)
	var tail := from.lerp(to, max(0.0, _ease_out_cubic(flight - 0.22))) + Vector2(120, -42)
	var fade := 1.0 - clampf((progress - 0.92) / 0.08, 0.0, 1.0)
	draw_line(tail, head, Color(0.32, 1.0, 0.88, 0.70 * fade), 8.0, true)
	draw_line(tail + Vector2(0, 8), head + Vector2(0, 8), Color(1.0, 0.76, 0.32, 0.42 * fade), 3.0, true)
	draw_circle(head, 16.0 * fade, Color(0.86, 1.0, 0.74, 0.62 * fade))
	for i in 5:
		var t := float(i) / 5.0
		var p := tail.lerp(head, t)
		draw_circle(p + Vector2(sin(time * 12.0 + i) * 12.0, cos(time * 9.0 + i) * 8.0), 2.0 + i % 2, Color(0.66, 1.0, 0.90, 0.34 * fade))

func _combo_pulse(progress: float, start: float, finish: float) -> float:
	return sin(clampf((progress - start) / maxf(finish - start, 0.001), 0.0, 1.0) * PI)

func _draw_combo_target_pressure() -> void:
	if pending_player_attack.is_empty(): return
	var progress := clampf((time - player_motion_started) / PLAYER_STRIKE_DURATION, 0.0, 1.0)
	var target := player_attack_target + Vector2(0, 56)
	var warning := clampf((progress - 0.54) / 0.28, 0.0, 1.0)
	if warning <= 0.0: return
	var pulse := 0.58 + sin(time * 22.0) * 0.20
	draw_circle(target, 92.0 + warning * 42.0, Color(1.0, 0.30, 0.18, 0.08 * warning))
	draw_arc(target, 104.0 + warning * 24.0, -time * 4.0, -time * 4.0 + TAU * 0.72, 32, Color(1.0, 0.73, 0.34, warning * pulse), 3.0)

func _draw_impact_burst() -> void:
	if time >= impact_flash_until: return
	var progress := 1.0 - (impact_flash_until - time) / 0.28
	var fade := 1.0 - progress
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(1.0, 0.78, 0.34, 0.10 * fade))
	for i in 16:
		var angle := float(i) * TAU / 16.0 + time * 5.0
		var start := impact_flash_position + Vector2(cos(angle), sin(angle)) * (16.0 + progress * 36.0)
		var finish := impact_flash_position + Vector2(cos(angle), sin(angle)) * (84.0 + progress * 188.0)
		draw_line(start, finish, Color("fff0ab", fade * (0.95 - float(i % 3) * 0.12)), 4.0 - float(i % 2), true)
	draw_circle(impact_flash_position, 86.0 * fade, Color(0.75, 1.0, 0.84, 0.38 * fade))

func _ease_out_cubic(v: float) -> float:
	var t := clampf(v, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)

func _ease_in_out_cubic(v: float) -> float:
	var t := clampf(v, 0.0, 1.0)
	if t < 0.5:
		return 4.0 * t * t * t
	return 1.0 - pow(-2.0 * t + 2.0, 3.0) / 2.0

func _draw_enemy_actor(index: int) -> void:
	var enemy = enemies[index]
	var boss: bool = enemy.boss
	var base: Vector2 = ENEMY_POSITIONS[index]
	var bob: float = sin(time * (1.75 if boss else 2.4) + index) * (7.0 if boss else 4.0)
	var pos: Vector2 = base + Vector2(0, bob)
	var motion: String = enemy.motion
	var tint := Color.WHITE
	if motion == "attack": pos.x -= (64.0 if boss else 42.0)
	if motion == "hit":
		var hit_started: float = float(enemy.get("motion_started", time))
		var hit_progress := clampf((time - hit_started) / 0.45, 0.0, 1.0)
		var recoil := sin(hit_progress * PI * 3.0) * (1.0 - hit_progress * 0.30)
		pos += Vector2(30.0 * recoil, -14.0 * sin(hit_progress * PI))
		tint = Color(1.0, 0.46 + 0.36 * hit_progress, 0.46 + 0.36 * hit_progress)
		draw_circle(pos + Vector2(0, 12), (104.0 if boss else 76.0) + hit_progress * 58.0, Color(1.0, 0.78, 0.38, (1.0 - hit_progress) * 0.26))
	if motion == "dead": tint = Color(0.32, 0.35, 0.4, 0.18)
	var aura: Color = Color("ee634f") if boss else Color("a567e7")
	if motion == "charge" or enemy.intent == "attack":
		draw_circle(pos + Vector2(0, 28), (168.0 if boss else 122.0) + sin(time * 8.0) * 9.0, Color(aura, 0.14))
		for ring in 3:
			draw_arc(pos + Vector2(0, 20), (145 if boss else 105) + ring * 13, -time * 2.0 + ring, -time * 2.0 + ring + 1.2, 18, Color(aura, 0.5), 2.0)
	else:
		draw_circle(pos + Vector2(0, 26), 145.0 if boss else 105.0, Color(aura, 0.08))
	var draw_size: Vector2 = Vector2(420, 236) if boss else Vector2(265, 180)
	var draw_offset: Vector2 = Vector2(-draw_size.x * 0.5, -draw_size.y * 0.60)
	draw_texture_rect(art[enemy.art], Rect2(pos + draw_offset, draw_size), false, tint)
	var title_y: float = pos.y + (165 if boss else 130)
	_draw_text(enemy.name, Vector2(pos.x - 130, title_y), 25 if boss else 21, Color("ffe0a0") if boss else Color("fff3cb"), HORIZONTAL_ALIGNMENT_CENTER, 260)
	var hp_width: float = 252.0 if boss else 214.0
	var hp_rect: Rect2 = Rect2(pos + Vector2(-hp_width * 0.5, title_y + 30), Vector2(hp_width, 15))
	draw_rect(hp_rect, Color("29131a"))
	draw_rect(Rect2(hp_rect.position, Vector2(hp_rect.size.x * float(enemy.hp) / enemy.max_hp, hp_rect.size.y)), Color("e86b55"))
	draw_rect(hp_rect, Color("e6d09b"), false, 1.0)
	_draw_text("%d/%d" % [enemy.hp, enemy.max_hp], hp_rect.position + Vector2(0, -1), 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, hp_width)
	if enemy.block > 0: _draw_pill(pos + Vector2(-42, title_y + 53), "格挡 %d" % enemy.block, Color("3f9f96"))
	_draw_enemy_intent(index, pos + Vector2(0, -150 if boss else -118))

func _draw_enemy_intent(index: int, pos: Vector2) -> void:
	var enemy = enemies[index]
	if enemy.hp <= 0:
		_draw_pill(pos - Vector2(42, 15), "已击破", Color("687984"))
		return
	var label := "⚔ %d" % enemy.value if enemy.intent == "attack" else ("◇ %d" % enemy.value if enemy.intent == "defend" else "✦ 虚弱")
	var color := Color("ff987a") if enemy.intent == "attack" else (Color("90e0d4") if enemy.intent == "defend" else Color("d3a0ed"))
	_draw_pill(pos - Vector2(42, 15), label, color)

func _draw_unit(pos: Vector2, texture: Texture2D, title: String, hp: int, max_hp: int, unit_block: int, mine: bool, enemy_index: int) -> void:
	var glow := Color("59d8b5") if mine else Color("ed7661")
	if enemy_index == hovered_enemy and chosen_card >= 0: glow = Color("ffd166")
	draw_circle(pos + Vector2(0, 20), 132, Color(glow, 0.17))
	draw_circle(pos + Vector2(0, 20), 109, Color("07171bd8"))
	if texture: _draw_texture_crop(texture, Rect2(pos - Vector2(105, 115), Vector2(210, 210)))
	draw_arc(pos + Vector2(0, 20), 112, 0, TAU, 48, Color(glow, 0.78), 2.0)
	_draw_text(title, pos + Vector2(-104, 142), 23, Color("fff3cb"), HORIZONTAL_ALIGNMENT_CENTER, 208)
	var hp_rect := Rect2(pos + Vector2(-112, 158), Vector2(224, 15))
	draw_rect(hp_rect, Color("29131a"))
	draw_rect(Rect2(hp_rect.position, Vector2(hp_rect.size.x * float(hp) / max_hp, hp_rect.size.y)), Color("43b99a") if mine else Color("d85e57"))
	draw_rect(hp_rect, Color("e6d09b"), false, 1.0)
	_draw_text("%d/%d" % [hp, max_hp], hp_rect.position + Vector2(0, -1), 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 224)
	if unit_block > 0: _draw_pill(pos + Vector2(-42, 182), "格挡 %d" % unit_block, Color("3f9f96"))
	if not mine: _draw_intent(enemy_index, pos + Vector2(0, -152))

func _draw_intent(index: int, pos: Vector2) -> void:
	var e = enemies[index]
	var text := "⚔ %d" % e.value if e.intent == "attack" else ("◇ %d" % e.value if e.intent == "defend" else "✦ 虚弱")
	var color := Color("ff987a") if e.intent == "attack" else (Color("90e0d4") if e.intent == "defend" else Color("d3a0ed"))
	_draw_pill(pos - Vector2(42, 15), text, color)

func _draw_hud() -> void:
	_draw_text("四界灵契  ·  赤烬战场", Vector2(42, 27), 25, Color("f7e7b3"))
	_draw_text("第 %d 回合" % turn, Vector2(1645, 29), 17, Color("d6c494"))
	_draw_text("灵契使 · 小澈     ♥ %d / 100" % player_hp, Vector2(40, 110), 20, Color("f7e5c2"))
	_draw_text(interaction_notice, Vector2(690, 94), 17, Color("f7dfa4"), HORIZONTAL_ALIGNMENT_CENTER, 540)
	_draw_energy()
	_draw_surrender_button()
	_draw_pile(Vector2(178, 912), "抽牌堆", draw_pile.size())
	_draw_pile(Vector2(1510, 912), "弃牌堆", discard_pile.size())
	_draw_button(Rect2(1660, 872, 190, 70), "结束回合")
	if time < banner_until:
		var a: float = clampf((banner_until - time) * 1.8, 0.0, 1.0)
		draw_rect(Rect2(660, 245, 600, 65), Color(0.02, 0.08, 0.1, 0.82 * a))
		_draw_text(banner, Vector2(660, 255), 36, Color(1, 0.87, 0.53, a), HORIZONTAL_ALIGNMENT_CENTER, 600)
	if time < damage_until:
		var t := 1.0 - (damage_until - time) / 0.72
		_draw_text(damage_text, damage_pos - Vector2(0, t * 72), 58 + t * 14, Color("ffe29a"), HORIZONTAL_ALIGNMENT_CENTER, 180)

func _draw_cards() -> void:
	for i in cards.size():
		var raised := i == chosen_card or i == hover_card
		var rect := _card_rect(i, raised)
		var rotation := (i - (cards.size() - 1) * 0.5) * 0.06
		if raised: rotation = 0.0
		draw_set_transform(rect.get_center(), rotation, Vector2.ONE)
		_draw_card(Rect2(-CARD_SIZE * 0.5, CARD_SIZE), cards[i], i == chosen_card)
		draw_set_transform(Vector2.ZERO)

func _draw_card(rect: Rect2, card: Dictionary, selected: bool) -> void:
	var border := Color("ffd779") if selected else Color("b98b4c")
	UISkin.panel(self, rect, Color("16171af2"), border, 16.0, 0.30 if selected else 0.09, 7.0)
	var image_rect := Rect2(rect.position + Vector2(12, 14), Vector2(rect.size.x - 24, 181))
	var art_key := _card_art_key(card)
	if art.has(art_key): _draw_texture_crop(art[art_key], image_rect)
	draw_rect(Rect2(rect.position + Vector2(12, 166), Vector2(rect.size.x - 24, 30)), Color("0a1119b5"))
	_draw_text(str(card.get("name", "灵契卡牌")), rect.position + Vector2(12, 203), 19, Color("ffe7ad"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 24)
	_draw_text("攻 %d   守 %d" % [int(card.get("attack", 0)), int(card.get("defense", 0))], rect.position + Vector2(12, 231), 16, Color("fff0bf"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 24)
	var note := _talent_note(card)
	_draw_text(note, rect.position + Vector2(12, 260), 14, Color("e7d6b0"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 24)
	draw_circle(rect.position + Vector2(13, 14), 25, Color("e9bb54"))
	_draw_text(str(int(card.get("cost", 1))), rect.position + Vector2(0, 0), 24, Color("182529"), HORIZONTAL_ALIGNMENT_CENTER, 27)

func _talent_note(card: Dictionary) -> String:
	var talent: Dictionary = card.get("talent", {})
	var key := str(talent.get("key", "none"))
	var value := int(talent.get("value", 0))
	if key == "heal":
		return "灵力：治疗 %d%%" % value
	if key == "reflect":
		return "体力：反弹 %d%%" % value
	if key == "curse":
		return "魔力：治疗反噬 %d%%" % value
	if key == "endurance_boost" or key == "intelligence_boost":
		return "%s：攻 +%d%% 守 +%d%%" % [str(talent.get("label", "成长")), int(talent.get("attack_bonus", 0)), int(talent.get("defense_bonus", 0))]
	return "灵契：无额外天赋"

func _draw_target_arrow(from: Vector2, to: Vector2) -> void:
	var direction := (to - from).normalized()
	var distance := from.distance_to(to)
	for i in 7:
		var p: Vector2 = from + direction * (54.0 + float(i) * minf(56.0, (distance - 100.0) / 7.0))
		var side := Vector2(-direction.y, direction.x)
		var points := PackedVector2Array([p - direction * 14 - side * 9, p + direction * 17, p - direction * 14 + side * 9])
		draw_colored_polygon(points, Color("ed554e"))

func _draw_texture_crop(texture: Texture2D, target: Rect2) -> void:
	var source_size := texture.get_size()
	var scale := maxf(target.size.x / source_size.x, target.size.y / source_size.y)
	var crop_size := target.size / scale
	var source := Rect2((source_size - crop_size) * 0.5, crop_size)
	draw_texture_rect_region(texture, target, source, Color(1, 1, 1, GameState.object_opacity))

func _draw_energy() -> void:
	draw_circle(Vector2(82, 888), 54, Color("3f2418"))
	draw_circle(Vector2(82, 888), 47, Color("e99f40"))
	_draw_text(str(energy), Vector2(49, 866), 42, Color("fff0bc"), HORIZONTAL_ALIGNMENT_CENTER, 66)
	_draw_text("/ 3", Vector2(49, 907), 14, Color("ffe8aa"), HORIZONTAL_ALIGNMENT_CENTER, 66)

func _draw_pile(pos: Vector2, caption: String, count: int) -> void:
	UISkin.panel(self, Rect2(pos, Vector2(82, 112)), Color("291b18e8"), Color("c79b57"), 14.0, 0.08, 5.0)
	_draw_text(str(count), pos + Vector2(0, 26), 29, Color("f5dda3"), HORIZONTAL_ALIGNMENT_CENTER, 82)
	_draw_text(caption, pos + Vector2(0, 67), 14, Color("d1c2a3"), HORIZONTAL_ALIGNMENT_CENTER, 82)

func _draw_button(rect: Rect2, text: String) -> void:
	var painted := UISkin.button(self, rect, rect.has_point(_arena_pointer(get_viewport().get_mouse_position())), true)
	_draw_text(text, painted.position + Vector2(0, 22), 22, Color("fff0c1"), HORIZONTAL_ALIGNMENT_CENTER, painted.size.x)

func _draw_surrender_button() -> void:
	var hover := SURRENDER_BUTTON.has_point(_arena_pointer(get_viewport().get_mouse_position()))
	draw_rect(SURRENDER_BUTTON, Color("7b342f") if hover else Color("492b2d"))
	draw_rect(SURRENDER_BUTTON, Color("e4a36d"), false, 2.0)
	_draw_text("认输 · 返回图鉴", SURRENDER_BUTTON.position + Vector2(0, 14), 17, Color("fff0c8"), HORIZONTAL_ALIGNMENT_CENTER, SURRENDER_BUTTON.size.x)

func _draw_pill(pos: Vector2, text: String, color: Color) -> void:
	var rect := Rect2(pos, Vector2(84, 29))
	UISkin.panel(self, rect, Color(color, 0.22), color, 14.0, 0.08, 4.0)
	_draw_text(text, rect.position + Vector2(0, 6), 13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)

func _draw_text(text: String, pos: Vector2, size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var scaled_size: int = int(round(float(size) * GameState.ui_font_scale))
	draw_string(font, pos + Vector2(0, float(scaled_size)), text, alignment, width, scaled_size, Color(color, color.a * GameState.ui_opacity))

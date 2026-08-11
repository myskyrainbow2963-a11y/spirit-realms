extends Node2D

const GameState = preload("res://game_state.gd")
const UISkin = preload("res://ui_skin.gd")

const VIEW := Vector2(1920, 1080)
const NAV_MAP := Rect2(780, 14, 126, 52)
const NAV_HOME := Rect2(915, 14, 126, 52)
const NAV_CARDS := Rect2(1050, 14, 144, 52)
const NAV_BATTLE := Rect2(1205, 14, 130, 52)
const ALTAR := Rect2(660, 395, 600, 470)
const ARCHIVE_PANEL := Rect2(38, 300, 290, 430)
const GUIDE_PANEL := Rect2(1592, 300, 290, 430)
const SKILL_RECTS := [Rect2(610, 375, 230, 86), Rect2(870, 375, 230, 86), Rect2(1130, 375, 230, 86), Rect2(610, 480, 230, 86), Rect2(870, 480, 230, 86)]
const TRAIN_CONFIRM := Rect2(730, 620, 510, 68)

var font: Font
var background: Texture2D
var egg_texture: Texture2D
var incubation_table: Texture2D
var time := 0.0
var focus := 0.0
var transition := 0.0
var destination := ""
var ritual_text := "灵蛋正在聆听山风"
var interaction_note := ""
var interaction_until := 0.0
var training_open := false
var selected_skill := ""
var skill_names := ["智力", "体力", "灵力", "魔力", "耐力"]
var hatch_sequence := -1.0
var revealed_card: Dictionary = {}
var revealed_texture: Texture2D
var hatch_sound_stage := 0

func _ready() -> void:
	AudioDirector.play_music("res://music/Moonlit Oath.mp3", -20.0)
	AudioDirector.stop_ambience()
	font = GameState.font_for(load("res://fonts/NotoSansSC-VF.ttf"))
	background = load("res://picture/Background1.png")
	incubation_table = load("res://picture/Incubation table1-alpha.png")
	if GameState.has_egg():
		var data: Dictionary = GameState.REALMS.get(GameState.egg_realm, GameState.REALMS["demon"])
		egg_texture = load(str(data.egg_art))
	if GameState.hatch_reveal_pending and GameState.is_hatched():
		hatch_sequence = 0.0
		AudioDirector.play_sfx("res://music/火焰燃起声.mp3", -13.0, 1.16)
	_create_interaction_buttons()
	set_process_input(true)

func _process(delta: float) -> void:
	time += delta
	focus = maxf(0.0, focus - delta)
	if destination != "":
		transition += delta
		if transition >= 0.78:
			get_tree().change_scene_to_file(destination)
	if hatch_sequence >= 0.0:
		hatch_sequence += delta
		_update_hatch_audio()
		if hatch_sequence >= 2.15 and revealed_card.is_empty():
			revealed_card = GameState.reveal_hatched_card()
			revealed_texture = load(str(revealed_card.art))
			AudioDirector.play_sfx("res://music/发射元素火焰强.mp3", -9.0, 1.06)
	queue_redraw()

func _update_hatch_audio() -> void:
	if hatch_sound_stage == 0 and hatch_sequence >= 0.55:
		AudioDirector.play_sfx("res://music/沉重.mp3", -18.0, 1.18)
		hatch_sound_stage = 1
	elif hatch_sound_stage == 1 and hatch_sequence >= 1.35:
		AudioDirector.play_sfx("res://music/岩石破碎.mp3", -13.0, 1.12)
		hatch_sound_stage = 2

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		GameState.admin_return_scene = get_tree().current_scene.scene_file_path
		get_tree().change_scene_to_file("res://admin.tscn")
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and destination == "":
		for p in _pointer_candidates(event.position):
			if training_open:
				if TRAIN_CONFIRM.has_point(p):
					_confirm_training()
					get_viewport().set_input_as_handled()
					return
				for i in SKILL_RECTS.size():
					if SKILL_RECTS[i].has_point(p):
						_choose_skill(i)
						get_viewport().set_input_as_handled()
						return
			if NAV_MAP.has_point(p):
				_leave("res://world_choice.tscn")
			elif NAV_HOME.has_point(p):
				_open_training()
			elif NAV_CARDS.has_point(p):
				_leave("res://spirit_codex.tscn")
			elif NAV_BATTLE.has_point(p):
				_leave("res://battle.tscn")
			elif ALTAR.has_point(p):
				_open_training()
			elif ARCHIVE_PANEL.has_point(p):
				interaction_note = "培育档案展开：当前灵息浓度为充盈"
				interaction_until = time + 2.4
			elif GUIDE_PANEL.has_point(p):
				interaction_note = "培育指南：每日为灵蛋注入灵息，可强化共鸣效果"
				interaction_until = time + 2.8
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C: _leave("res://spirit_codex.tscn")
		if event.keycode == KEY_B: _leave("res://battle.tscn")
		if event.keycode == KEY_ESCAPE and training_open: training_open = false

func _leave(scene: String) -> void:
	destination = scene
	transition = 0.01

func _pointer(pointer: Vector2) -> Vector2:
	for candidate in _pointer_candidates(pointer):
		if _is_hotspot(candidate): return candidate
	return pointer

func _pointer_candidates(pointer: Vector2) -> Array[Vector2]:
	var canvas_point: Vector2 = get_global_transform_with_canvas().affine_inverse() * pointer
	var viewport_size: Vector2 = get_viewport_rect().size
	var window_size: Vector2 = Vector2(DisplayServer.window_get_size())
	if window_size.x <= 0.0 or window_size.y <= 0.0: window_size = viewport_size
	var candidates: Array[Vector2] = [canvas_point, pointer, pointer * (VIEW / viewport_size), pointer * (VIEW / window_size), pointer * Vector2(1.5, 1.5)]
	return candidates

func _is_hotspot(point: Vector2) -> bool:
	return NAV_MAP.has_point(point) or NAV_HOME.has_point(point) or NAV_CARDS.has_point(point) or NAV_BATTLE.has_point(point) or ALTAR.has_point(point) or ARCHIVE_PANEL.has_point(point) or GUIDE_PANEL.has_point(point)

func _draw() -> void:
	_draw_background()
	_draw_motes()
	_draw_nav()
	_draw_header()
	_draw_altar()
	_draw_side_panels()
	if training_open: _draw_training_modal()
	if time < interaction_until:
		_text(interaction_note, Vector2(560, 930), 18, Color("fff0bd"), HORIZONTAL_ALIGNMENT_CENTER, 800)
	if destination != "": _draw_transition()

func _draw_background() -> void:
	var size := VIEW * (1.08 + sin(time * 0.09) * 0.025)
	var rect := Rect2((VIEW - size) * 0.5 + Vector2(sin(time * 0.1) * 9.0, cos(time * 0.13) * 6.0), size)
	if background: draw_texture_rect(background, rect, false)
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.015, 0.055, 0.05, 0.54))
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.06, 0.24, 0.70, GameState.blue_tone * 0.34))
	draw_rect(Rect2(0, 730, VIEW.x, 350), Color(0.008, 0.02, 0.025, 0.68))
	var breath := 0.5 + sin(time * 1.35) * 0.5
	draw_circle(Vector2(959, 579), 300 + breath * 32, Color(0.19, 0.85, 0.64, 0.055 + focus * 0.03))

func _draw_motes() -> void:
	for i in 74:
		var x: float = fposmod(float(i * 127) + sin(time * 0.8 + i) * 36.0, VIEW.x)
		var y: float = fposmod(float(i * 71) - time * (9.0 + i % 7 * 3.0), 880.0) + 90.0
		var glow := 0.25 + sin(time * 2.0 + i) * 0.18
		draw_circle(Vector2(x, y), 1.4 + i % 3, Color(0.92, 0.77, 0.32, glow))

func _draw_nav() -> void:
	draw_rect(Rect2(0, 0, VIEW.x, 74), Color("102c2be8"))
	draw_line(Vector2(0, 73), Vector2(VIEW.x, 73), Color("b79756"), 1.0)
	_text("契", Vector2(48, 12), 38, Color("e7c77f"))
	_text("四界灵契", Vector2(96, 14), 26, Color("f4e6bf"))
	_text("SPIRIT REALMS", Vector2(98, 43), 10, Color("9cae99"))
	_nav(NAV_MAP, "世界地图")
	_nav(NAV_HOME, "云栖小筑", true)
	_nav(NAV_CARDS, "灵契图鉴  15")
	_nav(NAV_BATTLE, "竞技场")
	_text("✦ 750", Vector2(1770, 23), 17, Color("d9ad55"))

func _nav(rect: Rect2, label: String, active := false) -> void:
	if active:
		draw_rect(rect, Color(0.27, 0.72, 0.57, 0.20))
		draw_rect(rect, Color("bfa05f"), false, 1.0)
	_text(label, rect.position + Vector2(0, 11), 19, Color("f4dfab") if active else Color("d5d7c2"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)

func _draw_header() -> void:
	_text("YOUR SANCTUARY  ·  云栖家园", Vector2(780, 95), 14, Color("e4c889"), HORIZONTAL_ALIGNMENT_CENTER, 360)
	_text("云栖小筑", Vector2(750, 112), 58, Color("fff0c5"), HORIZONTAL_ALIGNMENT_CENTER, 420)
	_text("云深不知处，万灵自有归期", Vector2(770, 182), 19, Color("e8dcc1"), HORIZONTAL_ALIGNMENT_CENTER, 380)

func _draw_altar() -> void:
	var center := Vector2(960, 615 + sin(time * 1.3) * 6.0)
	var pulse := 0.5 + sin(time * 2.4) * 0.5
	_draw_ritual_pedestal(center, pulse)
	for i in 4:
		draw_arc(center, 128 + i * 24 + pulse * 8, time * (0.35 + i * 0.1), time * (0.35 + i * 0.1) + 4.65, 42, Color(0.38, 0.95, 0.71, 0.22), 2.0)
	draw_circle(center, 110 + pulse * 15, Color(0.25, 0.98, 0.74, 0.11 + focus * 0.08))
	if incubation_table:
		# The table is layered over a Godot-drawn plinth so it reads as a physical altar, not a flat sticker.
		draw_texture_rect(incubation_table, Rect2(center - Vector2(218, 38), Vector2(436, 290)), false, Color.WHITE)
	draw_arc(center + Vector2(0, 58), 104, PI, TAU, 36, Color("caab5e"), 3.0)
	if hatch_sequence >= 0.0:
		_draw_hatch_sequence(center)
	else:
		_draw_egg(center)
	# The fully revealed card owns the center of the stage; suppress egg labels so nothing overlaps it.
	if hatch_sequence < 0.0:
		_text("共鸣灵蛋", Vector2(750, 825), 40, Color("fff1c8"), HORIZONTAL_ALIGNMENT_CENTER, 420)
		var incubation := GameState.hatch_text()
		_text(incubation if GameState.has_egg() else ritual_text, Vector2(715, 880), 20, Color("d6f0dc"), HORIZONTAL_ALIGNMENT_CENTER, 490)
		_text("点击祭坛 · 注入灵息", Vector2(730, 924), 18, Color("ffe29a"), HORIZONTAL_ALIGNMENT_CENTER, 460)

func _draw_egg(center: Vector2) -> void:
	var hover := 0.5 + sin(time * 2.1) * 0.5
	# Contact shadow plus offset shell glow give the egg volume even when its source art is a front-facing PNG.
	_ellipse(center + Vector2(0, 94), Vector2(74, 16), Color(0.0, 0.05, 0.04, 0.62))
	draw_circle(center + Vector2(0, 5), 79 + hover * 8, Color(0.98, 0.74, 0.32, 0.10))
	draw_arc(center + Vector2(0, 4), 70 + hover * 5, -time * 1.2, -time * 1.2 + 4.5, 42, Color("ffe69a", 0.72), 2.0)
	if egg_texture:
		draw_texture_rect(egg_texture, Rect2(center - Vector2(72, 96), Vector2(144, 192)), false, Color.WHITE)
		draw_circle(center + Vector2(-20, -36), 14.0 + hover * 3.0, Color(1.0, 0.98, 0.80, 0.20))
		return
	_ellipse(center, Vector2(40, 59), Color("f4e4bb"))
	_ellipse(center + Vector2(-11, -10), Vector2(16, 23), Color("fff8df"))
	draw_arc(center, 40, 0.2, 5.9, 32, Color("5e6f5a"), 3.0)
	for i in 5:
		var a: float = time * 2.2 + float(i) * TAU / 5.0
		draw_circle(center + Vector2(cos(a), sin(a)) * (78 + focus * 10), 3.5, Color("ffd978"))

func _draw_ritual_pedestal(center: Vector2, pulse: float) -> void:
	# Perspective ellipses and tiered stone bands create a stable pseudo-3D footprint under the raster altar.
	_ellipse(center + Vector2(0, 154), Vector2(286, 62), Color(0.0, 0.03, 0.025, 0.74))
	_ellipse(center + Vector2(0, 132), Vector2(252, 52), Color("082a28"))
	_ellipse(center + Vector2(0, 125), Vector2(238, 44), Color("154a43"))
	_ellipse(center + Vector2(0, 116), Vector2(214, 36), Color("0b2828"))
	for ring in 3:
		var radius := Vector2(180.0 - float(ring) * 31.0, 25.0 - float(ring) * 3.5)
		_draw_ellipse_outline(center + Vector2(0, 106), radius + Vector2(pulse * 4.0, pulse), Color("d6b760", 0.44 - float(ring) * 0.10), 1.5)
	for i in 12:
		var a := float(i) * TAU / 12.0 - time * 0.40
		var point := center + Vector2(cos(a) * 188.0, sin(a) * 31.0 + 108.0)
		draw_circle(point, 2.2, Color("7bffe0", 0.52 + sin(time * 3.0 + i) * 0.18))

func _draw_ellipse_outline(center: Vector2, radii: Vector2, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for i in 41:
		var a := TAU * float(i) / 40.0
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_polyline(points, color, width, true)

func _draw_hatch_sequence(center: Vector2) -> void:
	var p := hatch_sequence
	if p < 1.35:
		var wobble := sin(p * 30.0) * (4.0 + p * 8.0)
		_draw_egg(center + Vector2(wobble, 0.0))
		for i in 7:
			var a := float(i) * TAU / 7.0
			draw_line(center + Vector2(cos(a) * 15, sin(a) * 22), center + Vector2(cos(a) * 55, sin(a) * 66), Color("fff0af"), 2.0)
		_text("灵蛋正在挣扎破壳…", Vector2(670, 850), 24, Color("ffe7a4"), HORIZONTAL_ALIGNMENT_CENTER, 580)
	elif p < 2.15:
		var flash := clampf((p - 1.35) / 0.8, 0.0, 1.0)
		draw_circle(center, 80.0 + flash * 300.0, Color(0.94, 1.0, 0.78, 0.58 * (1.0 - flash * 0.35)))
		for i in 22:
			var a := float(i) * TAU / 22.0 + p * 8.0
			draw_line(center, center + Vector2(cos(a), sin(a)) * (100 + flash * 460), Color(1.0, 0.96, 0.75, 1.0 - flash), 3.0)
		_draw_falling_fireworks(center, p, 0.75)
		_text("灵现 · 契约正在凝结", Vector2(670, 850), 26, Color("fff6c5"), HORIZONTAL_ALIGNMENT_CENTER, 580)
	else:
		_draw_falling_fireworks(center, p, 1.0)
		_draw_completed_card(center)

func _draw_falling_fireworks(center: Vector2, p: float, strength: float) -> void:
	for i in 72:
		var seed := float(i * 71)
		var x := center.x + fposmod(seed * 13.0, 1040.0) - 520.0 + sin(p * 2.4 + seed) * 26.0
		var y := fposmod(seed * 19.0 + p * 175.0, 720.0) + 100.0
		var trail := 12.0 + fposmod(seed, 26.0)
		var color: Color = [Color("fff2a8"), Color("8fffe4"), Color("e0a6ff"), Color("ffbd70")][i % 4]
		draw_line(Vector2(x, y - trail), Vector2(x - sin(p + seed) * 7.0, y), Color(color, 0.28 * strength), 1.5)
		draw_circle(Vector2(x, y), 1.5 + float(i % 3), Color(color, 0.72 * strength))
	for burst in 7:
		var origin := center + Vector2(-300 + burst * 100, -120 + fmod(p * 30.0 + burst * 47.0, 110.0))
		for ray in 10:
			var a := float(ray) * TAU / 10.0 + p * 1.6 + burst
			draw_line(origin, origin + Vector2(cos(a), sin(a)) * 26.0, Color(1.0, 0.94, 0.66, 0.34 * strength), 1.2)

func _draw_completed_card(center: Vector2) -> void:
	var card := Rect2(center - Vector2(164, 252), Vector2(328, 486))
	var pulse := 0.5 + sin(time * 5.0) * 0.5
	draw_rect(card.grow(18), Color(0.57, 0.24, 0.92, 0.18 + pulse * 0.12))
	draw_rect(card, Color("17131feF"))
	draw_rect(card, Color("d6aa5c"), false, 5.0)
	draw_rect(card.grow(-10), Color("6943a8"), false, 2.0)
	var art_rect := Rect2(card.position + Vector2(20, 25), Vector2(card.size.x - 40, 284))
	draw_rect(art_rect, Color("0b1020"))
	if revealed_texture:
		draw_texture_rect_region(revealed_texture, art_rect, Rect2(Vector2.ZERO, revealed_texture.get_size()))
	draw_rect(Rect2(card.position + Vector2(20, 319), Vector2(card.size.x - 40, 58)), Color("251a20e8"))
	_text("新生灵契", card.position + Vector2(20, 326), 26, Color("fff0bd"), HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 40)
	_text(str(revealed_card.skill) + " · 完全体", card.position + Vector2(20, 357), 15, Color("b9a889"), HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 40)
	var values := [
		["攻", int(revealed_card.get("attack", 0))],
		["守", int(revealed_card.get("defense", 0))],
		["智", int(revealed_card.get("intelligence", 0))],
		["体", int(revealed_card.get("vitality", 0))],
		["灵", int(revealed_card.get("spirit", 0))]
	]
	for i in values.size():
		var x := card.position.x + 18.0 + (i % 3) * 98.0
		var y := card.position.y + 398.0 + (i / 3) * 42.0
		var stat := Rect2(x, y, 88, 35)
		draw_rect(stat, Color("16141a"))
		draw_rect(stat, Color("9d763f"), false, 1.0)
		_text(str(values[i][0]) + " " + str(values[i][1]), stat.position + Vector2(0, 5), 15, Color("fff0bf"), HORIZONTAL_ALIGNMENT_CENTER, stat.size.x)
	var talent: Dictionary = revealed_card.get("talent", {})
	_text(str(talent.get("label", "天赋")) + " " + str(talent.get("value", "")) + str(talent.get("unit", "")), card.position + Vector2(20, 476), 15, Color("fff0bf"), HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 40)

func _create_interaction_buttons() -> void:
	_add_hotspot(NAV_MAP, _go_map, "世界地图")
	_add_hotspot(NAV_HOME, _open_training, "打开修炼")
	_add_hotspot(NAV_CARDS, _go_cards, "灵契图鉴")
	_add_hotspot(NAV_BATTLE, _go_battle, "竞技场")
	_add_hotspot(ALTAR, _open_training, "选择修炼")
	for i in SKILL_RECTS.size():
		_add_hotspot(SKILL_RECTS[i], _choose_skill.bind(i), "选择" + skill_names[i])
	_add_hotspot(TRAIN_CONFIRM, _confirm_training, "确认修炼")

func _add_hotspot(rect: Rect2, action: Callable, tip: String) -> void:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.flat = true
	button.tooltip_text = tip
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color.TRANSPARENT)
	button.pressed.connect(action)
	add_child(button)

func _go_map() -> void:
	_leave("res://world_choice.tscn")

func _go_cards() -> void:
	_leave("res://spirit_codex.tscn")

func _go_battle() -> void:
	_leave("res://battle.tscn")

func _open_training() -> void:
	training_open = true
	focus = 3.0
	interaction_note = "选择灵兽本次修炼的天赋"
	interaction_until = time + 3.0

func _choose_skill(index: int) -> void:
	training_open = true
	selected_skill = skill_names[index]
	focus = 3.0

func _confirm_training() -> void:
	if selected_skill == "":
		interaction_note = "请先选择：智力、体力、灵力、魔力或耐力"
		interaction_until = time + 2.5
		return
	if not GameState.has_egg():
		GameState.egg_realm = GameState.active_realm
	GameState.start_training(selected_skill)
	training_open = false
	focus = 4.0
	ritual_text = selected_skill + " 修炼已开始 · 24 小时后将化为灵契卡牌"
	interaction_note = ritual_text
	interaction_until = time + 4.0

func _draw_training_modal() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.006, 0.02, 0.025, 0.68))
	var modal := Rect2(500, 260, 980, 510)
	_ornate_panel(modal, Color("082d2df8"), Color("dfbd6a"), 28)
	_text("选择修炼", Vector2(0, 292), 40, Color("fff0bd"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	_text("为灵兽选择一项核心天赋。确认后开始 24 小时孵化。", Vector2(0, 347), 19, Color("d6e6d4"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	for i in SKILL_RECTS.size():
		var rect: Rect2 = SKILL_RECTS[i]
		var active: bool = skill_names[i] == selected_skill
		var hovered: bool = rect.has_point(_pointer(get_viewport().get_mouse_position()))
		rect = UISkin.button(self, rect, hovered, active)
		_text(skill_names[i], rect.position + Vector2(0, 18), 27, Color("fff3c8"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
		_text(["提升思维", "提升体魄", "提升灵息", "提升术式", "提升韧性"][i], rect.position + Vector2(0, 52), 15, Color("d3e7dc"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
	UISkin.panel(self, TRAIN_CONFIRM, Color("d0a64f") if selected_skill != "" else Color("5a5b4d"), Color("fff0b8"), 16.0, 0.16, 6.0)
	_text("确认修炼 · 24 小时", TRAIN_CONFIRM.position + Vector2(0, 18), 23, Color("102523"), HORIZONTAL_ALIGNMENT_CENTER, TRAIN_CONFIRM.size.x)

func _draw_side_panels() -> void:
	var left := Rect2(52, 300, 270, 398)
	var right := Rect2(1604, 300, 270, 398)
	for panel in [left, right]:
		_ornate_panel(panel, Color("06362ff4"), Color("d1b366"), 24)
		draw_rect(Rect2(panel.position + Vector2(16, 62), Vector2(panel.size.x - 32, 2)), Color("d1b366", 0.38))
	_text("培育档案", left.position + Vector2(22, 20), 25, Color("f8dfa0"))
	_text("07", left.position + Vector2(24, 62), 54, Color("ffe6a1"))
	_text("已缔结灵契", left.position + Vector2(92, 86), 17, Color("d2e3d3"))
	for i in 3:
		var y := 146.0 + i * 58.0
		UISkin.panel(self, Rect2(left.position + Vector2(18, y), Vector2(234, 38)), Color("123b35e8"), Color("5f9c88"), 10.0, 0.03, 4.0)
		_text(["家园等级 · 壹·初阶", "灵息浓度 · 充盈 ↑", "环境加成 · 孵化速度 +5%"][i], left.position + Vector2(30, y + 6), 16, Color("e4ebd6"))
	_text("培育指南", right.position + Vector2(22, 20), 25, Color("f8dfa0"))
	draw_circle(right.position + Vector2(135, 136), 52, Color("e5c66d"))
	_text("☯", right.position + Vector2(100, 90), 62, Color("183834"))
	_text("万物皆有灵", right.position + Vector2(52, 202), 24, Color("fff0c4"), HORIZONTAL_ALIGNMENT_CENTER, 170)
	_text("不同境域的灵契孕育不同成长。", right.position + Vector2(28, 244), 16, Color("d7e5d7"))
	_text("静守灵息，让生命在共鸣中苏醒。", right.position + Vector2(28, 274), 16, Color("d7e5d7"))

func _ornate_panel(rect: Rect2, fill: Color, border: Color, radius: int) -> void:
	var outer := StyleBoxFlat.new()
	outer.bg_color = fill
	outer.border_color = border
	outer.set_border_width_all(2)
	outer.set_corner_radius_all(radius)
	outer.shadow_color = Color(0.0, 0.0, 0.0, 0.52)
	outer.shadow_size = 18
	outer.shadow_offset = Vector2(0, 9)
	draw_style_box(outer, rect)
	var inner := StyleBoxFlat.new()
	inner.bg_color = Color(0.07, 0.42, 0.34, 0.12)
	inner.border_color = Color(border, 0.26)
	inner.set_border_width_all(1)
	inner.set_corner_radius_all(maxi(8, radius - 9))
	draw_style_box(inner, rect.grow(-10))
	draw_line(rect.position + Vector2(radius, 13), rect.position + Vector2(rect.size.x - radius, 13), Color("fff0bd", 0.34), 1.0)
	draw_circle(rect.position + Vector2(22, 22), 3.0, Color("ffe39a", 0.9))

func _draw_transition() -> void:
	var p := clampf(transition / 0.78, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.02, 0.16, 0.13, p))
	for i in 24:
		var a: float = float(i) * TAU / 24.0 + time * 2.0
		draw_line(Vector2(960, 540), Vector2(960, 540) + Vector2(cos(a), sin(a)) * lerpf(90.0, 1400.0, p), Color(0.82, 1.0, 0.72, 1.0 - p), 2.0)

func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 33:
		var a: float = TAU * float(i) / 32.0
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(points, color)

func _text(value: String, pos: Vector2, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var scaled_size: int = int(round(float(size) * GameState.ui_font_scale))
	draw_string(font, pos + Vector2(0, float(scaled_size)), value, align, width, scaled_size, Color(color, color.a * GameState.ui_opacity))

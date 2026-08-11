extends Node2D

const GameState = preload("res://game_state.gd")

const VIEW := Vector2(1920, 1080)
const REALM_BUTTONS := [Rect2(250, 325, 300, 320), Rect2(680, 195, 300, 320), Rect2(1110, 325, 300, 320), Rect2(1460, 625, 300, 320)]
const KEYS := ["human", "demon", "celestial", "underworld"]
const LABELS := ["烟火人界", "赤烬魔域", "九霄仙界", "幽冥冥界"]
var font: Font
var map: Texture2D
var entrance: Texture2D
var time := 0.0
var hover := -1
var transition := 0.0
var chosen := -1

func _ready() -> void:
	font = GameState.font_for(load("res://fonts/NotoSansSC-VF.ttf"))
	map = load("res://picture/four-realms-map.png")
	entrance = load("res://picture/Entrance1-alpha.png")
	AudioDirector.play_music("res://music/Glass Orbit.mp3", -18.0)
	AudioDirector.stop_ambience()
	set_process_input(true)

func _process(delta: float) -> void:
	time += delta
	if chosen >= 0:
		transition += delta
		if transition >= 0.86: get_tree().change_scene_to_file("res://demon_realm.tscn")
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		GameState.admin_return_scene = get_tree().current_scene.scene_file_path
		get_tree().change_scene_to_file("res://admin.tscn")
		return
	if event is InputEventMouseMotion:
		hover = _at(event.position * (VIEW / get_viewport_rect().size))
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and chosen < 0:
		var found := _at(event.position * (VIEW / get_viewport_rect().size))
		if found >= 0:
			chosen = found
			GameState.active_realm = KEYS[found]
			AudioDirector.play_sfx("res://music/fire-onset-1-386711.mp3", -12.0, 0.92 + found * 0.04)
			AudioDirector.play_sfx("res://music/射箭声.mp3", -17.0, 0.92 + found * 0.04)

func _at(point: Vector2) -> int:
	for i in REALM_BUTTONS.size():
		if REALM_BUTTONS[i].grow(20).has_point(point): return i
	return -1

func _draw() -> void:
	var size := VIEW * (1.06 + sin(time * 0.1) * 0.02)
	if map: draw_texture_rect(map, Rect2((VIEW - size) * 0.5, size), false)
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.015, 0.018, 0.04, 0.47))
	_text("四界舆图", Vector2(0, 76), 50, Color("fff0c4"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	_text("接受山隐老人的委托，选择一界镇压妖祟", Vector2(0, 138), 18, Color("d7d2c0"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	for i in REALM_BUTTONS.size(): _draw_realm(i)
	if chosen >= 0:
		var p := clampf(transition / 0.86, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.95, 0.53, 0.25, p * 0.66))
		_text("界门开启 · " + LABELS[chosen], Vector2(0, 505), 42, Color(1, 0.96, 0.78, p), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)

func _draw_realm(index: int) -> void:
	var rect: Rect2 = REALM_BUTTONS[index]
	var active := index == hover
	var color: Color = [Color("47c88b"), Color("ff654a"), Color("68d9ff"), Color("af6cff")][index]
	var center := rect.get_center() + Vector2(0, -20.0 if active else 0.0)
	var pulse := 0.5 + sin(time * (2.0 + index * 0.17) + index) * 0.5
	var radius := 126.0 + (12.0 if active else 0.0) + pulse * 5.0
	# The selectable area stays generous, but the visual is a living realm gate rather than a card.
	_draw_gate_pedestal(center, color, pulse, active)
	draw_circle(center, radius + 44.0 + pulse * 18.0, Color(color, 0.055 + (0.055 if active else 0.0)))
	draw_circle(center, radius, Color(color, 0.15 + pulse * 0.06))
	for ring in 3:
		var start := time * (0.45 + ring * 0.16) + ring * 1.7
		draw_arc(center, radius + 14.0 + ring * 15.0, start, start + 1.78, 28, Color(color, 0.58), 2.2)
		_draw_rune(center, radius + 14.0 + ring * 15.0, start, color)
	if entrance:
		var gate_scale := 1.0 + (0.08 if active else 0.0) + pulse * 0.018
		var gate_size := Vector2(238, 292) * gate_scale
		# The source art stays crisp; Godot-generated depth layers make each entrance feel embedded in the world.
		draw_texture_rect(entrance, Rect2(center - Vector2(gate_size.x * 0.5, gate_size.y * 0.68) + Vector2(8, 18), gate_size), false, Color(0.01, 0.04, 0.07, 0.46))
		draw_texture_rect(entrance, Rect2(center - Vector2(gate_size.x * 0.5, gate_size.y * 0.68), gate_size), false, Color.WHITE)
	else:
		var diamond := PackedVector2Array([center + Vector2(0, -42), center + Vector2(42, 0), center + Vector2(0, 42), center + Vector2(-42, 0)])
		draw_colored_polygon(diamond, Color(color, 0.20 + pulse * 0.08))
		draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color(color, 0.9), 2.0, true)
	_text(["人界 · 01", "魔界 · 02", "仙界 · 03", "冥界 · 04"][index], center + Vector2(-150, 154), 15, Color("e8ce90"), HORIZONTAL_ALIGNMENT_CENTER, 300)
	_text(LABELS[index], center + Vector2(-155, 179), 30, Color("fff0c8"), HORIZONTAL_ALIGNMENT_CENTER, 310)
	_text(["烟火守望 · 百妖潜行", "赤月坠落 · 炎灵躁动", "浮岛云海 · 仙兽失控", "忘川裂隙 · 幽魂苏醒"][index], center + Vector2(-155, 222), 15, Color("d1d2c8"), HORIZONTAL_ALIGNMENT_CENTER, 310)
	_text("触碰界门", center + Vector2(-155, 254), 15, color, HORIZONTAL_ALIGNMENT_CENTER, 310)

func _draw_gate_pedestal(center: Vector2, color: Color, pulse: float, active: bool) -> void:
	var lift := 5.0 if active else 0.0
	# Ground shadow and three flattened rings establish perspective before the upright gate artwork is drawn.
	_ellipse(center + Vector2(0, 134 + lift), Vector2(142, 27), Color(0.0, 0.01, 0.025, 0.64))
	_ellipse(center + Vector2(0, 121 + lift), Vector2(124, 22), Color(0.03, 0.09, 0.12, 0.72))
	_ellipse(center + Vector2(0, 116 + lift), Vector2(108, 18), Color(color, 0.22 + pulse * 0.08))
	for i in 3:
		var radii := Vector2(84.0 + float(i) * 23.0 + pulse * 4.0, 13.0 + float(i) * 4.0)
		_draw_ellipse_outline(center + Vector2(0, 112 + lift), radii, Color(color, 0.72 - float(i) * 0.14), 1.8)
	for i in 8:
		var a := float(i) * TAU / 8.0 + time * (0.8 + float(i % 2) * 0.2)
		var p := center + Vector2(cos(a) * (99.0 + pulse * 8.0), sin(a) * 18.0 + 112.0 + lift)
		draw_circle(p, 2.6, Color("fff0a3", 0.72))

func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 33:
		var a := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(points, color)

func _draw_ellipse_outline(center: Vector2, radii: Vector2, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for i in 41:
		var a := TAU * float(i) / 40.0
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_polyline(points, color, width, true)

func _draw_rune(center: Vector2, radius: float, angle: float, color: Color) -> void:
	var pos := center + Vector2(cos(angle), sin(angle)) * radius
	draw_circle(pos, 4.0, Color(color, 0.9))
	draw_line(pos - Vector2(6, 0), pos + Vector2(6, 0), Color("fff0b0"), 1.0)

func _text(value: String, pos: Vector2, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var scaled_size: int = int(round(float(size) * GameState.ui_font_scale))
	draw_string(font, pos + Vector2(0, float(scaled_size)), value, align, width, scaled_size, Color(color, color.a * GameState.ui_opacity))

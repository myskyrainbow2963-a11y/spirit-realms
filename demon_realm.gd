extends Node2D

const GameState = preload("res://game_state.gd")

const VIEW := Vector2(1920, 1080)
const NAV_MAP := Rect2(780, 14, 126, 52)
const NAV_HOME := Rect2(915, 14, 126, 52)
const NAV_CARDS := Rect2(1050, 14, 144, 52)
const NAV_BATTLE := Rect2(1205, 14, 130, 52)
const EGG_RECT := Rect2(815, 360, 290, 390)
const HOME_BUTTON := Rect2(1500, 793, 300, 66)
const WORLD_BUTTON := Rect2(1710, 78, 200, 90)
const ENVOY_ACTION_ZONE := Rect2(1280, 650, 600, 280)

var font: Font
var title_font: Font
var world: Texture2D
var messenger: Texture2D
var egg_texture: Texture2D
var realm_data: Dictionary
var time := 0.0
var egg_claimed := false
var notice := "赤月正在召唤与你缔结灵契的生命。"
var notice_until := 0.0
var transition_target := ""
var transition_started := 0.0
var embers: Array[Dictionary] = []

func _ready() -> void:
	AudioDirector.play_music("res://music/Crimson Resolve.mp3", -17.0)
	AudioDirector.play_ambience("res://music/树木燃烧火焰声.mp3", -31.0)
	font = GameState.font_for(load("res://fonts/NotoSansSC-VF.ttf"))
	title_font = GameState.font_for(load("res://fonts/NotoSansSC-VF.ttf"))
	world = load("res://picture/four-realms-map.png")
	realm_data = GameState.realm()
	messenger = load(str(realm_data.messenger_art))
	egg_texture = load(str(realm_data.egg_art))
	set_process_input(true)
	for i in 90:
		embers.append({"x":fposmod(float(i * 83), VIEW.x), "y":fposmod(float(i * 131), VIEW.y), "speed":22.0 + i % 5 * 13.0, "size":1.5 + i % 4})
	queue_redraw()

func _process(delta: float) -> void:
	time += delta
	if transition_target != "" and time - transition_started >= 0.72:
		if transition_target == "battle": get_tree().change_scene_to_file("res://battle.tscn")
		elif transition_target == "home": get_tree().change_scene_to_file("res://cloud_roost.tscn")
		elif transition_target == "cards": get_tree().change_scene_to_file("res://spirit_codex.tscn")
		transition_target = ""
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		GameState.admin_return_scene = get_tree().current_scene.scene_file_path
		get_tree().change_scene_to_file("res://admin.tscn")
		return
	if event is InputEventMouseMotion:
		queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and transition_target == "":
		var p := _canvas_pointer(event.position)
		if NAV_BATTLE.has_point(p):
			_start_transition("battle")
		elif NAV_HOME.has_point(p) or HOME_BUTTON.has_point(p):
			_start_transition("home")
		elif NAV_CARDS.has_point(p):
			_start_transition("cards")
		elif NAV_MAP.has_point(p) or WORLD_BUTTON.has_point(p):
			_open_world_map()
		elif EGG_RECT.has_point(p) or ENVOY_ACTION_ZONE.has_point(p):
			egg_claimed = true
			GameState.receive_egg()
			notice = "灵兽蛋回应了你的灵息，赤月火星在蛋壳上流转。"
			notice_until = time + 2.4
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B: _start_transition("battle")
		if event.keycode == KEY_SPACE:
			egg_claimed = true
			GameState.receive_egg()
			notice = "灵息注入完成。"
			notice_until = time + 2.0

func _canvas_pointer(pointer: Vector2) -> Vector2:
	var raw := pointer
	var scaled := pointer * (VIEW / get_viewport_rect().size)
	if _is_clickable(raw): return raw
	if _is_clickable(scaled): return scaled
	return scaled

func _is_clickable(p: Vector2) -> bool:
	return NAV_MAP.has_point(p) or NAV_HOME.has_point(p) or NAV_CARDS.has_point(p) or NAV_BATTLE.has_point(p) or WORLD_BUTTON.has_point(p) or EGG_RECT.has_point(p) or HOME_BUTTON.has_point(p) or ENVOY_ACTION_ZONE.has_point(p)

func _start_transition(target: String) -> void:
	AudioDirector.play_sfx("res://music/火焰燃起声.mp3", -11.0, 1.0)
	transition_target = target
	transition_started = time

func _open_world_map() -> void:
	# Delay the scene replacement until the current mouse event has fully completed.
	# This prevents an input-time scene teardown on Windows builds.
	get_tree().call_deferred("change_scene_to_file", "res://world_choice.tscn")

func _draw() -> void:
	_draw_world()
	_draw_embers()
	_draw_navigation()
	_draw_title()
	_draw_egg_altar()
	_draw_story()
	_draw_envoy_panel()
	if time < notice_until:
		_draw_text(notice, Vector2(470, 1000), 18, Color("ffe5ad"), HORIZONTAL_ALIGNMENT_CENTER, 980)
	if transition_target != "": _draw_transition()

func _draw_world() -> void:
	var zoom := 1.045 + sin(time * 0.16) * 0.018
	var size := VIEW * zoom
	var rect := Rect2((VIEW - size) * 0.5 + Vector2(sin(time * 0.11) * 12.0, cos(time * 0.08) * 7.0), size)
	if world: draw_texture_rect(world, rect, false)
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.025, 0.018, 0.03, 0.46))
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.06, 0.17, 0.65, GameState.blue_tone * 0.24))
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.27, 0.035, 0.018, 0.16))
	draw_rect(Rect2(0, 0, VIEW.x, 190), Color(0.02, 0.03, 0.05, 0.36))
	draw_rect(Rect2(0, 750, VIEW.x, 330), Color(0.01, 0.012, 0.02, 0.48))

func _draw_embers() -> void:
	for ember in embers:
		var y := fposmod(ember.y - time * ember.speed, 900.0) + 90.0
		var x: float = float(ember.x) + sin(time * 1.7 + float(ember.y)) * 18.0
		var pulse := 0.45 + sin(time * 3.1 + ember.x) * 0.25
		draw_circle(Vector2(x, y), ember.size, Color(1.0, 0.38, 0.12, pulse))

func _draw_navigation() -> void:
	draw_rect(Rect2(0, 0, VIEW.x, 74), Color("102c2be8"))
	draw_line(Vector2(0, 73), Vector2(VIEW.x, 73), Color("b79756"), 1.0)
	_draw_text("契", Vector2(48, 15), 34, Color("e7c77f"))
	_draw_text("四界灵契", Vector2(96, 17), 23, Color("f4e6bf"))
	_draw_text("SPIRIT REALMS", Vector2(98, 43), 10, Color("9cae99"))
	_draw_nav(NAV_MAP, "世界地图", true)
	_draw_nav(NAV_HOME, "云栖小筑")
	_draw_nav(NAV_CARDS, "灵契图鉴  15")
	_draw_nav(NAV_BATTLE, "竞技场")
	_draw_text("✦ 750", Vector2(1770, 23), 17, Color("d9ad55"))
	_draw_text("♫", Vector2(1848, 21), 22, Color("e1d5ab"))

func _draw_nav(rect: Rect2, label: String, active := false) -> void:
	if active:
		_glass_panel(rect, Color(0.62, 0.43, 0.13, 0.27), Color("d4ba70"), 18)
	_draw_text(label, rect.position + Vector2(0, 13), 17, Color("f4dfab") if active else Color("d5d7c2"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)

func _draw_title() -> void:
	_draw_text("SPIRIT REALM  ·  01", Vector2(72, 100), 14, Color("e0b86c"))
	_draw_title_text(str(realm_data.name), Vector2(70, 128), 60, Color("ffebbf"))
	_draw_text(str(realm_data.subtitle), Vector2(73, 198), 17, Color("dbc5a0"))
	_draw_button(Rect2(1750, 100, 140, 42), "‹  四界舆图", Color("1b2025d9"), Color("c29d58"))

func _draw_egg_altar() -> void:
	var pulse := sin(time * 2.3) * 0.5 + 0.5
	var center := Vector2(960, 555 + sin(time * 1.6) * 12)
	draw_circle(center + Vector2(0, 86), 154 + pulse * 20, Color(0.85, 0.1, 0.05, 0.10))
	for ring in 3:
		draw_arc(center + Vector2(0, 86), 108 + ring * 20, time * (0.8 + ring * 0.3), time * (0.8 + ring * 0.3) + 4.8, 42, Color(1.0, 0.48, 0.17, 0.30), 2.0)
	draw_arc(center + Vector2(0, 115), 92, PI, TAU, 32, Color("c0764b"), 3.0)
	_draw_egg(center, pulse)
	_draw_text("来自魔界 · 生命波动稳定", Vector2(810, 750), 15, Color("e3c39b"), HORIZONTAL_ALIGNMENT_CENTER, 300)

func _draw_egg(center: Vector2, pulse: float) -> void:
	draw_circle(center, 70 + pulse * 5, Color(1.0, 0.67, 0.36, 0.17))
	if egg_texture:
		# Repeated opaque passes keep the realm egg solid even when the source matte has soft alpha.
		for layer in 3:
			draw_texture_rect(egg_texture, Rect2(center - Vector2(62, 80), Vector2(124, 160)), false, Color.WHITE)
		return
	_draw_ellipse(center, Vector2(46, 64), Color("e9d7ae"))
	_draw_ellipse(center + Vector2(-12, -8), Vector2(18, 25), Color("fff5d6"))
	draw_arc(center, 46, 0.2, 5.8, 28, Color("7b3228"), 4.0)
	draw_circle(center + Vector2(5, 22), 4, Color("9b4837"))
	draw_circle(center + Vector2(-16, 30), 3, Color("9b4837"))
	if egg_claimed:
		for i in 6:
			var a := time * 2.6 + i * TAU / 6
			draw_circle(center + Vector2(cos(a), sin(a)) * 92, 4, Color("ffd47b"))

func _draw_story() -> void:
	draw_line(Vector2(74, 852), Vector2(74, 978), Color("d0a54e"), 3.0)
	_draw_text("主线际遇", Vector2(100, 853), 13, Color("daa95d"))
	_draw_text("越过赤月之门", Vector2(100, 884), 31, Color("fff0c9"))
	_draw_text("空气里有硫磺与夜昙的气味。断碑之前，", Vector2(100, 928), 15, Color("d3c2a6"))
	_draw_text("戴着骨面具的使者已经等候多时。", Vector2(100, 954), 15, Color("d3c2a6"))

func _draw_envoy_panel() -> void:
	var actor_rect := Rect2(1310, 98 + sin(time * 1.4) * 8.0, 520, 620)
	if messenger:
		draw_circle(actor_rect.get_center() + Vector2(0, 196), 112, Color(0.96, 0.47, 0.20, 0.10))
		var tint := Color(1, 1, 1, GameState.character_opacity)
		if GameState.active_realm == "demon":
			draw_texture_rect_region(messenger, actor_rect, Rect2(450, 0, 1050, 1000), tint)
		elif GameState.active_realm == "celestial":
			# Preserve the portrait aspect ratio; the original 520px panel made this envoy appear too wide.
			var celestial_rect := Rect2(1370, 98 + sin(time * 1.4) * 8.0, 405, 620)
			draw_texture_rect(messenger, celestial_rect, false, tint)
		else:
			draw_texture_rect(messenger, actor_rect, false, tint)
	_draw_text("界域使者", Vector2(1420, 156), 17, Color("e8c47a"))
	_draw_text(str(realm_data.messenger), Vector2(1420, 183), 38, Color("fff0c8"))
	_draw_text("“玉佩选择了你。灵兽的真形，将因你的抉择显露。”", Vector2(1365, 704), 17, Color("eee2cc"), HORIZONTAL_ALIGNMENT_CENTER, 470)
	_draw_text("灵兽蛋已收入行囊", Vector2(1365, 740), 17, Color("9fe0b5"), HORIZONTAL_ALIGNMENT_CENTER, 470)
	_draw_button(HOME_BUTTON, "返回云栖小筑     ›", Color("a9432f"), Color("f0be78"))

func _draw_transition() -> void:
	var progress := clampf((time - transition_started) / 0.72, 0.0, 1.0)
	var center := Vector2(960, 540)
	draw_circle(center, lerpf(20.0, 1600.0, progress), Color(0.98, 0.51, 0.23, progress * 0.82))
	for i in 20:
		var a := i * TAU / 20.0 + time * 3.0
		draw_line(center, center + Vector2(cos(a), sin(a)) * lerpf(80.0, 1280.0, progress), Color(1.0, 0.85, 0.54, 1.0 - progress), 2.0)

func _draw_button(rect: Rect2, label: String, fill: Color, line: Color) -> void:
	_glass_panel(rect, fill, line, 18)
	_draw_text(label, rect.position + Vector2(0, 17), 18, Color("fff0ca"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)

func _glass_panel(rect: Rect2, fill: Color, border: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.36)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	draw_style_box(style, rect)

func _draw_title_text(value: String, pos: Vector2, size: int, color: Color) -> void:
	var scaled_size: int = int(round(float(size) * GameState.ui_font_scale))
	draw_string(title_font, pos + Vector2(0, float(scaled_size)), value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, scaled_size, Color(color, color.a * GameState.ui_opacity))

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 40:
		var a: float = TAU * float(i) / 40.0
		points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(points, color)

func _draw_text(text: String, pos: Vector2, size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var scaled_size: int = int(round(float(size) * GameState.ui_font_scale))
	draw_string(font, pos + Vector2(0, float(scaled_size)), text, alignment, width, scaled_size, Color(color, color.a * GameState.ui_opacity))

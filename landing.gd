extends Node2D

const GameState = preload("res://game_state.gd")
const UISkin = preload("res://ui_skin.gd")

const VIEW := Vector2(1920, 1080)
const ENTER_BUTTON := Rect2(86, 894, 145, 55)
const CODEX_BUTTON := Rect2(244, 894, 145, 55)
const NAV_MAP := Rect2(780, 14, 126, 52)
const NAV_HOME := Rect2(915, 14, 126, 52)
const NAV_CARDS := Rect2(1050, 14, 144, 52)
const NAV_BATTLE := Rect2(1205, 14, 130, 52)

var font: Font
var cover: Texture2D
var time := 0.0
var intro := 0.0
var transition := 0.0
var destination := ""
var sparkles: Array[Dictionary] = []

func _ready() -> void:
	font = GameState.font_for(load("res://fonts/NotoSansSC-VF.ttf"))
	cover = load("res://picture/cover.webp")
	AudioDirector.play_music("res://music/Moonlit Oath.mp3", -19.0)
	AudioDirector.play_ambience("res://music/森林鸟叫声短.mp3", -32.0)
	set_process_input(true)
	for i in 96:
		sparkles.append({"x": fposmod(float(i * 163), VIEW.x), "y": fposmod(float(i * 89), VIEW.y), "speed": 8.0 + i % 6 * 2.5, "size": 1.0 + i % 3})

func _process(delta: float) -> void:
	time += delta
	intro = minf(1.0, intro + delta * 0.55)
	if destination != "":
		transition += delta
		if transition >= 0.92: get_tree().change_scene_to_file(destination)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if _open_admin_hotkey(event): return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and destination == "":
		var p: Vector2 = _pointer(event.position)
		if ENTER_BUTTON.has_point(p) or NAV_MAP.has_point(p): _leave("res://elder.tscn")
		elif CODEX_BUTTON.has_point(p) or NAV_CARDS.has_point(p): _leave("res://spirit_codex.tscn")
		elif NAV_HOME.has_point(p): _leave("res://cloud_roost.tscn")
		elif NAV_BATTLE.has_point(p): _leave("res://battle.tscn")
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE: _leave("res://elder.tscn")

func _pointer(pointer: Vector2) -> Vector2:
	var scaled: Vector2 = pointer * (VIEW / get_viewport_rect().size)
	if ENTER_BUTTON.has_point(pointer) or CODEX_BUTTON.has_point(pointer) or NAV_MAP.has_point(pointer) or NAV_HOME.has_point(pointer) or NAV_CARDS.has_point(pointer) or NAV_BATTLE.has_point(pointer): return pointer
	return scaled

func _leave(scene: String) -> void:
	destination = scene
	transition = 0.01

func _open_admin_hotkey(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		GameState.admin_return_scene = get_tree().current_scene.scene_file_path
		get_tree().change_scene_to_file("res://admin.tscn")
		return true
	return false

func _draw() -> void:
	_draw_background()
	_draw_ambient()
	_draw_nav()
	_draw_story()
	if destination != "": _draw_transition()

func _draw_background() -> void:
	var zoom := 1.14 + sin(time * 0.08) * 0.025
	var size := VIEW * zoom
	var rect := Rect2((VIEW - size) * 0.5 + Vector2(sin(time * 0.09) * 12.0, cos(time * 0.11) * 8.0), size)
	if cover: draw_texture_rect(cover, rect, false)
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.01, 0.09, 0.08, 0.28))
	for i in 4:
		draw_circle(Vector2(1250 + i * 105, 190 + sin(time * 0.7 + i) * 35), 260 + i * 45, Color(0.86, 0.88, 0.47, 0.025))
	draw_rect(Rect2(0, 588, VIEW.x, 492), Color(0.005, 0.022, 0.025, 0.37))
	draw_rect(Rect2(0, 0, 640, VIEW.y), Color(0.008, 0.032, 0.035, 0.31))

func _draw_ambient() -> void:
	for mote in sparkles:
		var x: float = float(mote.x) + sin(time * 0.9 + float(mote.y)) * 22.0
		var y: float = fposmod(float(mote.y) - time * float(mote.speed), 920.0) + 95.0
		var alpha := 0.16 + sin(time * 2.0 + float(mote.x)) * 0.10
		draw_circle(Vector2(x, y), float(mote.size), Color(1.0, 0.91, 0.55, alpha))
	var ribbon := 0.5 + sin(time * 1.2) * 0.5
	draw_arc(Vector2(1160, 560), 390 + ribbon * 25, -2.6, -0.45, 52, Color(0.7, 0.95, 0.75, 0.10), 2.0)

func _draw_nav() -> void:
	UISkin.panel(self, Rect2(18, 8, VIEW.x - 36, 60), Color("102c2bea"), Color("b79756"), 18.0, 0.08, 6.0)
	draw_line(Vector2(0, 73), Vector2(VIEW.x, 73), Color("b79756"), 1.0)
	_text("契", Vector2(48, 15), 34, Color("e7c77f"))
	_text("四界灵契", Vector2(96, 17), 23, Color("f4e6bf"))
	_text("SPIRIT REALMS", Vector2(98, 43), 10, Color("9cae99"))
	_nav(NAV_MAP, "世界地图")
	_nav(NAV_HOME, "云栖小筑")
	_nav(NAV_CARDS, "灵契图鉴  15")
	_nav(NAV_BATTLE, "竞技场")
	_text("✦ 750", Vector2(1770, 23), 17, Color("d9ad55"))
	_text("♫", Vector2(1848, 21), 22, Color("e1d5ab"))

func _nav(rect: Rect2, label: String) -> void:
	if rect.has_point(_pointer(get_viewport().get_mouse_position())):
		UISkin.button(self, rect, true, false)
	_text(label, rect.position + Vector2(0, 13), 17, Color("d5d7c2"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)

func _draw_story() -> void:
	var title_alpha := smoothstep(0.05, 0.65, intro)
	var body_alpha := smoothstep(0.35, 0.95, intro)
	_text("东方幻想 · 灵兽养成 · 策略卡牌", Vector2(88, 701), 14, Color(0.88, 0.70, 0.34, title_alpha))
	_text("四界灵契", Vector2(86, 730), 78, Color(1.0, 0.93, 0.75, title_alpha))
	_text("山风捎来一封没有署名的信，沉睡的古玉在掌心发亮。", Vector2(88, 833), 18, Color(0.92, 0.91, 0.80, body_alpha))
	_text("跨过人、魔、仙、冥四界，与你命中注定的灵兽缔结契约。", Vector2(88, 864), 18, Color(0.92, 0.91, 0.80, body_alpha))
	_draw_button(ENTER_BUTTON, "踏入四界", true, body_alpha)
	_draw_button(CODEX_BUTTON, "查看灵契", false, body_alpha)
	_text("ENTER  ·  启程", Vector2(87, 971), 13, Color(0.78, 0.82, 0.72, body_alpha))

func _draw_button(rect: Rect2, label: String, primary: bool, alpha: float) -> void:
	var hovered := rect.has_point(_pointer(get_viewport().get_mouse_position()))
	var painted := UISkin.button(self, rect, hovered, primary)
	var text_color := Color(0.06, 0.16, 0.15, alpha) if primary else Color(0.92, 0.93, 0.82, alpha)
	_text(label, painted.position + Vector2(0, 15), 19, text_color, HORIZONTAL_ALIGNMENT_CENTER, painted.size.x)

func _draw_transition() -> void:
	var p := clampf(transition / 0.92, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.72, 0.89, 0.64, p * 0.56))
	for i in 44:
		var a: float = float(i) * TAU / 44.0 + time * 2.0
		draw_line(Vector2(1080, 530), Vector2(1080, 530) + Vector2(cos(a), sin(a)) * lerpf(35.0, 1520.0, p), Color(1.0, 0.96, 0.68, 1.0 - p), 2.0)
	_text("灵契之门 · 开启", Vector2(700, 492), 36, Color(1.0, 0.98, 0.82, p), HORIZONTAL_ALIGNMENT_CENTER, 520)

func _text(value: String, pos: Vector2, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var scaled_size: int = int(round(float(size) * GameState.ui_font_scale))
	draw_string(font, pos + Vector2(0, float(scaled_size)), value, align, width, scaled_size, Color(color, color.a * GameState.ui_opacity))

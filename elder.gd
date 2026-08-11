extends Node2D

const GameState = preload("res://game_state.gd")

const VIEW := Vector2(1920, 1080)
const ACCEPT := Rect2(730, 795, 230, 62)
const LEAVE := Rect2(980, 795, 180, 62)
var font: Font
var background: Texture2D
var elder: Texture2D
var time := 0.0
var transition := 0.0
var leaving := false

func _ready() -> void:
	font = GameState.font_for(load("res://fonts/NotoSansSC-VF.ttf"))
	background = load("res://picture/cover.webp")
	elder = load("res://picture/oldman1-solid.png")
	set_process_input(true)

func _process(delta: float) -> void:
	time += delta
	if leaving:
		transition += delta
		if transition >= 0.8: get_tree().change_scene_to_file("res://world_choice.tscn")
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		GameState.admin_return_scene = get_tree().current_scene.scene_file_path
		get_tree().change_scene_to_file("res://admin.tscn")
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not leaving:
		var p: Vector2 = event.position * (VIEW / get_viewport_rect().size)
		if ACCEPT.has_point(p):
			GameState.quest_accepted = true
			leaving = true
		elif LEAVE.has_point(p): get_tree().change_scene_to_file("res://landing.tscn")

func _draw() -> void:
	if background: draw_texture_rect(background, Rect2(-60, -40, 2040, 1160), false)
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.015, 0.04, 0.05, 0.58))
	for i in 70:
		var x: float = fposmod(float(i * 107), VIEW.x)
		var y: float = fposmod(float(i * 77) - time * 15.0, 900.0) + 80.0
		draw_circle(Vector2(x, y), 1.5 + i % 3, Color(0.93, 0.79, 0.40, 0.22))
	if elder:
		var bob := sin(time * 1.4) * 7.0
		draw_circle(Vector2(1170, 540 + bob), 270, Color(0.94, 0.75, 0.32, 0.10))
		draw_texture_rect(elder, Rect2(890, 150 + bob, 570, 690), false, Color(1, 1, 1, GameState.character_opacity))
	_dialogue_panel(Rect2(180, 570, 860, 260))
	_text("山隐老人", Vector2(220, 603), 19, Color("dbbd74"))
	_text("你终于来了，灵契使。", Vector2(220, 645), 36, Color("fff0c7"))
	_text("四界的裂隙正在滋生怪物。前往其中一界，", Vector2(220, 704), 20, Color("d7d4c1"))
	_text("击退它们；使者会把沉睡的灵兽蛋交予你。", Vector2(220, 737), 20, Color("d7d4c1"))
	_button(ACCEPT, "接受委托 · 选择四界", true)
	_button(LEAVE, "稍后再说", false)
	if leaving:
		var p := clampf(transition / 0.8, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.75, 0.86, 0.63, p * 0.7))

func _button(rect: Rect2, label: String, primary: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("d6a94f") if primary else Color("152b2dda")
	style.border_color = Color("fff0bd") if primary else Color("c8e2d2")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	draw_style_box(style, rect)
	draw_line(rect.position + Vector2(18, 10), rect.position + Vector2(rect.size.x - 18, 10), Color("fff5c6", 0.38), 1.0)
	_text(label, rect.position + Vector2(0, 17), 19, Color("132322") if primary else Color("f5e6bd"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)

func _dialogue_panel(rect: Rect2) -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("091b25f2")
	panel.border_color = Color("d4ae5e")
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(26)
	panel.shadow_color = Color(0, 0, 0, 0.60)
	panel.shadow_size = 22
	panel.shadow_offset = Vector2(0, 10)
	draw_style_box(panel, rect)
	var inner := StyleBoxFlat.new()
	inner.bg_color = Color(0.10, 0.30, 0.33, 0.20)
	inner.border_color = Color("f9dfa0", 0.22)
	inner.set_border_width_all(1)
	inner.set_corner_radius_all(18)
	draw_style_box(inner, rect.grow(-12))
	draw_line(rect.position + Vector2(36, 56), rect.position + Vector2(rect.size.x - 36, 56), Color("d4ae5e", 0.38), 1.0)
	draw_circle(rect.position + Vector2(28, 28), 4, Color("ffe29a"))

func _text(value: String, pos: Vector2, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var scaled_size: int = int(round(float(size) * GameState.ui_font_scale))
	draw_string(font, pos + Vector2(0, float(scaled_size)), value, align, width, scaled_size, Color(color, color.a * GameState.ui_opacity))

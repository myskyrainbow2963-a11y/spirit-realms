extends Node2D

const GameState = preload("res://game_state.gd")

const VIEW := Vector2(1920, 1080)
const PAGE_SIZE := 12
const BACK := Rect2(72, 930, 170, 58)
const PREV := Rect2(1410, 930, 160, 58)
const NEXT := Rect2(1600, 930, 160, 58)
var font: Font
var files: Array[String] = []
var page := 0
var time := 0.0
var background: Texture2D

func _ready() -> void:
	font = GameState.font_for(load("res://fonts/NotoSansSC-VF.ttf"))
	background = load("res://picture/four-realms-map.png")
	var dir := DirAccess.open("res://picture")
	if dir:
		dir.list_dir_begin()
		var file := dir.get_next()
		while file != "":
			if not dir.current_is_dir() and file.to_lower().ends_with(".png"):
				files.append(file)
			file = dir.get_next()
		dir.list_dir_end()
	files.sort()
	set_process_input(true)

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var p: Vector2 = event.position * (VIEW / get_viewport_rect().size)
		if BACK.has_point(p): get_tree().change_scene_to_file("res://spirit_codex.tscn")
		elif PREV.has_point(p): page = max(0, page - 1)
		elif NEXT.has_point(p): page = min(maxi(0, ceili(float(files.size()) / PAGE_SIZE) - 1), page + 1)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE: get_tree().change_scene_to_file("res://spirit_codex.tscn")
		elif event.keycode == KEY_LEFT: page = max(0, page - 1)
		elif event.keycode == KEY_RIGHT: page = min(maxi(0, ceili(float(files.size()) / PAGE_SIZE) - 1), page + 1)

func _draw() -> void:
	if background: draw_texture_rect(background, Rect2(-30, -20, 1980, 1120), false)
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.015, 0.025, 0.05, 0.84))
	for i in 90:
		var x: float = fposmod(float(i * 97), VIEW.x)
		var y: float = fposmod(float(i * 67) - time * 12.0, 950.0) + 70.0
		draw_circle(Vector2(x, y), 1.0 + i % 3, Color(0.72, 0.58, 1.0, 0.18))
	_text("万象素材馆", Vector2(70, 78), 48, Color("fff0c3"))
	_text("Godot 已载入 picture 内全部 %d 张 PNG · 卡牌、蛋、使者、背景、角色、小怪与 Boss" % files.size(), Vector2(74, 140), 17, Color("c7d6c6"))
	var start := page * PAGE_SIZE
	for local_index in PAGE_SIZE:
		var index := start + local_index
		if index < files.size(): _draw_asset(index, local_index)
	_button(BACK, "‹ 返回图鉴")
	_button(PREV, "‹ 上一页")
	_button(NEXT, "下一页 ›")
	_text("%d / %d" % [page + 1, maxi(1, ceili(float(files.size()) / PAGE_SIZE))], Vector2(0, 945), 20, Color("f1d795"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)

func _draw_asset(index: int, local_index: int) -> void:
	var col := local_index % 4
	var row := local_index / 4
	var rect := Rect2(70 + col * 455, 195 + row * 232, 390, 200)
	draw_rect(rect.grow(8), Color(0.38, 0.25, 0.68, 0.13))
	draw_rect(rect, Color("101423e9"))
	draw_rect(rect, Color("b99a58"), false, 2.0)
	var texture := load("res://picture/" + files[index]) as Texture2D
	if texture:
		var source := Rect2(Vector2.ZERO, texture.get_size())
		draw_texture_rect_region(texture, Rect2(rect.position + Vector2(12, 12), Vector2(170, 176)), source)
	_text(_kind(files[index]), rect.position + Vector2(205, 27), 14, Color("cba766"))
	_text(files[index].trim_suffix(".png"), rect.position + Vector2(205, 55), 18, Color("fff0c6"))
	_text("Godot Texture2D", rect.position + Vector2(205, 90), 14, Color("b9c8c1"))
	_text("已装载 · 可用于场景与战斗", rect.position + Vector2(205, 120), 14, Color("92d5bc"))

func _kind(file: String) -> String:
	var lower := file.to_lower()
	if lower.begins_with("card"): return "灵契卡牌"
	if lower.begins_with("egg"): return "灵兽蛋"
	if lower.begins_with("messenger"): return "界域使者"
	if lower.begins_with("littlemonster"): return "小怪"
	if lower.begins_with("boss"): return "大 Boss"
	if lower.begins_with("background"): return "竞技背景"
	if lower.begins_with("oldman"): return "主线 NPC"
	if lower.begins_with("arena-player"): return "玩家角色"
	return "场景素材"

func _button(rect: Rect2, text: String) -> void:
	draw_rect(rect, Color("1a3639e8"))
	draw_rect(rect, Color("d0aa5d"), false, 1.0)
	_text(text, rect.position + Vector2(0, 16), 18, Color("fff0c6"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)

func _text(value: String, pos: Vector2, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var scaled_size: int = int(round(float(size) * GameState.ui_font_scale))
	draw_string(font, pos + Vector2(0, float(scaled_size)), value, align, width, scaled_size, Color(color, color.a * GameState.ui_opacity))

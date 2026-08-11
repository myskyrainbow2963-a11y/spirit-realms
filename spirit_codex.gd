extends Node2D

const GameState = preload("res://game_state.gd")
const UISkin = preload("res://ui_skin.gd")

const VIEW := Vector2(1920, 1080)
const NAV_MAP := Rect2(780, 14, 126, 52)
const NAV_HOME := Rect2(915, 14, 126, 52)
const NAV_CARDS := Rect2(1050, 14, 144, 52)
const NAV_BATTLE := Rect2(1205, 14, 130, 52)
const GALLERY_BUTTON := Rect2(1640, 94, 210, 50)
const PREV_PAGE_BUTTON := Rect2(1310, 94, 130, 50)
const NEXT_PAGE_BUTTON := Rect2(1455, 94, 165, 50)
const CARD_RECTS := [Rect2(112, 220, 226, 390), Rect2(372, 220, 226, 390), Rect2(632, 220, 226, 390), Rect2(892, 220, 226, 390), Rect2(1152, 220, 226, 390), Rect2(1412, 220, 226, 390), Rect2(242, 656, 226, 390), Rect2(502, 656, 226, 390), Rect2(762, 656, 226, 390), Rect2(1022, 656, 226, 390), Rect2(1282, 656, 226, 390)]

var font: Font
var background: Texture2D
var art: Array[Texture2D] = []
var displayed_cards: Array[Dictionary] = []
var collection_cards: Array[Dictionary] = []
var page := 0
var time := 0.0
var hovered := -1
var selected := -1
var transition := 0.0
var destination := ""
var names := ["玄甲钧龙", "焰尾灵狐", "月影猫灵", "青羽云雀", "山海麒麟", "星辉水獭", "霜牙寒狮", "幽冥骨狼", "雷魇象", "深渊蛛皇", "琉璃灵蝶"]
var stats := [[62,91,58], [38,43,93], [58,61,93], [57,52,71], [74,37,79], [85,52,40], [68,74,54], [72,46,68], [63,68,62], [57,66,35], [84,44,76]]

func _ready() -> void:
	font = GameState.font_for(load("res://fonts/NotoSansSC-VF.ttf"))
	AudioDirector.play_music("res://music/Glass Orbit.mp3", -19.0)
	AudioDirector.stop_ambience()
	background = load("res://picture/cloud-roost-home.png")
	_build_display_cards()
	set_process_input(true)

func _build_display_cards() -> void:
	collection_cards.clear()
	for card in GameState.hatched_cards:
		collection_cards.append(card.duplicate(true))
	if collection_cards.is_empty():
		collection_cards = GameState.build_battle_deck()
	while collection_cards.size() > GameState.MAX_CARD_COLLECTION:
		collection_cards.pop_back()
	_refresh_page()

func _page_count() -> int:
	return max(1, int(ceil(float(collection_cards.size()) / float(CARD_RECTS.size()))))

func _refresh_page() -> void:
	displayed_cards.clear()
	art.clear()
	page = clampi(page, 0, _page_count() - 1)
	var start: int = page * CARD_RECTS.size()
	var finish: int = min(collection_cards.size(), start + CARD_RECTS.size())
	for i in range(start, finish):
		displayed_cards.append(collection_cards[i].duplicate(true))
	for card in displayed_cards:
		art.append(load(str(card.get("art", "res://picture/card20.png"))))

func _process(delta: float) -> void:
	time += delta
	if destination != "":
		transition += delta
		if transition >= 0.7: get_tree().change_scene_to_file(destination)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		GameState.admin_return_scene = get_tree().current_scene.scene_file_path
		get_tree().change_scene_to_file("res://admin.tscn")
		return
	if event is InputEventMouseMotion:
		hovered = _card_at(_pointer(event.position))
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and destination == "":
		var p: Vector2 = _pointer(event.position)
		if NAV_MAP.has_point(p): _leave("res://demon_realm.tscn")
		elif NAV_HOME.has_point(p): _leave("res://cloud_roost.tscn")
		elif NAV_BATTLE.has_point(p): _leave("res://battle.tscn")
		elif PREV_PAGE_BUTTON.has_point(p):
			page = max(0, page - 1)
			selected = -1
			hovered = -1
			_refresh_page()
		elif NEXT_PAGE_BUTTON.has_point(p):
			page = min(_page_count() - 1, page + 1)
			selected = -1
			hovered = -1
			_refresh_page()
		elif GALLERY_BUTTON.has_point(p): _leave("res://asset_gallery.tscn")
		else: selected = _card_at(p)
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H: _leave("res://cloud_roost.tscn")
		if event.keycode == KEY_B: _leave("res://battle.tscn")
		if event.keycode == KEY_G: _leave("res://asset_gallery.tscn")

func _pointer(pointer: Vector2) -> Vector2:
	var scaled: Vector2 = pointer * (VIEW / get_viewport_rect().size)
	if _card_at(pointer) >= 0 or NAV_MAP.has_point(pointer) or NAV_HOME.has_point(pointer) or NAV_BATTLE.has_point(pointer) or PREV_PAGE_BUTTON.has_point(pointer) or NEXT_PAGE_BUTTON.has_point(pointer): return pointer
	return scaled

func _card_at(point: Vector2) -> int:
	for i in displayed_cards.size():
		if CARD_RECTS[i].grow(14).has_point(point): return i
	return -1

func _leave(scene: String) -> void:
	destination = scene
	transition = 0.01

func _draw() -> void:
	_draw_background()
	_draw_particles()
	_draw_nav()
	_text("灵契图鉴", Vector2(62, 104), 48, Color("fff0c5"))
	_text("已缔结 %d 张灵契 · 轻触卡牌查看攻击、防守与核心天赋" % displayed_cards.size(), Vector2(66, 164), 17, Color("cad8c6"))
	_draw_pagination()
	_draw_gallery_button()
	_text("COLLECTION %d / %d  ·  PAGE %d / %d" % [collection_cards.size(), GameState.MAX_CARD_COLLECTION, page + 1, _page_count()], Vector2(66, 190), 15, Color("e8c982"))
	for i in displayed_cards.size(): _draw_card(i)
	if selected >= 0 and selected < displayed_cards.size(): _draw_inspector()
	if destination != "": _draw_transition()

func _draw_background() -> void:
	var size := VIEW * (1.06 + sin(time * 0.1) * 0.018)
	if background: draw_texture_rect(background, Rect2((VIEW - size) * 0.5, size), false)
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.025, 0.075, 0.075, 0.60))
	draw_rect(Rect2(0, 140, VIEW.x, 940), Color(0.01, 0.015, 0.025, 0.45))

func _draw_particles() -> void:
	for i in 110:
		var x: float = fposmod(float(i * 97) + sin(time + i) * 28.0, VIEW.x)
		var y: float = fposmod(float(i * 59) - time * (11 + i % 5), 960.0) + 80.0
		draw_circle(Vector2(x, y), 1.0 + i % 3, Color(0.66, 0.44, 1.0, 0.18 + sin(time * 2 + i) * 0.08))

func _draw_nav() -> void:
	UISkin.panel(self, Rect2(18, 8, VIEW.x - 36, 60), Color("102c2bea"), Color("b79756"), 18.0, 0.08, 6.0)
	draw_line(Vector2(0, 73), Vector2(VIEW.x, 73), Color("b79756"), 1.0)
	_text("契", Vector2(48, 15), 34, Color("e7c77f"))
	_text("四界灵契", Vector2(96, 17), 23, Color("f4e6bf"))
	_text("SPIRIT REALMS", Vector2(98, 43), 10, Color("9cae99"))
	_nav(NAV_MAP, "世界地图")
	_nav(NAV_HOME, "云栖小筑")
	_nav(NAV_CARDS, "灵契图鉴  15", true)
	_nav(NAV_BATTLE, "竞技场")

func _nav(rect: Rect2, label: String, active := false) -> void:
	if active:
		draw_rect(rect, Color(0.48, 0.21, 0.74, 0.28))
		draw_rect(rect, Color("d1a95d"), false, 1.0)
	_text(label, rect.position + Vector2(0, 13), 17, Color("f4dfab") if active else Color("d5d7c2"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)

func _draw_card(index: int) -> void:
	var base: Rect2 = CARD_RECTS[index]
	var card: Dictionary = displayed_cards[index]
	var hover_amount := 1.0 if index == hovered else 0.0
	var selected_amount := 1.0 if index == selected else 0.0
	var rect := Rect2(base.position + Vector2(0, -18.0 * hover_amount - 11.0 * selected_amount), base.size * (1.0 + 0.035 * hover_amount + 0.04 * selected_amount))
	UISkin.panel(self, rect, Color("181622f2"), Color("ffe29b") if selected_amount > 0 else Color("c89652"), 18.0, 0.30 if hover_amount > 0 or selected_amount > 0 else 0.10, 8.0)
	draw_rect(rect.grow(-8), Color("6440a0"), false, 2.0)
	draw_rect(Rect2(rect.position + Vector2(14, 18), Vector2(rect.size.x - 28, 230)), Color("0e1020"))
	if index < art.size() and art[index]:
		var source: Rect2 = Rect2(Vector2.ZERO, art[index].get_size())
		draw_texture_rect_region(art[index], Rect2(rect.position + Vector2(16, 20), Vector2(rect.size.x - 32, 226)), source)
	draw_rect(Rect2(rect.position + Vector2(16, 246), Vector2(rect.size.x - 32, 56)), Color("20171ce8"))
	_text(str(card.get("name", names[index % names.size()])), rect.position + Vector2(14, 251), 22, Color("ffe8b0"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 28)
	_text(str(card.get("skill", "灵力")) + " · " + _talent_note(card), rect.position + Vector2(14, 281), 12, Color("a89578"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 28)
	var card_stats := [int(card.get("attack", stats[index % stats.size()][0])), int(card.get("defense", stats[index % stats.size()][1])), int(card.get("spirit", stats[index % stats.size()][2]))]
	for j in 3:
		var stat_rect := Rect2(rect.position + Vector2(15 + j * (rect.size.x - 40) / 3.0, 320), Vector2((rect.size.x - 48) / 3.0, 52))
		UISkin.panel(self, stat_rect, Color("151319"), Color("a4773d"), 9.0, 0.03, 4.0)
		_text(["攻", "守", "灵"][j], stat_rect.position + Vector2(0, 4), 12, Color("cbb38a"), HORIZONTAL_ALIGNMENT_CENTER, stat_rect.size.x)
		_text(str(card_stats[j]), stat_rect.position + Vector2(0, 21), 21, Color("fff0bf"), HORIZONTAL_ALIGNMENT_CENTER, stat_rect.size.x)

func _draw_inspector() -> void:
	var rect := Rect2(1505, 190, 350, 545)
	var card: Dictionary = displayed_cards[selected]
	UISkin.panel(self, rect, Color("0d1222f5"), Color("d1a95d"), 22.0, 0.18, 10.0)
	_text("灵纹共鸣", rect.position + Vector2(30, 26), 16, Color("dcbf76"))
	_text(str(card.get("name", names[selected % names.size()])), rect.position + Vector2(28, 62), 31, Color("fff1c8"))
	_text(str(card.get("skill", "灵力")) + " · " + _talent_note(card), rect.position + Vector2(30, 110), 15, Color("b8c9c4"))
	var card_stats := [int(card.get("attack", 0)), int(card.get("defense", 0)), int(card.get("spirit", 0))]
	for i in 3:
		var y := 180.0 + i * 68.0
		_text(["攻击灵纹", "守御灵纹", "灵息灵纹"][i], rect.position + Vector2(30, y), 16, Color("ddcfb5"))
		UISkin.progress_bar(self, Rect2(rect.position + Vector2(30, y + 28), Vector2(244, 14)), float(card_stats[i]) / 100.0, Color("a568ec"))
		_text(str(card_stats[i]), rect.position + Vector2(290, y - 4), 20, Color("fff1c5"))
	_text("已收录于灵契星图", rect.position + Vector2(30, 448), 16, Color("a4d6c4"))
	_text("点击其他灵契可切换观测", rect.position + Vector2(30, 486), 14, Color("baa98b"))

func _talent_note(card: Dictionary) -> String:
	var talent: Dictionary = card.get("talent", {})
	if talent.is_empty():
		return "无核心天赋"
	var value_text := ""
	if int(talent.get("value", 0)) > 0:
		value_text = " %d%s" % [int(talent.get("value", 0)), str(talent.get("unit", ""))]
	return str(talent.get("label", "天赋")) + value_text

func _draw_transition() -> void:
	var p := clampf(transition / 0.7, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.09, 0.02, 0.16, p))
	for i in 30:
		var angle: float = float(i) * TAU / 30.0 + time * 2.4
		draw_line(Vector2(960, 540), Vector2(960, 540) + Vector2(cos(angle), sin(angle)) * lerpf(60.0, 1450.0, p), Color(0.75, 0.48, 1.0, 1.0 - p), 2.0)

func _draw_gallery_button() -> void:
	draw_rect(GALLERY_BUTTON, Color("203c3ee8"))
	draw_rect(GALLERY_BUTTON, Color("d1a95d"), false, 1.0)
	_text("万象素材馆  G", GALLERY_BUTTON.position + Vector2(0, 13), 17, Color("fff0c6"), HORIZONTAL_ALIGNMENT_CENTER, GALLERY_BUTTON.size.x)

func _draw_pagination() -> void:
	_page_button(PREV_PAGE_BUTTON, "‹ 上一页", page > 0)
	_page_button(NEXT_PAGE_BUTTON, "下一页 ›", page < _page_count() - 1)
	_text("第 %d / %d 页" % [page + 1, _page_count()], Vector2(1310, 160), 14, Color("c9baa0"), HORIZONTAL_ALIGNMENT_CENTER, 310)

func _page_button(rect: Rect2, label: String, active: bool) -> void:
	UISkin.panel(self, rect, Color("203c3ee8") if active else Color("131d22cc"), Color("d1a95d") if active else Color("56625d"), 14.0, 0.12, 4.0)
	_text(label, rect.position + Vector2(0, 12), 16, Color("fff0c6") if active else Color("7f8b83"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)

func _text(value: String, pos: Vector2, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var scaled_size: int = int(round(float(size) * GameState.ui_font_scale))
	draw_string(font, pos + Vector2(0, float(scaled_size)), value, align, width, scaled_size, Color(color, color.a * GameState.ui_opacity))

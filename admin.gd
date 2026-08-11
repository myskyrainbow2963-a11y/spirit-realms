extends Control

const GameState = preload("res://game_state.gd")

var font: Font
var values: Dictionary = {}

func _ready() -> void:
	font = GameState.font_for(load("res://fonts/NotoSansSC-VF.ttf"))
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("061b20")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var panel := Panel.new()
	panel.position = Vector2(220, 70)
	panel.size = Vector2(1480, 940)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("0d3439f5"), Color("d2ad5e"), 26))
	add_child(panel)
	_add_label(panel, "四界灵契 · 后台管理", Vector2(60, 48), 42, Color("fff0c2"))
	_add_label(panel, "实时调整显示与养成参数 · 修改后立即写入当前游戏状态", Vector2(64, 108), 19, Color("cce0d4"))
	_add_label(panel, "视觉设置", Vector2(70, 178), 27, Color("e5bf72"))
	_add_slider(panel, "字体大小", 240, 0.80, 1.55, GameState.ui_font_scale, func(v): GameState.ui_font_scale = v, "%.2f ×")
	_add_slider(panel, "界面不透明度", 315, 0.40, 1.0, GameState.ui_opacity, func(v): GameState.ui_opacity = v, "%.0f%%")
	_add_slider(panel, "物体不透明度", 390, 0.25, 1.0, GameState.object_opacity, func(v): GameState.object_opacity = v, "%.0f%%")
	_add_slider(panel, "人物不透明度", 465, 0.25, 1.0, GameState.character_opacity, func(v): GameState.character_opacity = v, "%.0f%%")
	_add_slider(panel, "环境蓝调", 540, 0.0, 0.75, GameState.blue_tone, func(v): GameState.blue_tone = v, "%.0f%%")
	_add_toggle(panel, "圆润字体", Vector2(80, 598), GameState.round_font, func(v): GameState.round_font = v)
	_add_toggle(panel, "粗体字体", Vector2(390, 598), GameState.bold_font, func(v): GameState.bold_font = v)
	_add_label(panel, "灵兽基础能力", Vector2(70, 630), 27, Color("e5bf72"))
	var names := ["智力", "体力", "灵力", "魔力", "耐力"]
	for i in names.size():
		_add_stat(panel, names[i], Vector2(80 + i * 270, 690))
	var reset := Button.new()
	reset.text = "恢复推荐视觉"
	reset.position = Vector2(70, 835)
	reset.size = Vector2(220, 58)
	_style_button(reset, Color("214b4d"))
	reset.pressed.connect(_reset_visuals)
	panel.add_child(reset)
	var finish_hatch := Button.new()
	finish_hatch.text = "一键完成孵化"
	finish_hatch.position = Vector2(320, 835)
	finish_hatch.size = Vector2(220, 58)
	_style_button(finish_hatch, Color("3d7c67"))
	finish_hatch.pressed.connect(_complete_hatch)
	panel.add_child(finish_hatch)
	var back := Button.new()
	back.text = "保存并返回游戏"
	back.position = Vector2(1090, 835)
	back.size = Vector2(320, 58)
	_style_button(back, Color("c89c4b"), Color("132b2c"))
	back.pressed.connect(_back)
	panel.add_child(back)
	_add_label(panel, "快捷键：游戏中按 F10 可再次打开后台", Vector2(70, 900), 16, Color("91aca7"))

func _add_slider(parent: Control, title: String, y: float, minimum: float, maximum: float, initial: float, setter: Callable, format: String) -> void:
	_add_label(parent, title, Vector2(80, y), 22, Color("f4e5c1"))
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 0.01
	slider.value = initial
	slider.position = Vector2(340, y + 4)
	slider.size = Vector2(720, 38)
	slider.add_theme_icon_override("grabber", _circle_icon(Color("f7db8a")))
	parent.add_child(slider)
	var readout := Label.new()
	readout.position = Vector2(1090, y - 3)
	readout.size = Vector2(150, 42)
	readout.add_theme_font_override("font", font)
	readout.add_theme_font_size_override("font_size", 22)
	readout.add_theme_color_override("font_color", Color("b8ead7"))
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	readout.text = _format_value(initial, format)
	parent.add_child(readout)
	slider.value_changed.connect(func(value): setter.call(value); readout.text = _format_value(value, format))

func _add_stat(parent: Control, name: String, pos: Vector2) -> void:
	var card := Panel.new()
	card.position = pos
	card.size = Vector2(220, 142)
	card.add_theme_stylebox_override("panel", _panel_style(Color("123d3bdd"), Color("5ca78e"), 16))
	parent.add_child(card)
	_add_label(card, name, Vector2(16, 14), 23, Color("fff0c2"))
	var spin := SpinBox.new()
	spin.min_value = 1
	spin.max_value = 999
	spin.step = 1
	spin.value = int(GameState.base_stats[name])
	spin.position = Vector2(16, 58)
	spin.size = Vector2(185, 48)
	spin.add_theme_font_override("font", font)
	spin.add_theme_font_size_override("font_size", 23)
	card.add_child(spin)
	spin.value_changed.connect(func(value): GameState.base_stats[name] = int(value))

func _add_toggle(parent: Control, title: String, pos: Vector2, initial: bool, setter: Callable) -> void:
	var toggle := CheckButton.new()
	toggle.text = title
	toggle.position = pos
	toggle.size = Vector2(240, 42)
	toggle.button_pressed = initial
	toggle.add_theme_font_override("font", font)
	toggle.add_theme_font_size_override("font_size", 22)
	toggle.add_theme_color_override("font_color", Color("f4e5c1"))
	toggle.toggled.connect(func(value): setter.call(value))
	parent.add_child(toggle)

func _add_label(parent: Control, text: String, pos: Vector2, size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _style_button(button: Button, fill: Color, text_color := Color("fff0c2")) -> void:
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_stylebox_override("normal", _panel_style(fill, Color("f6d98a"), 15))
	button.add_theme_stylebox_override("hover", _panel_style(fill.lightened(0.12), Color("fff0bc"), 15))

func _panel_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 8
	return style

func _circle_icon(color: Color) -> ImageTexture:
	var image := Image.create(18, 18, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in 18:
		for x in 18:
			if Vector2(x - 8.5, y - 8.5).length() < 7.5: image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)

func _format_value(value: float, format: String) -> String:
	if format == "%.0f%%": return "%d%%" % int(round(value * 100.0))
	return "%.2f ×" % value

func _reset_visuals() -> void:
	GameState.ui_font_scale = 1.0
	GameState.round_font = true
	GameState.bold_font = true
	GameState.ui_opacity = 0.92
	GameState.object_opacity = 1.0
	GameState.character_opacity = 1.0
	GameState.blue_tone = 0.18
	get_tree().reload_current_scene()

func _back() -> void:
	get_tree().change_scene_to_file(GameState.admin_return_scene)

func _complete_hatch() -> void:
	GameState.complete_training_now()
	get_tree().change_scene_to_file("res://cloud_roost.tscn")

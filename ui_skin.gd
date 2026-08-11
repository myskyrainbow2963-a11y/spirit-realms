class_name UISkin
extends RefCounted

# Shared painted UI primitives for the Godot scenes. Keeping the frame language
# here stops each scene from becoming a grid of unrelated rectangles.
static func panel(canvas: CanvasItem, rect: Rect2, fill: Color, border: Color, radius: float = 18.0, glow: float = 0.14, inset: float = 8.0) -> void:
	var halo := StyleBoxFlat.new()
	halo.bg_color = Color(border, glow)
	halo.corner_radius_top_left = int(radius + 8.0)
	halo.corner_radius_top_right = int(radius + 8.0)
	halo.corner_radius_bottom_left = int(radius + 8.0)
	halo.corner_radius_bottom_right = int(radius + 8.0)
	halo.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	halo.shadow_size = 18
	halo.shadow_offset = Vector2(0, 8)
	canvas.draw_style_box(halo, rect.grow(8.0))
	var shell := StyleBoxFlat.new()
	shell.bg_color = fill
	shell.border_color = border
	shell.set_border_width_all(2)
	shell.corner_radius_top_left = int(radius)
	shell.corner_radius_top_right = int(radius)
	shell.corner_radius_bottom_left = int(radius)
	shell.corner_radius_bottom_right = int(radius)
	canvas.draw_style_box(shell, rect)
	var inner := StyleBoxFlat.new()
	inner.bg_color = Color(0.02, 0.075, 0.075, 0.34)
	inner.border_color = Color(1.0, 0.94, 0.72, 0.10)
	inner.set_border_width_all(1)
	inner.corner_radius_top_left = maxi(3, int(radius - inset))
	inner.corner_radius_top_right = maxi(3, int(radius - inset))
	inner.corner_radius_bottom_left = maxi(3, int(radius - inset))
	inner.corner_radius_bottom_right = maxi(3, int(radius - inset))
	canvas.draw_style_box(inner, rect.grow(-inset))

static func button(canvas: CanvasItem, rect: Rect2, hovered: bool, primary: bool = true) -> Rect2:
	var lift := 5.0 if hovered else 0.0
	var result := Rect2(rect.position + Vector2(0, -lift), rect.size)
	var border := Color("ffe4a1") if primary else Color("9bd7c5")
	var fill := Color("c58b3f") if primary else Color("153f3b")
	if hovered: fill = fill.lightened(0.12)
	panel(canvas, result, Color(fill, 0.96), border, 14.0, 0.25 if hovered else 0.10, 6.0)
	return result

static func progress_bar(canvas: CanvasItem, rect: Rect2, ratio: float, color: Color) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color("100f16d9")
	track.corner_radius_top_left = 8
	track.corner_radius_top_right = 8
	track.corner_radius_bottom_left = 8
	track.corner_radius_bottom_right = 8
	canvas.draw_style_box(track, rect)
	var value := StyleBoxFlat.new()
	value.bg_color = color
	value.corner_radius_top_left = 8
	value.corner_radius_top_right = 8
	value.corner_radius_bottom_left = 8
	value.corner_radius_bottom_right = 8
	canvas.draw_style_box(value, Rect2(rect.position + Vector2(2, 2), Vector2(maxf(2.0, (rect.size.x - 4.0) * clampf(ratio, 0.0, 1.0)), rect.size.y - 4.0)))

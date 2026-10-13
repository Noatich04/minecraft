extends Control

const WORLD_SCENE := "res://scenes/game_world.tscn"

var home_panel: VBoxContainer
var servers_panel: VBoxContainer
var settings_panel: VBoxContainer
var footer_label: Label

func _ready() -> void:
	_build_background()
	_build_home()
	_build_servers()
	_build_settings()
	_show_panel(home_panel)

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("#17202b"))
	# Layered distant hills made from blocky polygons.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, size.y * 0.58), Vector2(size.x * 0.12, size.y * 0.43),
		Vector2(size.x * 0.23, size.y * 0.55), Vector2(size.x * 0.36, size.y * 0.36),
		Vector2(size.x * 0.50, size.y * 0.57), Vector2(size.x * 0.66, size.y * 0.40),
		Vector2(size.x * 0.79, size.y * 0.54), Vector2(size.x * 0.91, size.y * 0.38),
		Vector2(size.x, size.y * 0.51), Vector2(size.x, size.y), Vector2(0, size.y)
	]), Color("#263d43"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, size.y * 0.75), Vector2(size.x * 0.17, size.y * 0.64),
		Vector2(size.x * 0.31, size.y * 0.77), Vector2(size.x * 0.48, size.y * 0.62),
		Vector2(size.x * 0.67, size.y * 0.78), Vector2(size.x * 0.84, size.y * 0.65),
		Vector2(size.x, size.y * 0.74), Vector2(size.x, size.y), Vector2(0, size.y)
	]), Color("#355449"))
	draw_rect(Rect2(0, size.y * 0.84, size.x, size.y * 0.16), Color("#263c32"))
	# Floating pixel/voxel accents.
	for i in range(11):
		var x := fposmod(float(i * 173 + 41), maxf(size.x, 1.0))
		var y := fposmod(float(i * 89 + 33), maxf(size.y * 0.75, 1.0))
		var s := 9.0 + float(i % 3) * 5.0
		draw_rect(Rect2(x, y, s, s), Color(0.78, 0.86, 0.78, 0.12))

func _build_background() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)

func _build_home() -> void:
	home_panel = VBoxContainer.new()
	home_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	home_panel.add_theme_constant_override("separation", 14)
	home_panel.set_anchors_preset(Control.PRESET_CENTER)
	home_panel.position = Vector2(-210, -180)
	home_panel.size = Vector2(420, 410)
	add_child(home_panel)

	var title := Label.new()
	title.text = "VOXEL SURVIVAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("#f2f4e8"))
	home_panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "ĐÀO • XÂY DỰNG • SINH TỒN"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("#c2d7c2"))
	home_panel.add_child(subtitle)
	_add_spacer(home_panel, 8)
	_add_button(home_panel, "CHƠI ĐƠN", _start_world, true)
	_add_button(home_panel, "MÁY CHỦ", _show_servers)
	_add_button(home_panel, "CÀI ĐẶT", _show_settings)
	_add_button(home_panel, "THOÁT GAME", _quit_game)
	_add_spacer(home_panel, 8)
	var note := Label.new()
	note.text = "BẢN THỬ NGHIỆM • GODOT"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color("#b4c3b5"))
	home_panel.add_child(note)

func _build_servers() -> void:
	servers_panel = VBoxContainer.new()
	servers_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	servers_panel.add_theme_constant_override("separation", 14)
	servers_panel.set_anchors_preset(Control.PRESET_CENTER)
	servers_panel.position = Vector2(-245, -170)
	servers_panel.size = Vector2(490, 370)
	add_child(servers_panel)

	var title := Label.new()
	title.text = "MÁY CHỦ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#f2f4e8"))
	servers_panel.add_child(title)

	var server_card := PanelContainer.new()
	server_card.custom_minimum_size = Vector2(460, 105)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.12, 0.13, 0.9)
	card_style.border_color = Color("#8da98a")
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(4)
	card_style.content_margin_left = 18
	card_style.content_margin_right = 18
	card_style.content_margin_top = 12
	card_style.content_margin_bottom = 12
	server_card.add_theme_stylebox_override("panel", card_style)
	var card_text := Label.new()
	card_text.text = "THẾ GIỚI SINH TỒN\nBản thử nghiệm cục bộ • 1 người chơi"
	card_text.add_theme_font_size_override("font_size", 18)
	card_text.add_theme_color_override("font_color", Color("#e6eee0"))
	server_card.add_child(card_text)
	servers_panel.add_child(server_card)

	var info := Label.new()
	info.text = "Kết nối nhiều người qua mạng chưa được tích hợp.\nNút bên dưới sẽ mở thế giới chơi thử trên máy này."
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 14)
	info.add_theme_color_override("font_color", Color("#d2ded1"))
	servers_panel.add_child(info)
	_add_button(servers_panel, "VÀO THẾ GIỚI THỬ NGHIỆM", _start_world, true)
	_add_button(servers_panel, "QUAY LẠI", _show_home)

func _build_settings() -> void:
	settings_panel = VBoxContainer.new()
	settings_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	settings_panel.add_theme_constant_override("separation", 16)
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.position = Vector2(-230, -145)
	settings_panel.size = Vector2(460, 290)
	add_child(settings_panel)

	var title := Label.new()
	title.text = "CÀI ĐẶT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#f2f4e8"))
	settings_panel.add_child(title)

	var controls := Label.new()
	controls.text = "ĐIỀU KHIỂN\nW A S D  —  Di chuyển\nSpace  —  Nhảy\nChuột  —  Nhìn / phá / đặt khối\nE  —  Túi đồ và công thức\nEsc  —  Thả chuột"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 17)
	controls.add_theme_color_override("font_color", Color("#e0e8db"))
	settings_panel.add_child(controls)
	_add_button(settings_panel, "QUAY LẠI", _show_home)

func _add_button(parent: VBoxContainer, caption: String, callback: Callable, primary := false) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(320, 52)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 18)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#557b4d") if primary else Color("#273b3a")
	normal.border_color = Color("#b4cba2") if primary else Color("#819a8a")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(3)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#71985e") if primary else Color("#3a5550")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color("#ffffff"))
	button.add_theme_color_override("font_hover_color", Color("#ffffff"))
	button.pressed.connect(callback)
	parent.add_child(button)

func _add_spacer(parent: VBoxContainer, amount: int) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = amount
	parent.add_child(spacer)

func _show_panel(panel: Control) -> void:
	home_panel.visible = panel == home_panel
	servers_panel.visible = panel == servers_panel
	settings_panel.visible = panel == settings_panel

func _show_home() -> void:
	_show_panel(home_panel)

func _show_servers() -> void:
	_show_panel(servers_panel)

func _show_settings() -> void:
	_show_panel(settings_panel)

func _start_world() -> void:
	var error := get_tree().change_scene_to_file(WORLD_SCENE)
	if error != OK:
		push_error("Không thể mở thế giới: %s" % error)

func _quit_game() -> void:
	get_tree().quit()

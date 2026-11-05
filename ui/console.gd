extends Control

## Reference to the Map node
var map: Map
## Child nodes that own the message log, sound playback, and the side panel.
@onready var message_log: MessageLog = $MessageLog
@onready var sound_player: SoundPlayer = $SoundPlayer
@onready var status_panel: StatusPanel = $StatusPanel
var race_selection_active: bool = true
var license_screen_active: bool = false
var license_text: String = ""
var game_over_active: bool = false
var game_over_victory: bool = false
var game_over_highest_level: int = 1
var game_over_enemies_killed: int = 0

const RACE_NAMES: PackedStringArray = ["Orc (+1 to all attributes)", "Human (+3 Constitution)", "Gnome (+3 Intelligence)", "Dar (+3 Dexterity)", "Werebull (+3 Strength)"]
const RACE_VALUES: Array[PlayerData.Race] = [PlayerData.Race.ORC, PlayerData.Race.HUMAN, PlayerData.Race.GNOME, PlayerData.Race.DAR, PlayerData.Race.BEASTMAN]
const RACE_KEYS: Array[Key] = [KEY_O, KEY_H, KEY_G, KEY_D, KEY_W]
const RACE_MENU_FIRST_ROW: int = 20

## Console dimensions in tiles (full console)
const CONSOLE_W: int = 160
const CONSOLE_H: int = 50

## The Map displays in the top-left 120x40 region
const VIEW_X: int = 0
const VIEW_Y: int = 0
const VIEW_W: int = 120
const VIEW_H: int = 40

## Standard CGA 16-color palette
const CGA_COLORS: Array[Color] = [
	Color("#000000"), # 0 black
	Color("#00AA00"), # 1 green
	Color("#AA0000"), # 2 red
	Color("#AA5500"), # 3 yellow/brown
	Color("#0000AA"), # 4 blue
	Color("#AA00AA"), # 5 magenta
	Color("#00AAAA"), # 6 cyan
	Color("#AAAAAA"), # 7 light gray
	Color("#555555"), # 8 dark gray
	Color("#55FF55"), # 9 bright green
	Color("#FF5555"), # 10 bright red
	Color("#FFFF55"), # 11 bright yellow
	Color("#5555FF"), # 12 bright blue
	Color("#FF55FF"), # 13 bright magenta
	Color("#55FFFF"), # 14 bright cyan
	Color("#FFFFFF"), # 15 bright white
]

const INV_COLORS: Array[int] = [15, 13, 14, 12, 11, 9, 10, 8, 7, 5, 6, 4, 3, 1, 2, 0]

## Cached cell dimensions and draw-time scratch data.
var _cell_w: float = 0.0
var _cell_h: float = 0.0
var _cell_x_positions: PackedFloat32Array = PackedFloat32Array()
var _row_baselines: PackedFloat32Array = PackedFloat32Array()
var _render_foreground: PackedInt32Array = PackedInt32Array()
var _render_background: PackedInt32Array = PackedInt32Array()
var _render_characters: PackedStringArray = PackedStringArray()
var _cell_render_data: Array = [0, 0, 0, " "]
var _cursor_drawn: bool = false

# Cursor position in map-view coordinates
var cursor_pos: Vector2i = Vector2i(-1, -1)

## Font reference
var font: FontFile = preload("res://FSEX300.ttf")
var font_size: int = 12
var ascent: float = font.get_ascent(font_size)
var descent: float = font.get_descent(font_size)

var chromatic_aberration = true

func _init() -> void:
	seed(int(Time.get_unix_time_from_system()))
	ItemData.init_unid_names()

func _ready() -> void:
	# Keep the system cursor hidden; the console renders its own tile highlight.
	mouse_filter = Control.MOUSE_FILTER_PASS
	_update_cell_size()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	$ChromaticAberration.visible = chromatic_aberration
	queue_redraw()
	_start_background_map_generation.call_deferred()

func _start_background_map_generation() -> void:
	# Let the selection menu draw first, then build the first level behind it.
	var menu_display_delay: SceneTreeTimer = get_tree().create_timer(0.1)
	await menu_display_delay.timeout
	if race_selection_active and map == null:
		_create_map()

func _create_map() -> void:
	PlayerData.reset_run_stats()
	map = Map.new(1, Map.Biome.CAVE)
	add_child(map)
	map.map_changed.connect(_on_map_changed)
	map.redraw.connect(_on_map_redraw)
	map.player_died.connect(_on_player_died)
	map.player_won.connect(_on_player_won)
	_bind_map_services(map)

## Connects a Map's message and sound signals to this console's child nodes,
## and points the status panel at it. Safe to call again for a swapped-in map.
func _bind_map_services(target: Map) -> void:
	if not target.message_posted.is_connected(message_log.add_message):
		target.message_posted.connect(message_log.add_message)
	if not target.sound_requested.is_connected(sound_player.play):
		target.sound_requested.connect(sound_player.play)
	status_panel.bind_map(target)

func _unhandled_input(event: InputEvent) -> void:
	if game_over_active:
		if event.is_action_pressed("confirm") or event.is_action_pressed("abort"):
			_return_to_race_selection()
			get_viewport().set_input_as_handled()
		return
	if race_selection_active:
		if event is InputEventKey and event.pressed and not event.echo:
			if license_screen_active:
				license_screen_active = false
				license_text = ""
				queue_redraw()
				get_viewport().set_input_as_handled()
				return
			if event.keycode == KEY_L or event.physical_keycode == KEY_L:
				license_text = Engine.get_license_text()
				license_screen_active = true
				queue_redraw()
				get_viewport().set_input_as_handled()
				return
			for race_index: int in range(RACE_KEYS.size()):
				if event.keycode == RACE_KEYS[race_index] or event.physical_keycode == RACE_KEYS[race_index]:
					_select_race(race_index)
					get_viewport().set_input_as_handled()
					return
		return
	if map == null:
		return
	# Mouse hover positions are updated through GUI input, but keyboard actions
	# may be handled before they reach the GUI. Route inspect here as a fallback.
	if event is InputEventKey and map.handle_inspect_input(event):
		get_viewport().set_input_as_handled()
		return
	if map.handle_equip_input(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and (map.look_mode or map.throw_target_mode or map.wand_target_mode):
		if event.pressed and not event.echo:
			map._handle_target_mode_input(event)
			get_viewport().set_input_as_handled()
		return

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		font_size = _compute_font_size()
		ascent = font.get_ascent(font_size)
		descent = font.get_descent(font_size)
		_update_cell_size()
		queue_redraw()

func _update_cell_size() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	_cell_w = size.x / CONSOLE_W
	_cell_h = size.y / CONSOLE_H
	_cell_x_positions.resize(CONSOLE_W)
	_row_baselines.resize(CONSOLE_H)
	for x: int in range(CONSOLE_W):
		_cell_x_positions[x] = float(x) * _cell_w
	for y: int in range(CONSOLE_H):
		_row_baselines[y] = float(y) * _cell_h + (_cell_h + ascent - descent) / 2.0

func _compute_font_size() -> int:
	if map == null:
		return 20
	var target_h: float = 24.0
	var font_sz: int = int(target_h / 1.2)
	return clamp(font_sz, 8, 48)

func _draw() -> void:
	_cursor_drawn = false
	if font == null or _cell_w <= 0 or _cell_h <= 0:
		return
	if game_over_active:
		draw_rect(Rect2(Vector2.ZERO, size), CGA_COLORS[0], true)
		_draw_game_over()
		_draw_uncovered_cursor()
		return
	if race_selection_active:
		draw_rect(Rect2(Vector2.ZERO, size), CGA_COLORS[0], true)
		if license_screen_active:
			_draw_license_screen()
		else:
			_draw_race_menu()
		_draw_uncovered_cursor()
		return
	if map == null:
		return

	var view_cell_count: int = VIEW_W * VIEW_H
	_render_foreground.resize(view_cell_count)
	_render_background.resize(view_cell_count)
	_render_characters.resize(view_cell_count)
	var cursor_in_view: bool = cursor_pos.x >= VIEW_X and cursor_pos.x < VIEW_X + VIEW_W and cursor_pos.y >= VIEW_Y and cursor_pos.y < VIEW_Y + VIEW_H

	# Clear all uncovered areas once. The map pass below only paints non-black
	# runs, rather than one rectangle for each of the 8,000 console cells.
	draw_rect(Rect2(Vector2.ZERO, size), CGA_COLORS[0], true)

	for y: int in range(VIEW_H):
		for x: int in range(VIEW_W):
			var cell_index: int = y * VIEW_W + x
			var map_position: Vector2i = Vector2i(x + VIEW_X, y + VIEW_Y)
			map.get_render_cell_data(map_position, _cell_render_data)
			var tile_type: TerrainData.Terrain = _cell_render_data[0]
			var foreground: int = _cell_render_data[1]
			var background: int = _cell_render_data[2]
			var display_char: String = _cell_render_data[3]
			if foreground == background:
				foreground = INV_COLORS[foreground]
			var on_hover_path: bool = map.is_hover_path_tile(map_position)
			var on_hover_blast: bool = map.is_hover_blast_tile(map_position)
			if on_hover_blast:
				background = 4 if background == 0 else 12
				foreground = 14 if foreground == 0 else foreground
			if on_hover_path:
				var swapped_color: int = foreground
				foreground = background
				background = swapped_color
			if cursor_in_view and cursor_pos == map_position:
				foreground = INV_COLORS[foreground]
				background = INV_COLORS[background]
				_cursor_drawn = true
			_render_foreground[cell_index] = foreground
			_render_background[cell_index] = background
			_render_characters[cell_index] = display_char if tile_type else " "

	# Draw contiguous same-color background runs; black cells are already covered.
	for y: int in range(VIEW_H):
		var run_start: int = 0
		var run_color: int = -1
		for x: int in range(VIEW_W + 1):
			var next_color: int = -1
			if x < VIEW_W:
				next_color = _render_background[y * VIEW_W + x]
			if next_color == run_color:
				continue
			if run_color > 0:
				var run_rect: Rect2 = Rect2(
					Vector2(_cell_x_positions[run_start], float(y + VIEW_Y) * _cell_h),
					Vector2(float(x - run_start) * _cell_w, _cell_h)
				)
				draw_rect(run_rect, CGA_COLORS[run_color], true)
			run_start = x
			run_color = next_color

	# Draw non-empty glyphs only; no need to query the map again for their display data.
	for y: int in range(VIEW_H):
		var baseline_y: float = _row_baselines[y + VIEW_Y]
		for x: int in range(VIEW_W):
			var cell_index: int = y * VIEW_W + x
			var display_char: String = _render_characters[cell_index]
			if display_char.is_empty() or display_char == " ":
				continue
			draw_string(font, Vector2(_cell_x_positions[x + VIEW_X], baseline_y), display_char, HORIZONTAL_ALIGNMENT_LEFT, _cell_w, font_size, CGA_COLORS[_render_foreground[cell_index]])

	# The lower map area is black (already set by the full-console background).
	# The hover description occupies row 40, row 41 is a spacer, and the log starts at 42.
	if cursor_pos.x >= VIEW_X and cursor_pos.x < VIEW_X + VIEW_W and cursor_pos.y >= VIEW_Y and cursor_pos.y < VIEW_Y + VIEW_H:
		var hover_text: String = map.get_hover_text(cursor_pos.x, cursor_pos.y)
		_draw_text_field(hover_text, 40, 1, Color.WHITE)
	var lower_field_text: String = map.inspect_description if map.inspect_mode else message_log.get_text()
	_draw_text_field(lower_field_text, 42, CONSOLE_H - 42, Color.WHITE, not map.inspect_mode)

	_draw_panel()
	_draw_uncovered_cursor()


func _draw_game_over() -> void:
	var panel_width: int = 58
	var panel_height: int = 11
	var panel_x: int = (CONSOLE_W - panel_width) >> 1
	var panel_y: int = 16
	draw_rect(Rect2(Vector2(panel_x * _cell_w, panel_y * _cell_h), Vector2(panel_width * _cell_w, panel_height * _cell_h)), CGA_COLORS[4], true)
	var border: String = "═".repeat(panel_width - 2)
	_draw_menu_line("╔" + border + "╗", panel_x, panel_y, CGA_COLORS[15])
	_draw_menu_line("║" + " ".repeat(panel_width - 2) + "║", panel_x, panel_y + 1, CGA_COLORS[15])
	var ending_title: String = "VICTORY!" if game_over_victory else "YOU DIED."
	var title_padding: int = maxi(0, panel_width - 2 - ending_title.length())
	var title_left_padding: int = floori(float(title_padding) / 2.0)
	_draw_menu_line("║" + " ".repeat(title_left_padding) + ending_title + " ".repeat(title_padding - title_left_padding) + "║", panel_x, panel_y + 2, CGA_COLORS[11])
	_draw_menu_line("║" + " ".repeat(panel_width - 2) + "║", panel_x, panel_y + 3, CGA_COLORS[15])
	_draw_menu_line(_game_over_stat_line("Highest level reached:", game_over_highest_level, panel_width), panel_x, panel_y + 4, CGA_COLORS[15])
	_draw_menu_line("║" + " ".repeat(panel_width - 2) + "║", panel_x, panel_y + 5, CGA_COLORS[15])
	_draw_menu_line(_game_over_stat_line("Enemies killed:", game_over_enemies_killed, panel_width), panel_x, panel_y + 6, CGA_COLORS[15])
	_draw_menu_line("║" + " ".repeat(panel_width - 2) + "║", panel_x, panel_y + 7, CGA_COLORS[15])
	var ending_prompt: String = "Press Escape or Return to start again."
	var prompt_padding: int = maxi(0, panel_width - 2 - ending_prompt.length())
	var prompt_left_padding: int = floori(float(prompt_padding) / 2.0)
	_draw_menu_line("║" + " ".repeat(prompt_left_padding) + ending_prompt + " ".repeat(prompt_padding - prompt_left_padding) + "║", panel_x, panel_y + 8, CGA_COLORS[15])
	_draw_menu_line("║" + " ".repeat(panel_width - 2) + "║", panel_x, panel_y + 9, CGA_COLORS[15])
	_draw_menu_line("╚" + border + "╝", panel_x, panel_y + panel_height - 1, CGA_COLORS[15])


func _game_over_stat_line(label: String, value: int, width: int) -> String:
	var content: String = "  %s %d" % [label, value]
	return "║" + content + " ".repeat(maxi(0, width - 2 - content.length())) + "║"


func _draw_race_menu() -> void:
	var panel_width: int = 48
	var panel_height: int = 16
	var panel_x: int = (CONSOLE_W - panel_width) >> 1
	var panel_y: int = 15
	draw_rect(Rect2(Vector2(panel_x * _cell_w, panel_y * _cell_h), Vector2(panel_width * _cell_w, panel_height * _cell_h)), CGA_COLORS[4], true)
	var border: String = "═".repeat(panel_width - 2)
	var title_line: String = "╔" + border + "╗"
	_draw_menu_line(title_line, panel_x, panel_y, CGA_COLORS[15])
	_draw_menu_line("║                                              ║", panel_x, panel_y + 1, CGA_COLORS[15])
	_draw_menu_line("║               CHOOSE YOUR RACE               ║", panel_x, panel_y + 2, CGA_COLORS[11])
	_draw_menu_line("║                                              ║", panel_x, panel_y + 3, CGA_COLORS[15])
	for race_index: int in range(RACE_NAMES.size()):
		var line_row: int = RACE_MENU_FIRST_ROW + race_index * 2
		var race_name: String = RACE_NAMES[race_index]
		var prefix: String = "║ ("
		var suffix: String = ")" + race_name.substr(1)
		var padding_count: int = panel_width - 2 - prefix.length() - suffix.length()
		_draw_menu_line("║                                              ║", panel_x, line_row-1, CGA_COLORS[15])
		_draw_menu_line(prefix, panel_x, line_row, CGA_COLORS[15])
		_draw_menu_line(race_name.substr(0, 1), panel_x + prefix.length(), line_row, CGA_COLORS[11])
		_draw_menu_line(suffix + " ".repeat(maxi(0, padding_count)) + "║", panel_x + prefix.length() + 1, line_row, CGA_COLORS[15])
	_draw_menu_line("║                                              ║", panel_x, panel_y + 14, CGA_COLORS[15])
	_draw_menu_line("╚" + border + "╝", panel_x, panel_y + panel_height - 1, CGA_COLORS[15])
	#var version = Engine.get_version_info()
	_draw_menu_line("Foul Maze v0.1", 0, CONSOLE_H - 6, CGA_COLORS[8])
	_draw_menu_line("made in MMXXVI", 0, CONSOLE_H - 5, CGA_COLORS[8])
	_draw_menu_line("github.com/Olnarrosh/foul-maze", 0, CONSOLE_H - 4, CGA_COLORS[8])
	_draw_menu_line("Made with: Godot (licensed under the MIT (L)icense)", 0, CONSOLE_H - 3, CGA_COLORS[8])
	_draw_menu_line("           Ziva", 0, CONSOLE_H - 2, CGA_COLORS[8])
	_draw_menu_line("           GDFXR (by Haoyu Qiu, licensed under the MIT License)", 0, CONSOLE_H - 1, CGA_COLORS[8])

func _draw_license_screen() -> void:
	var license_panel_x: int = 5
	var license_panel_width: int = CONSOLE_W - license_panel_x * 2
	var license_lines: PackedStringArray = _wrap_text_to_cells(license_text, license_panel_width - 4)
	var visible_line_count: int = mini(license_lines.size(), CONSOLE_H - 6)
	var first_line: int = maxi(0, license_lines.size() - visible_line_count)
	var first_row: int = floori(float(CONSOLE_H - visible_line_count) / 2.0)
	for line_index: int in range(visible_line_count):
		_draw_menu_line(license_lines[first_line + line_index], license_panel_x + 2, first_row + line_index, CGA_COLORS[15])
	_draw_menu_line("Press any key to return", license_panel_x + 2, CONSOLE_H - 2, CGA_COLORS[8])


func _wrap_text_to_cells(text: String, max_characters: int) -> PackedStringArray:
	var wrapped_lines: PackedStringArray = PackedStringArray()
	for paragraph: String in text.split("\n"):
		var remaining: String = paragraph
		if remaining.is_empty():
			wrapped_lines.append("")
			continue
		while remaining.length() > max_characters:
			var break_at: int = remaining.rfind(" ", max_characters)
			if break_at <= 0:
				break_at = max_characters
			wrapped_lines.append(remaining.substr(0, break_at).strip_edges())
			remaining = remaining.substr(break_at).strip_edges()
		wrapped_lines.append(remaining)
	return wrapped_lines


func _draw_menu_line(text: String, cell_x: int, cell_y: int, color: Color) -> void:
	var foreground_index: int = _palette_index_for_color(color)
	for character_index: int in range(text.length()):
		var character_position: Vector2i = Vector2i(cell_x + character_index, cell_y)
		var background_index: int = _menu_background_index_at(character_position)
		_draw_console_character(text.substr(character_index, 1), character_position.x, character_position.y, foreground_index, background_index)


func _palette_index_for_color(color: Color) -> int:
	var best_index: int = 0
	var best_distance: float = INF
	for color_index: int in range(CGA_COLORS.size()):
		var palette_color: Color = CGA_COLORS[color_index]
		var red_difference: float = palette_color.r - color.r
		var green_difference: float = palette_color.g - color.g
		var blue_difference: float = palette_color.b - color.b
		var distance: float = red_difference * red_difference + green_difference * green_difference + blue_difference * blue_difference
		if distance < best_distance:
			best_distance = distance
			best_index = color_index
	return best_index


func _menu_background_index_at(cell: Vector2i) -> int:
	if license_screen_active:
		return 0
	var panel_x: int = (CONSOLE_W - (58 if game_over_active else 48)) >> 1
	var panel_y: int = 16 if game_over_active else 15
	var panel_width: int = 58 if game_over_active else 48
	var panel_height: int = 11 if game_over_active else 16
	if cell.x >= panel_x and cell.x < panel_x + panel_width and cell.y >= panel_y and cell.y < panel_y + panel_height:
		return 4
	if not race_selection_active and not game_over_active and cell.x >= VIEW_W and cell.x < CONSOLE_W and cell.y < VIEW_H:
		return 4
	return 0


func _draw_console_character(character: String, cell_x: int, cell_y: int, foreground_index: int, background_index: int) -> void:
	var is_cursor: bool = cursor_pos == Vector2i(cell_x, cell_y)
	var draw_background: int = INV_COLORS[background_index] if is_cursor else background_index
	var draw_foreground: int = INV_COLORS[foreground_index] if is_cursor else foreground_index
	if is_cursor:
		draw_rect(Rect2(Vector2(float(cell_x) * _cell_w, float(cell_y) * _cell_h), Vector2(_cell_w, _cell_h)), CGA_COLORS[draw_background], true)
		_cursor_drawn = true
	if character.is_empty() or character == " ":
		return
	var baseline: float = float(cell_y) * _cell_h + (_cell_h + ascent - descent) / 2.0
	draw_string(font, Vector2(float(cell_x) * _cell_w, baseline), character, HORIZONTAL_ALIGNMENT_LEFT, _cell_w, font_size, CGA_COLORS[draw_foreground])


func _draw_uncovered_cursor() -> void:
	if _cursor_drawn or cursor_pos.x < 0 or cursor_pos.x >= CONSOLE_W or cursor_pos.y < 0 or cursor_pos.y >= CONSOLE_H:
		return
	if not race_selection_active and not game_over_active and cursor_pos.x >= VIEW_X and cursor_pos.x < VIEW_X + VIEW_W and cursor_pos.y >= VIEW_Y and cursor_pos.y < VIEW_Y + VIEW_H:
		return
	var background_index: int = _menu_background_index_at(cursor_pos)
	var cursor_foreground: int = _default_console_cell_foreground(cursor_pos)
	var cursor_background: int = INV_COLORS[background_index]
	var cursor_rect: Rect2 = Rect2(Vector2(float(cursor_pos.x) * _cell_w, float(cursor_pos.y) * _cell_h), Vector2(_cell_w, _cell_h))
	draw_rect(cursor_rect, CGA_COLORS[cursor_background], true)
	var cursor_character: String = _console_character_at(cursor_pos)
	if not cursor_character.is_empty() and cursor_character != " ":
		var baseline: float = float(cursor_pos.y) * _cell_h + (_cell_h + ascent - descent) / 2.0
		draw_string(font, Vector2(float(cursor_pos.x) * _cell_w, baseline), cursor_character, HORIZONTAL_ALIGNMENT_LEFT, _cell_w, font_size, CGA_COLORS[INV_COLORS[cursor_foreground]])
	_cursor_drawn = true


func _default_console_cell_foreground(cell: Vector2i) -> int:
	if race_selection_active:
		return _race_menu_foreground_at(cell) if _menu_background_index_at(cell) == 4 else 8
	if game_over_active:
		if _menu_background_index_at(cell) != 4:
			return 0
		if cell.y == 18:
			return 11
		return 15
	if cell.x >= VIEW_W and cell.x < CONSOLE_W:
		return 15
	if cell.y >= 42:
		return 15
	return 7


func _console_character_at(cell: Vector2i) -> String:
	if game_over_active:
		return _game_over_character_at(cell)
	if race_selection_active:
		if license_screen_active:
			return ""
		return _race_menu_character_at(cell)
	if map == null:
		return ""
	if cell.y == 40 and cell.x < VIEW_W and cursor_pos.x >= VIEW_X and cursor_pos.x < VIEW_X + VIEW_W and cursor_pos.y >= VIEW_Y and cursor_pos.y < VIEW_Y + VIEW_H:
		var hover_text: String = map.get_hover_text(cursor_pos.x, cursor_pos.y)
		return hover_text.substr(cell.x, 1) if cell.x < hover_text.length() else " "
	if cell.y == 41:
		return ""
	if cell.y >= 42:
		var align_to_bottom: bool = not map.inspect_mode
		var text: String = map.inspect_description if map.inspect_mode else message_log.get_text()
		if text.is_empty():
			return ""
		var row_count: int = CONSOLE_H - 42
		var wrapped_lines: PackedStringArray = _wrap_text_field_lines(text)
		var visible_start: int = maxi(0, wrapped_lines.size() - row_count)
		var visible_line_count: int = mini(row_count, wrapped_lines.size())
		var first_row: int = 42 + (row_count - visible_line_count if align_to_bottom else 0)
		var visible_row_index: int = cell.y - first_row
		if visible_row_index >= 0 and visible_row_index < visible_line_count:
			var line_index: int = visible_start + visible_row_index
			if cell.x < wrapped_lines[line_index].length():
				return wrapped_lines[line_index].substr(cell.x, 1)
	return ""


func _game_over_character_at(cell: Vector2i) -> String:
	var panel_width: int = 58
	var panel_x: int = (CONSOLE_W - panel_width) >> 1
	var panel_y: int = 16
	var panel_height: int = 11
	if cell.x < panel_x or cell.x >= panel_x + panel_width or cell.y < panel_y or cell.y >= panel_y + panel_height:
		return ""
	var border: String = "═".repeat(panel_width - 2)
	if cell.y == panel_y:
		return ("╔" + border + "╗").substr(cell.x - panel_x, 1)
	if cell.y == panel_y + panel_height - 1:
		return ("╚" + border + "╝").substr(cell.x - panel_x, 1)
	if cell.x == panel_x or cell.x == panel_x + panel_width - 1:
		return "║"
	var title: String = "VICTORY!" if game_over_victory else "YOU DIED."
	if cell.y == panel_y + 2:
		var title_start: int = floori(float(panel_width - title.length()) / 2.0)
		var title_index: int = cell.x - panel_x - title_start
		return title.substr(title_index, 1) if title_index >= 0 and title_index < title.length() else " "
	if cell.y == panel_y + 4:
		return _padded_menu_text("  Highest level reached: %d" % game_over_highest_level, panel_width - 2).substr(cell.x - panel_x - 1, 1)
	if cell.y == panel_y + 6:
		return _padded_menu_text("  Enemies killed: %d" % game_over_enemies_killed, panel_width - 2).substr(cell.x - panel_x - 1, 1)
	if cell.y == panel_y + 8:
		return _padded_menu_text("Press Escape or Return to start again.", panel_width - 2).substr(cell.x - panel_x - 1, 1)
	return " "


func _padded_menu_text(text: String, width: int) -> String:
	var padding: int = maxi(0, width - text.length())
	var left_padding: int = floori(float(padding) / 2.0)
	return " ".repeat(left_padding) + text + " ".repeat(padding - left_padding)


func _race_menu_character_at(cell: Vector2i) -> String:
	var panel_x: int = (CONSOLE_W - 48) >> 1
	var panel_y: int = 15
	var panel_width: int = 48
	var panel_height: int = 16
	if cell.x < panel_x or cell.x >= panel_x + panel_width or cell.y < panel_y or cell.y >= panel_y + panel_height:
		return ""
	var border: String = "═".repeat(panel_width - 2)
	if cell.y == panel_y:
		return ("╔" + border + "╗").substr(cell.x - panel_x, 1)
	if cell.y == panel_y + panel_height - 1:
		return ("╚" + border + "╝").substr(cell.x - panel_x, 1)
	if cell.x == panel_x or cell.x == panel_x + panel_width - 1:
		return "║"
	if cell.y == panel_y + 2:
		var title: String = "               CHOOSE YOUR RACE               "
		return title.substr(cell.x - panel_x - 1, 1) if cell.x - panel_x - 1 < title.length() else " "
	if cell.y == panel_y + 14:
		return " "
	for race_index: int in range(RACE_NAMES.size()):
		var line_row: int = RACE_MENU_FIRST_ROW + race_index * 2
		if cell.y == line_row:
			var prefix: String = "║ ("
			var suffix: String = ")" + RACE_NAMES[race_index].substr(1)
			var padding_count: int = panel_width - 2 - prefix.length() - suffix.length()
			var full_line: String = prefix + RACE_NAMES[race_index].substr(0, 1) + suffix + " ".repeat(maxi(0, padding_count)) + "║"
			return full_line.substr(cell.x - panel_x, 1)
	return " "


func _race_menu_foreground_at(cell: Vector2i) -> int:
	for race_index: int in range(RACE_NAMES.size()):
		if cell.y == RACE_MENU_FIRST_ROW + race_index * 2 and cell.x == ((CONSOLE_W - 48) >> 1) + 4:
			return 11
	if cell.y == 17:
		return 11
	return 15



func _on_player_died(highest_level: int, enemies_killed: int) -> void:
	game_over_victory = false
	_show_game_over(highest_level, enemies_killed)

func _on_player_won(highest_level: int, enemies_killed: int) -> void:
	game_over_victory = true
	_show_game_over(highest_level, enemies_killed)

func _show_game_over(highest_level: int, enemies_killed: int) -> void:
	game_over_highest_level = highest_level
	game_over_enemies_killed = enemies_killed
	game_over_active = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	queue_redraw()


func _return_to_race_selection() -> void:
	game_over_active = false
	game_over_victory = false
	race_selection_active = true
	game_over_highest_level = 1
	game_over_enemies_killed = 0
	if map != null:
		map.queue_free()
		map = null
	message_log.clear()
	status_panel.bind_map(null)
	PlayerData.reset_run_stats()
	ItemData.init_unid_names()
	PlayerData.player_race = PlayerData.Race.GNOME
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	queue_redraw()
	_start_background_map_generation.call_deferred()


func _select_race(index: int) -> void:
	if index < 0 or index >= RACE_VALUES.size() or not race_selection_active:
		return
	race_selection_active = false
	PlayerData.player_race = RACE_VALUES[index]
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if map == null:
		_create_map()
	map.start_game_after_generation()
	queue_redraw()


func _wrap_text_field_lines(text: String) -> PackedStringArray:
	var wrapped_lines: PackedStringArray = PackedStringArray()
	for paragraph: String in text.split("\n"):
		var remaining: String = paragraph
		while remaining.length() > CONSOLE_W:
			var break_at: int = remaining.rfind(" ", CONSOLE_W)
			if break_at <= 0:
				break_at = CONSOLE_W
			wrapped_lines.append(remaining.substr(0, break_at))
			remaining = remaining.substr(break_at).strip_edges()
		wrapped_lines.append(remaining)
	return wrapped_lines


func _draw_text_field(text: String, start_row: int, row_count: int, color: Color, align_to_bottom: bool = false) -> void:
	if text.is_empty() or row_count <= 0:
		return
	var wrapped_lines: PackedStringArray = _wrap_text_field_lines(text)
	var visible_start: int = maxi(0, wrapped_lines.size() - row_count)
	var visible_line_count: int = mini(row_count, wrapped_lines.size())
	var first_row: int = start_row + (row_count - visible_line_count if align_to_bottom else 0)
	var foreground_index: int = _palette_index_for_color(color)
	for line_index: int in range(visible_line_count):
		var row: int = first_row + line_index
		var line: String = wrapped_lines[visible_start + line_index]
		for character_index: int in range(line.length()):
			_draw_console_character(line.substr(character_index, 1), character_index, row, foreground_index, 0)


func _mouse_tile_position(local_position: Vector2) -> Vector2i:
	return Vector2i(floori(local_position.x / _cell_w), floori(local_position.y / _cell_h))


func _update_cursor_from_mouse(local_position: Vector2) -> void:
	var mouse_position: Vector2i = Vector2i(
		clampi(floori(local_position.x / _cell_w), 0, CONSOLE_W - 1),
		clampi(floori(local_position.y / _cell_h), 0, CONSOLE_H - 1)
	)
	if cursor_pos == mouse_position:
		return
	cursor_pos = mouse_position
	if not race_selection_active and map != null:
		map.set_console_cursor_position(cursor_pos)
		if cursor_pos.x >= VIEW_X and cursor_pos.x < VIEW_X + VIEW_W and cursor_pos.y >= VIEW_Y and cursor_pos.y < VIEW_Y + VIEW_H:
			if map.look_mode or map.throw_target_mode or map.wand_target_mode:
				map.set_target_cursor_position(cursor_pos)
			else:
				map.set_hover_tile(cursor_pos)
		else:
			map.set_hover_tile(Vector2i(-1, -1))
	queue_redraw()


func _on_gui_input(event: InputEvent) -> void:
	if _cell_w <= 0 or _cell_h <= 0:
		return
	if event is InputEventMouseMotion:
		_update_cursor_from_mouse(event.position)
		return
	if event is InputEventMouseButton and event.pressed:
		_update_cursor_from_mouse(event.position)
	if game_over_active:
		return
	if race_selection_active:
		if license_screen_active:
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var clicked_cell: Vector2i = _mouse_tile_position(event.position)
			var panel_left: int = (CONSOLE_W - 48) >> 1
			var panel_right: int = panel_left + 48
			if clicked_cell.x >= panel_left and clicked_cell.x < panel_right:
				for race_index: int in range(RACE_NAMES.size()):
					if clicked_cell.y == RACE_MENU_FIRST_ROW + race_index * 2:
						_select_race(race_index)
						accept_event()
						return
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if map.look_mode or map.throw_target_mode or map.wand_target_mode:
			var target_position: Vector2i = _mouse_tile_position(event.position)
			map.confirm_target_at(target_position)
		else:
			map.handle_inspect_input(event)
		accept_event()
		return
	elif event is InputEventMouseButton and event.pressed:
		var click_x: int = floori(event.position.x / _cell_w)
		var click_y: int = floori(event.position.y / _cell_h)
		if click_x >= VIEW_X and click_x < VIEW_X + VIEW_W and click_y >= VIEW_Y and click_y < VIEW_Y + VIEW_H:
			var clicked_tile: Vector2i = Vector2i(click_x, click_y)
			if map.look_mode or map.throw_target_mode or map.wand_target_mode:
				map.set_target_cursor_position(clicked_tile)
				if event.button_index == MOUSE_BUTTON_LEFT:
					map.confirm_target_at(clicked_tile)
			else:
				if event.button_index == MOUSE_BUTTON_LEFT:
					map.start_auto_walk(clicked_tile)
			accept_event()


func _on_map_redraw() -> void:
	queue_redraw()

func _on_map_changed(next_map: Map) -> void:
	if map != null and map.redraw.is_connected(_on_map_redraw):
		map.redraw.disconnect(_on_map_redraw)
	if map != null and map.map_changed.is_connected(_on_map_changed):
		map.map_changed.disconnect(_on_map_changed)
	map = next_map
	if not map.redraw.is_connected(_on_map_redraw):
		map.redraw.connect(_on_map_redraw)
	if not map.map_changed.is_connected(_on_map_changed):
		map.map_changed.connect(_on_map_changed)
	_bind_map_services(map)
	queue_redraw()


func _draw_panel() -> void:
	var panel_x: int = VIEW_W
	var panel_y: int = 0
	var panel_w: int = CONSOLE_W - VIEW_W
	var panel_h: int = VIEW_H

	# Background (draw_rect uses pixel coordinates)
	draw_rect(Rect2(Vector2(panel_x * _cell_w, panel_y * _cell_h), Vector2(panel_w * _cell_w, panel_h * _cell_h)), CGA_COLORS[4], true)

	# Panel borders are built by StatusPanel.get_panel_lines().

	# Top and bottom horizontal borders
	#var top_baseline: float = panel_y * _cell_h + (_cell_h + ascent - descent) / 2.0
	#var bottom_baseline: float = (panel_y + panel_h - 1) * _cell_h + (_cell_h + ascent - descent) / 2.0
	#draw_string(font, Vector2((panel_x + 1) * _cell_w, top_baseline), border_str, HORIZONTAL_ALIGNMENT_LEFT, panel_w * _cell_w, font_size, CGA_COLORS[15])
	#draw_string(font, Vector2((panel_x + 1) * _cell_w, bottom_baseline), border_str, HORIZONTAL_ALIGNMENT_LEFT, panel_w * _cell_w, font_size, CGA_COLORS[15])
#
	## Left and right vertical borders
	#for y in range(panel_y + 1, panel_y + panel_h - 1):
		#var by: float = y * _cell_h + (_cell_h + ascent - descent) / 2.0
		#draw_string(font, Vector2(panel_x * _cell_w, by), v_line, HORIZONTAL_ALIGNMENT_LEFT, _cell_w, font_size, CGA_COLORS[15])
		#draw_string(font, Vector2((panel_x + panel_w - 1) * _cell_w, by), v_line, HORIZONTAL_ALIGNMENT_LEFT, _cell_w, font_size, CGA_COLORS[15])
#
	## Corners
	#draw_string(font, Vector2(panel_x * _cell_w, top_baseline), tl, HORIZONTAL_ALIGNMENT_LEFT, _cell_w, font_size, CGA_COLORS[15])
	#draw_string(font, Vector2((panel_x + panel_w - 1) * _cell_w, top_baseline), tr, HORIZONTAL_ALIGNMENT_LEFT, _cell_w, font_size, CGA_COLORS[15])
	#draw_string(font, Vector2(panel_x * _cell_w, bottom_baseline), bl, HORIZONTAL_ALIGNMENT_LEFT, _cell_w, font_size, CGA_COLORS[15])
	#draw_string(font, Vector2((panel_x + panel_w - 1) * _cell_w, bottom_baseline), br, HORIZONTAL_ALIGNMENT_LEFT, _cell_w, font_size, CGA_COLORS[15])

	# Content strings and their padded rows are cached by StatusPanel and rebuilt only when the panel model changes.
	var panel_rows: PackedStringArray = status_panel.get_panel_lines(panel_w, panel_h)
	if panel_rows.is_empty():
		return

	# Draw panel glyphs only. Blank panel cells need neither a text call nor
	# individual background rectangles because the panel background is solid.
	for y: int in range(panel_h):
		var line: String = panel_rows[y]
		var baseline: float = _row_baselines[y]
		for x: int in range(panel_w):
			var character: String = line[x]
			var is_cursor: bool = cursor_pos == Vector2i(panel_x + x, y)
			var foreground: int = 15
			var background: int = 4
			if is_cursor:
				foreground = INV_COLORS[foreground]
				background = INV_COLORS[background]
				draw_rect(Rect2(Vector2(_cell_x_positions[panel_x + x], float(y) * _cell_h), Vector2(_cell_w, _cell_h)), CGA_COLORS[background], true)
				_cursor_drawn = true
			if character == " ":
				continue
			draw_string(font, Vector2(_cell_x_positions[panel_x + x], baseline), character, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, CGA_COLORS[foreground])
	
	#draw_string(font, Vector2(panel_x * _cell_w, panel_y), "test", HORIZONTAL_ALIGNMENT_LEFT, panel_w * _cell_w, font_size, CGA_COLORS[15])
	#draw_string(font, Vector2(panel_x * _cell_w, panel_y), tl + border_str + tr + "\n" + "\n".join(lines) + bl + border_str + br, HORIZONTAL_ALIGNMENT_LEFT, panel_w * _cell_w, font_size, CGA_COLORS[15])
	#draw_string(font, Vector2((panel_x) * _cell_w, by), lines[i], HORIZONTAL_ALIGNMENT_LEFT, (panel_w) * _cell_w, font_size, CGA_COLORS[15])

	# Invert colors at cursor position anywhere within the panel
	#if cursor_pos.x >= panel_x and cursor_pos.x < panel_x + panel_w and cursor_pos.y >= panel_y and cursor_pos.y < panel_y + panel_h:
		#var by: float = cursor_pos.y * _cell_h + (_cell_h + ascent - descent) / 2.0
		#draw_rect(Rect2(Vector2(cursor_pos.x * _cell_w, cursor_pos.y * _cell_h), Vector2(_cell_w, _cell_h)), CGA_COLORS[INV_COLORS[4]], true)
		#var cursor_col := cursor_pos.x - panel_x - 1
		#var line_idx := cursor_pos.y - panel_y - 1
		#var char_str := " "
		#if line_idx < lines.size():
			#var line := lines[line_idx]
			#if cursor_col < line.length():
				#char_str = line.substr(cursor_col, 1)
		#draw_string(font, Vector2(cursor_pos.x * _cell_w, by), char_str, HORIZONTAL_ALIGNMENT_LEFT, _cell_w, font_size, CGA_COLORS[INV_COLORS[15]])

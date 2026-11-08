class_name MessageLog
extends Control

## Rolling list of recent game messages shown in the console's lower text field.
## Map posts messages through its message_posted signal, which Console connects to add_message().

## How many of the most recent messages are kept.
const MESSAGE_LOG_LIMIT: int = 8

## Stored messages, oldest first.
var messages: Array[String] = ["", "", "", "", "", "", "", ""]
var override_message: String = ""

var font: Font
var cursor_pos: Vector2

## Appends a message, dropping the oldest entries beyond MESSAGE_LOG_LIMIT. Empty messages are ignored.
func add_message(message: String) -> void:
	if message.is_empty():
		return
	for line in message.split("\n"):
		messages.append(line)
	while messages.size() > MESSAGE_LOG_LIMIT:
		messages.pop_front()
	queue_redraw()

func set_override_message(message: String = "") -> void:
	if message != override_message:
		override_message = message
		queue_redraw()

## Removes every stored message. Console calls this when a new level or game starts.
func clear() -> void:
	messages = ["", "", "", "", "", "", "", ""]
	queue_redraw()

## Returns the stored messages as one newline-separated string.
func get_text() -> String:
	return override_message if override_message else "\n".join(messages)

func set_cursor_pos(pos: Vector2) -> void:
	if (pos.x >= 0 and pos.y >= 0) or (cursor_pos.x >= 0 and cursor_pos.y >= 0):
		queue_redraw()
	if pos != cursor_pos:
		cursor_pos = pos

func _draw() -> void:
	draw_rect(Rect2(0, 756, 1600, 144), Color.BLACK)
	@warning_ignore("incompatible_ternary")
	var lines: Array = override_message.split("\n") if override_message else messages
	draw_lines(lines)
	if cursor_pos.x >= 0 and cursor_pos.y >= 0:
		var cursor_screen_pos := Vector2(0, 756) + cursor_pos * Vector2(10, 18)
		draw_rect(Rect2(cursor_screen_pos, Vector2(10, 18)), Color.WHITE)
		if cursor_pos.x < len(lines[cursor_pos.y]):
			draw_string(font, Vector2(cursor_screen_pos.x, cursor_screen_pos.y + 14), lines[cursor_pos.y][cursor_pos.x], HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color.BLACK)

func draw_lines(lines: Array) -> void:
	for i in range(len(lines)):
		draw_string(font, Vector2(0, 770 + 18 * i), lines[i], HORIZONTAL_ALIGNMENT_LEFT, 1600, 20)

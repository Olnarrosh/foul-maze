class_name MessageLog
extends Node

## Rolling list of recent game messages shown in the console's lower text field.
## Map posts messages through its message_posted signal, which Console connects to add_message().

## Emitted whenever the log contents change, so the console can redraw.
signal log_changed

## How many of the most recent messages are kept.
const MESSAGE_LOG_LIMIT: int = 8

## Stored messages, oldest first.
var messages: Array[String] = []

## Appends a message, dropping the oldest entries beyond MESSAGE_LOG_LIMIT. Empty messages are ignored.
func add_message(message: String) -> void:
	if message.is_empty():
		return
	messages.append(message)
	while messages.size() > MESSAGE_LOG_LIMIT:
		messages.pop_front()
	log_changed.emit()

## Removes every stored message. Console calls this when a new level or game starts.
func clear() -> void:
	messages.clear()
	log_changed.emit()

## Returns the stored messages as one newline-separated string.
func get_text() -> String:
	return "\n".join(messages)

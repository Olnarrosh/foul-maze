class_name SoundPlayer
extends Node

## Plays one-shot sound effects. Map requests sounds by name through its sound_requested signal.
## Each play() spawns a temporary AudioStreamPlayer that frees itself when the sound finishes.

## Sound effect streams keyed by the names Map uses in _play_sound().
const SOUND_STREAMS: Dictionary = {
	"enchant": preload("res://sound/enchant.sfxr"),
	"grenade": preload("res://sound/grenade.sfxr"),
	"grenade_e": preload("res://sound/grenade_e.sfxr"),
	"hit1": preload("res://sound/hit1.sfxr"),
	"hit2": preload("res://sound/hit2.sfxr"),
	"hit3": preload("res://sound/hit3.sfxr"),
	"hit4": preload("res://sound/hit4.sfxr"),
	"identify": preload("res://sound/identify.sfxr"),
	"item": preload("res://sound/item.sfxr"),
	"orblet": preload("res://sound/orblet.sfxr"),
	"power": preload("res://sound/power.sfxr"),
	"spell1": preload("res://sound/spell1.sfxr"),
	"spell2": preload("res://sound/spell2.sfxr"),
	"transform": preload("res://sound/transform.sfxr")
}

## Plays the named sound once. Unknown names and calls made outside the scene tree are ignored.
func play(sound_name: String) -> void:
	if not SOUND_STREAMS.has(sound_name) or not is_inside_tree():
		return
	var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
	audio_player.stream = SOUND_STREAMS[sound_name]
	audio_player.finished.connect(audio_player.queue_free)
	add_child(audio_player)
	audio_player.play()

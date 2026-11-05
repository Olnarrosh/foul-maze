class_name EnemyCreature
extends Creature

enum Behavior {WANDER, FOLLOW, SLEEP, URINATE, HUNT, FLEE}

var spawn_position: Vector2i
var awareness_mode: String = "unaware"
var awareness_turn: int = 0
var detection_range: float = 0.0
var detection_range_min: float = 0.0
var detection_range_max: float = 0.0
var last_seen_player_pos: Vector2i = Vector2i(-1, -1)
var last_seen_player_turn: int = -1
var last_seen_conspecific_pos: Vector2i = Vector2i(-1, -1)
var alerted_player_pos: Vector2i = Vector2i(-1, -1)
var sight_history_turn: int = 0
var enemy_sight_history: Array = []
var enemy_player_sight_history: Array = []
var enemy_seen_tiles_history: Array = []
var alternating_behavior: int = 0
var behavior_turns_left: int = 0
var behavior_mode: String = ""
var hazard_avoidance: Dictionary = {}

## Builds an enemy instance from a creature kind definition in CreatureData.creatures.
func _init(definition: Dictionary, spawn_position_in: Vector2i, spawn_time: float) -> void:
	creature_name = definition.name
	glyph = definition.char
	color = definition.fg
	move_speed = definition.move_speed
	attack_speed = definition.attack_speed
	sight_range = definition.sight_range
	max_health = definition.health
	health = max_health
	damage = definition.damage
	accuracy = definition.accuracy
	armor = definition.armor
	evasion = definition.evasion
	category = definition.category
	description = definition.desc
	traits.assign(definition.get("traits", []))
	resistances.assign(definition.get("resistances", []))
	attack_str.assign(definition.get("attack_str", []))
	super()
	pos = spawn_position_in
	spawn_position = spawn_position_in
	last_seen_conspecific_pos = spawn_position_in
	detection_range = maxf(0.0, float(sight_range) * 0.5)
	detection_range_min = float(sight_range) * 0.5
	detection_range_max = float(sight_range) * 2.0
	alternating_behavior = randi_range(0, 2)
	time = int(spawn_time + float(randi_range(0, maxi(0, move_speed - 1))))
	status = []
	if "Ephemeral" in traits:
		status.append(StatusData.Status.new("Temporary", 20))

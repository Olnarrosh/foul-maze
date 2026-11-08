@abstract
class_name Creature
extends Node

var creature_name: String
var glyph: String
var color: int
var move_speed: int
var attack_speed: int
var sight_range: int
var max_health: int
var health: int
var regen_progress: float
var damage: int
var accuracy: int
var armor: int
var evasion: int
var category: CreatureData.CreatureCategory
var description: String
var delay: int
var pos: Vector2i
var traits: Array[String]
var attack_str: Array[String]
var status: Array[StatusData.Status]
var visible_tiles: Dictionary[Vector2i, bool]
var resistances: Array[String]
var environment_checked_time: float = -1.0
var sleeping_regen: bool = false
var time: int
var id: int = 0
var transference_id: int = 0
var player_visible_turns: int = 0
var last_action_cost: float = 0.0
## Time at which the creature's next special ability (breath, healing spell, ...) is ready.
## No creature has more than one ability cooldown, so a single value suffices.
var ability_ready_at: float = 0.0
## Carried item for creatures with the Thief trait. Null when the creature is not carrying anything.
var stolen_item: Item = null
## Transient per-creature code flags (death bookkeeping, environment turn bookkeeping, ...).
## Flags that are set are present with value true; absent flags are false.
var flags: Dictionary[String, bool] = {}

func _init() -> void:
	regen_progress = 0
	status = []
	visible_tiles = {}
	time = 0
	delay = randi() % maxi(1, move_speed)

# Check if this creature has the specified trait.
# Traits are stored as strings in the traits Array.
# Common traits include: Flying, Amphibious, Mindless, No Regeneration, etc.
# Example: if creature.has_trait("Flying"): ...
func has_trait(trait_name: String) -> bool:
	return traits.has(trait_name)

# Check if this creature has the specified flag set.
# Flags are stored in a Dictionary[String, bool] and are used for
# per-creature state tracking (death bookkeeping, environment turn bookkeeping, etc.)
# Present flags have value true; absent flags are false.
func has_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

# Set or clear a flag on this creature.
# Flags are used for per-creature state tracking (death bookkeeping,
# environment turn bookkeeping, etc.).
# If value is true, the flag is set; if false, it is erased.
func set_flag(flag_name: String, value: bool = true) -> void:
	if value:
		flags[flag_name] = true
	else:
		flags.erase(flag_name)

func has_named_immunity(status_name: String) -> bool:
	if traits.has("Mindless") and status_name in ["Confused", "Frightened"]:
		return true
	return resistances.has(status_name.capitalize()) or resistances.has(status_name.to_lower()) or resistances.has(status_name.to_upper())

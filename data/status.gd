class_name StatusData
extends Node

# Game status effects that can be applied to creatures.
# Each status has an effect_type that determines when it triggers:
#   END_TURN: runs at the end of each creature turn
#   DELAY: modifies creature action delay
#   AI_BEHAVIOR: changes creature AI mode
#   DIRECTION: alters movement direction
#   VISION: modifies sight range
#   DAMAGE: deals damage each turn
#   REGENERATION: inverts or modifies health regen
#
# Each status also has an effect_func (Callable) that implements the behavior,
# and a negation list of statuses that cancel this status when applied.

## Effects trigger at the gameplay boundary named by their effect type. Each
## callable receives (entity, context) and mutates the context when needed.
enum EffectType {
	END_TURN,     # runs at the end of each creature turn
	DELAY,        # modifies creature action delay
	AI_BEHAVIOR,  # changes creature AI mode
	DIRECTION,    # alters movement direction
	VISION,       # modifies sight range
	DAMAGE,       # deals damage each turn
	REGENERATION, # inverts or modifies health regen
	ACTION        # miscellaneous action effects
}

class Status:
	# A status effect applied to a creature.
	# Properties:
	#   status_name: the name of the status (e.g. "Poisoned", "Burning")
	#   duration: number of turns remaining (decreases each turn)
	#   effect_type: EffectType that determines when the effect triggers
	#   effect_func: Callable that implements the effect behavior
	#   negation: Array of status names that cancel this status when applied
	#   id: unique identifier for the status instance
	var status_name: String
	var duration: int
	var effect_type: EffectType
	var effect_func: Callable
	var negation: Array
	var id: int
	
	@warning_ignore_start("shadowed_variable")
	func _init(status_name: String, duration: int):
		self.status_name = status_name
		self.duration = duration
		self.effect_type = STATUS_DEFINITIONS[status_name]["effect_type"]
		self.effect_func = STATUS_DEFINITIONS[status_name]["effect_func"]
		self.negation = STATUS_DEFINITIONS[status_name]["negation"]
		self.id = -1
	@warning_ignore_restore("shadowed_variable")

# Status definitions map status names to their configuration.
# Each entry has:
#   effect_type: when the effect triggers (EffectType enum)
#   effect_func: the callable that implements the effect
#   negation: Array of status names that cancel this status when applied
#
# Example: "Burning" triggers END_TURN, uses _effect_burning, and is negated by "Frozen" or "Wet"
const STATUS_DEFINITIONS: Dictionary = {
	"Burning": {"effect_type": EffectType.END_TURN, "effect_func": Callable(StatusData, "_effect_burning"), "negation": ["Frozen", "Wet"]},
	"Frozen": {"effect_type": EffectType.DELAY, "effect_func": Callable(StatusData, "_effect_frozen"), "negation": ["Burning", "Quickened"]},
	"Wet": {"effect_type": EffectType.ACTION, "effect_func": Callable(StatusData, "_effect_wet"), "negation": ["Burning"]},
	"Frightened": {"effect_type": EffectType.AI_BEHAVIOR, "effect_func": Callable(StatusData, "_effect_frightened"), "negation": ["Enraged"]},
	"Enraged": {"effect_type": EffectType.AI_BEHAVIOR, "effect_func": Callable(StatusData, "_effect_enraged"), "negation": ["Frightened"]},
	"Confused": {"effect_type": EffectType.DIRECTION, "effect_func": Callable(StatusData, "_effect_confused"), "negation": []},
	"Blind": {"effect_type": EffectType.VISION, "effect_func": Callable(StatusData, "_effect_blind"), "negation": ["Cat-eyed"]},
	"Cat-eyed": {"effect_type": EffectType.VISION, "effect_func": Callable(StatusData, "_effect_cat_eyed"), "negation": ["Blind"]},
	"Quickened": {"effect_type": EffectType.DELAY, "effect_func": Callable(StatusData, "_effect_quickened"), "negation": ["Frozen"]},
	"Invisible": {"effect_type": EffectType.ACTION, "effect_func": Callable(StatusData, "_effect_invisible"), "negation": ["Burning", "Wet"]},
	"Protection": {"effect_type": EffectType.DAMAGE, "effect_func": Callable(StatusData, "_effect_protected"), "negation": []},
	"Protected": {"effect_type": EffectType.DAMAGE, "effect_func": Callable(StatusData, "_effect_protected"), "negation": []},
	"Transference": {"effect_type": EffectType.ACTION, "effect_func": Callable(StatusData, "_effect_noop"), "negation": []},
	"Helpless": {"effect_type": EffectType.ACTION, "effect_func": Callable(StatusData, "_effect_noop"), "negation": []},
	"Sleeping": {"effect_type": EffectType.ACTION, "effect_func": Callable(StatusData, "_effect_noop"), "negation": []},
	"Poisoned": {"effect_type": EffectType.REGENERATION, "effect_func": Callable(StatusData, "_effect_poisoned"), "negation": []},
	"Paralyzed": {"effect_type": EffectType.ACTION, "effect_func": Callable(StatusData, "_effect_noop"), "negation": []},
	"Weakened": {"effect_type": EffectType.ACTION, "effect_func": Callable(StatusData, "_effect_noop"), "negation": []},
	"Temporary": {"effect_type": EffectType.ACTION, "effect_func": Callable(StatusData, "_effect_noop"), "negation": []},
}

const ADJACENT_DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i(1, -1), Vector2i.RIGHT, Vector2i(1, 1),
	Vector2i.DOWN, Vector2i(-1, 1), Vector2i.LEFT, Vector2i(-1, -1)
]

static func _status_name(status: Status) -> String:
	return status.status_name

static func _status_duration(status: Status) -> int:
	return status.duration

static func _status_effect_type(status: Status) -> int:
	return int(status.effect_type)

## Resistances to both statuses and damage types are configured per creature.
## damage_callback, when supplied in context, has signature (entity, amount, type).
static func apply_status(entity: Creature, status_name: String, duration: int, context: Dictionary = {}) -> bool:
	if status_name == "Protection" and has_status(entity, "Protection"):
		for s in entity.status:
			if _status_name(s) == "Protection":
				s.duration = maxi(s.duration, duration)
				return true
		return false
	if entity.has_named_immunity(status_name):
		return false
	var new_status: Status = Status.new(status_name, duration)
	if status_name == "Frozen" and has_status(entity, "Wet"):
		remove_status(entity, "Wet")
		_apply_context_damage(entity, 1, "cold", context)
	elif status_name == "Wet" and has_status(entity, "Frozen"):
		_apply_context_damage(entity, 1, "cold", context)
		return false

	var statuses: Array = entity.status
	var new_negations: Array = new_status.negation
	var existing_duration: int = 0
	for index: int in range(statuses.size() - 1, -1, -1):
		var s: Status = statuses[index]
		var existing_name: String = _status_name(s)
		if existing_name == status_name:
			existing_duration = maxi(existing_duration, _status_duration(s))
			statuses.remove_at(index)
			continue
		var existing_negations: Array = s.negation
		if new_negations.has(existing_name) or existing_negations.has(status_name):
			statuses.remove_at(index)
	new_status.duration = maxi(existing_duration, duration)
	statuses.append(new_status)
	entity.status = statuses
	if status_name == "Burning":
		remove_status(entity, "Invisible")
	return true

static func has_status(entity: Creature, status_name: String) -> bool:
	for s in entity.status:
		if _status_name(s) == status_name:
			return true
	return false

static func consume_status(entity: Creature, status_name: String) -> bool:
	var statuses: Array = entity.status
	for index: int in range(statuses.size() - 1, -1, -1):
		var s: Status = statuses[index]
		if _status_name(s) == status_name:
			statuses.remove_at(index)
			entity.status = statuses
			return true
	entity.status = statuses
	return false

static func remove_status(entity: Creature, status_name: String) -> bool:
	var statuses: Array = entity.status
	var removed: bool = false
	for index: int in range(statuses.size() - 1, -1, -1):
		var s: Status = statuses[index]
		if _status_name(s) == status_name:
			statuses.remove_at(index)
			removed = true
	entity.status = statuses
	return removed

static func trigger(entity: Creature, effect_type: EffectType, context: Dictionary = {}) -> void:
	for s in entity.status.duplicate():
		if int(_status_effect_type(s)) != int(effect_type):
			continue
		var effect_func: Callable = s.effect_func
		if effect_func.is_valid():
			effect_func.call(entity, context)

static func finish_turn(entity: Creature, context: Dictionary = {}) -> void:
	trigger(entity, EffectType.END_TURN, context)
	var statuses: Array = entity.status
	for index: int in range(statuses.size() - 1, -1, -1):
		var s: Status = statuses[index]
		if s.status_name == "Helpless":
			continue
		s.duration = _status_duration(s) - 1
		if _status_duration(s) <= 0:
			statuses.remove_at(index)
	entity.status = statuses

static func _apply_context_damage(entity: Creature, amount: int, damage_type: String, context: Dictionary) -> void:
	var damage_callback: Callable = context.get("damage_callback", Callable())
	if damage_callback.is_valid():
		damage_callback.call(entity, amount, damage_type)

static func _effect_noop(_entity: Creature, _context: Dictionary) -> void:
	pass

static func _effect_burning(entity: Creature, context: Dictionary) -> void:
	if has_status(entity, "Wet"):
		remove_status(entity, "Wet")
		remove_status(entity, "Burning")
		return
	_apply_context_damage(entity, 1, "fire", context)

static func _effect_frozen(_entity: Creature, context: Dictionary) -> void:
	if int(context.get("delay", 0)) > 0:
		context.delay = maxi(1, roundi(float(context.get("delay", 0)) * 2.0))

static func _effect_wet(entity: Creature, context: Dictionary) -> void:
	var action: String = str(context.get("action", ""))
	if action == "burning":
		remove_status(entity, "Wet")
		var burning_callback: Callable = context.get("apply_burning_callback", Callable())
		if burning_callback.is_valid():
			burning_callback.call(entity)

static func _effect_frightened(_entity: Creature, context: Dictionary) -> void:
	context.ai_mode = "flee"

static func _effect_enraged(_entity: Creature, context: Dictionary) -> void:
	context.ai_mode = "seek_nearest"

static func _effect_confused(_entity: Creature, context: Dictionary) -> void:
	var intended: Vector2i = context.get("direction", Vector2i.ZERO)
	var available: Array = context.get("available_directions", [])
	if intended == Vector2i.ZERO:
		if not available.is_empty():
			context.direction = available.pick_random()
		return
	var intended_index: int = ADJACENT_DIRECTIONS.find(intended)
	if intended_index < 0:
		if not available.is_empty():
			context.direction = available.pick_random()
		return
	var choices: Array[Vector2i] = []
	var valid_choices: Array[Vector2i] = []
	for candidate: Vector2i in ADJACENT_DIRECTIONS:
		if available.has(candidate):
			valid_choices.append(candidate)
	if valid_choices.is_empty():
		return
	for offset: int in [-1, 0, 1]:
		var candidate: Vector2i = ADJACENT_DIRECTIONS[posmod(intended_index + offset, ADJACENT_DIRECTIONS.size())]
		if valid_choices.has(candidate):
			choices.append(candidate)
	if not choices.is_empty():
		context.direction = choices.pick_random()
	else:
		context.direction = valid_choices.pick_random()

static func _effect_blind(_entity: Creature, context: Dictionary) -> void:
	context.sight_range = 1

static func _effect_cat_eyed(_entity: Creature, context: Dictionary) -> void:
	context.sight_range = int(context.get("sight_range", 1)) * 2

static func _effect_quickened(_entity: Creature, context: Dictionary) -> void:
	if int(context.get("delay", 0)) > 0:
		context.delay = maxi(1, roundi(float(context.get("delay", 0)) * 0.5))

static func _effect_invisible(entity: Creature, context: Dictionary) -> void:
	var action: String = str(context.get("action", ""))
	if action == "move" or action == "attack" or action == "throw" or action == "burning" or action == "wet":
		remove_status(entity, "Invisible")

static func _effect_protected(entity: Creature, context: Dictionary) -> void:
	var damage: int = maxi(0, int(context.get("damage", 0)))
	if damage <= 0:
		return
	for s in entity.status:
		if _status_name(s) not in ["Protection", "Protected"]:
			continue
		s.duration = _status_duration(s) - damage
		context.damage = 0
		if _status_duration(s) <= 0:
			remove_status(entity, _status_name(s))
		return

static func _effect_poisoned(_entity: Creature, context: Dictionary) -> void:
	context.rate_factor = float(context.get("rate_factor", 1.0)) * 3.0
	context.inverts_regeneration = true

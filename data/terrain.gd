class_name TerrainData
extends Node

# Terrain types define what occupies each tile on the map.
# Each TileType has associated properties: glyph, passability, danger,
# visual colors, movement cost, and optional terrain effects.
enum TileType {
	WALL,          # Impassable solid rock/earth
	FLOOR,         # Walkable floor tile
	BLANK,         # Empty space (used internally)
	STAIRS_UP,     # Up stairs to next level
	STAIRS_DOWN,   # Down stairs to next level
	ALTAR_ENCHANT, # Altar of enchantment (identify items)
	ALTAR_POWER,   # Altar of sacrifice (boost attributes)
	ALTAR_ID,      # Altar of enlightenment (identify item type)
	ALTAR_TRANSFORM, # Altar of transformation (change item type)
	MOSS,          # Fungi growth on floor
	TREE,          # Solid tree (blocks movement)
	SHRUB,         # Bush (can usually pass through)
	WATER_SHALLOW, # Shallow water (affects movement, wets creatures)
	WATER_DEEP,    # Deep water (affects movement, damages non-aquatic)
	ICE,           # Frozen surface (slippery)
	SNOW,          # Snowy ground (movement cost)
	SLIME_PIT,     # Acidic slime (damages over time)
	GLOWING_POOL,  # Magical pool (poisons creatures)
	GEYSER,        # Steam vent (generates steam environment)
	LAVA,          # Lava (damages creatures severely)
	STALAGMITE,    # Cave ceiling formation (blocks passage)
	ASHES,         # Burnt remains (flammable)
	BARRICADE,     # Town wall barrier
	PUDDLE,        # Liquid residue on floor
}

enum Flammability {
	FULL_FIRE, # can catch fire and burn
	LIMITED_FIRE, # can burn, but only briefly, and adjacent fires don't propagate to this terrain
	NO_FIRE, # cannot burn
	EXTINGUISH_STEAM, # cannot burn, and extinguishes burning creatures while generating steam
	EXTINGUISH_MELT_TO_FLOOR, # cannot burn, and extinguishes burning creatures while becoming floor
	EXTINGUISH_MELT_TO_WATER, # cannot burn, and extinguishes burning creatures while becoming water
	EVAPORATE, # on contact with fire, becomes floor and slightly reduces fire intensity
	}

class Terrain:
	var terrain_name: String
	var glyph: String
	var occluding: bool
	var passable: bool
	var dangerous: bool
	var move_cost: float
	var fg: int
	var bg: int
	var determiner: String
	var contains: bool # whether this tile has special content (e.g., items)
	var flammability: Flammability # how fire interacts with this terrain
	var timer: int = -1 # should be set externally when generated
	var effect_altar: Callable # effect on an item lying here when no creature is on the tile
	var effect_timed: Callable # effect when the timer has run out
	var effect_entered: Callable # effect when starting turn here
	var affects_flyers: bool # whether the turn start effect affects flying creatures

	@warning_ignore_start("shadowed_variable")
	func _init(terrain_name: String, glyph: String, occluding: bool, passable: bool, dangerous: bool, fg: int, bg: int, determiner: String, flammability: Flammability, move_cost: float = 1.0, contains: bool = false, effect_type: String = "", effect: String = ""):
		self.terrain_name = terrain_name
		self.glyph = glyph
		self.occluding = occluding
		self.passable = passable
		self.dangerous = dangerous
		self.fg = fg
		self.bg = bg
		self.flammability = flammability
		self.determiner = determiner
		self.move_cost = move_cost
		self.contains = contains
		match effect_type:
			"altar":
				effect_altar = Callable(self, effect)
			"timer":
				effect_timed = Callable(self, effect)
			"walking":
				effect_entered = Callable(self, effect)
				affects_flyers = false
			"walking_or_flying":
				effect_entered = Callable(self, effect)
				affects_flyers = true
	@warning_ignore_restore("shadowed_variable")
	
	func water_shallow_entered(entity: Creature, position: Vector2i, map: Node) -> void:
		map._apply_water_wetness(entity, position)

	func water_deep_entered(entity: Creature, position: Vector2i, map: Node) -> void:
		map._apply_water_wetness(entity, position)
		if not entity.has_trait("Aquatic") and (entity is PlayerCreature or entity.category != CreatureData.CreatureCategory.UNHOLY):
			map._status_damage_callback(entity, 1, "physical")

	func glowing_pool_entered(entity: Creature, _position: Vector2i, map: Node) -> void:
		if not entity.has_named_immunity("Poison"):
			map.apply_status_to_entity(entity, "Poisoned", 2)

	func lava_entered(entity: Creature, _position: Vector2i, map: Node) -> void:
		map._status_damage_callback(entity, 99, "fire")
	
	func altar_enchant(altar_item: Item, item_type: String, _item_grid: Dictionary[Vector2i, Item], _position: Vector2i, _player: PlayerCreature, item_str_func: Callable) -> Dictionary:
		if altar_item.enchantment > 8:
			return {}
		altar_item.enchantment += 1
		if item_type == "weapon":
			altar_item.damage += 1
		elif item_type == "armor":
			altar_item.armor += 1
		elif item_type == "projectile":
			altar_item.damage += ItemData.get_projectile_base_damage(altar_item.item_name)
			altar_item.poison_duration += floori(ItemData.get_projectile_base_poison_duration(altar_item.item_name) * 0.5)
		return {"message": "The gods bless %s." % item_str_func.call(altar_item, true), "sound": "enchant"}
	
	func altar_power(_altar_item: Item, item_type: String, item_grid: Dictionary[Vector2i, Item], position: Vector2i, player: PlayerCreature, _item_str_func: Callable) -> Dictionary:
		var stat_for_item: int = -1
		var stat_name = ""
		match item_type:
			"weapon":
				stat_for_item = PlayerData.Stat.STRENGTH
				stat_name = "strength"
			"armor":
				stat_for_item = PlayerData.Stat.CONSTITUTION
				stat_name = "constitution"
			"wand":
				stat_for_item = PlayerData.Stat.INTELLIGENCE
				stat_name = "intelligence"
			"charm":
				stat_for_item = PlayerData.Stat.DEXTERITY
				stat_name = "dexterity"
		if stat_for_item < 0 or PlayerData.stats[stat_for_item] > 8:
			return {}
		PlayerData.change_stat(stat_for_item, 1, player)
		item_grid.erase(position)
		return {"message": "The gods accept your offering and grant you %s." % stat_name, "sound": "power"}
	
	func altar_id(altar_item: Item, item_type: String, _item_grid: Dictionary[Vector2i, Item], _position: Vector2i, _player: PlayerCreature, item_str_func: Callable) -> Dictionary:
		var item_id_status: int = altar_item.get_id_status()
		if item_id_status == ItemData.ID_STATUS.FULL_ID or item_type == "projectile":
			return {}
		if item_type == "grenade" and item_id_status != ItemData.ID_STATUS.NO_ID:
			return {}
		else:
			altar_item.identify_fully()
		return {"message": "The gods grant you insight about %s." % item_str_func.call(altar_item, true), "sound": "identify"}
	
	func altar_transform(altar_item: Item, item_type: String, item_grid: Dictionary[Vector2i, Item], position: Vector2i, _player: PlayerCreature, item_str_func: Callable) -> Dictionary:
		var old_item = altar_item.item_name
		var current_name: String = altar_item.item_name
		var subtype_options: Array[Dictionary] = []
		for subtype: Dictionary in ItemData.ITEM_SUBTYPES[item_type]:
			if subtype["name"] != current_name:
				subtype_options.append(subtype)
		if subtype_options.is_empty():
			return {}
		var transformed: Item = Item.create_from_subtype(item_type, subtype_options.pick_random(), 0)
		transformed.enchantment = altar_item.enchantment
		var old_ego := ""
		if item_type == "weapon":
			transformed.damage += transformed.enchantment
			old_ego = altar_item.ego
		elif item_type == "armor":
			transformed.armor += transformed.enchantment
			old_ego = altar_item.ego
		if old_ego:
			var ego_pool: Array = ItemData.WEAPON_EGOS if item_type == "weapon" else ItemData.ARMOR_EGOS if item_type == "armor" else []
			var available_egos: Array[String] = []
			for ego: Dictionary in ego_pool:
				if ego.name == old_ego:
					continue
				if item_type == "weapon" and not ego.weapon_subtypes.has(transformed.item_name):
					continue
				available_egos.append(ego.name)
			if available_egos.is_empty():
				return {}
			transformed.ego = available_egos.pick_random()
			transformed.ego_unid = ItemData.get_runic_name()
		if not transformed:
			return {}
		item_grid[position] = transformed
		return {"message": "The gods transform %s into %s." % [old_item, item_str_func.call(transformed, false)], "sound": "transform"}
	
	func erupt(_terrain_grid: Dictionary[Vector2i, Terrain], environment_grid: Dictionary, position: Vector2i) -> void:
		# Geyser: adds steam environment at the position
		var is_steam: bool = false
		if environment_grid.has(position):
			var current: Dictionary = environment_grid[position]
			is_steam = current.has("type") and current["type"] == "steam"
		if not environment_grid.has(position) or not is_steam:
			environment_grid[position] = {"type": "steam", "concentration": 50, "burns_terrain": false}
		timer = randi_range(2000, 4000)
		
	func evaporate(terrain_grid: Dictionary[Vector2i, Terrain], _environment_grid: Dictionary, position: Vector2i) -> void:
		terrain_grid[position] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)
		
static func get_terrain(terrain: TileType) -> Terrain:
	var terr: Terrain = TILE_DATA[terrain]
	if terr.effect_timed.is_valid():
		var new_terr: Terrain = Terrain.new(terr.terrain_name, terr.glyph, terr.occluding, terr.passable, terr.dangerous, terr.fg, terr.bg, terr.determiner, terr.flammability, terr.move_cost, terr.contains)
		new_terr.effect_timed = terr.effect_timed
		return new_terr
	return terr

static var TILE_DATA: Dictionary = {
	TileType.WALL: Terrain.new("cave wall", "▓", true, false, true, 8, 3, "the", Flammability.NO_FIRE, INF),
	TileType.FLOOR: Terrain.new("cave floor", ".", false, true, false, 7, 0, "the", Flammability.LIMITED_FIRE, 1.0, false),
	TileType.STAIRS_UP: Terrain.new("stairs leading up", ">", true, true, false, 11, 8, "", Flammability.NO_FIRE),
	TileType.STAIRS_DOWN: Terrain.new("stairs leading down", "<", true, true, false, 11, 8, "", Flammability.NO_FIRE),
	TileType.ALTAR_ENCHANT: Terrain.new("altar of enchantment", "±", false, true, false, 12, 0, "an", Flammability.NO_FIRE, 1.0, false, "altar", "altar_enchant"),
	TileType.ALTAR_POWER: Terrain.new("altar of sacrifice", "=", false, true, false, 13, 0, "an", Flammability.NO_FIRE, 1.0, false, "altar", "altar_power"),
	TileType.ALTAR_ID: Terrain.new("altar of enlightenment", "⍛", false, true, false, 14, 0, "an", Flammability.NO_FIRE, 1.0, false, "altar", "altar_id"),
	TileType.ALTAR_TRANSFORM: Terrain.new("altar of transformation", "≠", false, true, false, 11, 0, "an", Flammability.NO_FIRE, 1.0, false, "altar", "altar_transform"),
	TileType.MOSS: Terrain.new("mossy ground", ".", false, true, false, 15, 1, "the", Flammability.FULL_FIRE, 1.0, false),
	TileType.TREE: Terrain.new("tree", "Ψ", true, false, true, 15, 1, "a", Flammability.FULL_FIRE),
	TileType.SHRUB: Terrain.new("shrubbery", "ო", true, true, false, 15, 1, "a", Flammability.FULL_FIRE, 2.0, true),
	TileType.WATER_SHALLOW: Terrain.new("shallow lake", "≈", false, true, false, 15, 12, "a", Flammability.EXTINGUISH_STEAM, 2.0, true, "walking", "water_shallow_entered"),
	TileType.WATER_DEEP: Terrain.new("deep lake", "≈", false, true, true, 0, 12, "a", Flammability.EXTINGUISH_STEAM, 2.0, false, "walking", "water_deep_entered"),
	TileType.ICE: Terrain.new("frozen lake", "=", false, true, false, 12, 15, "a", Flammability.EXTINGUISH_MELT_TO_WATER),
	TileType.SNOW: Terrain.new("snowy ground", ".", false, true, false, 0, 15, "the", Flammability.EXTINGUISH_MELT_TO_FLOOR, 1.5, true),
	TileType.SLIME_PIT: Terrain.new("slime pit", "░", false, true, false, 0, 9, "a", Flammability.NO_FIRE, 2.0, true),
	TileType.GLOWING_POOL: Terrain.new("glowing pool", "0", false, true, false, 7, 13, "a", Flammability.NO_FIRE, 1.5, true, "walking", "glowing_pool_entered"),
	TileType.GEYSER: Terrain.new("steam geyser", "ϒ", false, true, true, 15, 12, "a", Flammability.EXTINGUISH_STEAM, INF, true, "timer", "erupt"),
	TileType.LAVA: Terrain.new("lava", ",", false, true, true, 0, 10, "some", Flammability.NO_FIRE, 2.0, false, "walking_or_flying", "lava_entered"),
	TileType.STALAGMITE: Terrain.new("stalagmite", "Λ", false, false, true, 7, 0, "a", Flammability.NO_FIRE),
	TileType.ASHES: Terrain.new("ashes", ".", false, true, false, 7, 8, "some", Flammability.NO_FIRE, 1.0, true),
	TileType.BARRICADE: Terrain.new("wooden wall", "#", true, false, true, 7, 0, "a", Flammability.FULL_FIRE),
	TileType.PUDDLE: Terrain.new("puddle of urine", ".", false, true, false, 11, 0, "a", Flammability.LIMITED_FIRE, 1.0, true, "timer", "evaporate"),
}

class_name Map
extends Node

const MAP_W: int = 120
const MAP_H: int = 40
const CONSOLE_W: int = 160
const VIEW_X: int = 0
const VIEW_Y: int = 0
const VIEW_W: int = 120
const VIEW_H: int = 40
const EDGE: int = 1

enum Biome {
	CAVE,
	COLOSSAL,
	ROOMS,
	TOWN,
	SLIME,
	WATER,
	FOREST,
	WATER_AND_FOREST,
	FIRE,
	ICE
}

const MAX_LEVEL: int = 27
const ALTAR_LEVEL_COUNT: int = 26
const ALTAR_EXTRA_COUNT: int = 9
static var _altar_primary_schedule: Dictionary = {}
static var _altar_extra_schedule: Dictionary = {}
static var ID_TRANSFORM_ALTAR_LEVELS: Array[int] = []

const ENV_TICK_INTERVAL: Dictionary[String, int] = {"steam": 5, "smoke": 15, "fire": 25}

const REGEN_FULL_HEALTH_TIME: int = 5000

var _biome: Biome
var end_biome: Biome = Biome.FIRE
var _initialized: bool = false
var _is_active_map: bool = false
var grid: Dictionary[Vector2i, TerrainData.Terrain] = {}
var environment: Dictionary = {}
var environment_time: int = 0
var environment_next_tick: Dictionary = {"steam": ENV_TICK_INTERVAL["steam"], "smoke": ENV_TICK_INTERVAL["smoke"], "fire": ENV_TICK_INTERVAL["fire"]}
var creature: Dictionary[Vector2i, Creature] = {}
var item: Dictionary[Vector2i, Item] = {}

var show_inventory: bool = false
var equip_selection_active: bool = false
var activate_item_selection_active: bool = false
var look_mode: bool = false
var drop_selection_active: bool = false
var throw_item_selection_active: bool = false
var throw_target_mode: bool = false
var wand_target_mode: bool = false
var throw_inventory_index: int = -1
var activate_inventory_index: int = -1
var inspect_mode: bool = false
var inspect_description: String = ""
var inspect_item_selection_active: bool = false
var inspect_inventory_index: int = -1
var _inspect_entries: Array[Dictionary] = []
var _inspect_entry_index: int = -1
var console_cursor_position: Vector2i = Vector2i(-1, -1)
var look_cursor_position: Vector2i = Vector2i(-1, -1)
var _visible_target_positions: Array[Vector2i] = []
var _visible_target_index: int = -1
var _inspect_focus_signature: String = ""
var _player_death_logged: bool = false
var _hit_sound_played_this_player_turn: bool = false
var tutorial_messages_shown: Dictionary[String, bool] = {}
var _last_visible_creature_ids: Dictionary[int, bool] = {}
var _last_visible_item_keys: Dictionary[String, bool] = {}
var _suppress_sighting_log_item_keys: Dictionary[String, bool] = {}
const TUTORIAL_MESSAGES: Dictionary = {
	"welcome": "Welcome! Use the keypad, mouse, or HJKLYUBN to explore the Foul Maze.\nUse the mouse or Z and the movement keys (use Escape to switch back to moving) to see what the tiles represent.",
	"enemy_sighting": "You've spotted an enemy. Hover over it and press X to inspect it. Walk into it to attack. Note that most weapons and monsters can't attack diagonally.",
	"item_sighting": "You found an item. Step on it to pick it up.",
	"item_pickup": "You've gained an item. You can open your inventory with I and press X followed by its associated key to inspect it.",
	"stairs_down": "You've found the stairs to the next level. Descend when you're ready.",
	"enchant_altar": "Drop an item on an altar of enchantment to increase the item's power.",
	"power_altar": "Drop an item on an altar of sacrifice to destroy it and increase your attributes.\nWeapons give you strength, allowing you to use heavier weapons and throw items further.\nArmors give you constitution, making you more durable and allowing you to wear heavier armor.\nWands give you intelligence, allowing you to use wands and charms more frequently.\nCharms give you dexterity, improving your chances to hit enemies and to dodge their attacks.",
	"id_altar": "Drop an unidentified item on an altar of enlightenment to identify it.",
	"transform_altar": "Drop an item on an altar of transformation to change it into another item of the same kind.",
	"weapon_armor_pickup": "Weapons and armors can be equipped with W. You may incur penalties if your attribute scores are insufficient.",
	"throwable_pickup": "Grenades and throwing weapons can be thrown with T. (So can other items, but it won't achieve much.)",
	"wand_charm_pickup": "Wands and charms can be activated with A. Wands target enemies, charms target yourself.",
	"low_health": "You're injured. You may want to try finding a safe spot and resting with R.",
	"inventory_full": "You've just reached your inventory limit of 26 items. Drop or consume items to free space for new ones."
}
const PROJECTILE_BASE_DAMAGE: int = 1
const UNARMED_ATTACK_WORDS: Array[String] = ["punch", "kick", "beat", "slap", "fisticuff", "wrestle", "box", "slug", "clock", "knuckle", "sock"]

var map_above: Map
var map_below: Map
var level: int
var level_ordinal: String
var stairs_up_pos: Vector2i = Vector2i(-1, -1)
var stairs_down_pos: Vector2i = Vector2i(-1, -1)
var altar_types: Array[int] = []
var altar_positions: Array[Vector2i] = []
var town_barricade_rectangles: Array[Rect2i] = []

var player_pos: Vector2i = Vector2i.ZERO
var _player_entity: Creature
var _resting: bool = false
var _rest_took_damage: bool = false
var _rest_reached_full_health: bool = false

const REST_MAX_TURNS: int = 250

# Field of view state
var visible_tiles: Dictionary[Vector2i, bool] = {}
var seen_tiles: Dictionary[Vector2i, bool] = {}
var char_last_seen: Dictionary[Vector2i, String] = {}
var fg_last_seen: Dictionary[Vector2i, int] = {}
var bg_last_seen: Dictionary[Vector2i, int] = {}
var desc_last_seen: Dictionary[Vector2i, String] = {}
var tile_last_seen: Dictionary[Vector2i, TerrainData.Terrain] = {}
var hover_tile: Vector2i = Vector2i(-1, -1)
var hover_path: Dictionary[Vector2i, bool] = {}
var hover_blast_tiles: Dictionary[Vector2i, bool] = {}
var transient_visuals: Dictionary[Vector2i, Dictionary] = {}
var _throw_visual_generation: int = 0
var _throw_animation_enabled: bool = true
var auto_walk_active: bool = false
var auto_walk_target: Vector2i = Vector2i(-1, -1)
var auto_walk_initial_visible_creatures: Dictionary[int, bool] = {}
var _next_creature_id: int = 1
var creature_budget: int = 0
var respawn_budget_increment: int = 0
var _death_message_queue: Array[String] = []
var _attack_resolution_depth: int = 0
var _next_transference_id: int = 1
var _transference_links: Dictionary[int, Dictionary] = {}
const HALF_RESPAWN_INTERVAL: int = 500
var next_respawn_time: int = 1000
var _creature_population_initialized: bool = false

# emitted whenever something on the screen changes
signal redraw
signal redraw_status
signal inspect_changed
signal map_changed(next_map: Map)
signal player_died(highest_level: int, enemies_killed: int)
signal player_won(highest_level: int, enemies_killed: int)
## Emitted with each new message. The console forwards it to its MessageLog child.
signal message_posted(message: String)
## Emitted when a sound effect should play. The console forwards it to its SoundPlayer child.
signal sound_requested(sound_name: String)

var _run_root: Map
var lyrical_orblet_found: bool = false

var floor_tiles: Array[Vector2i]

func _creature_ignores_terrain_cost(entity: Creature) -> bool:
	return entity.has_trait("Flying")

func can_swim(entity: Creature) -> bool:
	return entity.has_trait("Aquatic") or entity.has_trait("Amphibious")

func _is_water_tile(tile: TerrainData.Terrain) -> bool:
	return tile.terrain_name.ends_with(" lake")

func _emit_quenching_steam(position: Vector2i) -> void:
	for offset_y: int in range(-1, 2):
		for offset_x: int in range(-1, 2):
			var steam_position: Vector2i = position + Vector2i(offset_x, offset_y)
			if steam_position.x < 0 or steam_position.x >= MAP_W or steam_position.y < 0 or steam_position.y >= MAP_H:
				continue
			var steam_concentration: int = 90 if offset_x == 0 and offset_y == 0 else 60
			var current_effect: Dictionary = _environment_effect(steam_position)
			if _environment_kind(current_effect) == "steam":
				steam_concentration = maxi(steam_concentration, _environment_concentration(current_effect))
			environment[steam_position] = {"type": "steam", "concentration": mini(ENVIRONMENT_MAX_CONCENTRATION, steam_concentration), "burns_terrain": false}
	redraw.emit()

func _is_altar_tile(tile: TerrainData.Terrain) -> bool:
	return tile.terrain_name.begins_with("altar ")
	
func _is_stairs_tile(tile: TerrainData.Terrain) -> bool:
	return tile.terrain_name.begins_with("stairs ")

func _apply_water_wetness(entity: Creature, position: Vector2i) -> void:
	var tile: TerrainData.Terrain = grid[position]
	if not _is_water_tile(tile):
		return
	if entity.has_trait("Flying") or can_swim(entity):
		StatusData.remove_status(entity, "Wet")
		return
	var was_burning: bool = StatusData.has_status(entity, "Burning")
	apply_status_to_entity(entity, "Wet", 10)
	if was_burning:
		StatusData.remove_status(entity, "Burning")
		_emit_quenching_steam(position)

func _entity_is_paralyzed(entity: Creature) -> bool:
	return StatusData.has_status(entity, "Paralyzed")

func _should_creature_flit(entity: Creature) -> bool:
	return entity.has_trait("Flitting") and randi_range(1, 3) == 1

func _terrain_movement_multiplier(tile: TerrainData.Terrain) -> float:
	return tile.move_cost

func _movement_delay_for_tile(base_delay: int, tile: TerrainData.Terrain, diagonal: bool = false) -> int:
	var multiplier: float = _terrain_movement_multiplier(tile) * (1.5 if diagonal else 1.0)
	return roundi(float(base_delay) * multiplier)

func _movement_delay_for_destination(base_delay: int, destination: Vector2i, diagonal: bool, entity: Creature) -> int:
	var movement_multiplier: float = 1.0 if _creature_ignores_terrain_cost(entity) else _terrain_movement_multiplier(grid[destination])
	return roundi(float(base_delay) * movement_multiplier * (1.5 if diagonal else 1.0))

func _creature_terrain_evasion(entity: Creature) -> int:
	if entity.has_trait("Flying"):
		return entity.evasion
	var entity_position: Vector2i = entity.pos
	var tile: TerrainData.Terrain = grid[entity_position]
	if tile.terrain_name in ["frozen lake", "slime pit"]:
		return 0
	return entity.evasion
	
var turn_queue: Array = []
var player_scent_trail: Array[Vector2i] = []
var is_player_turn: bool = true
var processing_turns: bool = false

func _init(depth: int, biome: Biome) -> void:
	level = depth
	match level % 10:
		1:
			level_ordinal = "%sst" % level
		2:
			level_ordinal = "%snd" % level
		3:
			level_ordinal = "%srd" % level
		_:
			level_ordinal = "%sth" % level
	_biome = Biome.COLOSSAL if depth == 1 else biome

func _ready() -> void:
	if _initialized:
		return
	if level == 1:
		end_biome = Biome.FIRE if randi() % 2 == 0 else Biome.ICE
		_generate_connected_maps(end_biome)
		_run_root = self
		_generate_level(true)

func start_game_after_generation() -> void:
	_generate_level(false)
	PlayerData.run_highest_level = maxi(PlayerData.run_highest_level, level)
	if not _player_entity:
		_init_player()
		_recompute_all_fov()
		_init_turn_queue(true)
		_append_message("The gate slams shut behind you. You will need to find the Lyrical Orblet to escape the Foul Maze.")
	_is_active_map = true
	_show_tutorial_once("welcome")
	_log_new_sightings()
	set_process_input(true)
	redraw.emit()

func _generate_connected_maps(final_biome: Biome) -> void:
	var previous_map: Map = self
	while previous_map.level < MAX_LEVEL:
		var next_level: int = previous_map.level + 1
		var next_map: Map = Map.new(next_level, _biome_for_level(next_level, final_biome))
		previous_map.map_below = next_map
		next_map.map_above = previous_map
		next_map.set_process_input(false)
		next_map.set_process(false)
		previous_map.add_child(next_map)
		previous_map = next_map

func _generate_level(defer_player_setup: bool = false) -> void:
	if _initialized:
		return
	_initialized = true
	_is_active_map = false
	set_process_input(false)
	_init_grid()
	var sectors: Array
	match _biome:
		Biome.COLOSSAL:
			sectors = _create_colossal_sectors()
			_run_walkers(sectors, true, 0.45, 0.65, false)
			_convert_isolated_walls_to_stalagmites()
			_connect_floors()
		Biome.TOWN:
			sectors = _create_colossal_sectors()
			var randomized_sector: int = randi_range(0, 1)
			_run_walkers(sectors, true, 0.5, 0.7, false, randomized_sector)
			_connect_floors()
			_place_town_barricades()
		Biome.ROOMS:
			sectors = _create_sectors()
			var room_centers: Array[Vector2i] = _generate_rooms(sectors)
			_connect_room_corridors(room_centers)
			_connect_floors()
		_:
			sectors = _create_sectors()
			_run_walkers(sectors)
			for sector: Dictionary in sectors:
				if randi() % 2:
					_smooth_walls(sector, 9, 6)
			if _biome == Biome.CAVE:
				_convert_isolated_walls_to_stalagmites()
			_connect_floors()
	_place_stairs()
	if _biome == Biome.CAVE:
		_place_cave_geysers()
	if _biome in [Biome.SLIME, Biome.WATER, Biome.FOREST, Biome.WATER_AND_FOREST, Biome.FIRE, Biome.ICE]:
		var biome_noise: FastNoiseLite = _create_biome_noise()
		_apply_biome_terrain(biome_noise)
	
	altar_types.clear()
	altar_positions.clear()
	if level < 1 or level > ALTAR_LEVEL_COUNT:
		return
	_ensure_altar_schedule()
	if _altar_primary_schedule.has(level):
		altar_types.append(int(_altar_primary_schedule[level]))
	if _altar_extra_schedule.has(level):
		altar_types.append(int(_altar_extra_schedule[level]))
	var strict_candidates: Array[Vector2i] = []
	var fallback_candidates: Array[Vector2i] = []
	for y: int in range(1, MAP_H - 1):
		for x: int in range(1, MAP_W - 1):
			var position: Vector2i = Vector2i(x, y)
			var tile_type: TerrainData.Terrain = grid[position]
			# Skip dangerous terrain for altar placement
			if not tile_type.passable or tile_type.dangerous or position == player_pos or position == stairs_up_pos or position == stairs_down_pos:
				continue
			if creature.has(position) or item.has(position):
				continue
			var has_impassable_neighbor: bool = false
			for direction: Vector2i in StatusData.ADJACENT_DIRECTIONS:
				var neighbor_type: TerrainData.Terrain = grid[position + direction]
				if not neighbor_type.passable or neighbor_type.dangerous:
					has_impassable_neighbor = true
					break
			if not has_impassable_neighbor:
				strict_candidates.append(position)
			fallback_candidates.append(position)
	strict_candidates.shuffle()
	fallback_candidates.shuffle()
	var candidates: Array[Vector2i] = strict_candidates if strict_candidates.size() >= altar_types.size() else fallback_candidates
	for altar_type: int in altar_types:
		var selected_position: Vector2i = Vector2i(-1, -1)
		while not candidates.is_empty():
			var candidate_position: Vector2i = candidates.pop_back()
			if altar_positions.has(candidate_position):
				continue
			selected_position = candidate_position
			break
		if selected_position.x < 0:
			break
		grid[selected_position] = TerrainData.get_terrain(altar_type)
		altar_positions.append(selected_position)
	
	if level == 1:
		if not defer_player_setup:
			_init_player()
			_recompute_all_fov()
			_init_turn_queue(true)
			_append_message("The gate slams shut behind you. You will need to find the Lyrical Orblet to escape the Foul Maze.")
		if _run_root == null:
			_run_root = self
	else:
		turn_queue.clear()
		_initialize_creature_population()
	_place_items()

func _travel_via_stairs(stair_type: TerrainData.Terrain, move_cost: int) -> bool:
	_prepare_environment_turn(_player_entity)
	_player_entity.set_flag("_environment_turn_prepared")
	if _player_entity.health <= 0:
		_player_entity.set_flag("_environment_turn_prepared", false)
		return false
	if stair_type.terrain_name == "stairs leading up" and level == 1:
		var run_root: Map = _run_root if _run_root != null else self
		if not run_root.lyrical_orblet_found:
			_player_entity.set_flag("_environment_turn_prepared", false)
			_append_message("The stairs are sealed. Find the Lyrical Orblet to open them.")
			redraw.emit()
			return false
		_finish_run_with_victory()
		_player_entity.set_flag("_environment_turn_prepared", false)
		return true
	var destination: Map
	if stair_type.terrain_name == "stairs leading up":
		if level == 1 or map_above == null:
			return false
		destination = map_above
	else:
		if level >= MAX_LEVEL or map_below == null:
			return false
		destination = map_below
	destination._generate_level()
	var destination_pos: Vector2i = destination.stairs_down_pos if stair_type.terrain_name == "stairs leading up" else destination.stairs_up_pos
	if destination_pos.x < 0 or destination_pos.y < 0:
		return false
	_apply_action_statuses(_player_entity, "move")
	var adjusted_move_cost: int = _adjust_delay(_player_entity, move_cost)
	_switch_to_map(destination, destination_pos, adjusted_move_cost)
	return true

func _finish_run_with_victory() -> void:
	var run_root: Map = _run_root if _run_root != null else self
	if run_root.lyrical_orblet_found and not run_root._player_death_logged:
		_is_active_map = false
		set_process_input(false)
		set_process(false)
		is_player_turn = false
		processing_turns = false
		cancel_auto_walk()
		run_root.player_won.emit(PlayerData.run_highest_level, PlayerData.run_enemies_killed)

func _offset_map_clock(time_offset: int) -> void:
	if is_zero_approx(time_offset):
		return
	environment_time += time_offset
	for kind: String in environment_next_tick.keys():
		environment_next_tick[kind] = float(environment_next_tick[kind]) + time_offset
	next_respawn_time += time_offset
	for entity: Creature in creature.values():
		if entity is PlayerCreature:
			continue
		entity.time = entity.time + time_offset

func _switch_to_map(destination: Map, destination_pos: Vector2i, move_cost: int) -> void:
	_reset_inspect_mode()
	_snapshot_visible_state()
	creature.erase(player_pos)
	for turn_index: int in range(turn_queue.size() - 1, -1, -1):
		if turn_queue[turn_index] == _player_entity:
			turn_queue.remove_at(turn_index)
	_is_active_map = false

	destination._generate_level()
	var run_root: Map = _run_root if _run_root != null else self
	PlayerData.run_highest_level = maxi(PlayerData.run_highest_level, destination.level)
	destination._run_root = run_root
	destination._player_entity = _player_entity
	destination.player_pos = destination_pos
	destination._player_entity.pos = destination_pos
	destination.creature.erase(destination_pos)
	destination.creature[destination_pos] = destination._player_entity
	if not destination._creature_population_initialized:
		destination._initialize_creature_population()
	destination.player_scent_trail = player_scent_trail.duplicate()
	destination.player_scent_trail.append(destination_pos)
	var adjusted_move_cost: int = move_cost
	var destination_time_offset: int = _player_entity.time - destination.environment_time
	destination._offset_map_clock(destination_time_offset)
	_advance_regeneration(_player_entity, adjusted_move_cost)
	destination._player_entity.time = destination._player_entity.time + adjusted_move_cost
	_finish_entity_turn(_player_entity)
	destination.creature[destination_pos] = destination._player_entity
	if not destination.turn_queue.has(destination._player_entity):
		destination.turn_queue.append(destination._player_entity)
	destination.turn_queue.sort_custom(destination._sort_by_time)
	destination._is_active_map = true
	destination.set_process_input(true)
	set_process_input(false)
	set_process(false)
	cancel_auto_walk()
	destination._recompute_all_fov()
	destination.redraw.emit()
	map_changed.emit(destination)
	destination._process_npc_turns()

func _biome_for_level(depth: int, final_biome: Biome) -> Biome:
	if depth >= MAX_LEVEL - 2:
		return final_biome
	var roll: int = randi() % 20
	if roll < 5:
		return Biome.CAVE
	if roll < 9:
		return Biome.WATER
	if roll < 13:
		return Biome.FOREST
	if roll < 16:
		return Biome.WATER_AND_FOREST
	if roll < 18:
		return Biome.ROOMS
	if roll < 19:
		return Biome.SLIME
	return Biome.TOWN

func _init_grid() -> void:
	environment.clear()
	environment_time = 0
	environment_next_tick = {"steam": ENV_TICK_INTERVAL["steam"], "smoke": ENV_TICK_INTERVAL["smoke"], "fire": ENV_TICK_INTERVAL["fire"]}
	for y in range(MAP_H):
		for x in range(MAP_W):
			grid[Vector2i(x, y)] = TerrainData.get_terrain(TerrainData.TileType.WALL)

func _create_colossal_sectors() -> Array[Dictionary]:
	var split_y: int = randi_range(16, 22)
	return [
		{"x_min": EDGE, "y_min": EDGE, "x_max": MAP_W - 1 - EDGE, "y_max": split_y - 1, "n": 0},
		{"x_min": EDGE, "y_min": split_y, "x_max": MAP_W - 1 - EDGE, "y_max": MAP_H - 1 - EDGE, "n": 1}
	]

func _create_sectors() -> Array:
	# Use independently staggered 2x4 layouts with guaranteed useful sector sizes.
	var top_cut_1: int = randi_range(26, 32)
	var top_cut_2: int = randi_range(56, 62)
	var top_cut_3: int = randi_range(86, 92)
	var bottom_cut_1: int = randi_range(26, 32)
	var bottom_cut_2: int = randi_range(56, 62)
	var bottom_cut_3: int = randi_range(86, 92)
	var row_split: int = randi_range(18, 21)
	var top_y_min: int = EDGE
	var top_y_max: int = row_split
	var bottom_y_min: int = row_split + 1
	var bottom_y_max: int = MAP_H - 1 - EDGE

	return [
		{"x_min": EDGE, "y_min": top_y_min, "x_max": top_cut_1, "y_max": top_y_max, "n": 0},
		{"x_min": top_cut_1 + 1, "y_min": top_y_min, "x_max": top_cut_2, "y_max": top_y_max, "n": 1},
		{"x_min": top_cut_2 + 1, "y_min": top_y_min, "x_max": top_cut_3, "y_max": top_y_max, "n": 2},
		{"x_min": top_cut_3 + 1, "y_min": top_y_min, "x_max": MAP_W - 1 - EDGE, "y_max": top_y_max, "n": 3},
		{"x_min": EDGE, "y_min": bottom_y_min, "x_max": bottom_cut_1, "y_max": bottom_y_max, "n": 4},
		{"x_min": bottom_cut_1 + 1, "y_min": bottom_y_min, "x_max": bottom_cut_2, "y_max": bottom_y_max, "n": 5},
		{"x_min": bottom_cut_2 + 1, "y_min": bottom_y_min, "x_max": bottom_cut_3, "y_max": bottom_y_max, "n": 6},
		{"x_min": bottom_cut_3 + 1, "y_min": bottom_y_min, "x_max": MAP_W - 1 - EDGE, "y_max": bottom_y_max, "n": 7}
	]
	
func _run_walkers(sectors: Array, force_walkers: bool = false, floor_min: float = 0.4, floor_max: float = 0.6, remove_connections: bool = true, randomized_sector: int = -1) -> void:
	if sectors.size() == 2:
		_generate_two_sector_walkers(sectors, floor_min, floor_max, randomized_sector)
		return
	# Generate walker positions at sector borders
	var wp := []
	wp.append(randi_range(EDGE, sectors[0].y_max))
	wp.append(randi_range(EDGE, min(sectors[1].y_max, sectors[2].y_max)))
	wp.append(randi_range(EDGE, sectors[3].y_max))
	wp.append(randi_range(sectors[4].y_min, MAP_H-1-EDGE))
	wp.append(randi_range(max(sectors[5].y_min, sectors[6].y_min), MAP_H-1-EDGE))
	wp.append(randi_range(sectors[7].y_min, MAP_H-1-EDGE))
	wp.append(randi_range(EDGE, min(sectors[0].x_max, sectors[4].x_max)))
	wp.append(randi_range(max(sectors[1].x_min, sectors[5].x_min), min(sectors[1].x_max, sectors[5].x_max)))
	wp.append(randi_range(max(sectors[2].x_min, sectors[6].x_min), min(sectors[2].x_max, sectors[6].x_max)))
	wp.append(randi_range(max(sectors[3].x_min, sectors[7].x_min), MAP_W-1-EDGE))

	# Place walkers at sector borders
	var walkers: Array = []
	# Horizontal border walkers: right/left edges of adjacent sectors
	# Top row: sector 0→1→2→3 at wp[0,1,2], bottom row: sector 4→5→6→7 at wp[3,4,5]
	for i in range(3):
		walkers.append({x=sectors[i].x_max, y=wp[i], sector=i})
		walkers.append({x=sectors[i + 1].x_min, y=wp[i], sector=i + 1})
	for i in range(3):
		walkers.append({x=sectors[i + 4].x_max, y=wp[i + 3], sector=i + 4})
		walkers.append({x=sectors[i + 5].x_min, y=wp[i + 3], sector=i + 5})
	# Vertical border walkers: top-bottom pairs at wp[6,7,8,9]
	# wp[6]→sectors 0&4, wp[7]→1&5, wp[8]→2&6, wp[9]→3&7
	for i in range(4):
		walkers.append({x=wp[6 + i], y=sectors[i].y_max, sector=i})
		walkers.append({x=wp[6 + i], y=sectors[i + 4].y_min, sector=i + 4})

	# Remove 1 to 3 connection pairs, except on biomes that don't use the
	# standard eight-sector topology.
	if remove_connections:
		var rem_secs: Array = []
		for i in range(9, 6, -1):
			var r = randi() % i
			if walkers[r * 2].sector % 4 in rem_secs or walkers[r * 2 + 1].sector % 4 in rem_secs:
				continue
			rem_secs.append(walkers[r * 2].sector)
			walkers.remove_at(r * 2)
			rem_secs.append(walkers[r * 2].sector)
			walkers.remove_at(r * 2)

	# Spawn walkers at sector borders
	for w in walkers:
		grid[Vector2i(w.x, w.y)] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)
	for sec: Dictionary in sectors:
		# 2/3 chance of walkers, 1/3 chance of noise-based generation.
		var use_walkers: bool = true if force_walkers else bool(randi() % 3)
		if randomized_sector == int(sec.n):
			use_walkers = randf() < 0.5
		if use_walkers:
			# Move walkers.
			var s_walkers: Array = []
			for w: Dictionary in walkers:
				if w.sector == sec.n:
					s_walkers.append(w)
			var sector_area: int = (int(sec.x_max) - int(sec.x_min) + 1) * (int(sec.y_max) - int(sec.y_min) + 1)
			var floor_req: int = int(float(sector_area) * randf_range(floor_min, floor_max))
			var floors: int = s_walkers.size()
			var steps: int = 0
			while floor_req > floors and steps < 1000:
				steps += 1
				for w in s_walkers:
					# Move randomly toward random target within sector
					if randi() % 2:
						var target := randi_range(sec.x_min, sec.x_max)
						if w.x == target:
							w.x += 1 if w.x < sec.x_max else -1
						else:
							w.x += 1 if w.x < target else -1
					else:
						var target := randi_range(sec.y_min, sec.y_max)
						if w.y == target:
							w.y += 1 if w.y < sec.y_max else -1
						else:
							w.y += 1 if w.y < target else -1
					if not grid[Vector2i(w.x, w.y)].passable:
						grid[Vector2i(w.x, w.y)] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)
						floors += 1
		else:
			var noise = FastNoiseLite.new()
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
			noise.frequency = randf_range(0.1, 1.0)
			for x in range(sec.x_min, sec.x_max + 1):
				for y in range(sec.y_min, sec.y_max + 1):
					grid[Vector2i(x, y)] = TerrainData.get_terrain(TerrainData.TileType.WALL) if noise.get_noise_2d(x, y) > 0 else TerrainData.get_terrain(TerrainData.TileType.FLOOR)
			_smooth_walls(sec, 8, 7)

func _generate_two_sector_walkers(sectors: Array, floor_min: float, floor_max: float, randomized_sector: int) -> void:
	var split_row: int = int(sectors[0].y_max) + 1
	var crossing_x: int = floori(float(MAP_W) / 2.0)
	var sector_uses_walkers: Array[bool] = [true, true]
	if randomized_sector >= 0:
		sector_uses_walkers[randomized_sector] = randf() < 0.5
	for sector: Dictionary in sectors:
		var sector_number: int = int(sector.n)
		var crossing_y: int = split_row - 1 if sector_number == 0 else split_row
		if sector_uses_walkers[sector_number]:
			var sector_area: int = (int(sector.x_max) - int(sector.x_min) + 1) * (int(sector.y_max) - int(sector.y_min) + 1)
			var floor_requirement: int = int(float(sector_area) * randf_range(floor_min, floor_max))
			var walker_position: Vector2i = Vector2i(crossing_x, crossing_y)
			grid[walker_position] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)
			var floors: int = 1
			while floors < floor_requirement:
				var direction: Vector2i = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN].pick_random()
				var next_position: Vector2i = walker_position + direction
				if next_position.x < int(sector.x_min) or next_position.x > int(sector.x_max) or next_position.y < int(sector.y_min) or next_position.y > int(sector.y_max):
					continue
				walker_position = next_position
				if not grid[walker_position].passable:
					grid[walker_position] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)
					floors += 1
		else:
			var noise: FastNoiseLite = FastNoiseLite.new()
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
			noise.seed = randi()
			noise.frequency = 0.12
			for x: int in range(int(sector.x_min), int(sector.x_max) + 1):
				for y: int in range(int(sector.y_min), int(sector.y_max) + 1):
					grid[Vector2i(x, y)] = TerrainData.get_terrain(TerrainData.TileType.WALL) if noise.get_noise_2d(x, y) > 0.0 else TerrainData.get_terrain(TerrainData.TileType.FLOOR)
			_smooth_walls(sector, 8, 7)
		grid[Vector2i(crossing_x, crossing_y)] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)

func _generate_rooms(sectors: Array) -> Array[Vector2i]:
	var room_centers: Array[Vector2i] = []
	for sector: Dictionary in sectors:
		var sector_width: int = int(sector.x_max) - int(sector.x_min) + 1
		var sector_height: int = int(sector.y_max) - int(sector.y_min) + 1
		var room_width: int = mini(7, sector_width)
		var room_height: int = mini(7, sector_height)
		var best_difference: float = INF
		for candidate_height: int in range(4, sector_height + 1):
			for candidate_width: int in range(4, sector_width + 1):
				var room_area: int = candidate_width * candidate_height
				var interior_area: int = maxi(0, candidate_width - 2) * maxi(0, candidate_height - 2)
				var wall_area: int = room_area - interior_area
				var floor_wall_ratio: float = float(interior_area) / float(maxi(1, wall_area))
				if floor_wall_ratio < 0.9 or floor_wall_ratio > 1.1:
					continue
				var difference: float = absf(floor_wall_ratio - 1.0)
				if difference < best_difference or (is_equal_approx(difference, best_difference) and room_area > room_width * room_height):
					best_difference = difference
					room_width = candidate_width
					room_height = candidate_height
		var room_x_min: int = randi_range(int(sector.x_min), maxi(int(sector.x_min), int(sector.x_max) - room_width + 1))
		var room_y_min: int = randi_range(int(sector.y_min), maxi(int(sector.y_min), int(sector.y_max) - room_height + 1))
		var room_x_max: int = room_x_min + room_width - 1
		var room_y_max: int = room_y_min + room_height - 1
		for y: int in range(room_y_min, room_y_max + 1):
			for x: int in range(room_x_min, room_x_max + 1):
				var room_border: bool = x == room_x_min or x == room_x_max or y == room_y_min or y == room_y_max
				grid[Vector2i(x, y)] = TerrainData.get_terrain(TerrainData.TileType.WALL) if room_border else TerrainData.get_terrain(TerrainData.TileType.FLOOR)
		room_centers.append(Vector2i(floori(float(room_x_min + room_x_max) / 2.0), floori(float(room_y_min + room_y_max) / 2.0)))
	return room_centers

func _connect_room_corridors(room_centers: Array[Vector2i]) -> void:
	if room_centers.size() < 2:
		return
	var connected_centers: Dictionary[int, bool] = {0: true}
	while connected_centers.size() < room_centers.size():
		var best_from: int = -1
		var best_to: int = -1
		var best_distance: int = 999
		for from_index: int in connected_centers:
			for to_index: int in range(room_centers.size()):
				if connected_centers.has(to_index):
					continue
				var distance: int = absi(room_centers[from_index].x - room_centers[to_index].x) + absi(room_centers[from_index].y - room_centers[to_index].y)
				if distance < best_distance:
					best_distance = distance
					best_from = from_index
					best_to = to_index
		if best_to < 0:
				return
		var corridor_start: Vector2i = room_centers[best_from]
		var corridor_end: Vector2i = room_centers[best_to]
		_carve_orthogonal_corridor(corridor_start, corridor_end, absi(corridor_start.x - corridor_end.x) >= absi(corridor_start.y - corridor_end.y))
		connected_centers[best_to] = true

func _carve_orthogonal_corridor(start: Vector2i, finish: Vector2i, horizontal_first: bool) -> void:
	var bend: Vector2i = Vector2i(finish.x, start.y) if horizontal_first else Vector2i(start.x, finish.y)
	_carve_straight_segment(start, bend)
	_carve_straight_segment(bend, finish)

func _carve_straight_segment(start: Vector2i, finish: Vector2i) -> void:
	var current: Vector2i = start
	grid[current] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)
	while current != finish:
		if current.x != finish.x:
			current.x += signi(finish.x - current.x)
		else:
			current.y += signi(finish.y - current.y)
		grid[current] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)

func _convert_isolated_walls_to_stalagmites() -> void:
	for y: int in range(EDGE, MAP_H - EDGE):
		for x: int in range(EDGE, MAP_W - EDGE):
			var position: Vector2i = Vector2i(x, y)
			if grid[position].passable:
				continue
			var has_adjacent_wall: bool = false
			for offset_y: int in range(-1, 2):
				for offset_x: int in range(-1, 2):
					if offset_x == 0 and offset_y == 0:
						continue
					if not grid[Vector2i(x + offset_x, y + offset_y)].passable:
						has_adjacent_wall = true
						break
				if has_adjacent_wall:
					break
			if not has_adjacent_wall and randi() % 2:
				grid[position] = TerrainData.get_terrain(TerrainData.TileType.STALAGMITE)

func _town_floor_network_connected() -> bool:
	var floor_positions: Array[Vector2i] = []
	for position: Vector2i in grid:
		if grid[position].passable:
			floor_positions.append(position)
	if floor_positions.is_empty():
		return false
	var reachable: Dictionary = _find_reachable(floor_positions[0])
	for position: Vector2i in floor_positions:
		if not reachable.has(position):
			return false
	return true

func _place_town_barricades() -> void:
	town_barricade_rectangles.clear()
	var target_rectangles: int = randi_range(5, 10)
	var candidate_rectangles: Array[Rect2i] = []
	for rectangle_height: int in range(5, 9):
		for rectangle_width: int in range(5, 9):
			for y_min: int in range(EDGE + 1, MAP_H - EDGE - rectangle_height):
				for x_min: int in range(EDGE + 1, MAP_W - EDGE - rectangle_width):
					candidate_rectangles.append(Rect2i(x_min, y_min, rectangle_width, rectangle_height))
	candidate_rectangles.shuffle()
	var attempts: int = 0
	var attempt_limit: int = candidate_rectangles.size()
	while town_barricade_rectangles.size() < target_rectangles and attempts < attempt_limit:
		var candidate: Rect2i = candidate_rectangles[attempts]
		attempts += 1
		if not _is_valid_town_barricade_candidate(candidate, town_barricade_rectangles):
			continue
		var reachable_before: Dictionary = _find_reachable(_first_town_floor_position())
		var opening_candidates: Array[Vector2i] = _town_barricade_opening_candidates(candidate, reachable_before)
		if opening_candidates.is_empty():
			continue
		var opening: Vector2i = opening_candidates.pick_random()
		var original_tiles: Dictionary[Vector2i, TerrainData.Terrain] = {}
		for y: int in range(candidate.position.y + 1, candidate.end.y - 1):
			for x: int in range(candidate.position.x + 1, candidate.end.x - 1):
				var interior_position: Vector2i = Vector2i(x, y)
				original_tiles[interior_position] = grid[interior_position]
				grid[interior_position] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)
		for position: Vector2i in _rectangle_positions(candidate):
			original_tiles[position] = grid[position]
			if position != opening:
				grid[position] = TerrainData.get_terrain(TerrainData.TileType.BARRICADE)
				floor_tiles.erase(position)
		grid[opening] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)
		town_barricade_rectangles.append(candidate)
		if not _town_floor_network_connected():
			town_barricade_rectangles.pop_back()
			for original_position: Vector2i in original_tiles:
				grid[original_position] = original_tiles[original_position]

func _first_town_floor_position() -> Vector2i:
	for position: Vector2i in grid.keys():
		if grid[position].passable:
			return position
	return Vector2i(-1, -1)

func _town_barricade_opening_candidates(rectangle: Rect2i, reachable: Dictionary) -> Array[Vector2i]:
	var openings: Array[Vector2i] = []
	for x: int in range(rectangle.position.x + 1, rectangle.end.x - 1):
		var top_opening: Vector2i = Vector2i(x, rectangle.position.y)
		var bottom_opening: Vector2i = Vector2i(x, rectangle.end.y - 1)
		if reachable.has(top_opening + Vector2i.UP):
			openings.append(top_opening)
		if reachable.has(bottom_opening + Vector2i.DOWN):
			openings.append(bottom_opening)
	for y: int in range(rectangle.position.y + 1, rectangle.end.y - 1):
		var left_opening: Vector2i = Vector2i(rectangle.position.x, y)
		var right_opening: Vector2i = Vector2i(rectangle.end.x - 1, y)
		if reachable.has(left_opening + Vector2i.LEFT):
			openings.append(left_opening)
		if reachable.has(right_opening + Vector2i.RIGHT):
			openings.append(right_opening)
	return openings

func _is_valid_town_barricade_candidate(candidate: Rect2i, reserved_rectangles: Array[Rect2i]) -> bool:
	var expanded_candidate: Rect2i = _get_barricade_clearance_rect(candidate)
	if expanded_candidate.position.x < EDGE or expanded_candidate.position.y < EDGE or expanded_candidate.end.x > MAP_W - EDGE or expanded_candidate.end.y > MAP_H - EDGE:
		return false
	for reserved: Rect2i in reserved_rectangles:
		if expanded_candidate.intersects(_get_barricade_clearance_rect(reserved)):
			return false
	return true

func _is_inside_town_barricade(position: Vector2i) -> bool:
	if _biome != Biome.TOWN:
		return false
	for rectangle: Rect2i in town_barricade_rectangles:
		if position.x > rectangle.position.x and position.x < rectangle.end.x - 1 and position.y > rectangle.position.y and position.y < rectangle.end.y - 1:
			return true
	return false

func _create_biome_noise() -> FastNoiseLite:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_VALUE
	noise.seed = randi()
	noise.frequency = 0.065
	noise.fractal_octaves = 2
	return noise

func _collect_tiles(terrain_types: Array[int]) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for position: Vector2i in grid:
		for terrain_type in terrain_types:
			if TerrainData.TILE_DATA[terrain_type].terrain_name == grid[position].terrain_name:
				positions.append(position)
				break
	return positions

func _biome_candidates_in_noise_range(positions: Array[Vector2i], noise: FastNoiseLite, minimum: float, maximum: float) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for position: Vector2i in positions:
		var influence: float = noise.get_noise_2d(float(position.x), float(position.y))
		if influence >= minimum and influence <= maximum:
			candidates.append({"position": position, "influence": influence})
	return candidates


func _place_spaced_biome_candidates(candidates: Array[Dictionary], tile_type: int, target_count: int) -> int:
	var shuffled_candidates: Array[Dictionary] = candidates.duplicate()
	shuffled_candidates.shuffle()
	var placed_count: int = 0
	for candidate: Dictionary in shuffled_candidates:
		if placed_count >= target_count:
			break
		var position: Vector2i = candidate.position
		if _has_adjacent_tile_type(position, TerrainData.get_terrain(tile_type)):
			continue
		grid[position] = TerrainData.get_terrain(tile_type)
		placed_count += 1
	return placed_count


func _place_unspaced_biome_candidates(candidates: Array[Dictionary], tile_type: int, target_count: int) -> int:
	var shuffled_candidates: Array[Dictionary] = candidates.duplicate()
	shuffled_candidates.shuffle()
	var placed_count: int = 0
	for candidate: Dictionary in shuffled_candidates:
		if placed_count >= target_count:
			break
		grid[candidate.position] = TerrainData.get_terrain(tile_type)
		placed_count += 1
	return placed_count


func _apply_water_terrain(noise: FastNoiseLite, inverse: bool) -> void:
	var floor_positions: Array[Vector2i] = _collect_tiles([TerrainData.TileType.FLOOR])
	var wall_positions: Array[Vector2i] = _collect_tiles([TerrainData.TileType.WALL])
	var water_floors: Array[Dictionary] = _biome_candidates_in_noise_range(floor_positions, noise, -1.0, -0.4) if inverse else _biome_candidates_in_noise_range(floor_positions, noise, 0.4, 1.0)
	var water_walls: Array[Dictionary] = _biome_candidates_in_noise_range(wall_positions, noise, -1.0, -0.2) if inverse else _biome_candidates_in_noise_range(wall_positions, noise, 0.2, 1.0)
	water_walls = water_walls.filter(func(candidate: Dictionary) -> bool:
		var position: Vector2i = candidate.position
		return position != player_pos and position != stairs_up_pos and position != stairs_down_pos
	)
	for candidate: Dictionary in water_floors:
		grid[candidate.position] = TerrainData.get_terrain(TerrainData.TileType.WATER_SHALLOW)
	for candidate: Dictionary in water_walls:
		grid[candidate.position] = TerrainData.get_terrain(TerrainData.TileType.WATER_DEEP)

func _apply_forest_terrain(noise: FastNoiseLite) -> void:
	var floor_positions: Array[Vector2i] = _collect_tiles([TerrainData.TileType.FLOOR])
	var shrub_candidates: Array[Dictionary] = _biome_candidates_in_noise_range(floor_positions, noise, 0.6, 1.0)
	var moss_candidates: Array[Dictionary] = _biome_candidates_in_noise_range(floor_positions, noise, 0.0, 0.6)
	for candidate: Dictionary in shrub_candidates:
		grid[candidate.position] = TerrainData.get_terrain(TerrainData.TileType.SHRUB)
	for candidate: Dictionary in moss_candidates:
		grid[candidate.position] = TerrainData.get_terrain(TerrainData.TileType.MOSS)
	var forest_walls: Array[Dictionary] = _biome_candidates_in_noise_range(_collect_tiles([TerrainData.TileType.WALL]), noise, 0.7, 1.0)
	for candidate: Dictionary in forest_walls:
		grid[candidate.position] = TerrainData.get_terrain(TerrainData.TileType.TREE)

func _apply_biome_terrain(noise: FastNoiseLite) -> void:
	match _biome:
		Biome.SLIME:
			var slime_floor_positions: Array[Vector2i] = _collect_tiles([TerrainData.TileType.FLOOR])
			var caustic_candidates: Array[Dictionary] = _biome_candidates_in_noise_range(slime_floor_positions, noise, 0.92, 1.0)
			var slime_candidates: Array[Dictionary] = _biome_candidates_in_noise_range(slime_floor_positions, noise, -1.0, -0.92)
			var glowing_pool_target: int = roundi(float(caustic_candidates.size()) * 0.5)
			_place_spaced_biome_candidates(caustic_candidates, TerrainData.TileType.GLOWING_POOL, glowing_pool_target)
			var slime_pit_target: int = roundi(float(slime_candidates.size()) * 0.5)
			_place_unspaced_biome_candidates(slime_candidates, TerrainData.TileType.SLIME_PIT, slime_pit_target)
		Biome.WATER:
			_apply_water_terrain(noise, false)
		Biome.FOREST:
			_apply_forest_terrain(noise)
		Biome.WATER_AND_FOREST:
			_apply_forest_terrain(noise)
			_apply_water_terrain(noise, true)
		Biome.FIRE:
			var fire_walls: Array[Dictionary] = _biome_candidates_in_noise_range(_collect_tiles([TerrainData.TileType.WALL]), noise, 0.5, 1.0)
			fire_walls = fire_walls.filter(func(candidate: Dictionary) -> bool:
				var position: Vector2i = candidate.position
				return position != player_pos and position != stairs_up_pos and position != stairs_down_pos
			)
			for candidate: Dictionary in fire_walls:
				grid[candidate.position] = TerrainData.get_terrain(TerrainData.TileType.LAVA)
			var fire_floor: Array[Dictionary] = _biome_candidates_in_noise_range(_collect_tiles([TerrainData.TileType.FLOOR]), noise, 0.5, 1.0)
			fire_floor = fire_floor.filter(func(candidate: Dictionary) -> bool:
				var position: Vector2i = candidate.position
				return position != player_pos and position != stairs_up_pos and position != stairs_down_pos
			)
			fire_floor.shuffle()
			_apply_fire_terrain(fire_floor)
		Biome.ICE:
			var ice_floor_positions: Array[Vector2i] = _collect_tiles([TerrainData.TileType.FLOOR])
			for position: Vector2i in ice_floor_positions:
				grid[position] = TerrainData.get_terrain(TerrainData.TileType.SNOW)
			var ice_floor: Array[Dictionary] = _biome_candidates_in_noise_range(ice_floor_positions, noise, 0.4, 1.0)
			for candidate: Dictionary in ice_floor:
				grid[candidate.position] = TerrainData.get_terrain(TerrainData.TileType.ICE)


func _apply_fire_terrain(candidates: Array[Dictionary]) -> void:
	if candidates.is_empty():
		return
	if not _are_walkable_tiles_connected():
		for candidate: Dictionary in candidates:
			grid[candidate.position] = TerrainData.get_terrain(TerrainData.TileType.ASHES)
		return
	for candidate: Dictionary in candidates:
		var candidate_position: Vector2i = candidate.position
		if candidate_position == player_pos or candidate_position == stairs_up_pos or candidate_position == stairs_down_pos:
			continue
		grid[candidate_position] = TerrainData.get_terrain(TerrainData.TileType.LAVA)
	if _are_walkable_tiles_connected():
		return
	var connected_limit: int = 0
	var disconnected_limit: int = candidates.size()
	while connected_limit + 1 < disconnected_limit:
		var test_count: int = floori(float(connected_limit + disconnected_limit) / 2.0)
		_set_fire_candidate_prefix(candidates, test_count)
		if _are_walkable_tiles_connected():
			connected_limit = test_count
		else:
			disconnected_limit = test_count
	_set_fire_candidate_prefix(candidates, connected_limit)

func _set_fire_candidate_prefix(candidates: Array[Dictionary], lava_count: int) -> void:
	for index: int in range(candidates.size()):
		var position: Vector2i = candidates[index].position
		if position == player_pos or position == stairs_up_pos or position == stairs_down_pos:
			grid[position] = TerrainData.get_terrain(TerrainData.TileType.ASHES)
			continue
		grid[position] = TerrainData.get_terrain(TerrainData.TileType.LAVA if index < lava_count else TerrainData.TileType.ASHES)

func _has_adjacent_tile_type(position: Vector2i, tile_type: TerrainData.Terrain) -> bool:
	for offset_y: int in range(-1, 2):
		for offset_x: int in range(-1, 2):
			if offset_x == 0 and offset_y == 0:
				continue
			if grid[position + Vector2i(offset_x, offset_y)].terrain_name == tile_type.terrain_name:
				return true
	return false

func _place_cave_geysers() -> void:
	var geyser_count: int = randi_range(-1, 3)
	if geyser_count <= 0:
		return
	var eligible_floor_tiles: Array[Vector2i] = []
	for position: Vector2i in floor_tiles:
		if grid[position].terrain_name != "cave floor":
			continue
		if position == player_pos or creature.has(position) or item.has(position):
			continue
		eligible_floor_tiles.append(position)
	eligible_floor_tiles.shuffle()
	var geysers_placed: int = 0
	for position: Vector2i in eligible_floor_tiles:
		if geysers_placed >= geyser_count:
			break
		grid[position] = TerrainData.get_terrain(TerrainData.TileType.GEYSER)
		if _are_walkable_tiles_connected():
			geysers_placed += 1
			grid[position].timer = randi_range(2000, 4000)
		else:
			grid[position] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)

func _are_walkable_tiles_connected() -> bool:
	var walkable_positions: Array[Vector2i] = []
	for position: Vector2i in grid:
		if grid[position].passable and not grid[position].dangerous:
			walkable_positions.append(position)
	if walkable_positions.is_empty():
		return false
	var start_position: Vector2i = stairs_up_pos if walkable_positions.has(stairs_up_pos) else walkable_positions[0]
	var reachable: Dictionary = {start_position: true}
	var pending: Array[Vector2i] = [start_position]
	var index: int = 0
	while index < pending.size():
		var current: Vector2i = pending[index]
		index += 1
		for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = current + direction
			if not grid.has(neighbor) or reachable.has(neighbor) or not grid[neighbor].passable:
				continue
			reachable[neighbor] = true
			pending.append(neighbor)
	for position: Vector2i in walkable_positions:
		if not reachable.has(position):
			return false
	return true

func _get_barricade_clearance_rect(rectangle: Rect2i) -> Rect2i:
	return Rect2i(rectangle.position - Vector2i.ONE, rectangle.size + Vector2i(2, 2))

func _rectangle_positions(rectangle: Rect2i) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	var right: int = rectangle.end.x - 1
	var bottom: int = rectangle.end.y - 1
	for y: int in range(rectangle.position.y, rectangle.end.y):
		positions.append(Vector2i(rectangle.position.x, y))
		positions.append(Vector2i(right, y))
	for x: int in range(rectangle.position.x + 1, right):
		positions.append(Vector2i(x, rectangle.position.y))
		positions.append(Vector2i(x, bottom))
	return positions

## Returns a list of vectors forming a circle with the given radius around the given position,
## computed using Jesko's method.
func _get_circle(radius: int, pos: Vector2i, fill: bool) -> Array[Vector2i]:
	var t1: float = radius / 16.0
	var t2: float
	var x: int = radius
	var y: int = 0
	var tiles: Array[Vector2i] = []
	while x >= y:
		if fill:
			for span: Vector2i in [Vector2i(x, y), Vector2i(x, -y), Vector2i(y, x), Vector2i(y, -x)]:
				for x0 in range(-span.x, span.x, 1 if span.x > 0 else -1):
					tiles.append(Vector2i(x0, span.y) + pos)
		else:
			tiles.append_array([Vector2i(x, y) + pos, Vector2i(x, -y) + pos, Vector2i(-x, y) + pos, Vector2i(-x, -y) + pos, Vector2i(y, x) + pos, Vector2i(y, -x) + pos, Vector2i(-y, x) + pos, Vector2i(-y, -x) + pos])
		y += 1
		t1 += y
		t2 = t1 - x
		if t2 >= 0:
			t1 = t2
			x -= 1
	return tiles

func _is_slope_blocked(slope: float, blocked_slopes: Array[Vector2]) -> bool:
	for blocked in blocked_slopes:
		var lower: float = minf(blocked.x, blocked.y)
		var upper: float = maxf(blocked.x, blocked.y)
		if slope >= lower and slope <= upper:
			return true
	return false

func _merge_slope_ranges(ranges: Array[Vector2]) -> Array[Vector2]:
	if ranges.size() < 2:
		return ranges
	ranges.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var merged: Array[Vector2] = [ranges[0]]
	for index in range(1, ranges.size()):
		var current: Vector2 = ranges[index]
		var previous: Vector2 = merged[merged.size() - 1]
		if current.x <= previous.y + 0.000001:
			merged[merged.size() - 1] = Vector2(previous.x, maxf(previous.y, current.y))
		else:
			merged.append(current)
	return merged

func _snapshot_visible_state() -> void:
	for tile in visible_tiles:
		tile_last_seen[tile] = grid[tile]
		char_last_seen[tile] = get_display_char(tile.x, tile.y)
		fg_last_seen[tile] = darken(get_fg_color(tile.x, tile.y))
		bg_last_seen[tile] = darken(get_bg_color(tile.x, tile.y))
		var description: String = get_hover_text(tile.x, tile.y, true)
		if not description.is_empty():
			desc_last_seen[tile] = description

# Based on https://roguebasin.com/index.php/Restrictive_Precise_Angle_Shadowcasting.
func _compute_fov(observer: Creature) -> Dictionary[Vector2i, bool]:
	# Statuses are derived on each recomputation; base sight range is never mutated.
	var vision_context: Dictionary = {"sight_range": observer.sight_range}
	StatusData.trigger(observer, StatusData.EffectType.VISION, vision_context)
	if StatusData.has_status(observer, "Sleeping") or (observer is PlayerCreature and _resting):
		vision_context.sight_range = maxi(1, floori(vision_context.get("sight_range", 1) * 0.5))
	
	var observer_pos: Vector2i = observer.pos
	var sight_range: int = maxi(1, int(vision_context.get("sight_range", observer.sight_range)))
	var observer_visible: Dictionary[Vector2i, bool] = {observer_pos: true}
	var octants: Array = [
		[Vector2i(1, 0), Vector2i(0, 1)],
		[Vector2i(0, 1), Vector2i(1, 0)],
		[Vector2i(0, 1), Vector2i(-1, 0)],
		[Vector2i(-1, 0), Vector2i(0, 1)],
		[Vector2i(-1, 0), Vector2i(0, -1)],
		[Vector2i(0, -1), Vector2i(-1, 0)],
		[Vector2i(0, -1), Vector2i(1, 0)],
		[Vector2i(1, 0), Vector2i(0, -1)]
	]

	for octant in octants:
		var major_axis: Vector2i = octant[0]
		var minor_axis: Vector2i = octant[1]
		var blocked_slopes: Array[Vector2] = []
		for major in range(1, sight_range + 1):
			var ring_walls: Array[Vector2] = []
			for minor in range(major + 1):
				var offset: Vector2i = major_axis * major + minor_axis * minor
				if offset.length_squared() > sight_range * sight_range:
					continue
				var pos: Vector2i = observer_pos + offset
				if pos.x < 0 or pos.x >= MAP_W or pos.y < 0 or pos.y >= MAP_H:
					continue

				var slope_min: float = maxf(0.0, (float(minor) - 0.5) / (major + 0.5))
				var slope_max: float = (float(minor) + 0.5) / (major - 0.5)
				var covered_width: float = 0.0
				for blocked_range in blocked_slopes:
					if blocked_range.x >= slope_max:
						break
					var overlap_start: float = maxf(slope_min, blocked_range.x)
					var overlap_end: float = minf(slope_max, blocked_range.y)
					if overlap_end > overlap_start:
						covered_width += overlap_end - overlap_start
				var is_visible: bool = covered_width < slope_max - slope_min - 0.000001
				if is_visible:
					observer_visible[pos] = true
				if grid[pos].occluding or _environment_blocks_vision(pos):
					ring_walls.append(Vector2(slope_min, slope_max))
			blocked_slopes.append_array(ring_walls)
			blocked_slopes = _merge_slope_ranges(blocked_slopes)
	return observer_visible

func _recompute_all_fov() -> void:
	visible_tiles = _compute_fov(_player_entity)
	for entity: Creature in creature.values():
		if not entity is PlayerCreature and StatusData.has_status(entity, "Invisible"):
			var invisible_position: Vector2i = entity.pos
			if visible_tiles.has(invisible_position):
				seen_tiles[invisible_position] = true
	_player_entity.visible_tiles = visible_tiles
	# Only the player's explored map persists between FOV computations.
	seen_tiles.merge(visible_tiles, true)
	_snapshot_visible_state()
	_log_new_sightings()
	_maybe_show_low_health_tutorial()
	_refresh_hover_path()

func _smooth_walls(sector, wall_threshold, floor_threshold) -> void:
	var to_wall := []
	var to_floor := []
	for y in range(sector.y_min, sector.y_max):
		for x in range(sector.x_min, sector.x_max):
			var wall_count: int = 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var nx: int = x + dx
					var ny: int = y + dy
					if not grid[Vector2i(nx, ny)].passable:
						wall_count += 3 - abs(dx) - abs(dy)
			if wall_count >= wall_threshold:
				to_wall.append(Vector2i(x,y))
			elif wall_count <= floor_threshold:
				to_floor.append(Vector2i(x,y))
	for v in to_wall:
		grid[v] = TerrainData.get_terrain(TerrainData.TileType.WALL)
	for v in to_floor:
		grid[v] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)

func _find_reachable(start: Vector2i, initial: Dictionary = {}) -> Dictionary:
	var stack := [start]
	var next_stack := []
	var reachable = {start: true}
	if initial:
		for v in initial:
			reachable[v] = true
	var steps = 0
	while stack.size() > 0 and steps < 1000:
		steps += 1
		for current in stack:
			for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var neighbor: Vector2i = current + dir
				if neighbor.x >= 0 and neighbor.x < MAP_W and neighbor.y >= 0 and neighbor.y < MAP_H:
					if grid[neighbor].terrain_name == "cave floor" and neighbor not in reachable:
						reachable[neighbor] = true
						next_stack.append(neighbor)
		stack = next_stack
		next_stack = []
	return reachable

func _connect_floors() -> void:
	# Simple flood-fill to check connectivity
	# Find all floor tiles
	floor_tiles = []
	for y in range(EDGE, MAP_H - EDGE):
		for x in range(EDGE, MAP_W - EDGE):
			if grid[Vector2i(x, y)].passable:
				floor_tiles.append(Vector2i(x, y))
	@warning_ignore("integer_division")
	var start_tile = floor_tiles[floor_tiles.size() / 2]
	floor_tiles.shuffle()
	
	# Connect unreachable tiles
	var reachable: Dictionary[Vector2i, bool] = _find_reachable(start_tile, {})
	for tile: Vector2i in floor_tiles:
		if not tile in reachable:
			var nearest: Vector2i = Vector2i.MIN
			var stack: Array[Vector2i] = [tile]
			var seen := {}
			var steps := 0
			while nearest == Vector2i.MIN:
				steps += 1
				@warning_ignore("confusable_local_declaration")
				var current: Vector2i = stack.pop_front()
				for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var neighbor: Vector2i = current + dir
					if neighbor not in seen:
						if neighbor in reachable:
							nearest = neighbor
							break
						stack.push_back(neighbor)
						seen[neighbor] = true
				if steps > 100:
					nearest = reachable.keys().pick_random()
			var current := tile
			while current != nearest:
				reachable[current] = true
				var dist_x := current.x - nearest.x
				var dist_y := current.y - nearest.y
				if dist_x == 0:
					current.y -= sign(dist_y)
				elif dist_y == 0:
					current.x -= sign(dist_x)
				elif randi() % (abs(dist_x) + abs(dist_y)) > abs(dist_x):
					current.y -= sign(dist_y)
				else:
					current.x -= sign(dist_x)
				grid[current] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)
			reachable = _find_reachable(tile, reachable)

func _terrain_distances(start: Vector2i) -> Dictionary:
	var distances: Dictionary = {start: 0}
	var frontier: Array[Vector2i] = [start]
	var frontier_index: int = 0
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	while frontier_index < frontier.size():
		var current: Vector2i = frontier[frontier_index]
		frontier_index += 1
		var current_distance: int = int(distances[current])
		for direction: Vector2i in directions:
			var target: Vector2i = current + direction
			if target.x < EDGE or target.x >= MAP_W - EDGE or target.y < EDGE or target.y >= MAP_H - EDGE or distances.has(target):
				continue
			if not grid[target].passable:
				continue
			if direction.x != 0 and direction.y != 0:
				var horizontal: Vector2i = Vector2i(target.x, current.y)
				var vertical: Vector2i = Vector2i(current.x, target.y)
				var horizontal_open: bool = grid[horizontal].passable
				var vertical_open: bool = grid[vertical].passable
				if not horizontal_open and not vertical_open:
					continue
			distances[target] = current_distance + 1
			frontier.append(target)
	return distances

func _place_stairs() -> void:
	var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	stairs_up_pos = Vector2i(-1, -1)
	stairs_down_pos = Vector2i(-1, -1)
	var up_floor: Vector2i = floor_tiles[0]
	var up_wall: Vector2i = Vector2i(-1, -1)
	for tile: Vector2i in floor_tiles:
		for dir: Vector2i in dirs:
			var target: Vector2i = tile + dir
			if target.x > EDGE and target.y > EDGE and target.x < MAP_W - 1 - EDGE and target.y < MAP_H - 1 - EDGE and grid[target].terrain_name == "cave wall":
				up_floor = tile
				up_wall = target
				break
		if up_wall.x >= 0:
			break
	if up_wall.x >= 0:
		stairs_up_pos = up_wall
		grid[stairs_up_pos] = TerrainData.get_terrain(TerrainData.TileType.STAIRS_UP)
		if level == 1:
			player_pos = up_floor
		else:
			player_pos = stairs_up_pos
	else:
		stairs_up_pos = up_floor
		grid[stairs_up_pos] = TerrainData.get_terrain(TerrainData.TileType.STAIRS_UP)
		player_pos = up_floor if level == 1 else stairs_up_pos

	if level >= MAX_LEVEL:
		stairs_down_pos = Vector2i(-1, -1)
		return
	var path_start: Vector2i = player_pos
	if grid[path_start].terrain_name == "stairs leading up":
		var adjacent_start: Vector2i = _adjacent_floor(path_start)
		if adjacent_start.x >= 0:
			path_start = adjacent_start
	var distances: Dictionary = _terrain_distances(path_start)
	var maximum_distance: int = 0
	for distance_value: int in distances.values():
		maximum_distance = maxi(maximum_distance, distance_value)
	var candidates: Array[Vector2i] = []
	var best_candidate_distance: int = -1
	for tile: Vector2i in floor_tiles:
		if tile == player_pos or not distances.has(tile):
			continue
		var adjacent_walls: Array[Vector2i] = []
		for direction: Vector2i in dirs:
			var target: Vector2i = tile + direction
			if target.x > EDGE and target.y > EDGE and target.x < MAP_W - 1 - EDGE and target.y < MAP_H - 1 - EDGE and grid[target].terrain_name == "cave wall":
				adjacent_walls.append(target)
		if adjacent_walls.is_empty():
			continue
		var tile_distance: int = int(distances[tile])
		if tile_distance > best_candidate_distance:
			best_candidate_distance = tile_distance
			candidates.clear()
		if tile_distance == best_candidate_distance:
			candidates.append_array(adjacent_walls)
	if not candidates.is_empty():
		stairs_down_pos = candidates.pick_random()
		grid[stairs_down_pos] = TerrainData.get_terrain(TerrainData.TileType.STAIRS_DOWN)
		return
	stairs_down_pos = player_pos

static func _ensure_altar_schedule() -> void:
	if not _altar_primary_schedule.is_empty() and not _altar_extra_schedule.is_empty():
		return
	_altar_primary_schedule.clear()
	_altar_extra_schedule.clear()
	ID_TRANSFORM_ALTAR_LEVELS.clear()
	var primary_level_candidates: Array[int] = []
	for level_number: int in range(1, ALTAR_LEVEL_COUNT + 1):
		primary_level_candidates.append(level_number)
	primary_level_candidates.shuffle()
	for level_index: int in range(primary_level_candidates.size()):
		var primary_level: int = primary_level_candidates[level_index]
		_altar_primary_schedule[primary_level] = TerrainData.TileType.ALTAR_ENCHANT if level_index % 2 == 0 else TerrainData.TileType.ALTAR_POWER
	var level_candidates: Array[int] = []
	for level_number: int in range(1, ALTAR_LEVEL_COUNT + 1):
		level_candidates.append(level_number)
	level_candidates.shuffle()
	var id_count: int = randi_range(1, ALTAR_EXTRA_COUNT - 1)
	var extra_types: Array[int] = []
	for _index: int in range(id_count):
		extra_types.append(TerrainData.TileType.ALTAR_ID)
	for _index: int in range(ALTAR_EXTRA_COUNT - id_count):
		extra_types.append(TerrainData.TileType.ALTAR_TRANSFORM)
	extra_types.shuffle()
	ID_TRANSFORM_ALTAR_LEVELS.clear()
	for index: int in range(ALTAR_EXTRA_COUNT):
		var level_number: int = level_candidates[index]
		var altar_type: int = extra_types[index]
		_altar_extra_schedule[level_number] = altar_type
		ID_TRANSFORM_ALTAR_LEVELS.append(level_number)

func _adjacent_passable_tile_types(position: Vector2i) -> Array[TerrainData.Terrain]:
	var passable_types: Array[TerrainData.Terrain] = []
	for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		var neighbor_type: TerrainData.Terrain = grid[position + direction]
		if neighbor_type.passable:
			passable_types.append(neighbor_type)
	return passable_types

func _activate_altar_at(position: Vector2i) -> bool:
	if not item.has(position):
		return false
	if creature.has(position):
		return false
	var altar_effect := grid[position].effect_altar
	if not altar_effect.is_valid():
		return false
	var altar_item: Item = item[position]
	var item_type: String = altar_item.get_type()
	var result = altar_effect.call(altar_item, item_type, item, position, _player_entity, _item_dp)
	if result.is_empty():
		return false
	_append_message(result["message"])
	_play_sound(result["sound"])
	var replacement_types: Array[TerrainData.Terrain] = _adjacent_passable_tile_types(position)
	if not replacement_types.is_empty():
		grid[position] = replacement_types.pick_random()
	redraw.emit()
	return true

func _init_player() -> void:
	if floor_tiles.size() > 0:
		var player_entity: PlayerCreature = PlayerData.init_player(PlayerData.player_race)
		player_entity.pos = player_pos
		player_entity.time = 0
		player_entity.status = []
		creature[player_pos] = player_entity
		_player_entity = player_entity

func _adjacent_floor(pos: Vector2i) -> Vector2i:
	for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var candidate: Vector2i = pos + direction
		if candidate.x >= 0 and candidate.x < MAP_W and candidate.y >= 0 and candidate.y < MAP_H and grid[candidate].terrain_name == "cave floor":
			return candidate
	return Vector2i(-1, -1)

func _player_is_present_on_map() -> bool:
	return _player_entity and creature.get(player_pos, null) == _player_entity

func _spawn_exclusion_fov() -> Dictionary:
	if not _player_is_present_on_map():
		return {}
	return _compute_fov(_player_entity)

func _creature_supports_current_biome(definition: Dictionary) -> bool:
	var creature_biomes: Array = definition.get("biomes", [])
	if creature_biomes.has(_biome):
		return true
	if _biome == Biome.WATER_AND_FOREST:
		return creature_biomes.has(Biome.WATER) or creature_biomes.has(Biome.FOREST)
	return false

func _creature_can_spawn_on_tile(definition: Dictionary, position: Vector2i) -> bool:
	if not _creature_supports_current_biome(definition):
		return false
	if creature.has(position):
		return false
	var tile: TerrainData.Terrain = grid[position]
	if _is_stairs_tile(tile):
		return false
	var traits: Array = definition.get("traits", [])
	if tile.terrain_name == "lava":
		return traits.has("Flying") and definition.get("resistances", []).has("fire")
	if _is_water_tile(tile):
		return traits.has("Aquatic") or traits.has("Amphibious")
	return floor_tiles.has(position) and not traits.has("Aquatic")

func _available_spawn_tiles(definition: Dictionary, forbidden_tiles: Dictionary = {}) -> Array[Vector2i]:
	var spawn_tiles: Array[Vector2i] = []
	for position: Vector2i in grid.keys():
		if not forbidden_tiles.has(position) and _creature_can_spawn_on_tile(definition, position):
			spawn_tiles.append(position)
	return spawn_tiles

func _choose_spawn_position(spawn_tiles: Array[Vector2i]) -> Vector2i:
	if _biome == Biome.TOWN:
		var barricade_spawn_tiles: Array[Vector2i] = []
		var other_spawn_tiles: Array[Vector2i] = []
		for spawn_position: Vector2i in spawn_tiles:
			if _is_inside_town_barricade(spawn_position):
				barricade_spawn_tiles.append(spawn_position)
			else:
				other_spawn_tiles.append(spawn_position)
		if not barricade_spawn_tiles.is_empty() and not other_spawn_tiles.is_empty():
			return barricade_spawn_tiles.pick_random() if randf() < 0.7 else other_spawn_tiles.pick_random()
		if not barricade_spawn_tiles.is_empty():
			return barricade_spawn_tiles.pick_random()
	return spawn_tiles.pick_random()

func _creature_definitions_for_budget(max_danger: int, preferred_band: bool = false, forbidden_tiles: Dictionary = {}) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	if max_danger <= 0:
		return candidates
	var minimum_danger: int = maxi(1, ceili(max_danger * 0.2)) if preferred_band else 0
	var maximum_band_danger: int = floori(max_danger * 0.4) if preferred_band else max_danger
	for definition: Dictionary in CreatureData.creatures:
		var danger: int = definition.get("danger", 0)
		if danger < minimum_danger or danger > maximum_band_danger:
			continue
		if _available_spawn_tiles(definition, forbidden_tiles).is_empty():
			continue
		candidates.append(definition)
	return candidates

func _create_creature_at_position(definition: Dictionary, spawn_position: Vector2i, spawn_time: float, add_to_turn_queue: bool = true) -> EnemyCreature:
	var entity: EnemyCreature = EnemyCreature.new(definition, spawn_position, spawn_time)
	entity.id = _next_creature_id
	_next_creature_id += 1
	creature[spawn_position] = entity
	if add_to_turn_queue:
		turn_queue.append(entity)
		turn_queue.sort_custom(_sort_by_time)
	return entity

func _spawn_creature_definition(definition: Dictionary, spawn_time: float, add_to_turn_queue: bool = true, forbidden_tiles_override: Dictionary = {}) -> EnemyCreature:
	var forbidden_tiles: Dictionary = forbidden_tiles_override if not forbidden_tiles_override.is_empty() else _spawn_exclusion_fov()
	var spawn_tiles: Array[Vector2i] = _available_spawn_tiles(definition, forbidden_tiles)
	if spawn_tiles.is_empty():
		return null
	var cluster_size: int = maxi(0, definition.get("cluster", 0))
	var matching_positions: Array[Vector2i] = []
	var creature_name: String = definition.get("name", "")
	for existing_position: Vector2i in creature.keys():
		var existing: Creature = creature[existing_position]
		if existing.creature_name == creature_name and existing.health > 0:
			matching_positions.append(existing_position)
	if cluster_size > matching_positions.size() and not matching_positions.is_empty():
		var nearby_tiles: Array[Vector2i] = []
		for spawn_position: Vector2i in spawn_tiles:
			for conspecific_position: Vector2i in matching_positions:
				if spawn_position.distance_squared_to(conspecific_position) <= 36:
					nearby_tiles.append(spawn_position)
					break
		if not nearby_tiles.is_empty():
			spawn_tiles = nearby_tiles
	var spawn_position: Vector2i = _choose_spawn_position(spawn_tiles)
	return _create_creature_at_position(definition, spawn_position, spawn_time, add_to_turn_queue)

func _initialize_creature_population() -> void:
	if _creature_population_initialized:
		return
	creature_budget = (1 + level) * 5
	respawn_budget_increment = maxi(1, level)
	next_respawn_time = environment_time + HALF_RESPAWN_INTERVAL * 2
	_creature_population_initialized = true
	var forbidden_tiles: Dictionary = _spawn_exclusion_fov()
	while creature_budget > 0:
		var preferred_definitions: Array[Dictionary] = _creature_definitions_for_budget(creature_budget, true, forbidden_tiles)
		var eligible_definitions: Array[Dictionary] = preferred_definitions if preferred_definitions else _creature_definitions_for_budget(creature_budget, false, forbidden_tiles)
		if eligible_definitions.is_empty():
			break
		var definition: Dictionary = eligible_definitions.pick_random()
		var spawned: EnemyCreature = _spawn_creature_definition(definition, environment_time, false)
		if not spawned:
			break
		turn_queue.append(spawned)
		creature_budget -= definition.get("danger", 1)

func _init_turn_queue(include_player: bool = true) -> void:
	turn_queue.clear()
	if include_player:
		_player_entity.pos = player_pos
		_player_entity.glyph = "@"
		_player_entity.color = 15
		_player_entity.time = 0
		turn_queue.append(_player_entity)
	if not _creature_population_initialized:
		_initialize_creature_population()
	turn_queue.sort_custom(_sort_by_time)

func _place_items() -> void:
	# On every level, make five rolls with a 75% chance each to generate an item.
	# Three of them can be any type of item at random.
	# Of the other two, one can only be a grenade, the other only a projectile.
	# Enchantment and ego chances depend on the current level (handled by Item.create_random).
	
	var new_items: Array[Item] = []
	
	# Rolls 1-3: Any item type
	for _i in range(3):
		if randi() % 100 < 75:  # 75% chance
			var kind: String = Item.ITEM_KINDS.pick_random()
			var candidate: Item = Item.create_random(kind, level)
			if candidate:
				new_items.append(candidate)
	
	# Roll 4: Grenade only
	if randi() % 100 < 75:  # 75% chance
		var candidate: Item = Item.create_random("grenade", level)
		if candidate:
			new_items.append(candidate)
	
	# Roll 5: Projectile only
	if randi() % 100 < 75:  # 75% chance
		var candidate: Item = Item.create_random("projectile", level)
		if candidate:
			new_items.append(candidate)
	
	# Place items on free tiles
	var free_tiles: Array[Vector2i] = []
	for position: Vector2i in floor_tiles:
		var tile: TerrainData.Terrain = grid[position]
		if not _is_altar_tile(tile) and not _is_hazardous_for_creature(_player_entity, tile) and tile.passable and not creature.has(position) and not item.has(position):
			free_tiles.append(position)
	free_tiles.shuffle()
	
	var item_count: int = min(new_items.size(), free_tiles.size())
	for item_index: int in range(item_count):
		item[free_tiles[item_index]] = new_items[item_index]
	
	if level == MAX_LEVEL:
		_place_lyrical_orblet()

func _place_lyrical_orblet() -> void:
	var free_tiles: Array[Vector2i] = []
	for position: Vector2i in floor_tiles:
		if position == stairs_up_pos or position == stairs_down_pos or position == player_pos:
			continue
		var tile: TerrainData.Terrain = grid[position]
		if not _is_altar_tile(tile) and not _is_hazardous_for_creature(_player_entity, tile) and tile.passable and not creature.has(position) and not item.has(position):
			free_tiles.append(position)
	if free_tiles.is_empty():
		return
	item[free_tiles.pick_random()] = LyricalOrblet.new()

func _active_transference_partner(target: Creature) -> Creature:
	var current_time: float = maxf(environment_time, _player_entity.time)
	var expired_link_ids: Array[int] = []
	for link_id: int in _transference_links.keys():
		var linked_entities: Dictionary = _transference_links[link_id]
		if current_time >= linked_entities["expires_at"]:
			expired_link_ids.append(link_id)
			continue
		if target == linked_entities["player"]:
			return linked_entities["target"]
		if target == linked_entities["target"]:
			return linked_entities["player"]
	for expired_link_id: int in expired_link_ids:
		var expired_link: Dictionary = _transference_links[expired_link_id]
		_transference_links.erase(expired_link_id)
		StatusData.remove_status(expired_link["player"], "Transference")
		StatusData.remove_status(expired_link["target"], "Transference")
	return null

func _apply_sorcery_armor_cooldown_reduction(damage: int) -> void:
	var inventory := PlayerData.inventory
	if damage <= 0 or PlayerData.equipped_armor < 0 or PlayerData.equipped_armor >= inventory.size():
		return
	var armor: Item = inventory[PlayerData.equipped_armor]
	var ego: String = armor.ego
	if ego != "sorcery":
		return
	var cooldown_reduction: int = maxi(0, armor.enchantment) * damage * 5
	if cooldown_reduction <= 0:
		return
	var current_time: float = _player_entity.time
	for inventory_index: int in range(inventory.size()):
		var inventory_item: Item = inventory[inventory_index]
		var item_type: String = inventory_item.type
		if item_type not in ["wand", "charm"]:
			continue
		inventory_item.cooldown = maxf(current_time, inventory_item.cooldown - cooldown_reduction)
	armor.identify_partially()

func _heal_entity(target: Creature, amount: int, bypass_transference: bool = false) -> int:
	var healing: int = maxi(0, amount)
	if healing == 0 or target.health <= 0:
		return 0
	if not bypass_transference:
		var partner: Creature = _active_transference_partner(target)
		if partner:
			var original_share: int = ceili(healing / 2.0)
			var partner_share: int = floori(healing / 2.0)
			var healed_original: int = _heal_entity(target, original_share, true)
			if partner_share > 0:
				_heal_entity(partner, partner_share, true)
			return healed_original
	var maximum_health: int = target.max_health
	var previous_health: int = target.health
	target["health"] = mini(maximum_health, previous_health + healing)
	if target is PlayerCreature:
		redraw_status.emit()
	return maxi(0, target.health - previous_health)

func _deal_damage(target: Creature, amount: int, damage_type: String = "physical", bypass_transference: bool = false) -> int:
	var incoming_damage: int = maxi(0, amount)
	if incoming_damage == 0 or target.health <= 0:
		return 0
	if target.has_named_immunity(damage_type):
		return 0
	if not bypass_transference:
		var transference_partner: Creature = _active_transference_partner(target)
		if transference_partner:
			var original_share: int = ceili(incoming_damage / 2.0)
			var partner_share: int = floori(incoming_damage / 2.0)
			var dealt_to_original: int = _deal_damage(target, original_share, damage_type, true)
			if partner_share > 0:
				_deal_damage(transference_partner, partner_share, damage_type, true)
			return dealt_to_original
	var protection_context: Dictionary = {"damage": incoming_damage}
	StatusData.trigger(target, StatusData.EffectType.DAMAGE, protection_context)
	incoming_damage = maxi(0, int(protection_context.get("damage", incoming_damage)))
	if incoming_damage == 0:
		return 0
	var previous_health: int = target.health
	target.health = previous_health - incoming_damage
	if target == _player_entity:
		_apply_sorcery_armor_cooldown_reduction(incoming_damage)
		redraw_status.emit()
	if target is PlayerCreature:
		_play_player_hit_sound()
		_maybe_show_low_health_tutorial()
		if _resting:
			_rest_took_damage = true
		if int(target.health) <= 0:
			var run_root: Map = _run_root if _run_root != null else self
			if not run_root._player_death_logged:
				_append_message("You die.")
				run_root._player_death_logged = true
				_is_active_map = false
				set_process_input(false)
				set_process(false)
				is_player_turn = false
				processing_turns = false
				cancel_auto_walk()
				run_root.player_died.emit(PlayerData.run_highest_level, PlayerData.run_enemies_killed)
	else:
		if int(target.health) <= 0:
			_remove_defeated_creature(target)
		elif previous_health > 1 and target.health == 1 and target.has_trait("Coward"):
			apply_status_to_entity(target, "Frightened", 5)
	return incoming_damage

func _status_damage_callback(target: Creature, amount: int, damage_type: String) -> void:
	_attack_resolution_depth += 1
	var dealt_damage: int = _deal_damage(target, amount, damage_type)
	if dealt_damage > 0:
		if target is PlayerCreature:
			_append_message("You suffer %d %s damage." % [dealt_damage, damage_type])
		else:
			if _is_active_map and _is_observed_by_player(target):
				_append_message("%s suffers %d %s damage." % [_creature_dp(target, true).capitalize(), dealt_damage, damage_type])
			_remove_defeated_creature(target)
	_attack_resolution_depth = maxi(0, _attack_resolution_depth - 1)
	if _attack_resolution_depth == 0:
		_flush_death_messages()

func _status_context() -> Dictionary:
	return {"damage_callback": Callable(self, "_status_damage_callback")}

func _apply_player_armor_status_ego(status_name: String, duration: int) -> int:
	if PlayerData.equipped_armor < 0 or PlayerData.equipped_armor >= PlayerData.inventory.size():
		return duration
	var armor: Item = PlayerData.inventory[PlayerData.equipped_armor]
	var ego: String = armor.ego
	var reduction_ego: String = ""
	if status_name == "Burning" or status_name == "Frozen":
		reduction_ego = "insulation"
	elif status_name == "Confused" or status_name == "Blind":
		reduction_ego = "clarity"
	if ego != reduction_ego:
		return duration
	var reduced_duration: int = maxi(0, duration - armor.enchantment)
	if reduced_duration < duration and armor.enchantment > 0:
		armor.identify_partially()
	return reduced_duration

func apply_status_to_entity(entity: Creature, status_name: String, duration: int) -> bool:
	if status_name == "Weakened" and not entity is PlayerCreature:
		status_name = "Poisoned"
	if entity is PlayerCreature and entity == _player_entity:
		duration = _apply_player_armor_status_ego(status_name, duration)
		if duration <= 0:
			return false
	var had_weakened: bool = entity is PlayerCreature and StatusData.has_status(entity, "Weakened")
	if status_name == "Burning":
		var entity_position: Vector2i = entity.pos
		var tile: TerrainData.Terrain = grid[entity_position]
		match tile.flammability:
			TerrainData.Flammability.EXTINGUISH_STEAM:
				var was_burning: bool = StatusData.has_status(entity, "Burning")
				StatusData.remove_status(entity, "Wet")
				StatusData.remove_status(entity, "Burning")
				if was_burning:
					_emit_quenching_steam(entity_position)
				return false
			TerrainData.Flammability.EXTINGUISH_MELT_TO_FLOOR:
				grid[entity_position] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)
				_extinguish_entity_on_cold_terrain(entity, entity_position)
				return false
			TerrainData.Flammability.EXTINGUISH_MELT_TO_WATER:
				grid[entity_position] = TerrainData.get_terrain(TerrainData.TileType.WATER_SHALLOW)
				_extinguish_entity_on_cold_terrain(entity, entity_position)
				return false
	var applied: bool = StatusData.apply_status(entity, status_name, duration, _status_context())
	if applied and entity is PlayerCreature:
		if status_name == "Weakened" and not had_weakened:
			for stat: PlayerData.Stat in [PlayerData.Stat.STRENGTH, PlayerData.Stat.DEXTERITY, PlayerData.Stat.INTELLIGENCE, PlayerData.Stat.CONSTITUTION]:
				PlayerData.change_stat(stat, -1, entity)
		elif status_name == "Transference":
			var active_transference_partner: Creature = _active_transference_partner(entity)
			if not active_transference_partner:
				_remove_transference_link_for_entity(entity)
	return applied

func _advance_regeneration(entity: Creature, time_cost: int) -> void:
	if time_cost <= 0:
		return
	var sleeping_regeneration: bool = entity.sleeping_regen and StatusData.has_status(entity, "Sleeping")
	var resting_regeneration: bool = entity is PlayerCreature and _resting
	var maximum_health: int = entity.max_health
	var current_health: int = entity.health
	if maximum_health <= 0 or current_health <= 0:
		return
	var regeneration_context: Dictionary = {"rate_factor": 1.0, "inverts_regeneration": false}
	StatusData.trigger(entity, StatusData.EffectType.REGENERATION, regeneration_context)
	if resting_regeneration:
		regeneration_context.rate_factor = regeneration_context.rate_factor * 3.0
	elif sleeping_regeneration:
		regeneration_context.rate_factor = regeneration_context.rate_factor * 2.0
	if entity.has_trait("No Regeneration") and not regeneration_context.inverts_regeneration:
		entity.regen_progress = 0.0
		return
	if entity.has_trait("Quick Regeneration") and not regeneration_context.inverts_regeneration:
		regeneration_context.rate_factor = regeneration_context.rate_factor * 5.0
	var rate_factor: float = regeneration_context.rate_factor
	var interval: float = float(REGEN_FULL_HEALTH_TIME) / float(maximum_health) / rate_factor
	var progress: float = entity.regen_progress + time_cost
	if current_health >= maximum_health and not regeneration_context.inverts_regeneration:
		entity.regen_progress = 0.0
		return
	while progress >= interval:
		progress -= interval
		if regeneration_context.inverts_regeneration:
			_deal_damage(entity, 1, "poison")
		else:
			_heal_entity(entity, 1)
		if entity.health <= 0:
			break
	if entity.health >= maximum_health and not regeneration_context.inverts_regeneration:
		progress = 0.0
		if resting_regeneration and entity.has_flag("_rest_started_injured"):
			_rest_reached_full_health = true
	entity.regen_progress = progress
	if sleeping_regeneration:
		var statuses: Array = entity.status
		for status: StatusData.Status in statuses:
			if status.status_name == "Sleeping" or status.status_name == "Helpless":
				status.duration = status.duration + 1
		entity.status = statuses

const ENVIRONMENT_VISIBLE_THRESHOLD: int = 2
const ENVIRONMENT_MAX_CONCENTRATION: int = 100

func _environment_effect(position: Vector2i) -> Dictionary:
	var effect: Dictionary = environment.get(position, {})
	return effect if _environment_kind(effect) in ["steam", "smoke", "fire"] else {}

func _environment_kind(effect: Dictionary) -> String:
	return effect.get("type", "")

func _environment_concentration(effect: Dictionary) -> int:
	return effect.get("concentration", 0)

func _environment_visible(position: Vector2i) -> bool:
	var effect: Dictionary = _environment_effect(position)
	if _environment_kind(effect) not in ["steam", "smoke", "fire"]:
		return false
	return _environment_concentration(effect) >= ENVIRONMENT_VISIBLE_THRESHOLD

func _environment_color(position: Vector2i) -> int:
	if not _environment_visible(position):
		return -1
	match _environment_kind(_environment_effect(position)):
		"steam":
			return 7
		"smoke":
			return 8
		"fire":
			return 10
	return -1

func _environment_blocks_vision(position: Vector2i) -> bool:
	if not _environment_visible(position):
		return false
	var kind: String = _environment_kind(_environment_effect(position))
	return kind == "steam" or kind == "smoke"

func set_environment_effect(position: Vector2i, effect_type: String, concentration: int) -> void:
	if position.x < 0 or position.x >= MAP_W or position.y < 0 or position.y >= MAP_H or concentration <= 0:
		return
	if effect_type not in ["steam", "smoke", "fire"]:
		return
	var current: Dictionary = _environment_effect(position)
	var current_concentration: int = _environment_concentration(current)
	if not current.is_empty() and current_concentration > concentration:
		return
	if _environment_kind(current) == "fire" and effect_type != "fire" and current.get("burns_terrain", false):
		grid[position] = TerrainData.get_terrain(TerrainData.TileType.ASHES)
	var clamped_concentration: int = mini(ENVIRONMENT_MAX_CONCENTRATION, concentration)
	var burns_terrain: bool = current.get("burns_terrain", false) if _environment_kind(current) == "fire" and effect_type != "fire" else effect_type == "fire" and grid[position].flammability == TerrainData.Flammability.FULL_FIRE
	if _environment_kind(current) == "fire" and effect_type != "fire" and current.get("burns_terrain", false):
		grid[position] = TerrainData.get_terrain(TerrainData.TileType.ASHES)
	environment[position] = {"type": effect_type, "concentration": clamped_concentration, "burns_terrain": burns_terrain}
	redraw.emit()

func _ignite_flammable_tile(position: Vector2i, concentration: int = 30) -> void:
	var tile: TerrainData.Terrain = grid[position]
	var existing: Dictionary = _environment_effect(position)
	var ignition_concentration: int = clampi(concentration, _environment_concentration(existing), ENVIRONMENT_MAX_CONCENTRATION)
	var flammability = tile.flammability
	if flammability == TerrainData.Flammability.EXTINGUISH_MELT_TO_FLOOR:
		grid[position] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)
		if creature.has(position):
			var snow_entity: Creature = creature[position]
			_extinguish_entity_on_cold_terrain(snow_entity, position)
		else:
			redraw.emit()
		return
	elif flammability == TerrainData.Flammability.EXTINGUISH_MELT_TO_WATER:
		grid[position] = TerrainData.get_terrain(TerrainData.TileType.WATER_SHALLOW)
		if creature.has(position):
			var ice_entity: Creature = creature[position]
			_extinguish_entity_on_cold_terrain(ice_entity, position)
		else:
			redraw.emit()
		return
	elif flammability == TerrainData.Flammability.EXTINGUISH_STEAM:
		set_environment_effect(position, "steam", ignition_concentration)
		redraw.emit()
		return
	elif flammability == TerrainData.Flammability.EVAPORATE:
		grid[position] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)
		ignition_concentration = max(0, ignition_concentration - 1)
	elif flammability == TerrainData.Flammability.LIMITED_FIRE:
		ignition_concentration /= 2
	elif flammability == TerrainData.Flammability.NO_FIRE:
		return
	if _environment_kind(existing) == "fire":
		if ignition_concentration < _environment_concentration(existing):
			return
	environment[position] = {"type": "fire", "concentration": ignition_concentration, "burns_terrain": true}
	redraw.emit()

func _record_environment_candidate(candidates: Dictionary, position: Vector2i, effect: Dictionary) -> void:
	var existing: Dictionary = candidates.get(position, {})
	if existing.is_empty() or _environment_concentration(effect) > _environment_concentration(existing):
		candidates[position] = effect.duplicate(true)

func _environment_neighbors(position: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for direction: Vector2i in StatusData.ADJACENT_DIRECTIONS:
		var neighbor: Vector2i = position + direction
		if neighbor.x >= 0 and neighbor.x < MAP_W and neighbor.y >= 0 and neighbor.y < MAP_H:
			neighbors.append(neighbor)
	return neighbors

func _step_environment(effect_types: Array[String]) -> void:
	var snapshot: Dictionary = environment.duplicate(true)
	var next_state: Dictionary = environment.duplicate(true)
	var candidates: Dictionary = {}
	var extinguished_fire: Dictionary[Vector2i, bool] = {}
	for position: Vector2i in snapshot.keys():
		var effect: Dictionary = snapshot[position]
		var effect_type: String = _environment_kind(effect)
		if effect_types.has("smoke") and effect_type == "fire":
			for smoke_position: Vector2i in _environment_neighbors(position):
				var smoke_emission: Dictionary = {"type": "smoke", "concentration": randi() % int(1 + sqrt(_environment_concentration(effect))), "burns_terrain": false}
				_record_environment_candidate(candidates, smoke_position, smoke_emission)
		if not effect_types.has(effect_type):
			continue
		var concentration: int = _environment_concentration(effect)
		var decay: int = mini(1, roundi(sqrt(concentration)))
		var remaining: int = maxi(0, concentration - decay)
		if remaining > 0:
			var retained: Dictionary = effect.duplicate(true)
			retained["concentration"] = remaining
			next_state[position] = retained
		else:
			next_state.erase(position)
			if effect_type == "fire":
				extinguished_fire[position] = bool(effect.get("burns_terrain", false))
		if concentration < ENVIRONMENT_VISIBLE_THRESHOLD:
			continue
		for neighbor: Vector2i in _environment_neighbors(position):
			if effect_type == "fire":
				if grid[neighbor].flammability == TerrainData.Flammability.FULL_FIRE and _environment_kind(_environment_effect(neighbor)) != "fire":
					var fire_candidate: Dictionary = {"type": "fire", "concentration": mini(ENVIRONMENT_MAX_CONCENTRATION, concentration + randi() % 10), "burns_terrain": true}
					_record_environment_candidate(candidates, neighbor, fire_candidate)
				continue
			var candidate: Dictionary = {"type": effect_type, "concentration": maxi(1, remaining), "burns_terrain": false}
			_record_environment_candidate(candidates, neighbor, candidate)
	for position: Vector2i in candidates.keys():
		var candidate: Dictionary = candidates[position]
		var existing: Dictionary = next_state.get(position, {})
		if existing.is_empty() or _environment_concentration(candidate) > _environment_concentration(existing):
			if _environment_kind(existing) == "fire" and _environment_kind(candidate) != "fire" and bool(existing.get("burns_terrain", false)):
				grid[position] = TerrainData.get_terrain(TerrainData.TileType.ASHES)
			next_state[position] = candidate
	for position: Vector2i in extinguished_fire:
		var final_effect: Dictionary = next_state.get(position, {})
		if _environment_kind(final_effect) != "fire" and bool(extinguished_fire[position]):
			grid[position] = TerrainData.get_terrain(TerrainData.TileType.ASHES)
	environment = next_state

func _process_creature_respawn() -> void:
	if not _creature_population_initialized:
		return
	creature_budget = mini(level * 2, creature_budget + respawn_budget_increment)
	respawn_budget_increment = mini(PlayerData.run_highest_level * 2, respawn_budget_increment + 1)
	var forbidden_tiles: Dictionary = _spawn_exclusion_fov()
	var eligible_definitions: Array[Dictionary] = _creature_definitions_for_budget(creature_budget, false, forbidden_tiles)
	if eligible_definitions.is_empty():
		next_respawn_time += HALF_RESPAWN_INTERVAL
		return
	var definition: Dictionary = eligible_definitions.pick_random()
	var danger: int = definition.get("danger", 0)
	var spawned: EnemyCreature = _spawn_creature_definition(definition, next_respawn_time, true, forbidden_tiles)
	if spawned == null:
		next_respawn_time += HALF_RESPAWN_INTERVAL
		return
	creature_budget -= danger
	next_respawn_time += HALF_RESPAWN_INTERVAL * 2

func _advance_environment_time(target_time: int) -> void:
	if target_time < environment_time:
		return
	# Timer effect: decrement timer and call effect_timed when it runs out
	for position in grid:
		var terrain: TerrainData.Terrain = grid[position]
		if terrain.timer >= 0:
			terrain.timer -= target_time - environment_time
			if terrain.timer <= 0 and terrain.effect_timed.is_valid():
				terrain.effect_timed.call(grid, environment, position)
	while true:
		var next_time: int = INT64_MAX
		for tick_time: int in environment_next_tick.values():
			next_time = mini(next_time, tick_time)
		if _creature_population_initialized:
			next_time = mini(next_time, next_respawn_time)
		if next_time < environment_time:
			next_time = environment_time
		if next_time > target_time:
			break
		if _creature_population_initialized and is_equal_approx(next_respawn_time, next_time):
			environment_time = maxi(environment_time, next_time)
			_process_creature_respawn()
			if next_respawn_time <= next_time:
				next_respawn_time = next_time + HALF_RESPAWN_INTERVAL
			continue
		var due_effects: Array[String] = []
		for kind: String in environment_next_tick.keys():
			if is_equal_approx(float(environment_next_tick[kind]), next_time):
				due_effects.append(kind)
		if not due_effects.is_empty():
			environment_time = maxi(environment_time, next_time)
			_step_environment(due_effects)
		for kind: String in due_effects:
			var interval: int = ENV_TICK_INTERVAL[kind]
			environment_next_tick[kind] = next_time + interval
		environment_time = maxi(environment_time, next_time)
		if next_time >= target_time:
			break
	environment_time = target_time

func _prepare_environment_turn(entity: Creature) -> void:
	# Prepare the environment for a creature's turn.
	# This checks if the turn has already been processed (via environment_checked_time),
	# and if not, starts the environment turn effects (terrain effects, status updates, etc.).
	# The environment_checked_time guard prevents frame-by-frame re-processing.
	var turn_time: int = entity.time
	_advance_environment_time(maxi(environment_time, turn_time))
	if is_equal_approx(entity.environment_checked_time, float(turn_time)):
		return
	entity.environment_checked_time = turn_time
	_environment_start_turn(entity)

func _creature_avoids_poison_pool(entity: Creature) -> bool:
	return not entity is PlayerCreature and not entity.has_named_immunity("poison")

func _environment_start_turn(entity: Creature) -> void:
	if entity.health <= 0:
		return
	var position: Vector2i = entity.pos
	var terrain: TerrainData.Terrain = grid[position]
	if terrain.effect_entered.is_valid() and (not entity.has_trait("Flying") or terrain.affects_flyers):
		terrain.effect_entered.call(entity, position, self)

	if entity.health <= 0:
		return
	if _environment_visible(position):
		var effect: Dictionary = _environment_effect(position)
		var concentration: int = _environment_concentration(effect)
		match _environment_kind(effect):
			"fire":
				apply_status_to_entity(entity, "Burning", clampi(roundi(concentration * 0.1), 1, 5))
			"steam":
				apply_status_to_entity(entity, "Wet", 1)
				_status_damage_callback(entity, 1, "fire")
	if StatusData.has_status(entity, "Burning"):
		_ignite_flammable_tile(position)

func _adjust_delay(entity: Creature, delay: int) -> int:
	var delay_context: Dictionary = {"delay": maxi(0, delay)}
	StatusData.trigger(entity, StatusData.EffectType.DELAY, delay_context)
	return maxi(1, roundi(delay_context.delay)) if delay > 0 else 0

func _record_armor_wear_time(entity: Creature, elapsed_time: int) -> void:
	if entity != _player_entity or PlayerData.equipped_armor < 0 or PlayerData.equipped_armor >= PlayerData.inventory.size() or elapsed_time <= 0:
		return
	var worn_armor: Item = PlayerData.inventory[PlayerData.equipped_armor]
	if worn_armor.get_id_status() == ItemData.ID_STATUS.FULL_ID:
		return
	worn_armor.identification_progress += elapsed_time
	if worn_armor.identification_progress >= 4000:
		worn_armor.identify_fully()

func _advance_entity_time(entity: Creature, base_delay: int, delay_is_adjusted: bool = false) -> int:
	var adjusted_delay: int = maxi(0, base_delay) if delay_is_adjusted else _adjust_delay(entity, maxi(0, base_delay))
	if entity == _player_entity:
		_record_armor_wear_time(entity, adjusted_delay)
	if not entity.has_flag("_environment_turn_prepared"): 
		if not entity.has_flag("_defer_environment_advance"):
			_prepare_environment_turn(entity)
		entity.set_flag("_environment_turn_prepared")
	if entity.health <= 0:
		entity.set_flag("_environment_turn_prepared", false)
		return 0
	var prior_time := entity.time
	_advance_regeneration(entity, adjusted_delay)
	entity.time = prior_time + adjusted_delay
	entity.set_flag("_environment_turn_prepared", false)
	_finish_entity_turn(entity)
	return adjusted_delay

func _apply_action_statuses(entity: Creature, action: String) -> void:
	if (action == "move" or action == "attack" or action == "throw" or action == "burning" or action == "wet") and StatusData.has_status(entity, "Invisible"):
		StatusData.remove_status(entity, "Invisible")
	var action_context: Dictionary = {"action": action, "apply_burning_callback": Callable(self, "_apply_burning_to_entity")}
	StatusData.trigger(entity, StatusData.EffectType.ACTION, action_context)

func _extinguish_entity_on_cold_terrain(entity: Creature, position: Vector2i) -> void:
	StatusData.remove_status(entity, "Wet")
	StatusData.remove_status(entity, "Burning")
	for fire_position: Vector2i in environment.keys():
		var fire_effect: Dictionary = _environment_effect(fire_position)
		if fire_position != position or _environment_kind(fire_effect) != "fire":
			continue
		fire_effect["burns_terrain"] = false
		if _environment_concentration(fire_effect) <= 1:
			environment.erase(fire_position)
		else:
			fire_effect["concentration"] = _environment_concentration(fire_effect) - 1
			environment[fire_position] = fire_effect
	redraw.emit()

func _apply_burning_to_entity(entity: Creature) -> void:
	var entity_position: Vector2i = entity.pos
	var tile: TerrainData.Terrain = grid[entity_position]
	match tile.flammability:
		TerrainData.Flammability.EXTINGUISH_STEAM:
			StatusData.remove_status(entity, "Wet")
			StatusData.remove_status(entity, "Burning")
			set_environment_effect(entity_position, "steam", 50)
			return
		TerrainData.Flammability.EXTINGUISH_MELT_TO_FLOOR:
			grid[entity_position] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)
			_extinguish_entity_on_cold_terrain(entity, entity_position)
			return
		TerrainData.Flammability.EXTINGUISH_MELT_TO_WATER:
			grid[entity_position] = TerrainData.get_terrain(TerrainData.TileType.WATER_SHALLOW)
			_extinguish_entity_on_cold_terrain(entity, entity_position)
			return
	if StatusData.has_status(entity, "Wet"):  
		StatusData.remove_status(entity, "Wet")
		StatusData.remove_status(entity, "Burning")
		return
	var statuses: Array = entity.status
	for status: StatusData.Status in statuses:
		if status.status_name == "Burning":
			return
	var burning_status: StatusData.Status = StatusData.Status.new("Burning", 1)
	if burning_status:
		statuses.append(burning_status)
	entity.status = statuses

func _finish_entity_turn(entity: Creature) -> void:
	var player_was_weakened: bool = entity is PlayerCreature and StatusData.has_status(entity, "Weakened")
	StatusData.finish_turn(entity, _status_context())
	if player_was_weakened and not StatusData.has_status(entity, "Weakened"):
		for stat: PlayerData.Stat in [PlayerData.Stat.STRENGTH, PlayerData.Stat.DEXTERITY, PlayerData.Stat.INTELLIGENCE, PlayerData.Stat.CONSTITUTION]:
			PlayerData.change_stat(stat, 1, entity)

func _sort_by_time(a: Creature, b: Creature) -> bool:
	return a.time < b.time

func _advance_ephemeral_lifetime(entity: Creature) -> bool:
	if not entity.has_trait("Ephemeral"):
		return false
	if StatusData.has_status(entity, "Temporary"):
		return false
	entity.set_flag("ephemeral_expired")
	entity["health"] = 0
	return true

# Process the NPC turn queue.
# Loops through creatures in the turn queue and processes their actions.
# Player turns are handled separately at the front of the queue.
# Each creature gets an action delay based on its speed and terrain.
func _process_npc_turns() -> void:
	if not _is_active_map:
		return
	# Cache only the player's remembered map before NPC actions.
	_snapshot_visible_state()
	processing_turns = true
	while turn_queue.size() > 0:
		var front: Creature = turn_queue[0]
		if front is PlayerCreature: 
			_hit_sound_played_this_player_turn = false
			_prepare_environment_turn(front)
			is_player_turn = true
			processing_turns = false
			break
		# NPC turn: act and push back
		_hit_sound_played_this_player_turn = false
		_prepare_environment_turn(front)
		if not _is_active_map or _player_death_logged:
			processing_turns = false
			is_player_turn = false
			break
		if front.health <= 0:
			_remove_defeated_creature(front)
			continue
		var npc_delay: int = _act_creature_random(front)
		front.set_flag("_defer_environment_advance")
		front.last_action_cost = _advance_entity_time(front, npc_delay, true)
		front.set_flag("_defer_environment_advance", false)
		front.set_flag("_environment_turn_prepared", false)
		if not _is_active_map or _player_death_logged:
			processing_turns = false
			is_player_turn = false
			break
		if front.health <= 0:
			_remove_defeated_creature(front)
			continue
		if _advance_ephemeral_lifetime(front):
			_remove_defeated_creature(front)
			continue
		# Insert back in sorted position
		turn_queue.append(front)
		turn_queue.sort_custom(_sort_by_time)
	if processing_turns:
		# Queue emptied somehow, give player turn
		is_player_turn = true
		processing_turns = false
	if not _is_active_map or _player_death_logged:
		return
	_recompute_all_fov()
	redraw.emit()
func _creature_detection_minimum(entity: EnemyCreature) -> float:
	if StatusData.has_status(entity, "Sleeping"):
		return 0.0
	var minimum_range: float = entity.detection_range_min
	if _player_entity and creature.get(player_pos, null) == _player_entity:
		var stealth_bonus: int = PlayerData.equipped_armor_ego_bonus("stealth")
		minimum_range -= stealth_bonus
		if stealth_bonus > 0 and PlayerData.equipped_armor >= 0 and PlayerData.equipped_armor < PlayerData.inventory.size():
			PlayerData.inventory[PlayerData.equipped_armor].identify_partially()
	return maxf(0.0, minimum_range)

func _creature_detection_maximum(entity: EnemyCreature) -> float:
	return entity.detection_range_max

func _creature_detection_penalty() -> float:
	return 1.0 if grid[player_pos].terrain_name == "mossy ground" else 0.0

func _creature_detection_range(entity: Creature) -> float:
	if StatusData.has_status(entity, "Sleeping"):
		return 0.0
	var minimum_range: float = _creature_detection_minimum(entity)
	var maximum_range: float = _creature_detection_maximum(entity)
	return maxf(0.0, clampf(float(entity.detection_range), minimum_range, maximum_range) - _creature_detection_penalty())

func _creature_has_player_in_fov(entity: Creature) -> bool:
	if _player_entity and StatusData.has_status(_player_entity, "Invisible"):
		return false
	var creature_visible_tiles: Dictionary = entity.visible_tiles
	if not creature_visible_tiles.has(player_pos):
		creature_visible_tiles = _compute_fov(entity)
		entity.visible_tiles = creature_visible_tiles
	return creature_visible_tiles.has(player_pos)

func _creature_player_visible(entity: Creature) -> bool:
	if can_swim(entity) and not _is_water_tile(grid[player_pos]):
		return false
	return _creature_has_player_in_fov(entity)

func _creature_can_detect_player(entity: Creature) -> bool:
	var detection_range: float = _creature_detection_range(entity)
	return _creature_player_visible(entity) and _creature_detection_distance(entity, player_pos) <= detection_range

func _creature_can_see_creature(observer: Creature, target: Creature) -> bool:
	if StatusData.has_status(target, "Invisible"):
		return false
	var target_position: Vector2i = target.pos
	if can_swim(observer) and not _is_water_tile(grid[target_position]):
		return false
	var observer_visible_tiles: Dictionary = _compute_fov(observer)
	observer.visible_tiles = observer_visible_tiles
	if not observer_visible_tiles.has(target_position):
		return false
	var observer_position: Vector2i = observer.pos
	for sight_position: Vector2i in _bresenham_line(observer_position, target_position):
		if sight_position == observer_position or sight_position == target_position:
			continue
		if _environment_blocks_vision(sight_position):
			return false
	return true

func _alert_creature_to_player(entity: EnemyCreature, attacker_position: Vector2i) -> void:
	if entity.health <= 0:
		return
	entity.alerted_player_pos = attacker_position
	entity.last_seen_player_pos = attacker_position
	entity.awareness_mode = "alerted"
	var minimum_detection: float = _creature_detection_minimum(entity)
	var maximum_detection: float = _creature_detection_maximum(entity)
	entity.detection_range = clampf(maxf(float(entity.detection_range), _creature_detection_distance(entity, attacker_position)), minimum_detection, maximum_detection)
	entity.behavior_mode = ""
	entity.behavior_turns_left = 0
	entity.sleeping_regen = false
	StatusData.remove_status(entity, "Sleeping")
	StatusData.remove_status(entity, "Helpless")

func _make_creature_aware_of_player(entity: Creature) -> void:
	if entity is PlayerCreature:
		return
	_alert_creature_to_player(entity, player_pos)
	if entity.health > 0:
		entity.awareness_mode = "aware"
		entity.enemy_sight_history = []
		entity.enemy_player_sight_history = []
		entity.enemy_seen_tiles_history = []
		entity.awareness_turn = 0
		entity.last_seen_player_turn = 0

func _make_creature_at_position_aware_of_player(position: Vector2i) -> void:
	if creature.has(position):
		_make_creature_aware_of_player(creature[position])

func _alert_cluster_conspecifics(entity: Creature) -> bool:
	var cluster = -1
	for c in CreatureData.creatures:
		if c.name == entity.creature_name:
			cluster = c.get("cluster", -1)
			break
	if cluster < 0:
		return false
	var visible_positions: Dictionary = entity.visible_tiles
	if visible_positions.is_empty():
		visible_positions = _compute_fov(entity)
		entity["visible_tiles"] = visible_positions
	var alerted_any: bool = false
	var own_creature_glyph: String = entity.glyph
	for visible_position: Vector2i in visible_positions.keys():
		if visible_position == entity.pos or not creature.has(visible_position):
			continue
		var conspecific: Creature = creature[visible_position]
		if conspecific == entity or conspecific.health <= 0 or conspecific.glyph != own_creature_glyph or conspecific.awareness_mode != "unaware":
			continue
		_alert_creature_to_player(conspecific, player_pos)
		conspecific.detection_range = _creature_detection_maximum(conspecific)
		alerted_any = true
	return alerted_any

func _creature_detection_distance(entity: Creature, destination: Vector2i) -> float:
	var dist_x: int = absi(entity.pos.x - destination.x)
	var dist_y: int = absi(entity.pos.y - destination.y)
	var dist_maj: int
	var dist_min: int
	if dist_x > dist_y:
		dist_maj = dist_x
		dist_min = dist_y
	else:
		dist_maj = dist_y
		dist_min = dist_x
	return dist_maj + 0.5 * dist_min

func _record_recent_creature_sight(entity: EnemyCreature) -> void:
	var sight_turn: int = maxi(entity.sight_history_turn, entity.awareness_turn) + 1
	var awareness_mode: String = entity.awareness_mode
	var tile_history: Array = entity.enemy_seen_tiles_history
	var player_history: Array = entity.enemy_player_sight_history
	if awareness_mode in ["aware", "searching"] and (not tile_history.is_empty() or not player_history.is_empty()):
		var latest_history_turn: int = 0
		if not tile_history.is_empty():
			latest_history_turn = maxi(latest_history_turn, int(tile_history.back().get("turn")))
		if not player_history.is_empty():
			latest_history_turn = maxi(latest_history_turn, int(player_history.back().get("turn")))
		sight_turn = maxi(sight_turn, latest_history_turn + 1)
	entity.sight_history_turn = sight_turn
	if awareness_mode not in ["aware", "searching"]:
		return
	var visible_tiles_for_history: Dictionary = _compute_fov(entity)
	entity.visible_tiles = visible_tiles_for_history
	var visible_positions: Array[Vector2i] = []
	for position_value: Vector2i in visible_tiles_for_history.keys():
		visible_positions.append(position_value)
	tile_history.append({"turn": sight_turn, "tiles": visible_positions})
	while not tile_history.is_empty() and sight_turn - int(tile_history[0].get("turn", 0)) >= 5:
		tile_history.pop_front()
	entity.enemy_seen_tiles_history = tile_history
	if entity.category == CreatureData.CreatureCategory.ANIMAL and not entity.has_trait("Mindless"):
		return
	if _creature_player_visible(entity):
		player_history.append({"turn": sight_turn, "pos": player_pos})
		while not player_history.is_empty() and sight_turn - int(player_history[0].get("turn", 0)) >= 5:
			player_history.pop_front()
		entity.enemy_player_sight_history = player_history
		var recent_positions: Array[Vector2i] = []
		for record: Dictionary in player_history:
			recent_positions.append(record.get("pos", player_pos))
		entity.enemy_sight_history = recent_positions

func _recently_seen_creature_tiles(entity: EnemyCreature) -> Dictionary:
	var remembered_positions: Dictionary = {}
	var tile_history: Array = entity.enemy_seen_tiles_history
	for record: Dictionary in tile_history:
		for position_value: Vector2i in record.get("tiles", Vector2i(-1, -1)):
			remembered_positions[position_value] = true
	return remembered_positions

func _prediction_step_is_open(entity: Creature, origin: Vector2i, direction: Vector2i, for_player: bool) -> bool:
	var target: Vector2i = origin + direction
	if target.x < 0 or target.x >= MAP_W or target.y < 0 or target.y >= MAP_H:
		return false
	var target_tile: TerrainData.Terrain = grid[target]
	var target_open: bool = target_tile.passable if for_player else _creature_can_reach_any_known_tile(entity, target)
	if not target_open or creature.has(target):
		return false
	if direction.x != 0 and direction.y != 0:
		var side_x: Vector2i = origin + Vector2i(direction.x, 0)
		var side_y: Vector2i = origin + Vector2i(0, direction.y)
		var side_x_open: bool = grid[side_x].passable if for_player else _creature_can_reach_any_known_tile(entity, side_x)
		var side_y_open: bool = grid[side_y].passable if for_player else _creature_can_reach_any_known_tile(entity, side_y)
		if not side_x_open and not side_y_open:
			return false
	if for_player:
		if _is_hazardous_for_creature(_player_entity, target_tile) and _has_safe_player_move():
			return false
	else:
		if not _is_valid_creature_move(entity, direction):
			return false
		var destination_tile: TerrainData.Terrain = grid[target]
		if _creature_avoids_poison_pool(entity) and destination_tile.terrain_name == "glowing pool":
			return false
	return true

func _predicted_unholy_search_target(entity: EnemyCreature, last_seen: Vector2i) -> Vector2i:
	var player_history: Array = entity.enemy_player_sight_history
	var unique_positions: Array[Vector2i] = []
	for record: Dictionary in player_history:
		var remembered_position: Vector2i = record.get("pos", last_seen)
		if unique_positions.is_empty() or unique_positions.back() != remembered_position:
			unique_positions.append(remembered_position)
	if unique_positions.size() < 2:
		return last_seen
	var total_movement: Vector2 = Vector2.ZERO
	var movement_count: int = 0
	for index: int in range(1, unique_positions.size()):
		var movement: Vector2i = unique_positions[index] - unique_positions[index - 1]
		if movement != Vector2i.ZERO:
			total_movement += Vector2(movement)
			movement_count += 1
	if movement_count == 0:
		return last_seen
	var average_movement: Vector2 = total_movement / float(movement_count)
	var direction: Vector2i = Vector2i(signi(roundi(average_movement.x * 100.0)), signi(roundi(average_movement.y * 100.0)))
	if direction == Vector2i.ZERO:
		return last_seen
	var predicted_target: Vector2i = last_seen
	var player_position: Vector2i = last_seen
	var creature_position: Vector2i = entity.pos
	for _step: int in range(5):
		if not _prediction_step_is_open(entity, player_position, direction, true):
			break
		var next_player_position: Vector2i = player_position + direction
		predicted_target = next_player_position
		player_position = next_player_position
		if _prediction_step_is_open(entity, creature_position, direction, false):
			creature_position += direction
		elif not _creature_can_reach_any_known_tile(entity, creature_position + direction):
			break
	return predicted_target

func _update_creature_awareness(entity: EnemyCreature) -> void:
	if entity.awareness_mode == "alerted":
		return
	var mindless_searching: bool = entity.has_trait("Mindless") and entity.awareness_mode == "searching"
	if mindless_searching:
		var remembered_player_position: Vector2i = entity.last_seen_player_pos
		if remembered_player_position != Vector2i(-1, -1) and not _creature_player_visible(entity):
			return
	var minimum_range: float = _creature_detection_minimum(entity)
	var maximum_range: float = _creature_detection_maximum(entity)
	var current_detection: float = entity.detection_range
	var detection_penalty: float = _creature_detection_penalty()
	var effective_minimum: float = maxf(0.0, minimum_range - detection_penalty)
	var effective_maximum: float = maxf(0.0, maximum_range - detection_penalty)
	var detection_range: float = maxf(0.0, current_detection) if StatusData.has_status(entity, "Sleeping") else clampf(current_detection, minimum_range, maximum_range)
	var player_visible: bool = _creature_player_visible(entity)
	var player_distance: float = float(entity.pos.distance_to(player_pos))
	var mindless: bool = entity.has_trait("Mindless")
	if player_visible:
		detection_range = minf(effective_maximum, detection_range + 1.0)
		if not mindless:
			entity.last_seen_player_pos = player_pos
			entity.last_seen_player_turn = entity.awareness_turn
		entity.player_visible_turns = entity.player_visible_turns
		if mindless:
			entity.awareness_mode = "aware"
		elif player_distance <= detection_range:
			if entity.awareness_mode != "aware":
				entity.awareness_turn = 0
			entity.awareness_mode = "aware"
	else:
		entity.player_visible_turns = 0
		var path_distance: float = _creature_detection_distance(entity, player_pos)
		if path_distance > detection_range:
			detection_range = maxf(effective_minimum, detection_range - 1.0)
			if not mindless and entity.category == CreatureData.CreatureCategory.ANIMAL and entity.awareness_mode != "unaware" and path_distance > detection_range:
				entity.awareness_mode = "unaware"
				entity.enemy_sight_history = []
				entity.awareness_turn = 0
				entity.behavior_turns_left = 0
				entity.behavior_mode = ""
		elif entity.awareness_mode == "aware":
			entity.awareness_mode = "searching"
			if entity.category == CreatureData.CreatureCategory.ANIMAL:
				entity.awareness_mode = "searching"
	entity.detection_range = clampf(detection_range, effective_minimum, effective_maximum)
	if StatusData.has_status(entity, "Sleeping"):
		entity.detection_range = maxf(0.0, float(entity.detection_range))
	if entity.awareness_mode == "aware" and player_visible:
		entity.detection_range = clampf(float(entity.detection_range) - 0.1, effective_minimum, effective_maximum)
		if entity.player_visible_turns == 1:
			entity.awareness_turn = 0
		entity.awareness_turn += 1
	elif entity.awareness_mode == "searching" or (mindless and player_visible):
		entity.awareness_turn += 1
	_record_recent_creature_sight(entity)

func _active_fire_concentration(position: Vector2i) -> int:
	var effect: Dictionary = _environment_effect(position)
	if _environment_kind(effect) != "fire":
		return 0
	return _environment_concentration(effect)

func _has_active_fire() -> bool:
	for position: Vector2i in environment.keys():
		if _active_fire_concentration(position) > 0:
			return true
	return false

func _creature_path_should_account_for_fire(entity: Creature, goal: Vector2i) -> bool:
	var category: int = entity.category
	if category == CreatureData.CreatureCategory.ANIMAL:
		var hunter: bool = entity.behavior_mode == "hunt"
		var health: int = entity.health
		var max_health: int = maxi(1, entity.max_health)
		return not hunter or entity.health * 2 < entity.max_health or goal != player_pos
	if category == CreatureData.CreatureCategory.HUMANOID:
		return entity.health * 2 < entity.max_health
	return true

func _creature_fire_path_cost(entity: Creature, concentration: int, pursuing_target: bool) -> float:
	if concentration <= 0 or entity.has_named_immunity("fire"):
		return 0.0
	if StatusData.has_status(entity, "Burning"):
		return -1.0
	var category: int = entity.category
	var health: int = entity.health
	var max_health: int = maxi(1, entity.max_health)
	var healthy: bool = health * 2 >= max_health
	if category == CreatureData.CreatureCategory.ANIMAL:
		var hunter: bool = entity.behavior_mode == "hunt"
		if hunter and pursuing_target and healthy and concentration == 1:
			return 0.0
		return -1.0
	if category == CreatureData.CreatureCategory.HUMANOID:
		if not healthy or concentration >= 3:
			return -1.0
		return float(concentration) * 2.0
	return -1.0

func _burning_duration(entity: Creature) -> int:
	for status: StatusData.Status in entity.status:
		if status.status_name == "Burning":
			return status.duration
	return 0

func _creature_fire_route(entity: Creature, goal: Vector2i, max_steps: int = 0, avoid_any_fire: bool = false, pursuing_target_override: bool = false) -> Dictionary:
	var start: Vector2i = entity.pos
	var distances: Dictionary = {start: 0.0}
	var steps_to: Dictionary = {start: 0}
	var previous: Dictionary = {}
	var frontier: Array[Dictionary] = []
	_path_heap_push(frontier, {"pos": start, "distance": 0.0})
	var directions: Array[Vector2i] = StatusData.ADJACENT_DIRECTIONS
	while not frontier.is_empty():
		var entry: Dictionary = _path_heap_pop(frontier)
		var position: Vector2i = entry.get("pos", start)
		var current_score: float = entry.get("distance", 0.0)
		if current_score > float(distances.get(position, INF)):
			continue
		if position == goal:
			break
		for direction: Vector2i in directions:
			var target: Vector2i = position + direction
			if target.x < 0 or target.x >= MAP_W or target.y < 0 or target.y >= MAP_H:
				continue
			if target != goal and creature.has(target):
				continue
			var tile: TerrainData.Terrain = grid[target]
			var flying: bool = entity.has_trait("Flying")
			var aquatic: bool = can_swim(entity)
			var passable_for_creature: bool = (aquatic and _is_water_tile(tile)) or (not aquatic and tile.passable) or (flying and tile.terrain_name == "deep lake")
			if target != goal and _is_stairs_tile(tile):
				continue
			if not passable_for_creature:
				continue
			var fire_concentration: int = _active_fire_concentration(target)
			var pursuing_target: bool = pursuing_target_override or goal == player_pos or creature.has(goal)
			var fire_cost: float = _creature_fire_path_cost(entity, fire_concentration, pursuing_target)
			if fire_concentration > 0 and (avoid_any_fire or fire_cost < 0.0):
				continue
			var diagonal: bool = direction.x != 0 and direction.y != 0
			if diagonal:
				var side_x: Vector2i = Vector2i(target.x, position.y)
				var side_y: Vector2i = Vector2i(position.x, target.y)
				var side_x_terr: TerrainData.Terrain = grid[side_x]
				var side_y_terr: TerrainData.Terrain = grid[side_y]
				var side_x_open: bool = side_x_terr.passable or ((flying or aquatic) and side_x_terr.terrain_name == "deep lake")
				var side_y_open: bool = side_y_terr.passable or ((flying or aquatic) and side_y_terr.terrain_name == "deep lake")
				if not side_x_open and not side_y_open:
					continue
			var next_steps: int = int(steps_to[position]) + 1
			if max_steps > 0 and next_steps > max_steps:
				continue
			var terrain_cost: float = (1.0 if _creature_ignores_terrain_cost(entity) else grid[target].move_cost) * (1.5 if diagonal else 1.0)
			var next_score: float = current_score + terrain_cost + fire_cost
			var should_update: bool = not distances.has(target) or next_score < float(distances[target])
			if not should_update and is_equal_approx(next_score, float(distances.get(target, INF))):
				should_update = next_steps < int(steps_to.get(target, 2147483647))
			if not should_update:
				continue
			distances[target] = next_score
			steps_to[target] = next_steps
			previous[target] = position
			_path_heap_push(frontier, {"pos": target, "distance": next_score})
	if start != goal and not previous.has(goal):
		return {}
	return {"previous": previous, "steps": steps_to, "score": distances}

func _creature_route_first_step(entity: Creature, goal: Vector2i, route: Dictionary) -> Vector2i:
	if route.is_empty() or goal == entity.pos:
		return Vector2i.ZERO
	var previous: Dictionary = route.get("previous", {})
	var position: Vector2i = goal
	var path_guard: int = 0
	while previous.has(position) and previous[position] != entity.pos and path_guard < MAP_W * MAP_H:
		position = previous[position]
		path_guard += 1
	if path_guard >= MAP_W * MAP_H or not previous.has(position):
		return Vector2i.ZERO
	return position - entity.pos

func _burning_escape_action(entity: Creature) -> int:
	if not StatusData.has_status(entity, "Burning") or entity.has_named_immunity("fire"):
		return -1
	var current_tile: TerrainData.Terrain = grid[entity.pos]
	if current_tile.flammability in [TerrainData.Flammability.FULL_FIRE, TerrainData.Flammability.LIMITED_FIRE, TerrainData.Flammability.EVAPORATE]:
		_apply_burning_to_entity(entity)
		return _move_creature(entity, Vector2i.ZERO)
	var burning_turns: int = _burning_duration(entity)
	if burning_turns <= 0:
		return -1
	var visible_tiles_for_entity: Dictionary = entity.visible_tiles
	if visible_tiles_for_entity.is_empty():
		visible_tiles_for_entity = _compute_fov(entity)
		entity.visible_tiles = visible_tiles_for_entity
	var cooling_candidates: Dictionary = {}
	for visible_position_value: Vector2i in visible_tiles_for_entity.keys():
		cooling_candidates[visible_position_value] = true
	var cold_destinations: Array[Vector2i] = []
	for destination: Vector2i in cooling_candidates.keys():
		var destination_tile: TerrainData.Terrain = grid[destination]
		if destination_tile.Flammability not in [TerrainData.Flammability.EXTINGUISH_STEAM, TerrainData.Flammability.EXTINGUISH_MELT_TO_FLOOR, TerrainData.Flammability.EXTINGUISH_MELT_TO_WATER]:
			continue
		cold_destinations.append(destination)
	var best_destination: Vector2i = Vector2i(-1, -1)
	var best_route: Dictionary = {}
	var best_steps: int = 2147483647
	for destination: Vector2i in cold_destinations:
		var route: Dictionary = _creature_fire_route(entity, destination, burning_turns, true)
		if route.is_empty():
			continue
		var steps: int = int(route.get("steps", {}).get(destination, 2147483647))
		if steps > 0 and steps < best_steps:
			best_destination = destination
			best_route = route
			best_steps = steps
	if best_destination == Vector2i(-1, -1):
		return -1
	var direction: Vector2i = _creature_route_first_step(entity, best_destination, best_route)
	if direction == Vector2i.ZERO:
		return -1
	return _move_creature(entity, direction)

func _is_orthogonally_adjacent(first_position: Vector2i, second_position: Vector2i) -> bool:
	var offset: Vector2i = second_position - first_position
	return absi(offset.x) + absi(offset.y) == 1

func _creature_move_toward(entity: Creature, goal: Vector2i) -> int:
	var pursuing_target: bool = goal == player_pos or creature.has(goal)
	var forced_pool_goal: bool = goal == player_pos or (creature.has(goal) and creature[goal] is PlayerCreature)
	if grid[goal].terrain_name == "glowing pool" and _creature_avoids_poison_pool(entity) and not forced_pool_goal:
		var safer_goal: Vector2i = _nearest_safe_creature_approach(entity, goal)
		if safer_goal == Vector2i(-1, -1):
			return _move_creature(entity, Vector2i.ZERO)
		goal = safer_goal
		pursuing_target = false
	if entity.pos == goal:
		return _move_creature(entity, Vector2i.ZERO)
	if _is_orthogonally_adjacent(entity.pos, goal) and goal == player_pos:
		return _creature_attack(entity, _player_entity)
	if _is_orthogonally_adjacent(entity.pos, goal) and creature.has(goal):
		var direct_target: Creature = creature[goal]
		if direct_target is PlayerCreature or _creature_can_attack_non_player_targets(entity) or _is_frightened_creature_blocking_only_escape(entity, direct_target):
			return _creature_attack(entity, direct_target)
	if _has_active_fire() and not entity.has_named_immunity("fire") and _creature_path_should_account_for_fire(entity, goal):
		var fire_goal: Vector2i = goal
		if goal == player_pos or creature.has(goal):
			var nearest_distance: float = INF
			for direction: Vector2i in StatusData.ADJACENT_DIRECTIONS:
				var candidate: Vector2i = goal + direction
				if candidate.x < 0 or candidate.x >= MAP_W or candidate.y < 0 or candidate.y >= MAP_H:
					continue
				if creature.has(candidate) or not grid[candidate].passable:
					continue
				var candidate_distance: float = entity.pos.distance_squared_to(candidate)
				if candidate_distance < nearest_distance:
					nearest_distance = candidate_distance
					fire_goal = candidate
		if goal == player_pos and fire_goal == goal and not _is_orthogonally_adjacent(entity.pos, player_pos):
			var safest_approach: Vector2i = _nearest_safe_creature_approach(entity, goal)
			if safest_approach != Vector2i(-1, -1):
				fire_goal = safest_approach
		var fire_route: Dictionary = _creature_fire_route(entity, fire_goal, 0, false, pursuing_target)
		if fire_route.is_empty():
			return _move_creature(entity, Vector2i.ZERO)
		var fire_direction: Vector2i = _creature_route_first_step(entity, fire_goal, fire_route)
		if fire_direction != Vector2i.ZERO:
			return _move_creature(entity, fire_direction)
		return _move_creature(entity, Vector2i.ZERO)
	var route_target: Vector2i = goal
	var path_goal: Vector2i = goal
	var path: Dictionary = {}
	if goal == player_pos and not _is_orthogonally_adjacent(entity.pos, goal):
		var approach_positions: Array[Vector2i] = []
		for approach_direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var approach_position: Vector2i = goal + approach_direction
			if approach_position == entity.pos or creature.has(approach_position) or not _creature_can_reach_any_known_tile(entity, approach_position):
				continue
			approach_positions.append(approach_position)
		var best_path_steps: int = 2147483647
		for approach_position: Vector2i in approach_positions:
			var candidate_path: Dictionary = dijkstra(entity, true, true, approach_position, 0.0, false)
			if not candidate_path.has(approach_position):
				continue
			var path_steps: int = 0
			var path_cursor: Vector2i = approach_position
			while candidate_path.has(path_cursor) and candidate_path[path_cursor] != entity.pos and path_steps < MAP_W * MAP_H:
				path_cursor = candidate_path[path_cursor]
				path_steps += 1
			if path_steps >= MAP_W * MAP_H or not candidate_path.has(path_cursor):
				continue
			if path_steps < best_path_steps:
				best_path_steps = path_steps
				path_goal = approach_position
				path = candidate_path
	else:
		path = dijkstra(entity, true, true, goal, 0.0, false)
	if path.has(path_goal):
		var route_position: Vector2i = path_goal
		var path_guard: int = 0
		while path.has(route_position) and path[route_position] != entity.pos and path_guard < MAP_W * MAP_H:
			route_position = path[route_position]
			path_guard += 1
		if path_guard < MAP_W * MAP_H and path.has(route_position):
			if route_position == player_pos and _is_orthogonally_adjacent(entity.pos, player_pos):
				return _creature_attack(entity, _player_entity)
			if goal == player_pos and route_position == path_goal and _is_orthogonally_adjacent(route_position, player_pos):
				return _move_creature(entity, route_position - entity.pos)
			if route_position != player_pos and creature.has(route_position):
				var route_occupant: Creature = creature[route_position]
				if route_occupant is PlayerCreature or _creature_can_attack_non_player_targets(entity) or _is_frightened_creature_blocking_only_escape(entity, route_occupant):
					return _creature_attack(entity, route_occupant)
			if route_position != player_pos and _is_valid_creature_move(entity, route_position - entity.pos):
				return _move_creature(entity, route_position - entity.pos)
	if goal == player_pos and not _is_orthogonally_adjacent(entity.pos, goal) and not path.has(path_goal):
		var fallback_approach: Vector2i = Vector2i(-1, -1)
		var fallback_distance: float = INF
		for fallback_direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var candidate_approach: Vector2i = goal + fallback_direction
			if creature.has(candidate_approach) or not _creature_can_reach_any_known_tile(entity, candidate_approach):
				continue
			var candidate_distance: float = entity.pos.distance_squared_to(candidate_approach)
			if candidate_distance < fallback_distance:
				fallback_distance = candidate_distance
				fallback_approach = candidate_approach
		if fallback_approach != Vector2i(-1, -1):
			route_target = fallback_approach
	var directions: Array[Vector2i] = StatusData.ADJACENT_DIRECTIONS.duplicate()
	if goal == player_pos or creature.has(goal):
		var closest_distance: float = INF
		for direction: Vector2i in directions:
			var candidate_position: Vector2i = goal + direction
			if candidate_position.x < 0 or candidate_position.x >= MAP_W or candidate_position.y < 0 or candidate_position.y >= MAP_H:
				continue
			if not grid[candidate_position].passable:
				continue
			var candidate_distance: float = entity.pos.distance_squared_to(candidate_position)
			if candidate_distance < closest_distance:
				closest_distance = candidate_distance
				route_target = candidate_position
	if _is_orthogonally_adjacent(entity.pos, goal) and goal == player_pos:
		return _creature_attack(entity, _player_entity)
	if _is_orthogonally_adjacent(entity.pos, goal) and creature.has(goal):
		var route_target_creature: Creature = creature[goal]
		if route_target_creature is PlayerCreature or _creature_can_attack_non_player_targets(entity) or _is_frightened_creature_blocking_only_escape(entity, route_target_creature):
			return _creature_attack(entity, route_target_creature)
	directions.sort_custom(func(first: Vector2i, second: Vector2i) -> bool:
		return (entity.pos + first).distance_squared_to(route_target) < (entity.pos + second).distance_squared_to(route_target)
	)
	for direction: Vector2i in directions:
		if not _is_valid_creature_move(entity, direction):
			continue
		var destination: Vector2i = entity.pos + direction
		if _creature_avoids_poison_pool(entity) and grid[destination].terrain_name == "glowing pool":
			continue
		return _move_creature(entity, direction)
	return _move_creature(entity, Vector2i.ZERO)

func _nearest_unremembered_destination(entity: Creature, remembered_positions: Dictionary) -> Vector2i:
	var maximum_radius: int = entity.sight_range * 2
	for radius: int in range(1, maximum_radius + 1):
		var best_position: Vector2i = Vector2i(-1, -1)
		var best_distance_squared: int = INT64_MAX
		for offset_y: int in range(-radius, radius + 1):
			for offset_x: int in [-radius, radius]:
				var candidate: Vector2i = entity.pos + Vector2i(offset_x, offset_y)
				if candidate.x < 0 or candidate.x >= MAP_W or candidate.y < 0 or candidate.y >= MAP_H or remembered_positions.has(candidate):
					continue
				if creature.has(candidate) or not _creature_can_reach_any_known_tile(entity, candidate):
					continue
				var candidate_distance_squared: int = offset_x * offset_x + offset_y * offset_y
				if candidate_distance_squared < best_distance_squared:
					best_position = candidate
					best_distance_squared = candidate_distance_squared
		for offset_x: int in range(-radius + 1, radius):
			for offset_y: int in [-radius, radius]:
				var candidate: Vector2i = entity.pos + Vector2i(offset_x, offset_y)
				if candidate.x < 0 or candidate.x >= MAP_W or candidate.y < 0 or candidate.y >= MAP_H or remembered_positions.has(candidate):
					continue
				if creature.has(candidate) or not _creature_can_reach_any_known_tile(entity, candidate):
					continue
				var candidate_distance_squared: int = offset_x * offset_x + offset_y * offset_y
				if candidate_distance_squared < best_distance_squared:
					best_position = candidate
					best_distance_squared = candidate_distance_squared
		if best_position != Vector2i(-1, -1):
			return best_position
	return Vector2i(-1, -1)

func _nearest_safe_creature_approach(entity: Creature, goal: Vector2i) -> Vector2i:
	var best_position: Vector2i = Vector2i(-1, -1)
	var best_distance: int = INT64_MAX
	for direction: Vector2i in StatusData.ADJACENT_DIRECTIONS:
		var candidate: Vector2i = goal + direction
		if not _creature_can_reach_any_known_tile(entity, candidate) or (creature.has(candidate) and candidate != player_pos):
			continue
		var candidate_tile: TerrainData.Terrain = grid[candidate]
		if _creature_avoids_poison_pool(entity) and candidate_tile.terrain_name == "glowing pool":
			continue
		var candidate_distance: int = entity.pos.distance_squared_to(candidate)
		if candidate_distance < best_distance:
			best_distance = candidate_distance
			best_position = candidate
	return best_position

func _creature_can_reach_any_known_tile(entity: Creature, destination: Vector2i) -> bool:
	if destination.x < 0 or destination.x >= MAP_W or destination.y < 0 or destination.y >= MAP_H:
		return false
	var tile: TerrainData.Terrain = grid[destination]
	if can_swim(entity):
		return _is_water_tile(tile)
	return tile.passable or (entity.has_trait("Flying") and tile.terrain_name == "deep lake")

func _creature_reaches_position_without_moving(entity: Creature, destination: Vector2i) -> bool:
	return entity.pos == destination

func _creature_can_reach_terrain(entity: Creature, destination: Vector2i) -> bool:
	return _creature_can_reach_any_known_tile(entity, destination)

func _act_creature_awareness(entity: EnemyCreature) -> int:
	var escape_delay: int = _burning_escape_action(entity)
	if escape_delay >= 0:
		return escape_delay
	if not entity.visible_tiles:
		entity.visible_tiles = _compute_fov(entity)
	var awareness_mode: String = entity.awareness_mode
	if entity.has_trait("Mindless") and awareness_mode == "searching" and entity.last_seen_player_pos == entity.pos:
		entity.awareness_turn = maxi(entity.awareness_turn, 1)
	if awareness_mode == "alerted":
		var alerted_position: Vector2i = entity.alerted_player_pos if entity.alerted_player_pos != Vector2i(-1, -1) else entity.last_seen_player_pos
		if alerted_position == player_pos and _creature_player_visible(entity) and _is_orthogonally_adjacent(entity.pos, player_pos):
			return _creature_attack(entity, _player_entity)
		if entity.pos != alerted_position:
			return _creature_move_toward(entity, alerted_position)
		entity.awareness_mode = "searching"
		entity.enemy_sight_history = []
		entity.enemy_player_sight_history = []
		awareness_mode = "searching"
	var was_aware: bool = awareness_mode == "aware"
	if awareness_mode != "alerted":
		if not (entity.has_trait("Mindless") and awareness_mode == "searching" and not _creature_player_visible(entity)):
			_update_creature_awareness(entity)
	var category: int = entity.category
	if not was_aware and entity.awareness_mode == "aware" and _alert_cluster_conspecifics(entity):
		return _adjust_delay(entity, entity.move_speed)
	awareness_mode = entity.awareness_mode
	if awareness_mode == "aware":
		if _creature_player_visible(entity) and entity.detection_range >= _creature_detection_distance(entity, player_pos):
			if _is_orthogonally_adjacent(entity.pos, player_pos):
				return _creature_attack(entity, _player_entity)
			return _creature_move_toward(entity, player_pos)
		awareness_mode = "searching"
		entity.awareness_mode = awareness_mode
	if awareness_mode == "searching":
		var player_visible: bool = _creature_player_visible(entity)
		if player_visible and (entity.has_trait("Mindless") or _creature_detection_distance(entity, player_pos) <= _creature_detection_range(entity)):
			entity.awareness_mode = "aware"
			if not entity.has_trait("Mindless"):
				entity.last_seen_player_pos = player_pos
			if _is_orthogonally_adjacent(entity.pos, player_pos):
				return _creature_attack(entity, _player_entity)
			return _creature_move_toward(entity, player_pos)
		var last_seen: Vector2i = entity.last_seen_player_pos
		var player_distance: float = _creature_detection_distance(entity, player_pos)
		if category == CreatureData.CreatureCategory.ANIMAL and player_distance > _creature_detection_range(entity):
			entity.awareness_mode = "unaware"
			return -1
		if category == CreatureData.CreatureCategory.ANIMAL:
			var last_tile: TerrainData.Terrain = grid[last_seen]
			if last_seen != Vector2i(-1, -1) and entity.pos != last_seen and last_tile in [TerrainData.TileType.FLOOR, TerrainData.TileType.SHRUB, TerrainData.TileType.ASHES, TerrainData.TileType.MOSS] and _creature_can_reach_any_known_tile(entity, last_seen):
				return _creature_move_toward(entity, last_seen)
			var scent_end_tile: TerrainData.Terrain = grid[player_pos]
			if last_tile in [TerrainData.TileType.FLOOR, TerrainData.TileType.SHRUB, TerrainData.TileType.ASHES, TerrainData.TileType.MOSS] and scent_end_tile in [TerrainData.TileType.FLOOR, TerrainData.TileType.SHRUB, TerrainData.TileType.ASHES, TerrainData.TileType.MOSS]:
				var scent: Array[Vector2i] = player_scent_trail
				for scent_index: int in range(scent.size() - 1, -1, -1):
					var scent_position: Vector2i = scent[scent_index]
					if scent_position != entity.pos and _creature_can_reach_any_known_tile(entity, scent_position):
						return _creature_move_toward(entity, scent_position)
			entity.awareness_mode = "unaware"
			return -1
		if last_seen != Vector2i(-1, -1) and entity.pos != last_seen and not (category == CreatureData.CreatureCategory.UNHOLY and entity.has_trait("Mindless")):
			var last_seen_goal: Vector2i = last_seen
			if category == CreatureData.CreatureCategory.UNHOLY and not entity.has_trait("Mindless"):
				last_seen_goal = _predicted_unholy_search_target(entity, last_seen)
			var at_search_goal: bool = entity.pos == last_seen_goal or _creature_reaches_position_without_moving(entity, last_seen_goal)
			if not at_search_goal:
				return _creature_move_toward(entity, last_seen_goal)
		var sight_history: Array = entity.enemy_sight_history
		if (entity.has_trait("Mindless") or category == CreatureData.CreatureCategory.UNHOLY) and sight_history.is_empty():
			sight_history = [last_seen]
		if entity.has_trait("Mindless") or category == CreatureData.CreatureCategory.UNHOLY:
			if not sight_history.is_empty():
				var center: Vector2 = Vector2.ZERO
				for remembered_position_value: Vector2i in sight_history:
					center += Vector2(remembered_position_value)
				center /= float(sight_history.size())
				var directions: Array[Vector2i] = _available_creature_directions(entity, Vector2i.ZERO)
				if not directions.is_empty():
					directions.sort_custom(func(first: Vector2i, second: Vector2i) -> bool:
						return Vector2(entity.pos + first).distance_squared_to(center) > Vector2(entity.pos + second).distance_squared_to(center)
					)
					return _move_creature(entity, directions[0])
		else:
			var seen_positions: Dictionary = _recently_seen_creature_tiles(entity)
			var destination: Vector2i = _nearest_unremembered_destination(entity, seen_positions)
			if destination != Vector2i(-1, -1):
				return _creature_move_toward(entity, destination)
		return _move_creature(entity, Vector2i.ZERO)
	return -1

func _roll_unaware_behavior(entity: Creature, visible_conspecifics: Array[Creature], non_conspecific_visible: bool) -> String:
	if entity.has_trait("Thief") and entity.stolen_item != null:
		return "flee"
	if entity.has_trait("Mindless"):
		return "wander"
	if entity.category == CreatureData.CreatureCategory.UNHOLY:
		return "wander"
	var poisoned: bool = StatusData.has_status(entity, "Poisoned")
	var sees_conspecifics: bool = not visible_conspecifics.is_empty()
	var injured: bool = entity.health < entity.max_health
	var sleep_weight: int = 0 if poisoned else 11 + int(sees_conspecifics) * 11 + int(injured) * 11
	var wander_weight: int = 33
	var follow_weight: int = 33
	var urinate_weight: int = 1 if entity.category == CreatureData.CreatureCategory.HUMANOID and not non_conspecific_visible else 0
	var choice: int = randi() % (wander_weight + follow_weight + sleep_weight + urinate_weight)
	if choice < wander_weight:
		return "wander"
	if choice < wander_weight + follow_weight:
		return "follow"
	if choice < wander_weight + follow_weight + sleep_weight:
		return "sleep"
	entity.behavior_turns_left = randi_range(3, 5)
	return "urinate"

func _visible_creature_group(entity: Creature) -> Array[Creature]:
	var result: Array[Creature] = []
	var entity_visible_tiles: Dictionary = entity.visible_tiles
	for visible_position: Vector2i in entity_visible_tiles.keys():
		if visible_position == player_pos or not creature.has(visible_position) or visible_position == entity.pos:
			continue
		if can_swim(entity) and not _is_water_tile(grid[visible_position]):
			continue
		var visible_creature: Creature = creature[visible_position]
		if visible_creature.health <= 0 or StatusData.has_status(visible_creature, "Invisible"): 
			continue
		result.append(visible_creature)
	return result

func _act_unaware_creature(entity: Creature) -> int:
	var escape_delay: int = _burning_escape_action(entity)
	if escape_delay >= 0:
		return escape_delay
	if entity.has_trait("Thief") and entity.stolen_item != null:
		return _act_thief_flee(entity)
	var visible_creatures: Array[Creature] = _visible_creature_group(entity)
	var conspecifics: Array[Creature] = []
	var non_conspecific_visible: bool = false
	for visible_creature: Creature in visible_creatures:
		if visible_creature.glyph == entity.glyph:
			conspecifics.append(visible_creature)
			entity.last_seen_conspecific_pos = visible_creature.pos
		else:
			non_conspecific_visible = true
	var behavior: String = entity.behavior_mode
	if behavior == "urinate" and entity.behavior_turns_left <= 0:
		behavior = ""
		entity.behavior_mode = ""
	if behavior == "":
		behavior = _roll_unaware_behavior(entity, conspecifics, non_conspecific_visible)
		entity.behavior_mode = behavior
		entity.alternating_behavior = (entity.alternating_behavior + 1) % 3
	if behavior == "sleep":
		if StatusData.has_status(entity, "Poisoned"):
			entity.behavior_mode = "wander"
			behavior = "wander"
		else:
			var sleep_duration: int = randi_range(60, 120)
			StatusData.apply_status(entity, "Sleeping", sleep_duration)
			StatusData.apply_status(entity, "Helpless", sleep_duration)
			entity.sleeping_regen = true
			return _move_creature(entity, Vector2i.ZERO)
	if StatusData.has_status(entity, "Sleeping"):
		StatusData.remove_status(entity, "Sleeping")
		StatusData.remove_status(entity, "Helpless")
		entity.sleeping_regen = false
	if behavior == "urinate":
		entity.behavior_turns_left -= 1
		if grid[entity.pos].terrain_name == "cave floor":
			grid[entity.pos] = TerrainData.get_terrain(TerrainData.TileType.PUDDLE)
			grid[entity.pos].timer = 4000
		if int(entity.behavior_turns_left) <= 0:
			entity.behavior_mode = ""
		return _move_creature(entity, Vector2i.ZERO)
	if behavior == "follow":
		var follow_target: Vector2i = entity.last_seen_conspecific_pos if entity.last_seen_conspecific_pos != Vector2i(-1, -1) else entity.spawn_position
		if not conspecifics.is_empty():
			conspecifics.sort_custom(func(first: Creature, second: Creature) -> bool:
				return entity.pos.distance_squared_to(first.pos) < entity.pos.distance_squared_to(second.pos)
			)
			follow_target = conspecifics[0].pos
		else:
			var spawn_position: Vector2i = entity.spawn_position
			if follow_target == spawn_position:
				follow_target = spawn_position
		if follow_target == entity.pos or not _creature_can_reach_any_known_tile(entity, follow_target):
			entity.behavior_mode = ""
			return _move_creature(entity, Vector2i.ZERO)
		return _creature_move_toward(entity, follow_target)
	if behavior == "wander":
		var reachable_known_points: Array[Vector2i] = []
		var sight_limit: int = entity.sight_range * 2
		for candidate_position: Vector2i in floor_tiles:
			if candidate_position != entity.pos and entity.pos.distance_squared_to(candidate_position) <= sight_limit * sight_limit and not creature.has(candidate_position) and _creature_can_reach_any_known_tile(entity, candidate_position):
				reachable_known_points.append(candidate_position)
		var spawn_position: Vector2i = entity.spawn_position
		if spawn_position != entity.pos and entity.pos.distance_squared_to(spawn_position) <= sight_limit * sight_limit and not creature.has(spawn_position) and _creature_can_reach_any_known_tile(entity, spawn_position):
			reachable_known_points.append(spawn_position)
		if not reachable_known_points.is_empty():
			var destination: Vector2i = reachable_known_points.pick_random()
			return _creature_move_toward(entity, destination)
		return _move_creature(entity, Vector2i.ZERO)
	return _move_creature(entity, Vector2i.ZERO)

func _breath_line_is_clear(start: Vector2i, finish: Vector2i) -> bool:
	var line: Array[Vector2i] = _bresenham_line(start, finish)
	for line_index: int in range(1, line.size() - 1):
		var tile: TerrainData.Terrain = grid[line[line_index]]
		if tile.occluding or _environment_blocks_vision(line[line_index]):
			return false
	return true

func _act_creature_special_trait(entity: Creature) -> int:
	if StatusData.has_status(_player_entity, "Invisible") or not _creature_player_visible(entity):
		return -1
	var distance: float = entity.pos.distance_to(player_pos)
	var next_ready_time: float = entity.ability_ready_at
	if distance > 1.5 and distance <= 6.0 and entity.time >= next_ready_time and _breath_line_is_clear(entity.pos, player_pos):
		var breath_type: String = ""
		if entity.has_trait("Fire Breath"):
			breath_type = "fire"
		elif entity.has_trait("Cold Breath"):
			breath_type = "cold"
		if breath_type:
			var breath_damage: int = 5
			var breath_positions: Array[Vector2i] = _bresenham_line(entity.pos, player_pos)
			for breath_position: Vector2i in breath_positions.slice(1):
				var breath_target: Creature = creature[breath_position]
				var may_hit_creature: bool = breath_target and breath_target is PlayerCreature or _creature_can_attack_non_player_targets(entity)
				if may_hit_creature:
					var dealt_damage: int = _deal_damage(breath_target, breath_damage, breath_type)
					if dealt_damage > 0 and breath_type == "fire":
						apply_status_to_entity(breath_target, "Burning", 3)
					elif dealt_damage > 0:
						apply_status_to_entity(breath_target, "Frozen", 2)
				elif breath_target:
					break
				elif breath_type == "fire" and not breath_target:
					_ignite_flammable_tile(breath_position)
					set_environment_effect(breath_position, "fire", 3)
				if may_hit_creature and breath_target.health <= 0:
					_remove_defeated_creature(breath_target)
			entity.ability_ready_at = float(entity.time) + 100.0
			return _adjust_delay(entity, entity.attack_speed)
	var blink_delay: int = _try_creature_blink(entity, false)
	if blink_delay >= 0:
		return blink_delay
	return -1

func _try_creature_blink(entity: Creature, force_flee: bool = false) -> int:
	var distance: float = entity.pos.distance_to(player_pos)
	if not entity.has_trait("Blinking") or distance > 1.5 or (not force_flee and not _creature_player_visible(entity)):
		return -1
	if not force_flee and randi_range(1, 3) != 1:
		return -1
	var candidates: Array[Vector2i] = []
	for offset_y: int in range(-4, 5):
		for offset_x: int in range(-4, 5):
			var candidate: Vector2i = entity.pos + Vector2i(offset_x, offset_y)
			if candidate.x < 0 or candidate.x >= MAP_W or candidate.y < 0 or candidate.y >= MAP_H or candidate.distance_squared_to(entity.pos) > 16:
				continue
			if creature.has(candidate) or not _creature_can_reach_any_known_tile(entity, candidate):
				continue
			if force_flee and candidate.distance_squared_to(player_pos) <= 2:
				continue
			if _is_hazardous_for_creature(entity, grid[candidate]):
				continue
			candidates.append(candidate)
	if candidates.is_empty():
		return -1
	var old_position: Vector2i = entity.pos
	var blink_position: Vector2i = candidates.pick_random()
	creature.erase(old_position)
	entity.pos = blink_position
	creature[blink_position] = entity
	entity.awareness_mode = "aware"
	_append_message("%s blinks from place to place." % _creature_dp(entity, true).capitalize())
	return _adjust_delay(entity, entity.move_speed)

func _act_flitting_randomly(entity: Creature) -> int:
	var available_moves: Array[Vector2i] = _available_creature_directions(entity, Vector2i.ZERO)
	var can_attack_allies: bool = _creature_can_attack_non_player_targets(entity)
	var adjacent_targets: Array[Creature] = []
	for direction: Vector2i in StatusData.ADJACENT_DIRECTIONS:
		if _can_creature_attack_direction(entity, direction):
			var target_position: Vector2i = entity.pos + direction
			var target: Creature = creature.get(target_position, null)
			if target != null and not StatusData.has_status(target, "Invisible") and (target is PlayerCreature or can_attack_allies):
				adjacent_targets.append(target)
	if not available_moves.is_empty():
		return _move_creature(entity, available_moves.pick_random())
	if not adjacent_targets.is_empty():
		return _creature_attack(entity, adjacent_targets.pick_random())
	return _move_creature(entity, Vector2i.ZERO)

func _phantom_blade_summon_position(shaman: Creature, visible_positions: Dictionary) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for position: Vector2i in visible_positions.keys():
		if creature.has(position) or item.has(position):
			continue
		if _is_altar_tile(grid[position]) or _is_stairs_tile(grid[position]):
			continue
		var tile: TerrainData.Terrain = grid[position]
		if not tile.passable:
			continue
		candidates.append(position)
	if candidates.is_empty():
		return Vector2i(-1, -1)
	candidates.sort_custom(func(first_position: Vector2i, second_position: Vector2i) -> bool:
		var first_player_distance: int = first_position.distance_squared_to(player_pos)
		var second_player_distance: int = second_position.distance_squared_to(player_pos)
		if first_player_distance != second_player_distance:
			return first_player_distance < second_player_distance
		return first_position.distance_squared_to(shaman.pos) < second_position.distance_squared_to(shaman.pos)
	)
	return candidates[0]

func _summon_phantom_blade(shaman: Creature, visible_positions: Dictionary, shaman_time: float) -> bool:
	var phantom_definition: Dictionary = {}
	for definition: Dictionary in CreatureData.creatures:
		if definition.name == "phantom blade":
			phantom_definition = definition
			break
	if phantom_definition.is_empty():
		return false
	var summon_position: Vector2i = _phantom_blade_summon_position(shaman, visible_positions)
	if summon_position == Vector2i(-1, -1):
		return false
	var summoned_blade: EnemyCreature = _create_creature_at_position(phantom_definition, summon_position, shaman_time, true)
	if summoned_blade == null:
		return false
	if _is_active_map and (_is_observed_by_player(shaman) or _is_observed_by_player(summoned_blade)):
		_append_message("The goblin shaman conjures a phantom blade!")
	return true

func _act_goblin_shaman_heal(entity: Creature) -> int:
	if entity.creature_name != "goblin shaman":
		return -1
	var shaman_time: float = entity.time
	if shaman_time < entity.ability_ready_at:
		return -1
	var shaman_visible_positions: Dictionary = _compute_fov(entity)
	entity.visible_tiles = shaman_visible_positions
	var injured_goblins: Array[Creature] = []
	var seeking_goblins: Array[Creature] = []
	var has_nearby_goblin: bool = false
	for visible_position: Vector2i in shaman_visible_positions.keys():
		if not creature.has(visible_position):
			continue
		var candidate: Creature = creature[visible_position]
		if candidate == entity or candidate.health <= 0 or candidate.glyph != entity.glyph:
			continue
		if StatusData.has_status(candidate, "Invisible") or not _creature_can_see_creature(entity, candidate):
			continue
		has_nearby_goblin = true
		if candidate.health < candidate.max_health:
			injured_goblins.append(candidate)
		elif candidate.awareness_mode in ["aware", "alerted", "searching"]:
			seeking_goblins.append(candidate)
	var spell_target: Creature
	if not injured_goblins.is_empty():
		injured_goblins.sort_custom(func(first: Creature, second: Creature) -> bool:
			var first_missing_health: int = first.max_health - first.health
			var second_missing_health: int = second.max_health - second.health
			if first_missing_health != second_missing_health:
				return first_missing_health > second_missing_health
			return entity.pos.distance_squared_to(first.pos) < entity.pos.distance_squared_to(second.pos)
		)
		spell_target = injured_goblins[0]
	elif not seeking_goblins.is_empty():
		seeking_goblins.sort_custom(func(first: Creature, second: Creature) -> bool:
			return first.pos.distance_squared_to(player_pos) > second.pos.distance_squared_to(player_pos)
		)
		spell_target = seeking_goblins[0]
	if not spell_target and not has_nearby_goblin:
		if not _creature_player_visible(entity):
			return -1
		if not _summon_phantom_blade(entity, shaman_visible_positions, shaman_time):
			return -1
		entity.ability_ready_at = shaman_time + 400.0
		return _adjust_delay(entity, entity.attack_speed)
	if not spell_target:
		return -1
	spell_target.health = mini(spell_target.max_health, spell_target.health + 2)
	apply_status_to_entity(spell_target, "Quickened", 4)
	entity.ability_ready_at = shaman_time + 400.0
	if _is_active_map and (_is_observed_by_player(entity) or _is_observed_by_player(spell_target)):
		_append_message("%s heals %s." % [_creature_dp(entity, true).capitalize(), _creature_dp(spell_target, true)])
	return _adjust_delay(entity, entity.attack_speed)

func _act_creature_random(entity: Creature) -> int:
	var ai_context: Dictionary = {"ai_mode": "normal"}
	StatusData.trigger(entity, StatusData.EffectType.AI_BEHAVIOR, ai_context)
	if _entity_is_paralyzed(entity):
		return _move_creature(entity, Vector2i.ZERO)
	if entity.has_trait("Mindless"):
		for mindless_direction: Vector2i in StatusData.ADJACENT_DIRECTIONS:
			if not _can_creature_attack_direction(entity, mindless_direction):
				continue
			var mindless_target: Creature = creature.get(entity.pos + mindless_direction, null)
			if mindless_target != null and mindless_target.health > 0 and not StatusData.has_status(mindless_target, "Invisible") and (mindless_target is PlayerCreature or _creature_can_attack_non_player_targets(entity)):
				return _creature_attack(entity, mindless_target)
	var burning_escape_delay: int = _burning_escape_action(entity)
	if burning_escape_delay >= 0:
		return burning_escape_delay
	if entity.has_trait("Thief") and entity.stolen_item != null:
		return _act_thief_flee(entity)
	var shaman_spell_delay: int = _act_goblin_shaman_heal(entity)
	if shaman_spell_delay >= 0:
		return shaman_spell_delay
	if _should_creature_flit(entity):
		return _act_flitting_randomly(entity)
	var special_trait_delay: int = _act_creature_special_trait(entity)
	if special_trait_delay >= 0:
		return special_trait_delay
	var hazard_escape_delay: int = _hazard_escape_action(entity)
	if hazard_escape_delay >= 0:
		return hazard_escape_delay
	var directions: Array[Vector2i] = StatusData.ADJACENT_DIRECTIONS.duplicate()
	directions.shuffle()
	var is_confused: bool = StatusData.has_status(entity, "Confused")
	if not entity is PlayerCreature:
		if str(ai_context.get("ai_mode", "normal")) == "normal":
			var basic_ai_delay: int = _act_creature_awareness(entity)
			if basic_ai_delay >= 0:
				return basic_ai_delay
			if entity.awareness_mode == "unaware":
				return _act_unaware_creature(entity)
		elif str(ai_context.get("ai_mode", "normal")) == "seek_nearest":
			entity.awareness_mode = "aware"
		elif str(ai_context.get("ai_mode", "normal")) == "flee":
			entity.awareness_mode = "aware"

	if is_confused and (ai_context.ai_mode == "normal" or ai_context.ai_mode == "seek_nearest"):
		var intended_direction: Vector2i = Vector2i.ZERO
		for direction: Vector2i in directions:
			if _can_creature_attack_direction(entity, direction) and creature.has(entity.pos + direction) and not StatusData.has_status(creature[entity.pos + direction], "Invisible"):
				intended_direction = direction
				break
		if intended_direction == Vector2i.ZERO and ai_context.ai_mode == "seek_nearest":
			var enraged_target: Creature = _nearest_creature_target(entity)
			if enraged_target:
				intended_direction = Vector2i(signi(enraged_target.pos.x - entity.pos.x), signi(enraged_target.pos.y - entity.pos.y))
		if intended_direction == Vector2i.ZERO:
			var possible_directions: Array[Vector2i] = _available_creature_directions(entity, Vector2i.ZERO)
			if possible_directions.is_empty():
				return _move_creature(entity, Vector2i.ZERO)
			intended_direction = possible_directions.pick_random()
		return _confused_creature_action(entity, intended_direction)

	if not entity is PlayerCreature and ai_context.ai_mode == "flee":
		if entity.has_trait("Blinking"):
			var blink_delay: int = _try_creature_blink(entity, true)
			if blink_delay >= 0:
				return blink_delay
		var fleeing_target: Creature = _player_entity
		var player_direction: Vector2i = Vector2i(signi(fleeing_target.pos.x - entity.pos.x), signi(fleeing_target.pos.y - entity.pos.y))
		var all_flee_directions: Array[Vector2i] = _available_creature_directions(entity, Vector2i(-player_direction.x, -player_direction.y))
		if is_confused:
			return _confused_creature_action(entity, Vector2i(-player_direction.x, -player_direction.y))
		var flee_directions: Array[Vector2i] = []
		for flee_direction: Vector2i in all_flee_directions:
			if (entity.pos + flee_direction).distance_squared_to(player_pos) > entity.pos.distance_squared_to(player_pos):
				flee_directions.append(flee_direction)
		if not flee_directions.is_empty():
			flee_directions.sort_custom(func(first: Vector2i, second: Vector2i) -> bool:
				return (entity.pos + first).distance_squared_to(_player_entity.pos) > (entity.pos + second).distance_squared_to(_player_entity.pos)
			)
			return _move_creature(entity, flee_directions[0])
		for blocked_direction: Vector2i in StatusData.ADJACENT_DIRECTIONS:
			var blocked_position: Vector2i = entity.pos + blocked_direction
			var blocked_creature: Creature = creature.get(blocked_position, null)
			if blocked_creature != null and _is_frightened_creature_blocking_only_escape(entity, blocked_creature):
				return _creature_attack(entity, blocked_creature)
		return _move_creature(entity, Vector2i.ZERO)

	if not entity is PlayerCreature and ai_context.ai_mode == "seek_nearest":
		var enraged_target: Creature = _nearest_creature_target(entity)
		if enraged_target:
			var toward_target: Vector2i = Vector2i(signi(enraged_target.pos.x - entity.pos.x), signi(enraged_target.pos.y - entity.pos.y))
			if is_confused:
				return _confused_creature_action(entity, toward_target)
			if _can_creature_attack_direction(entity, toward_target) and creature.has(entity.pos + toward_target):
				return _creature_attack(entity, creature[entity.pos + toward_target])
			var approach_directions: Array[Vector2i] = _available_creature_directions(entity, toward_target)
			if not approach_directions.is_empty():
				return _move_creature(entity, approach_directions[0])
			return _move_creature(entity, Vector2i.ZERO)

	# In normal behavior, creatures attack an adjacent non-invisible target if
	# present, otherwise they choose a random unoccupied walkable direction.
	for direction: Vector2i in directions:
		var target_position: Vector2i = entity.pos + direction
		if not _can_creature_attack_direction(entity, direction) or not creature.has(target_position):
			continue
		var defender: Creature = creature[target_position]
		if StatusData.has_status(defender, "Invisible"):
			continue
		if not defender is PlayerCreature and not _creature_can_attack_non_player_targets(entity) and not _is_frightened_creature_blocking_only_escape(entity, defender):
			continue
		if is_confused:
			return _confused_creature_action(entity, direction)
		return _creature_attack(entity, defender)

	var available: Array[Vector2i] = _available_creature_directions(entity, Vector2i.ZERO)
	if is_confused:
		return _confused_creature_action(entity, available.pick_random()) if not available.is_empty() else _move_creature(entity, Vector2i.ZERO)
	return _move_creature(entity, available.pick_random()) if not available.is_empty() else _move_creature(entity, Vector2i.ZERO)

func _nearest_creature_target(entity: Creature) -> Creature:
	var best_target: Creature = null
	var best_distance: int = 2147483647
	var can_attack_allies: bool = _creature_can_attack_non_player_targets(entity)
	for candidate: Creature in creature.values():
		if candidate == entity or candidate.health <= 0 or StatusData.has_status(candidate, "Invisible"):
			continue
		if not candidate is PlayerCreature and not can_attack_allies:
			continue
		if can_swim(entity) and not _is_water_tile(grid[candidate.pos]):
			continue
		var entity_visible_tiles: Dictionary = entity.visible_tiles
		if not entity_visible_tiles.has(candidate.pos):
			continue
		var distance: int = entity.pos.distance_squared_to(candidate.pos)
		if distance < best_distance:
			best_distance = distance
			best_target = candidate
	return best_target

func _creature_can_attack_non_player_targets(entity: Creature) -> bool:
	return StatusData.has_status(entity, "Enraged") or StatusData.has_status(entity, "Confused")

func _is_frightened_creature_blocking_only_escape(entity: Creature, defender: Creature) -> bool:
	if not StatusData.has_status(entity, "Frightened") or defender is PlayerCreature:
		return false
	var current_distance: int = entity.pos.distance_squared_to(player_pos)
	var defender_position: Vector2i = defender.pos
	if defender_position.distance_squared_to(player_pos) <= current_distance:
		return false
	var escape_destinations: Array[Vector2i] = []
	for direction: Vector2i in StatusData.ADJACENT_DIRECTIONS:
		var destination: Vector2i = entity.pos + direction
		if destination.distance_squared_to(player_pos) <= current_distance:
			continue
		var occupying_creature: Creature = creature.get(destination, null)
		if occupying_creature != null:
			creature.erase(destination)
		var is_valid_escape: bool = _is_valid_creature_move(entity, direction)
		if occupying_creature:
			creature[destination] = occupying_creature
		if is_valid_escape or destination == defender_position:
			escape_destinations.append(destination)
	return escape_destinations.size() == 1 and escape_destinations[0] == defender_position and creature.get(defender_position, {}) == defender

func _can_creature_attack_direction(entity: Creature, direction: Vector2i) -> bool:
	if direction == Vector2i.ZERO:
		return false
	var target: Vector2i = entity.pos + direction
	if target.x < 0 or target.x >= MAP_W or target.y < 0 or target.y >= MAP_H:
		return false
	var target_tile: TerrainData.Terrain = grid[target]
	var target_passable: bool = target_tile.passable or ((entity.has_trait("Flying") or can_swim(entity)) and target_tile.terrain_name == "deep lake")
	if not target_passable:
		return false
	if not creature.has(target):
		return false
	if direction.x != 0 and direction.y != 0:
		return false
	return true

func _confused_creature_action(entity: Creature, intended: Vector2i) -> int:
	var available: Array[Vector2i] = []
	var poison_pool_directions: Array[Vector2i] = []
	for direction: Vector2i in StatusData.ADJACENT_DIRECTIONS:
		if _is_valid_creature_move(entity, direction):
			if _creature_avoids_poison_pool(entity) and grid[entity.pos + direction].terrain_name == "glowing pool":
				poison_pool_directions.append(direction)
			else:
				available.append(direction)
			continue
		var target_position: Vector2i = entity.pos + direction
		if _can_creature_attack_direction(entity, direction) and creature.has(target_position) and not StatusData.has_status(creature[target_position], "Invisible"):
			available.append(direction)
	if available.is_empty():
		available = poison_pool_directions
	if available.is_empty():
		return _move_creature(entity, Vector2i.ZERO)
	for direction: Vector2i in [Vector2i(intended.x - intended.y, intended.y + intended.x), intended, Vector2i(intended.x + intended.y, intended.y - intended.x)]:
		var target: Vector2i = entity.pos + direction
		if _can_creature_attack_direction(entity, direction) and creature.has(target) and not StatusData.has_status(creature[target], "Invisible") and not available.has(direction):
			available.append(direction)
	if available.is_empty():
		return _move_creature(entity, Vector2i.ZERO)
	available.shuffle()
	var intended_available: Array[Vector2i] = []
	for direction: Vector2i in [Vector2i(intended.x - intended.y, intended.y + intended.x), intended, Vector2i(intended.x + intended.y, intended.y - intended.x)]:
		if available.has(direction):
			intended_available.append(direction)
	var context: Dictionary = {"direction": intended, "available_directions": intended_available if not intended_available.is_empty() else available}
	StatusData.trigger(entity, StatusData.EffectType.DIRECTION, context)
	var selected: Vector2i = context.get("direction", available.pick_random())
	var destination: Vector2i = entity.pos + selected
	if creature.has(destination):
		return _creature_attack(entity, creature[destination])
	return _move_creature(entity, selected)

func _is_hazardous_for_creature(entity: Creature, tile: TerrainData.Terrain) -> bool:
	if tile.terrain_name == "lava":
		return not (entity.has_trait("Flying") and entity.has_named_immunity("fire"))
	if tile.terrain_name == "steam geyser":
		return true
	if tile.terrain_name != "deep lake" or entity.has_trait("Flying") or can_swim(entity):
		return false
	return entity.category != CreatureData.CreatureCategory.UNHOLY

func _safe_creature_escape_directions(entity: Creature) -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	for direction: Vector2i in StatusData.ADJACENT_DIRECTIONS:
		var target: Vector2i = entity.pos + direction
		if _is_hazardous_for_creature(entity, grid[target]):
			continue
		if _is_valid_creature_move(entity, direction, true):
			directions.append(direction)
	return directions

func _has_safe_creature_move(entity: Creature) -> bool:
	return not _safe_creature_escape_directions(entity).is_empty()

func _hazard_escape_action(entity: Creature) -> int:
	if entity is PlayerCreature or not _is_hazardous_for_creature(entity, grid[entity.pos]):
		return -1
	var safe_directions: Array[Vector2i] = _safe_creature_escape_directions(entity)
	if not safe_directions.is_empty():
		return _move_creature(entity, safe_directions.pick_random())
	var hazardous_directions: Array[Vector2i] = []
	for direction: Vector2i in StatusData.ADJACENT_DIRECTIONS:
		if _is_valid_creature_move(entity, direction, true):
			hazardous_directions.append(direction)
	if not hazardous_directions.is_empty():
		return _move_creature(entity, hazardous_directions.pick_random())
	return _move_creature(entity, Vector2i.ZERO)

func _is_valid_creature_move(entity: Creature, direction: Vector2i, allow_hazardous_destination: bool = false) -> bool:
	if direction == Vector2i.ZERO:
		return false
	var origin: Vector2i = entity.pos
	var target: Vector2i = origin + direction
	if target.x < 0 or target.x >= MAP_W or target.y < 0 or target.y >= MAP_H:
		return false
	var target_tile: TerrainData.Terrain = grid[target]
	var origin_is_hazardous: bool = _is_hazardous_for_creature(entity, grid[origin])
	var flying: bool = entity.has_trait("Flying")
	var aquatic: bool = can_swim(entity)
	if aquatic and _is_water_tile(target_tile):
		pass
	elif aquatic:
		return false
	elif flying and target_tile.terrain_name == "deep lake":
		pass
	elif flying and target_tile.terrain_name == "lava" and entity.has_named_immunity("fire"):
		pass
	elif _is_hazardous_for_creature(entity, target_tile):
		if not allow_hazardous_destination and (not origin_is_hazardous or _has_safe_creature_move(entity)):
			return false
	elif not target_tile.passable:
		return false
	if _is_stairs_tile(target_tile) or _creature_at(target):
		return false
	var horizontal_tile: TerrainData.Terrain = grid[origin + Vector2i(direction.x, 0)]
	var vertical_tile: TerrainData.Terrain = grid[origin + Vector2i(0, direction.y)]
	var flying_can_cross_lava: bool = flying and entity.has_named_immunity("fire")
	var horizontal_passable: bool = horizontal_tile.passable or (_is_hazardous_for_creature(entity, horizontal_tile) and (origin_is_hazardous or allow_hazardous_destination)) or (flying and horizontal_tile.terrain_name == "deep lake") or (flying_can_cross_lava and horizontal_tile.terrain_name == "lava") or (aquatic and _is_water_tile(horizontal_tile))
	var vertical_passable: bool = vertical_tile.passable or (_is_hazardous_for_creature(entity, vertical_tile) and (origin_is_hazardous or allow_hazardous_destination)) or (flying and vertical_tile.terrain_name == "deep lake") or (flying_can_cross_lava and vertical_tile.terrain_name == "lava") or (aquatic and _is_water_tile(vertical_tile))
	if direction.x != 0 and direction.y != 0 and not horizontal_passable and not vertical_passable:
		return false
	return true

func _creature_attack(attacker: Creature, defender: Creature) -> int:
	var attacker_position: Vector2i = attacker.pos
	var defender_position: Vector2i = defender.pos
	if not _is_orthogonally_adjacent(attacker_position, defender_position):
		return _adjust_delay(attacker, attacker.move_speed)
	if not attacker is PlayerCreature and not defender is PlayerCreature and not _creature_can_attack_non_player_targets(attacker) and not _is_frightened_creature_blocking_only_escape(attacker, defender):
		return _adjust_delay(attacker, attacker.move_speed)
	_snapshot_visible_state()
	_apply_action_statuses(attacker, "attack")
	var attack_delay: int = _adjust_delay(attacker, attacker.attack_speed)
	_resolve_attack(attacker, defender)
	_remove_defeated_creature(defender)
	return attack_delay

func _has_safe_player_move() -> bool:
	for direction: Vector2i in StatusData.ADJACENT_DIRECTIONS:
		var destination: Vector2i = player_pos + direction
		if creature.has(destination):
			continue
		var destination_tile: TerrainData.Terrain = grid[destination]
		if _is_hazardous_for_creature(_player_entity, destination_tile) or not destination_tile.passable:
			continue
		if direction.x != 0 and direction.y != 0:
			var horizontal: TerrainData.Terrain = grid[player_pos + Vector2i(direction.x, 0)]
			var vertical: TerrainData.Terrain = grid[player_pos + Vector2i(0, direction.y)]
			if not horizontal.passable and not vertical.passable:
				continue
		return true
	return false

func _available_player_directions(intended: Vector2i, allow_attacks: bool = false) -> Array[Vector2i]:
	var available: Array[Vector2i] = []
	var intended_index: int = StatusData.ADJACENT_DIRECTIONS.find(intended)
	var candidate_directions: Array[Vector2i] = []
	if intended_index >= 0:
		for offset: int in [-1, 0, 1]:
			candidate_directions.append(StatusData.ADJACENT_DIRECTIONS[posmod(intended_index + offset, StatusData.ADJACENT_DIRECTIONS.size())])
	else:
		candidate_directions = StatusData.ADJACENT_DIRECTIONS.duplicate()
	for direction: Vector2i in candidate_directions:
		var target: Vector2i = player_pos + direction
		if target.x < 0 or target.x >= MAP_W or target.y < 0 or target.y >= MAP_H:
			continue
		var target_tile: TerrainData.Terrain = grid[target]
		var origin_tile: TerrainData.Terrain = grid[player_pos]
		if _is_hazardous_for_creature(_player_entity, target_tile):
			if _has_safe_player_move():
				continue
		elif not target_tile.passable:
			continue
		if direction.x != 0 and direction.y != 0:
			var horizontal_tile: TerrainData.Terrain = grid[player_pos + Vector2i(direction.x, 0)]
			var vertical_tile: TerrainData.Terrain = grid[player_pos + Vector2i(0, direction.y)]
			var origin_is_hazardous: bool = _is_hazardous_for_creature(_player_entity, origin_tile)
			var horizontal_passable: bool = horizontal_tile.passable or (origin_is_hazardous and _is_hazardous_for_creature(_player_entity, horizontal_tile))
			var vertical_passable: bool = vertical_tile.passable or (origin_is_hazardous and _is_hazardous_for_creature(_player_entity, vertical_tile))
			if not horizontal_passable and not vertical_passable:
				continue
		if _creature_at(target):
			if not allow_attacks or (direction.x != 0 and direction.y != 0 and not _player_has_reach()):
				continue
		if not available.has(direction):
			available.append(direction)
	return available

func _available_creature_directions(entity: Creature, _intended: Vector2i) -> Array[Vector2i]:
	var candidate_directions: Array[Vector2i] = StatusData.ADJACENT_DIRECTIONS.duplicate()
	var safe_directions: Array[Vector2i] = []
	var glowing_pool_directions: Array[Vector2i] = []
	var fire_directions: Array[Vector2i] = []
	var fire_glowing_pool_directions: Array[Vector2i] = []
	var avoids_poison_pools: bool = _creature_avoids_poison_pool(entity)
	var avoids_fire: bool = _has_active_fire() and not entity.has_named_immunity("fire") and _creature_path_should_account_for_fire(entity, entity.last_seen_player_pos)
	for direction: Vector2i in candidate_directions:
		if not _is_valid_creature_move(entity, direction):
			continue
		var destination: Vector2i = entity.pos + direction
		var fire_cost: float = _creature_fire_path_cost(entity, _active_fire_concentration(destination), false) if avoids_fire else 0.0
		if fire_cost < 0.0:
			continue
		var is_glowing_pool: bool = grid[destination].terrain_name == "glowing pool" and avoids_poison_pools
		if fire_cost > 0.0:
			if is_glowing_pool:
				fire_glowing_pool_directions.append(direction)
			else:
				fire_directions.append(direction)
		elif is_glowing_pool:
			glowing_pool_directions.append(direction)
		else:
			safe_directions.append(direction)
	if not safe_directions.is_empty():
		return safe_directions
	if not glowing_pool_directions.is_empty():
		return glowing_pool_directions
	if not fire_directions.is_empty():
		return fire_directions
	return fire_glowing_pool_directions

func _move_creature(entity: Creature, direction: Vector2i) -> int:
	var move_cost: int = entity.move_speed
	if _entity_is_paralyzed(entity):
		_apply_action_statuses(entity, "wait")
		return _adjust_delay(entity, move_cost)
	if direction == Vector2i.ZERO:
		_apply_action_statuses(entity, "wait")
		return _adjust_delay(entity, move_cost)
	if not _is_valid_creature_move(entity, direction):
		var entity_position: Vector2i = entity.pos
		move_cost = _movement_delay_for_destination(move_cost, entity_position, false, entity)
		return _adjust_delay(entity, move_cost)
	var target: Vector2i = entity.pos + direction
	var is_diagonal: bool = direction.x != 0 and direction.y != 0
	move_cost = _movement_delay_for_destination(move_cost, target, is_diagonal, entity)
	_apply_action_statuses(entity, "move")
	move_cost = _adjust_delay(entity, move_cost)
	var vacated_position: Vector2i = entity.pos
	creature.erase(vacated_position)
	creature[target] = entity
	entity.pos = target
	_activate_altar_at(vacated_position)
	_apply_water_wetness(entity, target)
	if entity.has_trait("Flying") and _is_water_tile(grid[target]):
		StatusData.remove_status(entity, "Wet")
	if StatusData.has_status(entity, "Burning"):
		_ignite_flammable_tile(target)
	return move_cost

func _record_player_weapon_attack() -> void:
	if PlayerData.equipped_weapon < 0 or PlayerData.equipped_weapon >= PlayerData.inventory.size():
		return
	PlayerData.inventory[PlayerData.equipped_weapon].record_identification_progress(1, 50)

func _record_player_armor_attack() -> void:
	if PlayerData.equipped_armor < 0 or PlayerData.equipped_armor >= PlayerData.inventory.size():
		return
	PlayerData.inventory[PlayerData.equipped_armor].record_identification_progress(20, 4000)

func _player_weapon_ego_bonus(ego_name: String) -> int:
	if not _player_entity or PlayerData.equipped_weapon < 0 or PlayerData.equipped_weapon >= PlayerData.inventory.size() or not creature.has(player_pos) or creature[player_pos] != _player_entity:
		return 0
	return PlayerData.equipped_weapon_ego_bonus(ego_name)

func _player_weapon_ego_name() -> String:
	if PlayerData.equipped_weapon < 0 or PlayerData.equipped_weapon >= PlayerData.inventory.size():
		return ""
	var weapon: Weapon = PlayerData.inventory[PlayerData.equipped_weapon]
	return weapon.ego

func _identify_weapon_ego_if_effective(weapon: Weapon, ego_name: String, ego_level: int, applied_damage: int = 0) -> void:
	if ego_name in ["cleaving", "piercing", "lunging"]:
		return
	var effect_size: int = 0
	match ego_name:
		"precision":
			effect_size = 5 * ego_level if ego_level > 0 else 0
		"speed":
			effect_size = ego_level if ego_level > 0 else 0
		"penetration":
			effect_size = mini(ego_level, maxi(0, applied_damage))
		"draining", "force":
			effect_size = mini(maxi(0, applied_damage), floori(ego_level / 2.0))
		"fire", "frost":
			effect_size = ego_level if applied_damage > 0 else 0
		"stunning":
			effect_size = 5 * ego_level
		"quietus":
			effect_size = applied_damage if ego_level > 0 else 0
	if effect_size > 0:
		weapon.identify_partially()

func _act_thief_flee(thief: Creature) -> int:
	var blink_delay: int = _try_creature_blink(thief, true)
	if blink_delay >= 0:
		return blink_delay
	var flee_directions: Array[Vector2i] = _available_creature_directions(thief, Vector2i.ZERO)
	if flee_directions.is_empty():
		return _move_creature(thief, Vector2i.ZERO)
	flee_directions.sort_custom(func(first: Vector2i, second: Vector2i) -> bool:
		return (thief.pos + first).distance_squared_to(player_pos) > (thief.pos + second).distance_squared_to(player_pos)
	)
	return _move_creature(thief, flee_directions[0])

func _thief_steal_item(thief: EnemyCreature) -> bool:
	var inventory := PlayerData.inventory
	if inventory.is_empty() or thief.stolen_item != null:
		return false
	var stolen_index: int = randi_range(0, inventory.size() - 1)
	if stolen_index == PlayerData.equipped_weapon or stolen_index == PlayerData.equipped_armor:
		return false
	var stolen_item: Item = inventory[stolen_index]
	thief.stolen_item = stolen_item
	inventory.remove_at(stolen_index)
	if PlayerData.equipped_weapon > stolen_index:
		PlayerData.equipped_weapon -= 1
	if PlayerData.equipped_armor > stolen_index:
		PlayerData.equipped_armor -= 1
	_append_message("%s steals %s!" % [_creature_dp(thief, true).capitalize(), _item_dp(stolen_item, true)])
	thief.behavior_mode = "flee"
	return true

func _push_creature_from(attacker: Creature, defender: Creature, distance: int) -> void:
	var defender_position: Vector2i = defender.pos
	var attacker_position: Vector2i = attacker.pos
	var direction: Vector2i = Vector2i(signi(defender_position.x - attacker_position.x), signi(defender_position.y - attacker_position.y))
	var steps: int = maxi(0, distance)
	for _step: int in range(steps):
		var destination: Vector2i = defender_position + direction
		if destination.x < 0 or destination.x >= MAP_W or destination.y < 0 or destination.y >= MAP_H:
			break
		if creature.has(destination) or not grid[destination].passable:
			break
		creature.erase(defender_position)
		defender.pos = destination
		creature[destination] = defender
		if StatusData.has_status(defender, "Burning"):
			_ignite_flammable_tile(destination)

func _corrode_equipped_weapon() -> void:
	var inventory := PlayerData.inventory
	var weapon_index: int = PlayerData.equipped_weapon
	if weapon_index < 0 or weapon_index >= inventory.size():
		return
	var corroded_weapon: Weapon = inventory[weapon_index]
	PlayerData._unequip_weapon(_player_entity, weapon_index)
	corroded_weapon.enchantment -= 1
	corroded_weapon.damage -= 1
	if int(corroded_weapon.damage) < 0:
		inventory.remove_at(weapon_index)
		if PlayerData.equipped_armor > weapon_index:
			PlayerData.equipped_armor -= 1
		_append_message("The corrosive slime destroys your %s." % corroded_weapon.get_item_name())
		return
	PlayerData._equip_weapon(_player_entity, weapon_index)
	_append_message("Your %s corrodes." % corroded_weapon.get_item_name())

func _corrode_equipped_armor() -> void:
	var inventory := PlayerData.inventory
	var armor_index: int = PlayerData.equipped_armor
	if armor_index < 0 or armor_index >= inventory.size():
		return
	var corroded_armor: Armor = inventory[armor_index]
	PlayerData._unequip_armor(_player_entity, armor_index)
	corroded_armor.enchantment -= 1
	corroded_armor.armor -= 1
	if int(corroded_armor.armor) < 0:
		inventory.remove_at(armor_index)
		if PlayerData.equipped_weapon > armor_index:
			PlayerData.equipped_weapon -= 1
		_append_message("The corrosive slime destroys your %s." % corroded_armor.get_item_name())
		return
	PlayerData._equip_armor(_player_entity, armor_index)
	_append_message("Your %s corrodes." % corroded_armor.get_item_name())

func _resolve_attack(attacker: Creature, defender: Creature, attack_verb: String = "", weapon_melee_attack: bool = false, allow_weapon_sweeps: bool = true, uses_projectile: Projectile = null) -> bool:
	var inventory := PlayerData.inventory
	var defender_health_before: int = defender.health
	var attacker_is_player: bool = attacker is PlayerCreature
	var defender_is_player: bool = defender is PlayerCreature
	_attack_resolution_depth += 1
	var attack_result: bool
	var uses_player_weapon: bool = weapon_melee_attack and attacker == _player_entity and _player_weapon_ego_name() != ""
	var weapon_ego: String = _player_weapon_ego_name() if uses_player_weapon else ""
	var weapon_ego_level: int = inventory[PlayerData.equipped_weapon].enchantment if uses_player_weapon and PlayerData.equipped_weapon >= 0 and PlayerData.equipped_weapon < inventory.size() else 0
	var helpless: bool = StatusData.has_status(defender, "Helpless")
	if not helpless and not attacker_is_player and StatusData.has_status(defender, "Invisible") and not StatusData.has_status(attacker, "Blind"):
		attack_result = false
	var defender_was_unaware: bool = defender is EnemyCreature and defender.awareness_mode == "unaware"
	if defender is PlayerCreature and not attacker_is_player:
		_record_player_armor_attack()
	var attacker_position: Vector2i = attacker.pos
	var attack_target_position: Vector2i = defender.pos
	var defender_can_see_attacker: bool = _creature_can_see_creature(defender, attacker)
	var surprised: bool = not defender_can_see_attacker
	if surprised and attacker_is_player and not defender is PlayerCreature:
		_make_creature_aware_of_player(defender)
	var defender_evasion: int = _creature_terrain_evasion(defender)
	if defender is PlayerCreature:
		defender_evasion += PlayerData.equipped_armor_ego_bonus("evasion")
		if PlayerData.equipped_armor_ego_bonus("evasion") > 0 and PlayerData.equipped_armor >= 0 and PlayerData.equipped_armor < inventory.size():
			inventory[PlayerData.equipped_armor].identify_partially()
	var reflection_damage: int = 0
	var retaliatory_delay: int = 0
	var worn_armor: Item
	var armor_ego_name: String = ""
	var armor_ego_level: int = 0
	if defender is PlayerCreature and PlayerData.equipped_armor >= 0 and PlayerData.equipped_armor < inventory.size():
		worn_armor = inventory[PlayerData.equipped_armor]
		armor_ego_name = worn_armor.ego
		armor_ego_level = worn_armor.enchantment
		if armor_ego_name == "reflection":
			reflection_damage = maxi(0, armor_ego_level)
		elif armor_ego_name == "stunning":
			retaliatory_delay = maxi(0, armor_ego_level * 5)
		if armor_ego_name == "evasion" and armor_ego_level > 0:
			worn_armor.identify_partially()
		elif armor_ego_name == "insulation" and armor_ego_level > 0 and (StatusData.has_status(defender, "Burning") or StatusData.has_status(defender, "Frozen")):
			worn_armor.identify_partially()
		elif armor_ego_name == "clarity" and armor_ego_level > 0 and (StatusData.has_status(defender, "Confused") or StatusData.has_status(defender, "Blind")):
			worn_armor.identify_partially()
		elif armor_ego_name == "health" and armor_ego_level > 0:
			worn_armor.identify_partially()
	var accuracy: float = 1.0 if helpless else maxf(((attacker.acc_thrown + uses_projectile.acc_mod) if uses_projectile else attacker.accuracy) * 0.01 * pow(0.933033, 0 if surprised else defender_evasion), 0.1)
	var quietus_multiplier: int = 1
	if weapon_ego == "quietus":
		if helpless and uses_player_weapon and weapon_ego_level > 0:
			quietus_multiplier = 3
		elif defender_was_unaware and uses_player_weapon and weapon_ego_level > 0:
			quietus_multiplier = 2
	var base_attack_damage: int = maxi(1, uses_projectile.damage if uses_projectile else attacker.damage) * quietus_multiplier
	if uses_player_weapon:
		_identify_weapon_ego_if_effective(inventory[PlayerData.equipped_weapon], weapon_ego, weapon_ego_level, 0)
	var attack_rolls: Array[bool] = []
	for _i: int in range(base_attack_damage):
		attack_rolls.append(helpless or randf() <= accuracy)
	var armor_penetration: int = weapon_ego_level if weapon_ego == "penetration" else 0
	var effective_defender_armor: int = maxi(0, defender.armor - armor_penetration)
	var deflection: int = 0 if helpless else mini(effective_defender_armor, base_attack_damage - 1)
	var damage: int = 0
	for roll: bool in attack_rolls.slice(deflection):
		damage += 1 if helpless else int(roll)
	if not attacker is PlayerCreature and StatusData.has_status(defender, "Invisible") and not StatusData.has_status(attacker, "Blind"): 
		attack_result = false
	var armor_deflected: bool = false
	for roll: bool in attack_rolls.slice(0, deflection):
		if roll:
			armor_deflected = true
			break
	var physical_damage: int = damage
	var elemental_damage: int = 0
	var applied_damage: int = 0
	if weapon_ego == "penetration" and uses_player_weapon and mini(maxi(0, weapon_ego_level), int(defender.get("armor"))) > 0:
		inventory[PlayerData.equipped_weapon].identify_partially()
	var physical_hit_damage: int = damage
	if damage > 0 and weapon_ego in ["fire", "frost"]:
		if weapon_ego_level > 0:
			inventory[PlayerData.equipped_weapon].identify_partially()
		elemental_damage = floori(damage / 2.0)
		physical_damage = physical_hit_damage - elemental_damage
		applied_damage += _deal_damage(defender, physical_damage, "physical")
		applied_damage += _deal_damage(defender, elemental_damage, "fire" if weapon_ego == "fire" else "cold")
	else:
		physical_damage = physical_hit_damage
		applied_damage = _deal_damage(defender, physical_damage, "physical")
	if attacker_is_player and weapon_melee_attack and defender.has_trait("Corrosive"): 
		var equipped_weapon_index: int = PlayerData.equipped_weapon
		var has_equipped_weapon: bool = equipped_weapon_index >= 0 and equipped_weapon_index < inventory.size()
		if has_equipped_weapon:
			_corrode_equipped_weapon()
		else:
			apply_status_to_entity(attacker, "Poisoned", 10)
	if armor_deflected and not attacker_is_player and defender is PlayerCreature and attacker.has_trait("Corrosive"):
		_corrode_equipped_armor()
	if applied_damage > 0 and not attacker_is_player:
		if attacker.has_trait("Thief") and defender is PlayerCreature: 
			_thief_steal_item(attacker)
		if attacker.has_trait("Venomous"):  
			apply_status_to_entity(defender, "Poisoned", 5)
		if attacker.has_trait("Paralyzing"):
			apply_status_to_entity(defender, "Paralyzed", 1)
		if attacker.has_trait("Weakening"):
			apply_status_to_entity(defender, "Weakened", 10)
	if applied_damage > 0 and attacker.has_trait("Draining"):
		var creature_heal: int = floori(float(applied_damage) / 2.0)
		_heal_entity(attacker, creature_heal)
	if applied_damage > 0 and uses_player_weapon:
		_identify_weapon_ego_if_effective(inventory[PlayerData.equipped_weapon], weapon_ego, weapon_ego_level, applied_damage)
		match weapon_ego:
			"draining":
				var healed_amount: int = mini(applied_damage, floori(float(weapon_ego_level) / 2.0))
				_heal_entity(attacker, healed_amount)
			"fire":
				apply_status_to_entity(defender, "Burning", weapon_ego_level)
			"frost":
				apply_status_to_entity(defender, "Frozen", weapon_ego_level)
			"stunning":
				defender.time = defender.time + weapon_ego_level * 5
				turn_queue.sort_custom(_sort_by_time)
			"force":
				var push_distance: int = mini(applied_damage, floori(float(weapon_ego_level) / 2.0))
				_push_creature_from(attacker, defender, push_distance)
	if applied_damage > 0 and reflection_damage > 0 and not attacker_is_player:
		var reflected_amount: int = _deal_damage(attacker, mini(applied_damage, reflection_damage), "physical")
		if reflected_amount > 0 and worn_armor:
			worn_armor.identify_partially()
	if uses_player_weapon and allow_weapon_sweeps and weapon_ego in ["cleaving", "piercing"]:
		var sweep_targets: Array[Vector2i] = []
		if weapon_ego == "cleaving":
			for sweep_direction: Vector2i in StatusData.ADJACENT_DIRECTIONS:
				var adjacent_position: Vector2i = attack_target_position + sweep_direction
				var sweep_creature: Creature = creature.get(adjacent_position, null)
				if adjacent_position != attacker_position and adjacent_position != attack_target_position and attacker_position.distance_to(adjacent_position) <= 1.5 and sweep_creature != null and not sweep_creature is PlayerCreature:
					sweep_targets.append(adjacent_position)
		elif weapon_ego == "piercing":
			var behind_position: Vector2i = attack_target_position + (attack_target_position - attacker_position)
			var behind_creature: Creature = creature.get(behind_position, {})
			if behind_creature != null and not behind_creature is PlayerCreature:
				sweep_targets.append(behind_position)
		for sweep_position: Vector2i in sweep_targets:
			if creature.has(sweep_position):
				var sweep_defender: Creature = creature[sweep_position]
				var sweep_health_before: int = sweep_defender.health
				var sweep_hit: bool = _resolve_attack(attacker, sweep_defender, "", false, false)
				if sweep_hit and sweep_health_before > sweep_defender.health:
					inventory[PlayerData.equipped_weapon].identify_partially()
				_remove_defeated_creature(sweep_defender)
	if retaliatory_delay > 0 and not attacker_is_player:
		attacker.time = attacker.time + retaliatory_delay
		turn_queue.sort_custom(_sort_by_time)
	if worn_armor and armor_ego_name in ["reflection", "stunning"] and applied_damage > 0 and maxi(reflection_damage, retaliatory_delay) > 0:
		var armor_effect_size: int = mini(applied_damage, reflection_damage) if armor_ego_name == "reflection" else retaliatory_delay
		if armor_effect_size > 0:
			worn_armor.identify_partially()
	if helpless:
		StatusData.consume_status(defender, "Helpless")
	var observed: bool = _is_observed_by_player(attacker) or _is_observed_by_player(defender)
	if observed:
		var attacker_name: String = "You" if attacker_is_player else _creature_dp(attacker, true).capitalize()
		var defender_name: String = "you" if defender is PlayerCreature else _creature_dp(defender, true)
		var verb: String = attack_verb if not attack_verb.is_empty() else _attack_verb(attacker)
		if applied_damage > 0:
			_append_message("%s %s %s for %s damage." % [attacker_name, verb, defender_name, applied_damage])
		elif armor_deflected and defender is PlayerCreature:
			_append_message("%s attacks %s, but your %s deflects the blow." % [attacker_name, defender_name, PlayerData.inventory[PlayerData.equipped_armor].get_item_name()])
		elif armor_deflected:
			_append_message("%s %s %s, but its armor deflects the blow." % [attacker_name, verb, defender_name])
		elif attacker_is_player:
			_append_message("You miss %s." % defender_name)
		else:
			_append_message("%s misses %s." % [attacker_name, defender_name])
	attack_result = damage > 0
	if attacker_is_player and not defender_is_player:
		_make_creature_aware_of_player(defender)
	_attack_resolution_depth = maxi(0, _attack_resolution_depth - 1)
	if _attack_resolution_depth == 0:
		_flush_death_messages()
	if attacker_is_player and not defender_is_player and defender.health < defender_health_before:
		_play_player_hit_sound()
	return attack_result

func _player_has_reach() -> bool:
	var weapon_index: int = PlayerData.equipped_weapon
	if weapon_index < 0 or weapon_index >= PlayerData.inventory.size():
		return false
	var equipped_weapon: Item = PlayerData.inventory[weapon_index]
	return equipped_weapon.reach

func _flush_death_messages() -> void:
	for death_message: String in _death_message_queue:
		_append_message(death_message)
	_death_message_queue.clear()

func _remove_defeated_creature(entity: Creature) -> void:
	if entity is PlayerCreature or entity.health > 0 or entity.has_flag("_death_processed"):
		return
	_remove_transference_link_for_entity(entity)
	entity.set_flag("death_processed")
	if not entity.has_flag("run_kill_counted") and not entity.has_flag("ephemeral_expired"):
		entity.set_flag("run_kill_counted")
		PlayerData.run_enemies_killed += 1
	if entity.stolen_item != null:
		var drop_position: Vector2i = _nearest_free_item_tile(entity.pos, false)
		if drop_position.x >= 0:
			item[drop_position] = entity.stolen_item
			entity.stolen_item = null
			if _is_active_map and _is_observed_by_player(entity):
				_append_message("The %s drops its stolen goods." % entity.creature_name)
	if _is_active_map and _is_observed_by_player(entity) and not entity.has_flag("_death_message_logged"):
		entity.set_flag("_death_message_logged")
		var death_message: String = "%s dies." % _creature_dp(entity, true).capitalize()
		if _attack_resolution_depth > 0:
			_death_message_queue.append(death_message)
		else:
			_append_message(death_message)
	var entity_pos: Vector2i = entity.pos
	if creature.has(entity_pos) and creature[entity_pos].id == entity.id:
		creature.erase(entity_pos)
	for turn_index: int in range(turn_queue.size() - 1, -1, -1):
		var queued_entity: Creature = turn_queue[turn_index]
		if queued_entity is PlayerCreature:
			continue
		if queued_entity.id == entity.id:
			turn_queue.remove_at(turn_index)

func _creature_at(pos: Vector2i) -> bool:
	return pos in creature

func _remove_item_if_blocking_altar(position: Vector2i) -> void:
	if not item.has(position):
		return
	var current_tile: TerrainData.Terrain = grid[position]
	if not _is_altar_tile(current_tile):
		return
	if _activate_altar_at(position):
		return
	# A failed requirement leaves the offering and altar unchanged; they cannot be stacked by ordinary drops.
	
# source can be a tile (from_creature=false) or creature (from_creature=true)
# if it's a creature, only obstacles it can see are considered
# if return_path is true, it returns a map of previous tiles on the shortest path from the source tile
# if return_path is false, it returns a map of minimum distances to the source tile
# if stop_at is set, it stops when reaching that point (useful for pathfinding)
# if max_distance is set, it stops after reaching that distance
func _path_knows_tile(pos: Vector2i, source: Variant, from_creature: bool) -> bool:
	if pos.x < 0 or pos.x >= MAP_W or pos.y < 0 or pos.y >= MAP_H:
		return false
	if from_creature and source is PlayerCreature:
		return seen_tiles.has(pos)
	return true

func _path_tile_type(pos: Vector2i, source: Variant, from_creature: bool) -> TerrainData.Terrain:
	if not from_creature:
		return grid[pos]
	if not source is PlayerCreature or visible_tiles.has(pos):
		return grid[pos]
	return tile_last_seen[pos]

func _path_heap_push(heap: Array[Dictionary], entry: Dictionary) -> void:
	heap.append(entry)
	var child_index: int = heap.size() - 1
	while child_index > 0:
		var parent_index: int = floori((child_index - 1) / 2.0)
		if heap[parent_index].get("distance", 0.0) <= heap[child_index].get("distance", 0.0):
			break
		var parent_entry: Dictionary = heap[parent_index]
		heap[parent_index] = heap[child_index]
		heap[child_index] = parent_entry
		child_index = parent_index

func _path_heap_pop(heap: Array[Dictionary]) -> Dictionary:
	var first_entry: Dictionary = heap[0]
	var last_entry: Dictionary = heap.pop_back()
	if heap.is_empty():
		return first_entry
	heap[0] = last_entry
	var parent_index: int = 0
	while true:
		var left_index: int = parent_index * 2 + 1
		var right_index: int = left_index + 1
		if left_index >= heap.size():
			break
		var child_index: int = left_index
		if right_index < heap.size() and heap[right_index].get("distance", 0.0) < heap[left_index].get("distance", 0.0):
			child_index = right_index
		if heap[parent_index].get("distance", 0.0) <= heap[child_index].get("distance", 0.0):
			break
		var parent_entry: Dictionary = heap[parent_index]
		heap[parent_index] = heap[child_index]
		heap[child_index] = parent_entry
		parent_index = child_index
	return first_entry

func _player_path_to(target: Vector2i) -> Dictionary:
	if target == player_pos:
		return {player_pos: Vector2i(-1, -1)}
	var distance: Dictionary = {player_pos: 0.0}
	var previous: Dictionary = {}
	var frontier: Array[Dictionary] = []
	_path_heap_push(frontier, {"pos": player_pos, "distance": 0.0})
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	while not frontier.is_empty():
		var entry: Dictionary = _path_heap_pop(frontier)
		var pos: Vector2i = entry.get("pos", player_pos)
		var current_distance: float = entry.get("distance", 0.0)
		if current_distance > distance[pos]:
			continue
		if pos == target:
			return previous
		for direction in directions:
			var next_pos: Vector2i = pos + direction
			if not is_in_view(next_pos.x, next_pos.y) or not seen_tiles.has(next_pos):
				continue
			var next_tile: TerrainData.Terrain = _path_tile_type(next_pos, _player_entity, true)
			if not next_tile.passable:
				continue
			# Exclude dangerous tiles (lava, deep lake) from hover path
			if _is_hazardous_for_creature(_player_entity, next_tile):
				continue
			if visible_tiles.has(next_pos) and creature.has(next_pos) and next_pos != player_pos:
				continue
			var diagonal: bool = direction.x != 0 and direction.y != 0
			if diagonal:
				var side_x: Vector2i = Vector2i(next_pos.x, pos.y)
				var side_y: Vector2i = Vector2i(pos.x, next_pos.y)
				if not is_in_view(side_x.x, side_x.y) or not is_in_view(side_y.x, side_y.y) or not seen_tiles.has(side_x) or not seen_tiles.has(side_y):
					continue
				if not _path_tile_type(side_x, _player_entity, true).passable and not _path_tile_type(side_y, _player_entity, true).passable:
					continue
			var next_distance: float = current_distance + (1.5 if diagonal else 1.0) * next_tile.move_cost
			if not distance.has(next_pos) or next_distance < float(distance[next_pos]):
				distance[next_pos] = next_distance
				previous[next_pos] = pos
				_path_heap_push(frontier, {"pos": next_pos, "distance": next_distance})
	return {}

## Posts a message to the game log. Storage and display live in the MessageLog node.
func _append_message(message: String) -> void:
	message_posted.emit(message)

## Requests a sound effect by name. Playback lives in the SoundPlayer node.
func _play_sound(sound_name: String) -> void:
	sound_requested.emit(sound_name)

func _play_player_hit_sound() -> void:
	if _hit_sound_played_this_player_turn:
		return
	_hit_sound_played_this_player_turn = true
	_play_sound("hit%d" % randi_range(1, 4))

func _show_tutorial_once(tutorial_key: String) -> void:
	var run_root: Map = _run_root if _run_root != null else self
	if run_root.tutorial_messages_shown.has(tutorial_key):
		return
	var tutorial_message: String = str(TUTORIAL_MESSAGES.get(tutorial_key, ""))
	if tutorial_message.is_empty():
		return
	run_root.tutorial_messages_shown[tutorial_key] = true
	_append_message(tutorial_message)

func _has_aware_enemies() -> bool:
	for entity: Creature in creature.values():
		if entity is PlayerCreature or entity.health <= 0:
			continue
		if entity.awareness_mode in ["aware", "alerted", "searching"]:
			return true
	return false

func _maybe_show_low_health_tutorial() -> void:
	if not _is_active_map or not _player_entity or _player_entity.max_health <= 0:
		return
	if _player_entity.health * 2 < _player_entity.max_health and not _has_aware_enemies():
		_show_tutorial_once("low_health")

func _log_new_sightings() -> void:
	var current_creature_ids: Dictionary[int, bool] = {}
	var current_item_keys: Dictionary[String, bool] = {}
	if not _initialized or not _is_active_map:
		_last_visible_creature_ids.clear()
		_last_visible_item_keys.clear()
		return
	for position: Vector2i in visible_tiles:
		var visible_tile_type: String = grid[position].terrain_name
		match visible_tile_type:
			"stairs leading down":
				_show_tutorial_once("stairs_down")
			"altar of enchantment":
				_show_tutorial_once("enchant_altar")
			"altar of sacrifice":
				_show_tutorial_once("power_altar")
			"altar of enlightenment":
				_show_tutorial_once("id_altar")
			"altar of transformation":
				_show_tutorial_once("transform_altar")
		if creature.has(position):
			var seen_creature: Creature = creature[position]
			if StatusData.has_status(seen_creature, "Invisible"):
				continue
			if not seen_creature is PlayerCreature:
				var creature_id: int = seen_creature.id
				current_creature_ids[creature_id] = true
				if not _last_visible_creature_ids.has(creature_id) and seen_creature.health > 0:
					_append_message("You see %s." % _creature_dp(seen_creature, false))
					_show_tutorial_once("enemy_sighting")
		if item.has(position):
			var seen_item: Item = item[position]
			var item_key: String = "%d:%d:%d" % [level, position.x, position.y]
			current_item_keys[item_key] = true
			if _suppress_sighting_log_item_keys.has(item_key):
				_suppress_sighting_log_item_keys.erase(item_key)
				continue
			if not _last_visible_item_keys.has(item_key):
				_append_message("You see %s." % _item_dp(seen_item))
				_show_tutorial_once("item_sighting")
	_last_visible_creature_ids = current_creature_ids
	_last_visible_item_keys = current_item_keys

func _item_dp(item_data: Item, definite: bool = false) -> String:
	var item_name: String = item_data.get_item_name()
	return ("the " if definite else ("an " if item_name[0] in "aeiouy" else "a ")) + item_name

func _creature_dp(entity: Creature, definite: bool = false) -> String:
	var creature_name: String = entity.creature_name
	return ("the " if definite else ("an " if creature_name[0] in "aeiouy" else "a ")) + creature_name

func _is_observed_by_player(entity: Creature) -> bool:
	if entity is PlayerCreature:
		return true
	return visible_tiles.has(entity.pos)

func _attack_verb(attacker: Creature) -> String:
	if attacker is PlayerCreature:
		var weapon_index: int = PlayerData.equipped_weapon
		if weapon_index >= 0 and weapon_index < PlayerData.inventory.size():
			var weapon: Item = PlayerData.inventory[weapon_index]
			var weapon_verbs: Array = weapon.attack_str
			if weapon_verbs:
				return weapon_verbs.pick_random()
			return "hit"
		return UNARMED_ATTACK_WORDS.pick_random()
	var creature_verbs: Array = attacker.attack_str
	if creature_verbs:
		return creature_verbs.pick_random()
	return "hits"

func _reset_inspect_mode() -> void:
	inspect_mode = false
	inspect_description = ""
	inspect_item_selection_active = false
	inspect_inventory_index = -1
	_inspect_entries.clear()
	_inspect_entry_index = -1
	_inspect_focus_signature = ""
	inspect_changed.emit()

func set_console_cursor_position(position: Vector2i) -> void:
	if console_cursor_position == position:
		return
	console_cursor_position = position
	if inspect_mode and inspect_inventory_index >= 0 and _inventory_index_at_cursor() != inspect_inventory_index:
		_reset_inspect_mode()
	redraw.emit()

func _inventory_index_at_cursor() -> int:
	if not show_inventory or console_cursor_position.x < VIEW_X + VIEW_W or console_cursor_position.x >= CONSOLE_W:
		return -1
	var text_lines: PackedStringArray = StatusPanel.build_inventory_text(self).split("\n")
	var line_index: int = console_cursor_position.y - 1
	if line_index < 0 or line_index >= text_lines.size():
		return -1
	var displayed_line: String = text_lines[line_index].trim_prefix("║").trim_suffix("║").strip_edges()
	for inventory_index: int in range(PlayerData.inventory.size()):
		if displayed_line.begins_with("(%s) " % StatusPanel.inventory_letter(inventory_index)):
			return inventory_index
	return -1

func _inventory_item_line_index(inventory_index: int) -> int:
	var lines: PackedStringArray = StatusPanel.build_inventory_text(self).split("\n")
	var prefix: String = "(%s) " % StatusPanel.inventory_letter(inventory_index)
	for line_index: int in range(lines.size()):
		var display_line: String = lines[line_index]
		if display_line.begins_with("    "):
			display_line = display_line.strip_edges()
		if display_line.begins_with(prefix):
			return line_index
	return -1

func _build_inspect_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if StatusData.has_status(_player_entity, "Blind"):
		return entries
	var position: Vector2i = hover_tile
	var vision_context: Dictionary = {"sight_range": int(_player_entity.sight_range)}
	StatusData.trigger(_player_entity, StatusData.EffectType.VISION, vision_context)
	var observer_distance: float = player_pos.distance_to(position)
	if is_in_view(position.x, position.y) and observer_distance <= float(vision_context.get("sight_range", 10)) and _is_visible(position.x, position.y):
		if creature.has(position):
			var target_creature: Creature = creature[position]
			if not target_creature is PlayerCreature and not StatusData.has_status(target_creature, "Invisible"):
				entries.append({"kind": "creature", "id": target_creature.id, "description": CreatureData.get_description(target_creature, _player_entity)})
		if item.has(position):
			var ground_item: Item = item[position]
			entries.append({"kind": "item", "id": position, "description": ground_item.get_description()})
	if entries.is_empty() and show_inventory:
		var inventory_index: int = _inventory_index_at_cursor()
		if inventory_index >= 0:
			var carried_item: Item = PlayerData.inventory[inventory_index]
			entries.append({"kind": "item", "id": inventory_index, "description": carried_item.get_description()})
	return entries

func _inspect_signature(entries: Array[Dictionary]) -> String:
	var signature_parts: Array[String] = []
	for entry: Dictionary in entries:
		signature_parts.append("%s:%s" % [str(entry.get("kind", "")), str(entry.get("id", ""))])
	if not entries.is_empty():
		signature_parts.append("log")
	return "|".join(signature_parts)

func _inspect_item_inventory_index(inventory_index: int) -> void:
	redraw_status.emit()
	if inventory_index < 0 or inventory_index >= PlayerData.inventory.size():
		inspect_item_selection_active = false
		inspect_inventory_index = -1
		return
	var selected_item: Item = PlayerData.inventory[inventory_index]
	inspect_inventory_index = inventory_index
	_inspect_entries = [{"kind": "item", "id": inventory_index, "description": selected_item.get_description()}]
	_inspect_focus_signature = _inspect_signature(_inspect_entries)
	_inspect_entry_index = 0
	inspect_item_selection_active = false
	inspect_mode = true
	inspect_description = _inspect_entries[0].get("description", "")
	console_cursor_position = Vector2i(VIEW_W + 1, _inventory_item_line_index(inventory_index) + 1)
	inspect_changed.emit()

func _handle_inspect_item_selection(event: InputEventKey) -> bool:
	if not inspect_item_selection_active or not event.pressed or event.echo:
		return false
	var inventory_index: int = _inventory_index_from_key(event)
	if inventory_index >= 0 and inventory_index < PlayerData.inventory.size():
		_inspect_item_inventory_index(inventory_index)
		return true
	if event.is_action_pressed("abort") or event.is_action_pressed("inspect"):
		inspect_item_selection_active = false
		inspect_inventory_index = -1
		redraw_status.emit()
		return true
	if event.is_action_pressed("inventory_toggle"):
		inspect_item_selection_active = false
		inspect_inventory_index = -1
		show_inventory = false
		redraw_status.emit()
		return true
	if event.is_action_pressed("equip") or event.is_action_pressed("drop") or event.is_action_pressed("throw") or event.is_action_pressed("look") or event.is_action_pressed("activate"):
		return true
	return true

func handle_inspect_input(event: InputEvent) -> bool:
	var inspect_pressed: bool = false
	if event is InputEventMouseButton:
		inspect_pressed = event.button_index == MOUSE_BUTTON_RIGHT and event.pressed
	elif event is InputEventKey:
		inspect_pressed = event.is_action_pressed("inspect") and event.pressed
	if not inspect_pressed:
		return false
	var entries: Array[Dictionary] = _build_inspect_entries()
	if entries.is_empty():
		_reset_inspect_mode()
		if not PlayerData.inventory.is_empty():
			show_inventory = true
			inspect_item_selection_active = true
			inspect_mode = false
			inspect_description = ""
		redraw_status.emit()
		return true
	inspect_item_selection_active = false
	var signature: String = _inspect_signature(entries)
	if not inspect_mode or signature != _inspect_focus_signature:
		_inspect_entries = entries
		_inspect_focus_signature = signature
		_inspect_entry_index = 0
	else:
		_inspect_entry_index += 1
	if _inspect_entry_index >= _inspect_entries.size():
		_reset_inspect_mode()
	elif str(_inspect_entries[_inspect_entry_index].get("kind", "")) == "log":
		_reset_inspect_mode()
	else:
		inspect_mode = true
		inspect_description = str(_inspect_entries[_inspect_entry_index].get("description", ""))
		inspect_changed.emit()
	redraw_status.emit()
	return true

func _bresenham_line(start: Vector2i, finish: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var x: int = start.x
	var y: int = start.y
	var delta_x: int = absi(finish.x - start.x)
	var delta_y: int = absi(finish.y - start.y)
	var step_x: int = 1 if start.x < finish.x else -1
	var step_y: int = 1 if start.y < finish.y else -1
	var error: int = delta_x - delta_y
	while true:
		points.append(Vector2i(x, y))
		if x == finish.x and y == finish.y:
			break
		var doubled_error: int = 2 * error
		if doubled_error > -delta_y:
			error -= delta_y
			x += step_x
		if doubled_error < delta_x:
			error += delta_x
			y += step_y
	return points

func _clear_path_to(target: Vector2i) -> bool:
	# Check that there's an uninterrupted line of passable tiles from player to target
	var path: Array[Vector2i] = _bresenham_line(player_pos, target)
	for position in path:
		if position == player_pos or position == target:
			continue
		var terrain: TerrainData.Terrain = grid[position]
		# Check if tile is passable for the player (considering flying, swimming, etc.)
		var is_passable: bool = terrain.passable
		if not is_passable and not _player_entity.has_trait("Flying"):
			# Check if it's water and player can swim
			if not (_player_entity.has_trait("Aquatic") or _player_entity.has_trait("Amphibious")) and terrain.terrain_name.ends_with(" lake"):
				is_passable = false
			# Check deep lake for flying
			elif terrain.terrain_name == "deep lake" and not _player_entity.has_trait("Flying"):
				is_passable = false
		if not is_passable:
			return false
	return true

func _preview_grenade_radius(grenade: Item) -> int:
	return maxi(0, grenade.enchantment) + 4

func _set_transient_visual(position: Vector2i, display_char: String, foreground: int, background: int = 0, redraw_after: bool = true) -> void:
	if position.x < 0 or position.x >= MAP_W or position.y < 0 or position.y >= MAP_H or not visible_tiles.has(position):
		return
	transient_visuals[position] = {"char": display_char, "fg": foreground, "bg": background}
	if redraw_after:
		redraw.emit()

func _animate_throw_effect(path: Array[Vector2i], thrown_item: Item, detonation_position: Vector2i, blast_radius: int = 0, blast_color: int = 15) -> void:
	if not _throw_animation_enabled or not is_inside_tree() or not _is_active_map:
		return
	_throw_visual_generation += 1
	var animation_generation: int = _throw_visual_generation
	var item_char: String = thrown_item.glyph
	var item_color: int = thrown_item.color
	var animation_path: Array[Vector2i] = path.duplicate()
	for path_position: Vector2i in animation_path:
		if animation_generation != _throw_visual_generation:
			return
		transient_visuals.clear()
		_set_transient_visual(path_position, item_char, item_color)
		if not visible_tiles.has(path_position):
			continue
		await get_tree().create_timer(0.04).timeout
	if blast_radius > 0:
		transient_visuals.clear()
		_set_transient_visual(detonation_position, "█", blast_color, 0, false)
		redraw.emit()
		await get_tree().create_timer(0.07).timeout
		for ring_radius: int in range(1, blast_radius + 1):
			if animation_generation != _throw_visual_generation:
				return
			if ring_radius == 1:
				transient_visuals.clear()
				_set_transient_visual(detonation_position, "█", blast_color)
			transient_visuals.clear()
			for ring_position: Vector2i in _get_circle(ring_radius, detonation_position, false):
				_set_transient_visual(ring_position, "█", blast_color, 0, false)
			redraw.emit()
			await get_tree().create_timer(0.07).timeout
	if animation_generation == _throw_visual_generation:
		transient_visuals.clear()
		redraw.emit()

func _refresh_throw_trajectory_preview() -> void:
	if throw_inventory_index < 0 or throw_inventory_index >= PlayerData.inventory.size():
		return
	var target_position: Vector2i = hover_tile
	var projectile: Item = PlayerData.inventory[throw_inventory_index]
	if player_pos.distance_to(target_position) > float(_throw_range(projectile)):
		return
	for position: Vector2i in _bresenham_line(player_pos, target_position):
		hover_path[position] = true
	if projectile.get_type() == "grenade":
		var blast_radius: int = _preview_grenade_radius(projectile)
		for blast_position: Vector2i in _get_circle(blast_radius, target_position, true):
			hover_blast_tiles[blast_position] = true

func _refresh_wand_trajectory_preview() -> void:
	var target_position: Vector2i = hover_tile
	if not visible_tiles.has(target_position) or not creature.has(target_position):
		return
	var target_entity: Creature = creature[target_position]
	if target_entity is PlayerCreature or target_entity.health <= 0 or StatusData.has_status(target_entity, "Invisible"):
		return
	for position: Vector2i in _bresenham_line(player_pos, target_position):
		hover_path[position] = true

func _refresh_target_trajectory_preview() -> void:
	if throw_target_mode:
		_refresh_throw_trajectory_preview()
	elif wand_target_mode:
		_refresh_wand_trajectory_preview()

func _refresh_hover_path() -> void:
	hover_path.clear()
	hover_blast_tiles.clear()
	if StatusData.has_status(_player_entity, "Blind"):
		return
	if not is_in_view(hover_tile.x, hover_tile.y):
		return
	if throw_target_mode or wand_target_mode:
		_refresh_target_trajectory_preview()
		return
	if not seen_tiles.has(hover_tile):
		return
	var path_previous: Dictionary = _player_path_to(hover_tile)
	if hover_tile == player_pos:
		hover_path[player_pos] = true
		return
	if not path_previous.has(hover_tile):
		return
	var path_tile: Vector2i = hover_tile
	while path_tile != player_pos and path_previous.has(path_tile):
		hover_path[path_tile] = true
		path_tile = path_previous[path_tile]
	if path_tile == player_pos:
		hover_path[player_pos] = true

func set_hover_tile(pos: Vector2i) -> void:
	if StatusData.has_status(_player_entity, "Blind") and pos.x >= 0 and pos.y >= 0 and player_pos.distance_to(pos) > 1.0:
		pos = Vector2i(-1, -1)
	if hover_tile == pos:
		return
	hover_tile = pos
	if inspect_mode:
		_reset_inspect_mode()
	_refresh_hover_path()
	redraw.emit()

func is_hover_path_tile(pos: Vector2i) -> bool:
	return hover_path.has(pos)

func is_hover_blast_tile(pos: Vector2i) -> bool:
	return hover_blast_tiles.has(pos)

func _visible_creature_ids() -> Dictionary[int, bool]:
	var ids: Dictionary[int, bool] = {}
	for visible_pos in visible_tiles:
		if not creature.has(visible_pos):
			continue
		var entity: Creature = creature[visible_pos]
		if StatusData.has_status(entity, "Invisible"):
			continue
		if entity is PlayerCreature:
			continue
		if entity.id == 0:
			entity.id = _next_creature_id
			_next_creature_id += 1
		ids[int(entity.id)] = true
	return ids

func _has_newly_visible_creature() -> bool:
	var current_ids: Dictionary[int, bool] = _visible_creature_ids()
	for creature_id in current_ids:
		if not auto_walk_initial_visible_creatures.has(creature_id):
			return true
	return false

func start_auto_walk(target: Vector2i) -> void:
	if StatusData.has_status(_player_entity, "Blind") or not is_in_view(target.x, target.y) or not seen_tiles.has(target):
		return
	var path_previous: Dictionary = _player_path_to(target)
	if target != player_pos and not path_previous.has(target):
		return
	auto_walk_target = target
	auto_walk_initial_visible_creatures = _visible_creature_ids()
	auto_walk_active = target != player_pos
	if auto_walk_active and is_player_turn and not processing_turns:
		_continue_auto_walk.call_deferred()

func cancel_auto_walk() -> void:
	auto_walk_active = false
	auto_walk_target = Vector2i(-1, -1)
	auto_walk_initial_visible_creatures.clear()

func _continue_auto_walk() -> void:
	if not auto_walk_active or not is_player_turn or processing_turns:
		return
	if StatusData.has_status(_player_entity, "Blind"):
		cancel_auto_walk()
		redraw.emit()
		return
	if StatusData.has_status(_player_entity, "Confused"):
		cancel_auto_walk()
		redraw.emit()
		return
	if _has_newly_visible_creature() or player_pos == auto_walk_target:
		cancel_auto_walk()
		redraw.emit()
		return
	var path_previous: Dictionary = _player_path_to(auto_walk_target)
	if not path_previous.has(auto_walk_target):
		cancel_auto_walk()
		redraw.emit()
		return
	var next_tile: Vector2i = auto_walk_target
	var path_steps: int = 0
	while path_previous.has(next_tile) and path_previous[next_tile] != player_pos and path_steps < MAP_W * MAP_H:
		next_tile = path_previous[next_tile]
		path_steps += 1
	if path_steps >= MAP_W * MAP_H or not path_previous.has(next_tile) or path_previous[next_tile] != player_pos:
		cancel_auto_walk()
		redraw.emit()
		return
	var dx: int = next_tile.x - player_pos.x
	var dy: int = next_tile.y - player_pos.y
	var move_cost: int = int(_player_entity.move_speed)
	var intended_direction: Vector2i = Vector2i(dx, dy)
	if not move_player(intended_direction.x, intended_direction.y, move_cost, true):
		cancel_auto_walk()
		redraw.emit()
		_process_npc_turns()
		return
	await get_tree().process_frame
	if _has_newly_visible_creature():
		cancel_auto_walk()
	_process_npc_turns()
	if auto_walk_active and is_player_turn and not processing_turns:
		_continue_auto_walk()

func dijkstra(source: Variant, from_creature: bool = false, return_path: bool = false, stop_at: Vector2i = Vector2i.ZERO, max_distance: float = 0.0, ignore_impassable_tiles: bool = false) -> Dictionary:
	var start: Vector2i = source.pos if from_creature else source
	var distance: Dictionary = {start: 0.0}
	var previous: Dictionary = {}
	var frontier: Array[Vector2i] = [start]
	var visible_creatures: Dictionary = {}
	if from_creature:
		visible_creatures = visible_tiles if source is PlayerCreature else source.visible_tiles

	var directions: Array[Vector2i] = [
		Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT,
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
	]
	while not frontier.is_empty():
		var next_frontier: Array[Vector2i] = []
		for pos in frontier:
			for direction in directions:
				var target: Vector2i = pos + direction
				if target.x < 0 or target.x >= MAP_W or target.y < 0 or target.y >= MAP_H:
					continue
				if not _path_knows_tile(target, source, from_creature):
					continue
				var diagonal: bool = direction.x != 0 and direction.y != 0
				if from_creature and visible_creatures.has(target) and creature.has(target) and target != start and target != stop_at:
					continue
				var target_tile: TerrainData.Terrain = _path_tile_type(target, source, from_creature)
				var aquatic: bool = from_creature and can_swim(source)
				var flying: bool = from_creature and source.has_trait("Flying")
				if aquatic and not _is_water_tile(target_tile):
					continue
				var movement_multiplier: float = 1.0 if from_creature and (_creature_ignores_terrain_cost(source) or aquatic) else _terrain_movement_multiplier(target_tile)
				var step_cost: float = (1.5 if diagonal else 1.0) * movement_multiplier
				var next_distance: float = distance[pos] + step_cost
				if max_distance > 0.0 and next_distance > max_distance:
					continue
				var target_is_passable: bool = target_tile.passable or (aquatic and _is_water_tile(target_tile)) or (flying and target_tile.terrain_name == "deep lake")
				if not ignore_impassable_tiles and not target_is_passable:
					continue
				if from_creature and visible_creatures.has(target) and creature.has(target) and target != start and target != stop_at:
					continue
				if diagonal and not ignore_impassable_tiles:
					var horizontal: Vector2i = Vector2i(target.x, pos.y)
					var vertical: Vector2i = Vector2i(pos.x, target.y)
					if not _path_knows_tile(horizontal, source, from_creature) or not _path_knows_tile(vertical, source, from_creature):
						continue
					var horizontal_tile: TerrainData.Terrain = _path_tile_type(horizontal, source, from_creature)
					var vertical_tile: TerrainData.Terrain = _path_tile_type(vertical, source, from_creature)
					var horizontal_passable: bool = horizontal_tile.passable or (aquatic and _is_water_tile(horizontal_tile)) or (flying and horizontal_tile.terrain_name == "deep lake")
					var vertical_passable: bool = vertical_tile.passable or (aquatic and _is_water_tile(vertical_tile)) or (flying and vertical_tile.terrain_name == "deep lake")
					if not horizontal_passable and not vertical_passable:
						continue
				if not distance.has(target) or next_distance < distance[target]:
					distance[target] = next_distance
					next_frontier.append(target)
					if return_path:
						previous[target] = pos
					if target == stop_at:
						return previous if return_path else distance
		frontier = next_frontier
	return previous if return_path else distance

func move_player(dx: int, dy: int, cost: int, from_auto_walk: bool = false) -> bool:
	_reset_inspect_mode()
	if not _player_entity:
		return false
	if _entity_is_paralyzed(_player_entity):
		_apply_action_statuses(_player_entity, "wait")
		_advance_player_action(_adjust_delay(_player_entity, _player_entity.move_speed))
		return true
	_prepare_environment_turn(_player_entity)
	_player_entity.set_flag("_environment_turn_prepared")
	if _player_entity.health <= 0:
		return false
	if (dx != 0 or dy != 0) and not from_auto_walk:
		cancel_auto_walk()
	var direction_is_confused: bool = StatusData.has_status(_player_entity, "Confused")
	var direction_is_blind: bool = StatusData.has_status(_player_entity, "Blind")
	var intended_direction: Vector2i = Vector2i(dx, dy)
	if intended_direction == Vector2i.ZERO:
		if direction_is_blind:
			var blind_wait_moves: Array[Vector2i] = _available_player_directions(Vector2i.ZERO, false)
			if blind_wait_moves.is_empty():
				if direction_is_blind:
					return false
				_apply_action_statuses(_player_entity, "wait")
				var blocked_wait_delay: int = _adjust_delay(_player_entity, cost)
				_advance_player_action(blocked_wait_delay)
				return true
			intended_direction = blind_wait_moves.pick_random()
			cost = _player_entity.move_speed
		else:
			_apply_action_statuses(_player_entity, "wait")
			var wait_delay: int = _adjust_delay(_player_entity, cost)
			_advance_player_action(wait_delay)
			return true

	if direction_is_blind:
		var target_in_requested_direction: Vector2i = player_pos + intended_direction
		var requested_in_bounds: bool = target_in_requested_direction.x >= 0 and target_in_requested_direction.x < MAP_W and target_in_requested_direction.y >= 0 and target_in_requested_direction.y < MAP_H
		var can_blind_attack: bool = requested_in_bounds and creature.has(target_in_requested_direction) and grid[target_in_requested_direction].passable and (intended_direction.x == 0 or intended_direction.y == 0 or _player_has_reach())
		if not can_blind_attack and not _available_player_directions(Vector2i.ZERO, false).has(intended_direction):
			var blind_moves: Array[Vector2i] = _available_player_directions(Vector2i.ZERO, false)
			if blind_moves.is_empty():
				return false
			intended_direction = blind_moves.pick_random()

	if direction_is_confused and not direction_is_blind:
		if dx == 0 and dy == 0:
			_apply_action_statuses(_player_entity, "wait")
			var confused_wait_delay: int = _adjust_delay(_player_entity, cost)
			_advance_player_action(confused_wait_delay)
			return true
		var available_directions: Array[Vector2i] = _available_player_directions(intended_direction, true)
		if available_directions.is_empty():
			return false
		var direction_context: Dictionary = {"direction": intended_direction, "available_directions": available_directions}
		StatusData.trigger(_player_entity, StatusData.EffectType.DIRECTION, direction_context)
		intended_direction = direction_context.get("direction", intended_direction)
		if not available_directions.has(intended_direction):
			return false

	var target: Vector2i = player_pos + intended_direction
	if target.x < 0 or target.x >= MAP_W or target.y < 0 or target.y >= MAP_H:
		return false
	if intended_direction.x != 0 and intended_direction.y != 0:
		var origin_is_hazardous: bool = _is_hazardous_for_creature(_player_entity, grid[player_pos])
		var horizontal_tile: TerrainData.Terrain = grid[player_pos + Vector2i(intended_direction.x, 0)]
		var vertical_tile: TerrainData.Terrain = grid[player_pos + Vector2i(0, intended_direction.y)]
		var horizontal_passable: bool = horizontal_tile.passable or (origin_is_hazardous and _is_hazardous_for_creature(_player_entity, horizontal_tile))
		var vertical_passable: bool = vertical_tile.passable or (origin_is_hazardous and _is_hazardous_for_creature(_player_entity, vertical_tile))
		if not horizontal_passable and not vertical_passable:
			return false
	var target_has_living_creature: bool = _creature_at(target) and creature[target].health > 0
	if not target_has_living_creature and (_is_stairs_tile(grid[target])):
		var stair_move_cost: int = _player_entity.move_speed if direction_is_confused or direction_is_blind or (dx == 0 and dy == 0) else cost
		if intended_direction.x != 0 and intended_direction.y != 0:
			stair_move_cost = roundi(float(stair_move_cost) * 1.5)
		return _travel_via_stairs(grid[target], stair_move_cost)
	var target_tile: TerrainData.Terrain = grid[target]
	if _is_hazardous_for_creature(_player_entity, target_tile):
		if _has_safe_player_move():
			return false
	elif not target_tile.passable:
		return false

	if direction_is_blind and _creature_at(target) and (intended_direction.x == 0 or intended_direction.y == 0 or _player_has_reach()):
		var blind_attack_defender: Creature = creature[target]
		if StatusData.has_status(blind_attack_defender, "Invisible"):
			_append_message("You swing blindly at the hidden creature.")
		_apply_action_statuses(_player_entity, "attack")
		var blind_attack_delay: int = _adjust_delay(_player_entity, int(_player_entity.attack_speed))
		_snapshot_visible_state()
		_resolve_attack(_player_entity, blind_attack_defender, "", true)
		_record_player_weapon_attack()
		_advance_player_action(blind_attack_delay)
		_remove_defeated_creature(blind_attack_defender)
		cancel_auto_walk()
		return true

	if _creature_at(target) and not direction_is_blind:
		if intended_direction.x != 0 and intended_direction.y != 0 and not _player_has_reach():
			return false
		var defender: Creature = creature[target]
		if StatusData.has_status(defender, "Invisible"):
			_append_message("You swing blindly at the hidden creature.")
		_apply_action_statuses(_player_entity, "attack")
		var attack_delay: int = _adjust_delay(_player_entity, int(_player_entity.attack_speed))
		_snapshot_visible_state()
		_resolve_attack(_player_entity, defender, "", true)
		_record_player_weapon_attack()
		_advance_player_action(attack_delay)
		_remove_defeated_creature(defender)
		cancel_auto_walk()
		return true

	_apply_action_statuses(_player_entity, "move")
	if direction_is_confused or direction_is_blind or (dx == 0 and dy == 0):
		cost = _player_entity.move_speed
	var is_diagonal_move: bool = intended_direction.x != 0 and intended_direction.y != 0
	cost = _movement_delay_for_destination(cost, target, is_diagonal_move, _player_entity)
	var adjusted_move_cost: int = _adjust_delay(_player_entity, cost)
	_hit_sound_played_this_player_turn = false
	_snapshot_visible_state()
	if player_scent_trail.is_empty() or player_scent_trail.back() != player_pos:
		player_scent_trail.append(player_pos)
	while player_scent_trail.size() > MAP_W * MAP_H:
		player_scent_trail.pop_front()
	_player_entity.pos = target
	_player_entity.last_action_cost = _advance_entity_time(_player_entity, adjusted_move_cost, true)
	var previous_player_position: Vector2i = player_pos
	creature.erase(player_pos)
	player_pos = target
	_player_entity.pos = target
	creature[player_pos] = _player_entity
	_apply_water_wetness(_player_entity, player_pos)
	_activate_altar_at(previous_player_position)
	if _player_weapon_ego_name() == "lunging":
		for lunge_direction: Vector2i in StatusData.ADJACENT_DIRECTIONS:
			var lunge_target_position: Vector2i = player_pos + lunge_direction
			if not creature.has(lunge_target_position):
				continue
			var previous_distance_to_target: float = previous_player_position.distance_to(lunge_target_position)
			var new_distance_to_target: float = player_pos.distance_to(lunge_target_position)
			if previous_distance_to_target <= 1.5 or new_distance_to_target >= previous_distance_to_target:
				continue
			var lunge_defender: Creature = creature[lunge_target_position]
			if lunge_defender.health <= 0 or lunge_defender is PlayerCreature:
				continue
			if StatusData.has_status(lunge_defender, "Invisible"): 
				continue
			_snapshot_visible_state()
			_resolve_attack(_player_entity, lunge_defender, "", true)
			_record_player_weapon_attack()
			_remove_defeated_creature(lunge_defender)
			break
	if StatusData.has_status(_player_entity, "Burning"): 
		_ignite_flammable_tile(player_pos)
	for moved_observer: Creature in creature.values():
		if not moved_observer is PlayerCreature:
			moved_observer.visible_tiles = _compute_fov(moved_observer)
			_update_creature_awareness(moved_observer)
	var inventory = PlayerData.inventory
	var MAX_INVENTORY = PlayerData.MAX_INVENTORY
	if target in item:
		var picked_item: Item = item[target]
		if picked_item is LyricalOrblet:
			item.erase(target)
			var run_root: Map = _run_root if _run_root != null else self
			run_root.lyrical_orblet_found = true
			if run_root.stairs_up_pos.x >= 0 and run_root.stairs_up_pos.y >= 0:
				run_root.grid[run_root.stairs_up_pos] = TerrainData.get_terrain(TerrainData.TileType.STAIRS_UP)
			_play_sound("orblet")
			_append_message("The Lyrical Orblet starts floating alongside you. You will now be able to climb back up to the outside world.")
		elif not _activate_altar_at(target) and inventory.size() < MAX_INVENTORY:
			inventory.append(picked_item)
			item.erase(target)
			_play_sound("item")
			_append_message("You pick up %s." % _item_dp(picked_item))
			_show_tutorial_once("item_pickup")
			if show_inventory:
				redraw_status.emit()
			var picked_item_type: String = picked_item.get_type()
			if picked_item_type in ["weapon", "armor"]:
				_show_tutorial_once("weapon_armor_pickup")
			elif picked_item_type in ["grenade", "projectile"]:
				_show_tutorial_once("throwable_pickup")
			elif picked_item_type in ["wand", "charm"]:
				_show_tutorial_once("wand_charm_pickup")
			if inventory.size() >= MAX_INVENTORY:
				_show_tutorial_once("inventory_full")
		elif inventory.size() >= MAX_INVENTORY:
			_show_tutorial_once("inventory_full")
	turn_queue.sort_custom(_sort_by_time)
	_recompute_all_fov()
	redraw.emit()
	return true

func _inventory_index_from_key(event: InputEventKey) -> int:
	# Inventory slots are lettered a-z. Prefer the produced keycode so shifted
	# input (for example, Shift+W) still refers to the matching inventory slot.
	var key_code: Key = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
	if key_code >= KEY_A and key_code <= KEY_Z:
		return int(key_code - KEY_A)
	return -1

func _equip_inventory_item(inventory_index: int) -> void:
	if inventory_index < 0 or inventory_index >= PlayerData.inventory.size():
		return
	var selected_item: Item = PlayerData.inventory[inventory_index]
	var equipped: bool = false
	match selected_item.get_type():
		"weapon":
			equipped = PlayerData.equip_weapon(_player_entity, inventory_index)
		"armor":
			equipped = PlayerData.equip_armor(_player_entity, inventory_index)
	if equipped:
		equip_selection_active = false
		redraw_status.emit()
		_adjust_delay(_player_entity, _player_entity.move_speed)
		get_viewport().set_input_as_handled()

func handle_equip_input(event: InputEvent) -> bool:
	if not equip_selection_active or not event is InputEventKey or not event.pressed or event.echo:
		return false
	if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
		equip_selection_active = false
		redraw_status.emit()
		get_viewport().set_input_as_handled()
		return true
	var inventory_index: int = _inventory_index_from_key(event)
	if inventory_index >= 0 and inventory_index < PlayerData.inventory.size():
		_equip_inventory_item(inventory_index)
	return true

func _attack_adjacent_enemy() -> bool:
	if not is_player_turn or processing_turns:
		return false
	var can_attack_blindly: bool = StatusData.has_status(_player_entity, "Blind")
	var enemy_positions: Array[Vector2i] = []
	if can_attack_blindly:
		for direction: Vector2i in StatusData.ADJACENT_DIRECTIONS:
			var position: Vector2i = player_pos + direction
			if creature.has(position) and not creature[position] is PlayerCreature and creature[position].health > 0:
				enemy_positions.append(position)
	else:
		enemy_positions = _visible_enemy_positions()
	for enemy_position: Vector2i in enemy_positions:
		var direction: Vector2i = enemy_position - player_pos
		if absi(direction.x) > 1 or absi(direction.y) > 1 or direction == Vector2i.ZERO:
			continue
		if direction.x != 0 and direction.y != 0 and not _player_has_reach():
			continue
		return move_player(direction.x, direction.y, _player_entity.attack_speed)
	return false

func _movement_direction(event: InputEventKey) -> Vector2i:
	if event.is_action_pressed("move_up", true):
		return Vector2i.UP
	if event.is_action_pressed("move_down", true):
		return Vector2i.DOWN
	if event.is_action_pressed("move_left", true):
		return Vector2i.LEFT
	if event.is_action_pressed("move_right", true):
		return Vector2i.RIGHT
	if event.is_action_pressed("move_up_right", true):
		return Vector2i(1, -1)
	if event.is_action_pressed("move_down_right", true):
		return Vector2i(1, 1)
	if event.is_action_pressed("move_down_left", true):
		return Vector2i(-1, 1)
	if event.is_action_pressed("move_up_left", true):
		return Vector2i(-1, -1)
	return Vector2i.ZERO

func _visible_enemy_positions() -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	if StatusData.has_status(_player_entity, "Blind"):
		return targets
	for position: Vector2i in visible_tiles:
		if creature.has(position) and not creature[position] is PlayerCreature and creature[position].health > 0 and not StatusData.has_status(creature[position], "Invisible"):
			targets.append(position)
	targets.sort_custom(_sort_target_positions)
	return targets

func _nearest_available_target(targets: Array[Vector2i]) -> Vector2i:
	return targets[0] if not targets.is_empty() else player_pos

func _available_throw_target_positions(inventory_index: int) -> Array[Vector2i]:
	var targets: Array[Vector2i] = _visible_enemy_positions()
	if inventory_index < 0 or inventory_index >= PlayerData.inventory.size():
		return []
	var projectile: Item = PlayerData.inventory[inventory_index]
	var max_range: float = _throw_range(projectile)
	for target_index: int in range(targets.size() - 1, -1, -1):
		if player_pos.distance_to(targets[target_index]) > max_range:
			targets.remove_at(target_index)
	return targets

func _update_target_mode_hover_cursor() -> void:
	if throw_target_mode:
		return
	if wand_target_mode and _visible_enemy_positions().is_empty():
		set_hover_tile(player_pos)

func _sort_target_positions(first: Vector2i, second: Vector2i) -> bool:
	var first_distance: float = player_pos.distance_squared_to(first)
	var second_distance: float = player_pos.distance_squared_to(second)
	if is_equal_approx(first_distance, second_distance):
		if first.y == second.y:
			return first.x < second.x
		return first.y < second.y
	return first_distance < second_distance

func _begin_look_mode() -> void:
	if StatusData.has_status(_player_entity, "Blind"):
		return
	look_mode = true
	throw_target_mode = false
	wand_target_mode = false
	_visible_target_positions = _visible_enemy_positions()
	_visible_target_index = -1
	var initial_position: Vector2i = hover_tile if is_in_view(hover_tile.x, hover_tile.y) and seen_tiles.has(hover_tile) else player_pos
	look_cursor_position = initial_position
	set_hover_tile(initial_position)
	redraw.emit()

func _begin_throw_target_mode(inventory_index: int) -> void:
	if StatusData.has_status(_player_entity, "Blind"):
		return
	throw_inventory_index = inventory_index
	throw_item_selection_active = false
	throw_target_mode = true
	look_mode = false
	wand_target_mode = false
	_visible_target_positions = _available_throw_target_positions(inventory_index)
	_visible_target_index = -1
	var initial_position: Vector2i = _nearest_available_target(_visible_target_positions)
	look_cursor_position = initial_position
	set_hover_tile(initial_position)
	_refresh_hover_path()
	redraw.emit()

func _begin_wand_target_mode(inventory_index: int) -> void:
	activate_item_selection_active = false
	if StatusData.has_status(_player_entity, "Blind"):
		_append_message("You cannot target a wand while blind.")
		redraw.emit()
		return
	activate_inventory_index = inventory_index
	activate_item_selection_active = false
	wand_target_mode = true
	look_mode = false
	throw_target_mode = false
	_visible_target_positions = _visible_enemy_positions()
	_visible_target_index = -1
	var initial_position: Vector2i = _nearest_available_target(_visible_target_positions)
	look_cursor_position = initial_position
	set_hover_tile(initial_position)
	_refresh_hover_path()
	redraw.emit()

func _end_target_mode() -> void:
	look_mode = false
	throw_target_mode = false
	wand_target_mode = false
	throw_inventory_index = -1
	activate_inventory_index = -1
	_visible_target_positions.clear()
	_visible_target_index = -1
	look_cursor_position = Vector2i(-1, -1)
	redraw.emit()

func set_target_cursor_position(position: Vector2i) -> void:
	if StatusData.has_status(_player_entity, "Blind") or (not look_mode and not throw_target_mode and not wand_target_mode):
		return
	if not is_in_view(position.x, position.y):
		return
	look_cursor_position = position
	set_hover_tile(position)
	if throw_target_mode or wand_target_mode:
		_update_target_mode_hover_cursor()
		_refresh_hover_path()
	redraw.emit()

func _move_target_cursor(direction: Vector2i) -> void:
	if direction == Vector2i.ZERO:
		return
	set_target_cursor_position(look_cursor_position + direction)

func confirm_target_at(position: Vector2i) -> void:
	if StatusData.has_status(_player_entity, "Blind") or (not look_mode and not throw_target_mode and not wand_target_mode) or not is_in_view(position.x, position.y):
		return
	set_target_cursor_position(position)
	if throw_target_mode:
		var target: Vector2i = look_cursor_position
		_throw_selected_item_at(target)
		_end_target_mode()
	elif wand_target_mode:
		_activate_selected_wand_at(look_cursor_position)
	else:
		_confirm_look_target()

func _cycle_visible_target() -> void:
	if StatusData.has_status(_player_entity, "Blind"):
		return
	_visible_target_positions = _visible_enemy_positions()
	if _visible_target_positions.is_empty():
		_visible_target_index = -1
		return
	_visible_target_index = (_visible_target_index + 1) % _visible_target_positions.size()
	look_cursor_position = _visible_target_positions[_visible_target_index]
	set_hover_tile(look_cursor_position)
	redraw.emit()

func _path_step_count(previous: Dictionary, target: Vector2i) -> int:
	if target == player_pos:
		return 0
	if not previous.has(target):
		return 2147483647
	var position: Vector2i = target
	var steps: int = 0
	while position != player_pos and previous.has(position):
		position = previous[position]
		steps += 1
	return steps if position == player_pos else 2147483647

func _confirm_look_target() -> void:
	if StatusData.has_status(_player_entity, "Blind"):
		_end_target_mode()
		return
	var target: Vector2i = look_cursor_position
	_end_target_mode()
	if not is_in_view(target.x, target.y) or target == player_pos:
		return
	if creature.has(target):
		if not creature[target] is PlayerCreature:
			var best_position: Vector2i = Vector2i(-1, -1)
			var best_steps: int = 2147483647
			for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
				var neighbor: Vector2i = target + direction
				if StatusData.has_status(_player_entity, "Blind") or not is_in_view(neighbor.x, neighbor.y) or not grid[neighbor].passable or creature.has(neighbor):
					continue
				var path: Dictionary = _player_path_to(neighbor)
				var steps: int = _path_step_count(path, neighbor)
				if steps < best_steps:
					best_steps = steps
					best_position = neighbor
			if best_position.x >= 0:
				start_auto_walk(best_position)
			return
		if creature[target] is PlayerCreature:
			return
	start_auto_walk(target)

func _handle_target_mode_input(event: InputEventKey) -> bool:
	if not look_mode and not throw_target_mode and not wand_target_mode:
		return false
	if event.is_action_pressed("look") and look_mode:
		_end_target_mode()
		return true
	if event.is_action_pressed("abort"):
		_end_target_mode()
		return true
	if event.is_action_pressed("next_target"):
		_cycle_visible_target()
		return true
	if event.is_action_pressed("confirm"):
		if throw_target_mode:
			_throw_selected_item_at(look_cursor_position)
			_end_target_mode()
		elif wand_target_mode:
			_activate_selected_wand_at(look_cursor_position)
		else:
			_confirm_look_target()
		return true
	_move_target_cursor(_movement_direction(event))
	return true

func _remove_inventory_item(inventory_index: int) -> Item:
	var removed_item: Item = PlayerData.inventory[inventory_index]
	PlayerData.inventory.remove_at(inventory_index)
	if PlayerData.equipped_weapon > inventory_index:
		PlayerData.equipped_weapon -= 1
	if PlayerData.equipped_armor > inventory_index:
		PlayerData.equipped_armor -= 1
	return removed_item

func _unequip_delay_for_item(inventory_index: int) -> int:
	if PlayerData.equipped_weapon == inventory_index:
		PlayerData.equip_weapon(_player_entity, inventory_index)
		return _player_entity.attack_speed
	if PlayerData.equipped_armor == inventory_index:
		PlayerData.equip_armor(_player_entity, inventory_index)
		return _player_entity.move_speed
	return 0

func _spend_player_action_delay(delay: int, action: String = "wait") -> void:
	if _entity_is_paralyzed(_player_entity):
		_apply_action_statuses(_player_entity, "wait")
		_advance_player_action(_adjust_delay(_player_entity, _player_entity.move_speed))
		return
	_prepare_environment_turn(_player_entity)
	_player_entity.set_flag("_environment_turn_prepared")
	if _player_entity.health <= 0:
		redraw.emit()
		return
	_apply_action_statuses(_player_entity, action)
	var action_delay: int = _adjust_delay(_player_entity, maxi(0, delay))
	_advance_player_action(action_delay)

func _advance_player_action(adjusted_delay: int) -> void:
	if not _player_entity.has_flag("_environment_turn_prepared"):
		_prepare_environment_turn(_player_entity)
		_player_entity.set_flag("_environment_turn_prepared")
	redraw.emit()
	if _player_entity.health <= 0:
		_player_entity.set_flag("_environment_turn_prepared", false)
		return
	_player_entity.set_flag("_defer_environment_advance")
	_player_entity.last_action_cost = _advance_entity_time(_player_entity, adjusted_delay, true)
	_player_entity.set_flag("_defer_environment_advance", false)
	_player_entity.set_flag("_environment_turn_prepared", false)
	turn_queue.sort_custom(_sort_by_time)
	_recompute_all_fov()
	_process_npc_turns()

func _drop_inventory_item(inventory_index: int) -> void:
	_prepare_environment_turn(_player_entity)
	_player_entity.set_flag("_environment_turn_prepared")
	if _player_entity.health <= 0:
		return
	if inventory_index < 0 or inventory_index >= PlayerData.inventory.size():
		return
	if item.has(player_pos):
		_append_message("There is already an item here.")
		return
	var move_delay: int = _player_entity.move_speed
	var equipment_delay: int = _unequip_delay_for_item(inventory_index)
	var dropped_item: Item = _remove_inventory_item(inventory_index)
	_apply_action_statuses(_player_entity, "drop")
	var action_delay: int = _adjust_delay(_player_entity, move_delay + equipment_delay)
	item[player_pos] = dropped_item
	_suppress_sighting_log_item_keys["%d:%d:%s" % [level, player_pos.x, str(player_pos.y)]] = true
	_append_message("You drop %s." % _item_dp(dropped_item, true))
	drop_selection_active = false
	_advance_player_action(action_delay)
	redraw_status.emit()

func _throw_range(projectile: Item) -> int:
	var base_range: int = 5 + int(PlayerData.stats[PlayerData.Stat.STRENGTH])
	if projectile.get_type() == "projectile":
		return floori(base_range * (projectile as Projectile).range_mod)
	return base_range

func _nearest_free_item_tile(origin: Vector2i, require_visible: bool = true) -> Vector2i:
	var origin_tile: TerrainData.Terrain = grid[origin]
	if not item.has(origin) and not _is_hazardous_for_creature(_player_entity, origin_tile) and origin_tile.passable:
		return origin
	var visited: Dictionary[Vector2i, bool] = {origin: true}
	var frontier: Array[Vector2i] = [origin]
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	while not frontier.is_empty():
		var next_frontier: Array[Vector2i] = []
		for position: Vector2i in frontier:
			for direction: Vector2i in directions:
				var neighbor: Vector2i = position + direction
				if (require_visible and not is_in_view(neighbor.x, neighbor.y)) or visited.has(neighbor):
					continue
				visited[neighbor] = true
				var neighbor_tile: TerrainData.Terrain = grid[neighbor]
				if not item.has(neighbor) and not _is_hazardous_for_creature(_player_entity, neighbor_tile) and neighbor_tile.passable:
					return neighbor
				next_frontier.append(neighbor)
		frontier = next_frontier
	return Vector2i(-1, -1)

func _reduce_status_duration(entity: Creature, status_name: String, amount: int) -> void:
	if amount <= 0:
		return
	var statuses: Array = entity.status
	for status_index: int in range(statuses.size() - 1, -1, -1):
		var status: StatusData.Status = statuses[status_index]
		if status.status_name != status_name:
			continue
		status.duration -= amount
		if status.duration <= 0:
			statuses.remove_at(status_index)
	entity.status = statuses

func _extinguish_fire_at(position: Vector2i) -> void:
	var fire_effect: Dictionary = _environment_effect(position)
	if _environment_kind(fire_effect) != "fire":
		return
	if bool(fire_effect.get("burns_terrain", false)):
		grid[position] = TerrainData.get_terrain(TerrainData.TileType.ASHES)
	environment.erase(position)

func _apply_seed_grenade_terrain(position: Vector2i, center: Vector2i, concentration: int, _enchantment: int) -> void:
	if position.x < 0 or position.x >= MAP_W or position.y < 0 or position.y >= MAP_H:
		return
	var tile: TerrainData.Terrain = grid[position]
	var adjusted_concentration: int = concentration
	if tile.terrain_name in ["puddle of urine", "mossy ground", "ashes"]:
		adjusted_concentration += 1
	elif tile.terrain_name == "snowy ground":
		adjusted_concentration -= 1
	if tile.terrain_name not in ["cave floor", "mossy ground", "ashes", "puddle of urine", "snow"]:
		return
	var in_shrub_zone: bool = maxi(absi(center.x - position.x), absi(center.y - position.y)) <= 1
	if in_shrub_zone and adjusted_concentration >= 3:
		grid[position] = TerrainData.get_terrain(TerrainData.TileType.SHRUB)
	else:
		grid[position] = TerrainData.get_terrain(TerrainData.TileType.MOSS)

func _apply_noise_grenade(_center: Vector2i, _radius: int, concentration: int, blast_position: Vector2i) -> void:
	if not creature.has(blast_position):
		return
	var noise_target: Creature = creature[blast_position]
	if noise_target is PlayerCreature or noise_target.health <= 0:
		return
	_make_creature_aware_of_player(noise_target)
	noise_target.time += 15 * concentration
	if noise_target != _player_entity:
		for turn_index: int in range(turn_queue.size() - 1, -1, -1):
			if turn_queue[turn_index] == noise_target:
				turn_queue.remove_at(turn_index)
		turn_queue.append(noise_target)
	apply_status_to_entity(noise_target, "Helpless", maxi(1, concentration))

func _broadcast_noise_awareness(center: Vector2i, radius: int) -> void:
	var alerted_entities: Array[Creature] = []
	for noise_target: Creature in creature.values():
		if noise_target is PlayerCreature or noise_target.health <= 0:
			continue
		if _creature_detection_distance(noise_target, center) > float(radius * 3):
			continue
		var player_visible: bool = _creature_player_visible(noise_target) and _creature_detection_distance(noise_target, player_pos) <= _creature_detection_maximum(noise_target)
		var is_inside_blast: bool = _creature_detection_distance(noise_target, center) <= float(radius)
		noise_target.detection_range = _creature_detection_maximum(noise_target)
		noise_target.sleeping_regen = false
		StatusData.remove_status(noise_target, "Sleeping")
		if not is_inside_blast:
			StatusData.remove_status(noise_target, "Helpless")
		if player_visible:
			noise_target.last_seen_player_pos = player_pos
			noise_target.alerted_player_pos = player_pos
			noise_target.awareness_mode = "aware"
		else:
			noise_target.last_seen_player_pos = center
			noise_target.alerted_player_pos = center
			noise_target.awareness_mode = "alerted"
		noise_target.last_seen_player_turn = noise_target.awareness_turn
		noise_target.behavior_mode = ""
		noise_target.behavior_turns_left = 0
		alerted_entities.append(noise_target)
	for alerted_entity: Creature in alerted_entities:
		if alerted_entity is PlayerCreature:
			continue
		for turn_index: int in range(turn_queue.size() - 1, -1, -1):
			if turn_queue[turn_index] == alerted_entity:
				turn_queue.remove_at(turn_index)
		turn_queue.append(alerted_entity)
	turn_queue.sort_custom(_sort_by_time)

func _throw_selected_item_at(target: Vector2i) -> void:
	_prepare_environment_turn(_player_entity)
	_player_entity.set_flag("_environment_turn_prepared")
	if _player_entity.health <= 0:
		_end_target_mode()
		return
	var inventory_index: int = throw_inventory_index
	if inventory_index < 0 or inventory_index >= PlayerData.inventory.size() or not is_in_view(target.x, target.y):
		return
	var projectile: Item = PlayerData.inventory[inventory_index]
	var range_limit: int = _throw_range(projectile)
	var distance: float = player_pos.distance_to(target)
	if distance > float(range_limit):
		_append_message("You can only throw %s in a range of %s." % [_item_dp(projectile, true), range_limit])
		return
	if not _clear_path_to(target):
		_append_message("There is no clear path to throw %s." % [_item_dp(projectile, true)])
		return
	var move_delay: int = _player_entity.move_speed
	var equipment_delay: int = _unequip_delay_for_item(inventory_index)
	projectile = _remove_inventory_item(inventory_index)
	throw_inventory_index = -1
	var is_grenade: bool = projectile.get_type() == "grenade"
	if is_grenade:
		projectile.identify_partially()
	_apply_action_statuses(_player_entity, "throw")
	var action_delay: int = _adjust_delay(_player_entity, move_delay + equipment_delay)
	var throw_path: Array[Vector2i] = _bresenham_line(player_pos, target)
	var grenade_effect: String = projectile.item_name.to_lower() if is_grenade else ""
	var grenade_enchantment: int = projectile.enchantment
	var grenade_radius: int = grenade_enchantment + 4 if is_grenade else 0
	if is_grenade:
		_play_sound("grenade" if grenade_enchantment == 0 else "grenade_e")
	await _animate_throw_effect(throw_path, projectile, target, grenade_radius, (projectile as Grenade).grenade_flash_color() if is_grenade else 15)
	if is_grenade:
		for blast_position in _get_circle(grenade_radius, target, true):
			if blast_position.x < 0 or blast_position.x >= MAP_W or blast_position.y < 0 or blast_position.y > MAP_H:
				continue
			var offset = Vector2i(absi(blast_position.x - target.x), absi(blast_position.y - target.y))
			var blast_distance := ceili(offset.y + offset.x / 2.0) if offset.max_axis_index() else ceili(offset.x + offset.y / 2.0)
			var concentration: int = maxi(1, grenade_radius - blast_distance)
			_make_creature_at_position_aware_of_player(blast_position)
			var terrain: TerrainData.Terrain = grid[blast_position]
			if grenade_effect == "seed":
				_apply_seed_grenade_terrain(blast_position, target, concentration, grenade_enchantment)
				continue
			match grenade_effect:
				"smoke":
					set_environment_effect(blast_position, "smoke", roundi(concentration * randf_range(2, 4)))
				"fire":
					set_environment_effect(blast_position, "fire", concentration * 5)
					if creature.has(blast_position):
						var blast_target: Creature = creature[blast_position]
						apply_status_to_entity(blast_target, "Burning", mini(5, concentration))
				"poison":
					if creature.has(blast_position):
						var poison_target: Creature = creature[blast_position]
						apply_status_to_entity(poison_target, "Poisoned", concentration * 5)
				"frost":
					_extinguish_fire_at(blast_position)
					if terrain.terrain_name == "puddle of urine":
						grid[blast_position] = TerrainData.get_terrain(TerrainData.TileType.SNOW)
					elif terrain.terrain_name == "shallow lake":
						grid[blast_position] = TerrainData.get_terrain(TerrainData.TileType.ICE)
					if creature.has(blast_position):
						var frost_target: Creature = creature[blast_position]
						_deal_damage(frost_target, concentration, "cold")
						if frost_target.health > 0:
							apply_status_to_entity(frost_target, "Frozen", mini(5, concentration))
				"healing":
					if creature.has(blast_position):
						var healing_target: Creature = creature[blast_position]
						if healing_target.health > 0:
							_reduce_status_duration(healing_target, "Poisoned", concentration)
							if not healing_target.has_trait("No Regeneration"):
								var healing_amount: int = maxi(1, concentration + projectile.enchantment)
								_heal_entity(healing_target, healing_amount)
				"shattering":
					if terrain.terrain_name == "cave wall":
						grid[blast_position] = TerrainData.get_terrain(TerrainData.TileType.FLOOR)
						if not floor_tiles.has(blast_position):
							floor_tiles.append(blast_position)
				"holy":
					if creature.has(blast_position):
						if creature[blast_position].has_trait("Holy"):
							if creature[blast_position].health <= 0:
								return
							var healing_amount: int = maxi(1, concentration + grenade_enchantment)
							_heal_entity(creature[blast_position], healing_amount)
						elif creature[blast_position].category == CreatureData.CreatureCategory.UNHOLY:
							_deal_damage(creature[blast_position], (concentration + grenade_enchantment) * 2, "holy")
				"noise":
					if creature.has(blast_position) and (creature[blast_position] is PlayerCreature or _creature_detection_distance(creature[blast_position], target) <= float(grenade_radius)):
						var noise_target: Creature = creature[blast_position]
						noise_target.time += 15 * concentration
						apply_status_to_entity(noise_target, "Helpless", maxi(1, concentration))
		if grenade_effect == "noise":
			_broadcast_noise_awareness(target, grenade_radius)
		projectile.identify_partially()
		_append_message("You throw %s." % _item_dp(projectile, true))
		_advance_player_action(action_delay)
		return
	var hit: bool = false
	if projectile.get_type() == "projectile" and creature.has(target) and not creature[target] is PlayerCreature:
		var projectile_target: Creature = creature[target]
		var target_health_before: int = projectile_target.health
		hit = _resolve_attack(_player_entity, projectile_target, "throw %s at" % _item_dp(projectile, true), false, false, projectile)
		if hit:
			var damage_dealt: bool = projectile_target.health < target_health_before
			if damage_dealt and projectile.item_name.to_lower() == "poison dart" and projectile_target.health > 0:
				apply_status_to_entity(projectile_target, "Poisoned", projectile.poison_duration)
			_remove_defeated_creature(projectile_target)
	if not hit:
		var landing_position: Vector2i = _nearest_free_item_tile(target)
		if landing_position.x >= 0:
			item[landing_position] = projectile
			if visible_tiles.has(landing_position):
				_suppress_sighting_log_item_keys["%d:%d:%s" % [level, landing_position.x, str(landing_position.y)]] = true
			if landing_position == target:
				_append_message("You throw %s." % _item_dp(projectile, true))
			else:
				_append_message("%s lands nearby." % _item_dp(projectile, true).capitalize())
			_activate_altar_at(landing_position)
	_advance_player_action(action_delay)
	redraw_status.emit()

func _activation_recharge_for_type(item_type: String) -> int:
	if item_type == "wand":
		return maxi(1, PlayerData.wand_recharge_time)
	if item_type == "charm":
		return maxi(1, PlayerData.charm_recharge_time)
	return 0

func _apply_timed_activation_status(entity: Creature, status_name: String, duration: int) -> void:
	var status_was_active: bool = StatusData.has_status(entity, status_name)
	if duration <= 0 or not apply_status_to_entity(entity, status_name, duration) or status_was_active or not entity is PlayerCreature:
		return
	var statuses: Array = entity.status
	for index: int in range(statuses.size() - 1, -1, -1):
		var status: StatusData.Status = statuses[index]
		if status.status_name == status_name:
			break
	entity.status = statuses

func _apply_wand_effect(wand: Wand, target: Creature) -> void:
	_make_creature_aware_of_player(target)
	var enchantment: int = wand.enchantment
	var effect_name: String = wand.item_name.to_lower()
	match effect_name:
		"fire":
			_apply_timed_activation_status(target, "Burning", enchantment + 2)
		"frost":
			_deal_damage(target, ceili((enchantment + 1) / 2.0), "cold")
			if target.health > 0:
				_apply_timed_activation_status(target, "Frozen", floori(float(enchantment + 3) / 2.0))
		"fear":
			_apply_timed_activation_status(target, "Frightened", 2 * (enchantment + 2))
		"rage":
			_apply_timed_activation_status(target, "Quickened", enchantment + 2)
			_apply_timed_activation_status(target, "Enraged", enchantment + 2)
		"paralysis":
			var paralysis_delay: int = 9 * (enchantment + 2)
			target.time += paralysis_delay
			apply_status_to_entity(target, "Helpless", 1)
			turn_queue.sort_custom(_sort_by_time)
		"confusion":
			_apply_timed_activation_status(target, "Confused", 2 * (enchantment + 2))
		"repulsion":
			_repel_target_from_player(target, enchantment + 3)
		"transference":
			_apply_transference(target, maxi(1, 1 + enchantment) * 40)
		"blinding":
			_apply_timed_activation_status(target, "Blind", enchantment + 3)

func _remove_transference_link_for_entity(entity: Creature) -> void:
	for link_id: int in _transference_links.keys():
		var linked_entities: Dictionary = _transference_links[link_id]
		if entity == linked_entities["player"] or entity == linked_entities["target"]:
			_transference_links.erase(link_id)
			StatusData.remove_status(linked_entities["player"], "Transference")
			StatusData.remove_status(linked_entities["target"], "Transference")

func _apply_transference(target: Creature, duration: int) -> void:
	if target.health <= 0 or duration <= 0:
		return
	_remove_transference_link_for_entity(_player_entity)
	_remove_transference_link_for_entity(target)
	var transference_id: int = _next_transference_id
	_next_transference_id += 1
	_apply_timed_activation_status(_player_entity, "Transference", duration)
	_apply_timed_activation_status(target, "Transference", duration)
	for entity: Creature in [_player_entity, target]:
		for status: StatusData.Status in entity.status:
			if status.status_name == "Transference":
				status.id = transference_id
	_transference_links[transference_id] = {"player": _player_entity, "target": target, "expires_at": maxf(float(environment_time), _player_entity.time) + duration}

func _repel_target_from_player(target: Creature, distance: int) -> void:
	if distance <= 0 or target.health <= 0:
		return
	var origin: Vector2i = target.pos
	var direction: Vector2i = Vector2i(signi(origin.x - player_pos.x), signi(origin.y - player_pos.y))
	if direction == Vector2i.ZERO:
		return
	var moved_count: int = 0
	var blocked_count: int = 0
	var did_collide: bool = false
	var opposing_creature: Creature
	for _step: int in range(distance):
		var next_position: Vector2i = target.pos + direction
		if next_position.x < 0 or next_position.x >= MAP_W or next_position.y < 0 or next_position.y >= MAP_H:
			blocked_count = distance - moved_count
			did_collide = true
			break
		if next_position == stairs_up_pos or next_position == stairs_down_pos:
			blocked_count = distance - moved_count
			did_collide = true
			break
		var next_tile: TerrainData.Terrain = grid[next_position]
		if not next_tile.passable:
			blocked_count = distance - moved_count
			did_collide = true
			break
		if creature.has(next_position):
			opposing_creature = creature[next_position]
			blocked_count = distance - moved_count
			did_collide = true
			break
		creature.erase(target.pos)
		target.pos = next_position
		creature[next_position] = target
		moved_count += 1
	var collision_damage: int = mini(moved_count, blocked_count) if did_collide else 0
	if collision_damage > 0:
		if opposing_creature:
			var other_damage: int = floori((collision_damage) / 2.0)
			var target_damage: int = ceili((collision_damage) / 2.0)
			_deal_damage(target, target_damage, "physical")
			_deal_damage(opposing_creature, other_damage, "physical")
		else:
			_deal_damage(target, collision_damage, "physical")
	if target.health <= 0:
		_remove_defeated_creature(target)
	if opposing_creature != null and opposing_creature.health <= 0:
		_remove_defeated_creature(opposing_creature)

func _activate_charm_effect(charm: Charm) -> void:
	var enchantment: int = charm.enchantment
	var effect_name: String = charm.item_name.to_lower()
	match effect_name:
		"sight":
			_apply_timed_activation_status(_player_entity, "Cat-eyed", 3 * (enchantment + 4))
		"healing":
			_heal_entity(_player_entity, enchantment + 1)
		"haste":
			_apply_timed_activation_status(_player_entity, "Quickened", enchantment + 3)
		"invisibility":
			_apply_timed_activation_status(_player_entity, "Invisible", enchantment + 3)
		"detection":
			_reveal_random_unseen_tiles(4 * (4 + enchantment))
		"stoneskin":
			_apply_timed_activation_status(_player_entity, "Protection", 2 * (enchantment + 2))
		"magic":
			_reduce_other_activation_cooldowns(PlayerData.inventory.find(charm), 20 * (enchantment + 1))
		"teleportation":
			_teleport_player_randomly(10 * (enchantment + 1))
		"repulsion":
			_repel_nearby_creatures(enchantment)
	_append_message("You activate %s." % _item_dp(charm, true))

func _repel_nearby_creatures(enchantment: int) -> void:
	var radius: int = 1 + floori((enchantment + 1) / 2.0)
	var repulsion_range: int = 1 + floori(enchantment / 2.0)
	var targets: Array[Creature] = []
	for target: Creature in creature.values():
		if target is PlayerCreature or target.health <= 0:
			continue
		if maxi(absi(target.pos.x - player_pos.x), absi(target.pos.y - player_pos.y)) <= radius:
			targets.append(target)
	for target: Creature in targets:
		_make_creature_aware_of_player(target)
		_repel_target_from_player(target, repulsion_range)
	if not targets.is_empty():
		_append_message("A force repels the creatures around you.")

func _reveal_random_unseen_tiles(maximum_count: int) -> void:
	if maximum_count <= 0:
		return
	var prioritized_tiles: Array[Vector2i] = []
	var other_tiles: Array[Vector2i] = []
	for y: int in range(MAP_H):
		for x: int in range(MAP_W):
			var position: Vector2i = Vector2i(x, y)
			if seen_tiles.has(position):
				continue
			if creature.has(position) or item.has(position):
				prioritized_tiles.append(position)
			else:
				other_tiles.append(position)
	prioritized_tiles.shuffle()
	other_tiles.shuffle()
	var candidates: Array[Vector2i] = prioritized_tiles + other_tiles
	var reveal_count: int = mini(maximum_count, candidates.size())
	for index: int in range(reveal_count):
		_remember_current_tile(candidates[index])
	redraw.emit()

func _remember_current_tile(position: Vector2i) -> void:
	seen_tiles[position] = true
	tile_last_seen[position] = grid[position]
	var remembered_char: String = tile_last_seen[position].glyph
	var remembered_fg: int = tile_last_seen[position].fg
	var remembered_bg: int = tile_last_seen[position].bg
	if creature.has(position):
		var entity: Creature = creature[position]
		remembered_char = str(entity.glyph)
		remembered_fg = int(entity.color)
	elif item.has(position):
		var ground_item: Item = item[position]
		remembered_char = str(ground_item.glyph)
		remembered_fg = int(ground_item.color)
	char_last_seen[position] = remembered_char
	fg_last_seen[position] = darken(remembered_fg)
	bg_last_seen[position] = darken(remembered_bg)
	var description: String = ""
	if creature.has(position):
		description = "You remember seeing %s." % _creature_dp(creature[position], false)
	elif item.has(position):
		description = "You remember seeing %s." % _item_dp(item[position], false)
	else:
		var determiner = tile_last_seen[position].determiner
		description = "You remember seeing %s%s%s." % [determiner, " " if determiner else "", tile_last_seen[position].terrain_name]
	if not description.is_empty():
		desc_last_seen[position] = description

func _reduce_other_activation_cooldowns(charm_inventory_index: int, reduction: int) -> void:
	if reduction <= 0:
		return
	var current_time: float = _player_entity.time
	for inventory_index: int in range(PlayerData.inventory.size()):
		if inventory_index == charm_inventory_index:
			continue
		var inventory_item: Item = PlayerData.inventory[inventory_index]
		var item_type: String = inventory_item.get_type()
		if item_type != "wand" and item_type != "charm":
			continue
		inventory_item.cooldown = maxf(current_time, float(inventory_item.cooldown) - float(reduction))

func _teleport_player_randomly(radius: int) -> void:
	_prepare_environment_turn(_player_entity)
	_player_entity.set_flag("_environment_turn_prepared")
	if _player_entity.health <= 0:
		return
	var candidates: Array[Vector2i] = []
	var unseen_candidates: Array[Vector2i] = []
	var radius_squared: int = maxi(0, radius) * maxi(0, radius)
	for y: int in range(MAP_H):
		for x: int in range(MAP_W):
			var position: Vector2i = Vector2i(x, y)
			if position == player_pos or player_pos.distance_squared_to(position) > radius_squared:
				continue
			var tile: TerrainData.Terrain = grid[position]
			if position == stairs_up_pos or position == stairs_down_pos or _is_hazardous_for_creature(_player_entity, tile) or not tile.passable or creature.has(position) or item.has(position):
				continue
			candidates.append(position)
			if not _is_visible_to_any_creature(position):
				unseen_candidates.append(position)
	if candidates.is_empty():
		_append_message("The charm cannot find a place to take you.")
		return
	var destination: Vector2i = unseen_candidates.pick_random() if not unseen_candidates.is_empty() else candidates.pick_random()
	_snapshot_visible_state()
	creature.erase(player_pos)
	player_pos = destination
	_player_entity.pos = destination
	creature[destination] = _player_entity

func _is_visible_to_any_creature(position: Vector2i) -> bool:
	if visible_tiles.has(position):
		return true
	for entity: Creature in creature.values():
		var entity_visible_tiles: Dictionary = entity.visible_tiles
		if entity_visible_tiles.has(position):
			return true
	return false

func _begin_item_activation(inventory_index: int) -> void:
	_prepare_environment_turn(_player_entity)
	_player_entity.set_flag("_environment_turn_prepared")
	if _player_entity.health <= 0:
		return
	if inventory_index < 0 or inventory_index >= PlayerData.inventory.size():
		return
	var selected_item: Item = PlayerData.inventory[inventory_index]
	var item_type: String = selected_item.get_type()
	if item_type not in ["wand", "charm"]:
		_append_message("You cannot activate that item.")
		return
	if not is_player_turn or processing_turns:
		_append_message("You must wait for your turn to activate an item.")
		activate_item_selection_active = false
		return
	var current_time: float = _player_entity.time
	var ready_at: float = selected_item.cooldown
	if current_time < ready_at:
		if selected_item.get_id_status() == ItemData.ID_STATUS.FULL_ID:
			var turn_length: int = maxi(1, _player_entity.move_speed)
			var turns_remaining: int = ceili((ready_at - current_time) / float(turn_length))
			_append_message("%s is still recharging (%d turns remaining)." % [_item_dp(selected_item, true).capitalize(), turns_remaining])
		else:
			_append_message("%s is still recharging." % [_item_dp(selected_item, true).capitalize()])
			_spend_player_action_delay(_player_entity.move_speed, "activate")
		activate_item_selection_active = false
		redraw_status.emit()
		return
	if item_type == "wand":
		_begin_wand_target_mode(inventory_index)
		return
	selected_item.cooldown = current_time + _activation_recharge_for_type(item_type)
	selected_item.identify_partially()
	if item_type == "charm":
		selected_item.record_identification_progress(1, 10)
		_play_sound("spell1")
	_activate_charm_effect(selected_item)
	activate_item_selection_active = false
	_spend_player_action_delay(_player_entity.move_speed, "activate")

func _activate_selected_wand_at(target: Vector2i) -> void:
	_prepare_environment_turn(_player_entity)
	_player_entity.set_flag("_environment_turn_prepared")
	if _player_entity.health <= 0:
		_end_target_mode()
		return
	var inventory_index: int = activate_inventory_index
	if inventory_index < 0 or inventory_index >= PlayerData.inventory.size():
		_end_target_mode()
		return
	if not is_in_view(target.x, target.y) or not visible_tiles.has(target) or not creature.has(target):
		_append_message("You must target a visible creature.")
		return
	if not _clear_path_to(target):
		_append_message("There is no clear path to wave your wand at the target.")
		return
	var target_entity: Creature = creature[target]
	if target_entity is PlayerCreature or target_entity.health <= 0 or StatusData.has_status(target_entity, "Invisible"):
		_append_message("You must target a visible creature.")
		return
	var selected_item: Item = PlayerData.inventory[inventory_index]
	if selected_item.get_type() != "wand":
		_end_target_mode()
		return
	var current_time: float = _player_entity.time
	if current_time < selected_item.cooldown:
		_append_message("%s is still recharging." % _item_dp(selected_item, true).capitalize())
		_end_target_mode()
		return
	if not is_player_turn or processing_turns:
		return
	selected_item.cooldown = current_time + _activation_recharge_for_type("wand")
	selected_item.identify_partially()
	selected_item.record_identification_progress(1, 20)
	_play_sound("spell2")
	_apply_wand_effect(selected_item, target_entity)
	_append_message("You wave %s at %s." % [_item_dp(selected_item, true), _creature_dp(target_entity, true)])
	_end_target_mode()
	_spend_player_action_delay(_player_entity.move_speed, "activate")

func _handle_item_selection_input(event: InputEventKey) -> bool:
	if not event.pressed or event.echo:
		return false
	if event.is_action_pressed("abort"):
		equip_selection_active = false
		drop_selection_active = false
		throw_item_selection_active = false
		activate_item_selection_active = false
		redraw_status.emit()
		return true
	var inventory_index: int = _inventory_index_from_key(event)
	if inventory_index < 0 or inventory_index >= PlayerData.inventory.size():
		return true
	if equip_selection_active:
		_equip_inventory_item(inventory_index)
	elif drop_selection_active:
		_drop_inventory_item(inventory_index)
	elif throw_item_selection_active:
		_begin_throw_target_mode(inventory_index)
	elif activate_item_selection_active:
		_begin_item_activation(inventory_index)
	return true

func _input(event: InputEvent) -> void:
	if not _is_active_map:
		return
	if _entity_is_paralyzed(_player_entity) and event is InputEventKey and event.pressed:
		_apply_action_statuses(_player_entity, "wait")
		_advance_player_action(_adjust_delay(_player_entity, _player_entity.move_speed))
		get_viewport().set_input_as_handled()
		return
	if inspect_item_selection_active:
		if event is InputEventKey:
			_handle_inspect_item_selection(event)
			get_viewport().set_input_as_handled()
		return
	if equip_selection_active or drop_selection_active or throw_item_selection_active or activate_item_selection_active:
		if event is InputEventKey:
			_handle_item_selection_input(event)
			get_viewport().set_input_as_handled()
		return
	if look_mode or throw_target_mode or wand_target_mode:
		if event is InputEventKey and event.pressed and not event.echo:
			_handle_target_mode_input(event)
			get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey or not event.pressed:
		return
	if event.is_action_pressed("activate"):
		show_inventory = true
		activate_item_selection_active = true
		redraw_status.emit()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("equip"):
		show_inventory = true
		equip_selection_active = true
		redraw_status.emit()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("drop"):
		show_inventory = true
		drop_selection_active = true
		redraw_status.emit()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("throw"):
		show_inventory = true
		throw_item_selection_active = true
		redraw_status.emit()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("look"):
		_begin_look_mode()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("inventory_toggle"):
		show_inventory = !show_inventory
		if not show_inventory:
			_reset_inspect_mode()
		redraw_status.emit()
		return
	if not is_player_turn or processing_turns:
		return
	_reset_inspect_mode()
	if event.is_action_pressed("rest"):
		_rest_player()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("attack_action"): 
		cancel_auto_walk()
		if not _attack_adjacent_enemy():
			_append_message("There is no adjacent enemy to attack.")
		get_viewport().set_input_as_handled()
		return
	var direction: Vector2i = _movement_direction(event)
	var dx: int = direction.x
	var dy: int = direction.y
	if (dx != 0 or dy != 0) and event.is_action_pressed("stand"):
		return
	if direction == Vector2i.ZERO and not event.is_action_pressed("stand"):
		return
	if dx != 0 or dy != 0:
		cancel_auto_walk()
	var move_cost: int = _player_entity.move_speed
	if direction == Vector2i.ZERO:
		move_cost = _player_entity.attack_speed
	if move_player(direction.x, direction.y, move_cost):
		_process_npc_turns()

func _has_visible_enemy() -> bool:
	for visible_position: Vector2i in visible_tiles:
		if not creature.has(visible_position):
			continue
		var visible_creature: Creature = creature[visible_position]
		if visible_creature is PlayerCreature or StatusData.has_status(visible_creature, "Invisible"):
			continue
		return true
	return false

func _rest_statuses_expired(initial_status_names: Array[String]) -> bool:
	for status_name: String in initial_status_names:
		if StatusData.has_status(_player_entity, status_name):
			return false
	return true

func _rest_player() -> void:
	if not _player_entity or not is_player_turn or processing_turns:
		return
	cancel_auto_walk()
	_reset_inspect_mode()
	var initial_health: int = _player_entity.health
	var maximum_health: int = _player_entity.max_health
	var started_injured: bool = initial_health < maximum_health
	var initial_status_names: Array[String] = []
	for status: StatusData.Status in _player_entity.status:
		var status_name: String = status.status_name
		if not status_name.is_empty() and not initial_status_names.has(status_name):
			initial_status_names.append(status_name)
	_resting = true
	_rest_took_damage = false
	_rest_reached_full_health = false
	_player_entity.set_flag("_rest_started_injured", started_injured)
	_recompute_all_fov()
	var stop_reason: String = "a long time has passed"
	var turns_resting: int = 0
	if _has_visible_enemy():
		stop_reason = "an enemy came into view"
	else:
		for _rest_turn: int in range(REST_MAX_TURNS):
			if not is_player_turn or processing_turns or _player_entity.health <= 0:
				break
			_spend_player_action_delay(_player_entity.move_speed, "wait")
			turns_resting += 1
			if _rest_took_damage:
				stop_reason = "you took damage"
				break
			if started_injured and _rest_reached_full_health:
				stop_reason = "you are fully healed"
				break
			if _has_visible_enemy():
				stop_reason = "an enemy came into view"
				break
			if not initial_status_names.is_empty() and _rest_statuses_expired(initial_status_names):
				stop_reason = "your conditions wore off"
				break
	_resting = false
	_player_entity.set_flag("_rest_started_injured", false)
	_recompute_all_fov()
	if _player_entity.health > 0:
		_append_message("You stop resting because %s." % stop_reason + (" (%d turns)." % turns_resting if stop_reason == "the time limit" else ""))
	redraw.emit()

func get_tile(x: int, y: int) -> TerrainData.Terrain:
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return null
	return grid[Vector2i(x, y)]

func get_render_cell_data(position: Vector2i, render_data: Array) -> void:
	if render_data.size() != 4:
		render_data.resize(4)
	var tile: TerrainData.Terrain = grid[position]
	var foreground: int = 0
	var background: int = 0
	var display_char: String = " "
	if transient_visuals.has(position) and visible_tiles.has(position):
		var transient_visual: Dictionary = transient_visuals[position]
		foreground = int(transient_visual.get("fg", 15))
		background = int(transient_visual.get("bg", 0))
		display_char = str(transient_visual.get("char", "*"))
	elif seen_tiles.has(position):
		if visible_tiles.has(position):
			background = tile.bg
			var environment_background: int = _environment_color(position)
			if environment_background >= 0:
				background = environment_background
			if creature.has(position) and (creature[position] is PlayerCreature or not StatusData.has_status(creature[position], "Invisible")):
				var creature_data: Creature = creature[position]
				foreground = int(creature_data.color)
				display_char = str(creature_data.glyph)
			elif item.has(position):
				var item_obj: Item = item[position]
				foreground = item_obj.color
				display_char = str(item_obj.glyph)
			else:
				foreground = tile.fg
				display_char = tile.glyph
		else:
			foreground = int(fg_last_seen.get(position, 0))
			background = int(bg_last_seen.get(position, 0))
			display_char = str(char_last_seen.get(position, " "))
	render_data[0] = tile
	render_data[1] = foreground
	render_data[2] = background
	render_data[3] = display_char

func is_in_view(x: int, y: int) -> bool:
	return x >= VIEW_X and x < VIEW_X + VIEW_W and y >= VIEW_Y and y < VIEW_Y + VIEW_H

func _is_seen(x: int, y: int) -> bool:
	return Vector2i(x, y) in seen_tiles

func _is_visible(x: int, y: int) -> bool:
	return Vector2i(x, y) in visible_tiles

func get_display_char(x: int, y: int) -> String:
	if not is_in_view(x, y):
		return " "
	var pos := Vector2i(x, y)
	if StatusData.has_status(_player_entity, "Blind") and player_pos.distance_to(pos) > 1.0:
		return " "
	if not _is_visible(pos.x, pos.y) and not _is_seen(pos.x, pos.y):
		return " "
	if creature.has(pos) and not creature[pos] is PlayerCreature and StatusData.has_status(creature[pos], "Invisible"):
		return grid[pos].glyph
	# Fog of war: never seen tiles are blank (including creatures/items)
	if not _is_seen(x, y):
		return " "
	# Seen but not currently visible: show darkened last seen state
	if not _is_visible(x, y):
		return char_last_seen.get(pos, " ")
	# Fully visible: check creatures and items first
	if pos in creature:
		if not creature[pos] is PlayerCreature and StatusData.has_status(creature[pos], "Invisible"):
			return grid[pos].glyph
		return creature[pos].glyph
	if pos in item:
		return item[pos].glyph
	return grid[pos].glyph

func darken(color: int) -> int:
	return 8 if color == 15 or color == 7 else color % 8

func get_fg_color(x: int, y: int) -> int:
	if not is_in_view(x, y):
		return 0
	var pos := Vector2i(x, y)
	if StatusData.has_status(_player_entity, "Blind") and player_pos.distance_to(pos) > 1.0:
		return 0
	if not _is_seen(x, y):
		return 0
	# Fog of war: never seen tiles are blank
	if not _is_seen(x, y):
		return 0
	# Seen but not currently visible: darken
	if not _is_visible(x, y):
		return fg_last_seen.get(pos, 0)
	# Fully visible: check creatures and items first
	if pos in creature:
		if not creature[pos] is PlayerCreature and StatusData.has_status(creature[pos], "Invisible"):
			return grid[pos].fg
		return int(creature[pos].color)
	if pos in item:
		return int(item[pos].color)
	return grid[pos].fg

func get_bg_color(x: int, y: int) -> int:
	if not is_in_view(x, y):
		return 0
	var pos := Vector2i(x, y)
	if StatusData.has_status(_player_entity, "Blind") and player_pos.distance_to(pos) > 1.0:
		return 0
	if not _is_seen(x, y):
		return 0
	if _is_visible(x, y):
		var environment_background: int = _environment_color(pos)
		if environment_background >= 0:
			return environment_background
	var bg: int = grid[pos].bg
	# Fog of war: never seen tiles are blank
	if not _is_seen(x, y):
		return 0
	# Seen but not currently visible: darken
	if not _is_visible(x, y):
		return bg_last_seen.get(pos, 0)
	# Fully visible
	return bg

func _remembered_hover_text(pos: Vector2i) -> String:
	var remembered_description: String = str(desc_last_seen.get(pos, ""))
	if not remembered_description.is_empty():
		return remembered_description
	if not tile_last_seen.has(pos):
		return ""
	var remembered_tile: TerrainData.Terrain = tile_last_seen[pos]
	if not remembered_tile.terrain_name:
		return ""
	var determiner = remembered_tile.determiner
	return "You remember seeing %s%s%s." % [determiner, " " if determiner else "", remembered_tile.terrain_name]

func get_hover_text(x: int, y: int, member: bool = false) -> String:
	var description: String = _get_hover_text_base(x, y, member)
	if description.is_empty() or not is_in_view(x, y):
		return description
	var position: Vector2i = Vector2i(x, y)
	if not visible_tiles.has(position) or not _environment_visible(position):
		return description
	var effect_type: String = _environment_kind(_environment_effect(position))
	var effect_description: String = ""
	match effect_type:
		"steam":
			effect_description = "Steam billows through the area."
		"smoke":
			effect_description = "Smoke fills the area."
		"fire":
			effect_description = "Flames consume the area."
	if effect_description.is_empty():
		return description
	return description + " " + effect_description

func _get_hover_text_base(x: int, y: int, member: bool = false) -> String:
	var pos: Vector2i = Vector2i(x, y)
	if not is_in_view(x, y) or not _is_seen(x, y):
		return ""
	if not visible_tiles.has(pos) and not tile_last_seen.has(pos):
		return ""
	var vision_context: Dictionary = {"sight_range": _player_entity.sight_range}
	StatusData.trigger(_player_entity, StatusData.EffectType.VISION, vision_context)
	var observer_distance: float = player_pos.distance_to(pos)
	if observer_distance > float(vision_context.get("sight_range", 10)):
		return _remembered_hover_text(pos)
	if StatusData.has_status(_player_entity, "Blind") and observer_distance > 1.0:
		return ""
	if not _is_visible(x, y):
		return _remembered_hover_text(pos)
	if creature.has(pos) and not creature[pos] is PlayerCreature and StatusData.has_status(creature[pos], "Invisible"):
		return ""
	var has_creature: bool = pos in creature
	var has_item: bool = pos in item
	var tile: TerrainData.Terrain = grid[pos]
	if has_creature or has_item:
		var parts: Array[String] = []
		if has_creature:
			if creature[pos] is PlayerCreature:
				return "You are here."
			parts.append(_creature_dp(creature[pos], false))
			if not member:
				parts[parts.size() - 1] += " (which " + CreatureData.get_behavior_state_description(creature[pos]) + ")"
		if has_item:
			var item_name: String = _item_dp(item[pos], false)
			parts.append(item_name + " %s the %s" % ["in" if tile.contains else "on", tile.terrain_name])
		if member:
			return "You remember seeing %s." % ", and ".join(parts)
		return "You see %s." % ", and ".join(parts)
	if tile.terrain_name != "":
		var determiner = tile.determiner
		var terrain_name = tile.terrain_name
		return "You " + ("remember seeing" if member else "see") + " %s%s%s." % [determiner, " " if determiner else "", terrain_name]
	return ""

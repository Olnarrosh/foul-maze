class_name CreatureData
extends Node

# Creature categories determine traits, resistances, and gameplay behavior.
# HUMANOID: Goblins, humans, etc. - can use items, have intelligence
# ANIMAL: Creatures - beasts, monsters, etc.
# UNHOLY: Undead, demons, etc. - resistant to poison, often have special traits
enum CreatureCategory {
	HUMANOID,
	ANIMAL,
	UNHOLY,
}

# Creature definitions in this array define all enemy and creature types.
# Each dictionary contains: name, char, danger level, clustering, colors,
# movement/attack stats, sight range, health/damage/armor/accuracy/evasion,
# creature category, traits, resistances, attack strings, and biomes.
# Traits correspond to the has_trait() method on Creature class.
# Biomes match Map.Biome enum values.
const creatures: Array[Dictionary] = [
	{name="goblin", char="G", cluster=4, danger=4, fg=13, move_speed=20, attack_speed=20, sight_range=10, health=5, damage=2, armor=0, accuracy=50, evasion=3, category=CreatureCategory.HUMANOID, traits=["Coward"], desc="A distant relative of the Orc, a Goblin is considerably smaller, weaker, and hairier.", attack_str=["shivs", "shanks", "slashes", "cuts", "bites"], biomes=[Map.Biome.CAVE, Map.Biome.TOWN, Map.Biome.FOREST, Map.Biome.COLOSSAL]},
	{name="rat", char="r", danger=1, cluster=4, fg=15, move_speed=25, attack_speed=20, sight_range=8, health=1, damage=1, armor=0, accuracy=80, evasion=8, category=CreatureCategory.ANIMAL, desc="A large and aggressive rodent.", attack_str=["bites", "gnaws", "scratches"], biomes=[Map.Biome.CAVE, Map.Biome.WATER, Map.Biome.FOREST, Map.Biome.COLOSSAL]},
	{name="zombie", char="Z", danger=4, fg=9, move_speed=40, attack_speed=40, sight_range=10, health=7, damage=3, armor=0, accuracy=40, evasion=0, category=CreatureCategory.UNHOLY, desc="A sloppily necromantized, slow-moving corpse.", attack_str=[], traits=["Mindless", "No Regeneration"], resistances=["poison"], biomes=[Map.Biome.ROOMS, Map.Biome.SLIME]},
	{name="vampyre bat", char="V", cluster=5, danger=6, fg=8, move_speed=10, attack_speed=15, sight_range=15, health=3, damage=2, armor=0, accuracy=60, evasion=7, category=CreatureCategory.ANIMAL, traits=["Flying", "Flitting", "Draining"], desc="A large, bloodsucking bat.", biomes=[Map.Biome.CAVE, Map.Biome.WATER, Map.Biome.ROOMS]},
	{name="abomination", char="A", danger=44, fg=13, move_speed=20, attack_speed=20, sight_range=10, health=30, damage=10, armor=0, accuracy=100, evasion=0, category=CreatureCategory.UNHOLY, desc="A demonic, ever-shifting mass of claws, tentacles, and scales.", attack_str=["whips", "claws", "rips", "tears", "brutalizes"], traits=["Quick Regeneration"], biomes=[Map.Biome.FIRE, Map.Biome.ICE, Map.Biome.COLOSSAL]},
	{name="basilisk", char="B", danger=35, fg=9, move_speed=20, attack_speed=20, sight_range=10, health=15, damage=7, armor=2, accuracy=70, evasion=1, category=CreatureCategory.ANIMAL, desc="A large lizard said to be able to turn people to stone if it stares at them for long enough.", attack_str=["bites", "strikes", "gazes at"], traits=["Paralyzing"], biomes=[Map.Biome.CAVE, Map.Biome.FOREST, Map.Biome.ICE, Map.Biome.FIRE]},
	{name="imp", char="i", danger=15,  fg=11, move_speed=20, attack_speed=20, sight_range=10, health=10, damage=5, armor=0, accuracy=80, evasion=8, category=CreatureCategory.HUMANOID, desc="A thieving, sorcerous trickster.", attack_str=[], traits=["Blinking", "Thief"], biomes=[Map.Biome.CAVE, Map.Biome.FIRE]},
	{name="frost wyrm", char="F", danger=40, fg=14, move_speed=20, attack_speed=20, sight_range=10, health=50, damage=12, armor=8, accuracy=70, evasion=0, category=CreatureCategory.ANIMAL, desc="An ice-breathing dragon with thick, icy scales.", attack_str=["ices", "bites", "claws"], traits=["Cold Breath", "Flying"], resistances=["cold"], biomes=[Map.Biome.ICE]},
	{name="goblin shaman", char="G", danger=6, cluster=4, fg=14, move_speed=20, attack_speed=20, sight_range=10, health=4, damage=2, armor=0, accuracy=50, evasion=3, category=CreatureCategory.HUMANOID, traits=["Coward"], desc="A goblin with a staff, wearing what seems to be some sort of ceremonial garb.", attack_str=["beats", "smashes", "clobbers"], biomes=[Map.Biome.CAVE, Map.Biome.TOWN, Map.Biome.FOREST]},
	{name="goblin necromancer", char="G", danger=12, cluster=4, fg=7, move_speed=20, attack_speed=20, sight_range=10, health=4, damage=2, armor=0, accuracy=50, evasion=3, category=CreatureCategory.HUMANOID, traits=["Coward", "Necromancer"], desc="A goblin with an ornate dagger, wearing a grey robe and a helmet made from a humanoid skull.", attack_str=["shivs", "shanks", "slashes", "cuts", "sacrifices"], biomes=[Map.Biome.TOWN]},
	{name="wyvern", char="W", fg=9, danger=28, cluster=2, move_speed=20, attack_speed=20, sight_range=10, health=12, damage=5, armor=1, accuracy=60, evasion=5, category=CreatureCategory.ANIMAL, desc="A venomous flying lizard.", attack_str=["bites"], traits=["Flying", "Venomous"], biomes=[Map.Biome.CAVE, Map.Biome.FOREST, Map.Biome.FIRE, Map.Biome.COLOSSAL]},
	{name="wolf", char="w", fg=7, cluster=6, danger=5, move_speed=20, attack_speed=20, sight_range=12, health=4, damage=3, armor=0, accuracy=60, evasion=2, category=CreatureCategory.ANIMAL, desc="A gray-furred pack hunter.", attack_str=["bites", "claws"], biomes=[Map.Biome.CAVE, Map.Biome.WATER, Map.Biome.FOREST, Map.Biome.COLOSSAL]},
	{name="skeleton", char="S", fg=15, danger=5, move_speed=20, attack_speed=20, sight_range=10, health=6, damage=3, armor=2, accuracy=60, evasion=0, category=CreatureCategory.UNHOLY, desc="Walking bones, their flesh rotten away long since.", attack_str=[], traits=["Mindless", "No Regeneration"], resistances=["poison"], biomes=[Map.Biome.SLIME, Map.Biome.ROOMS]},
	{name="ogre", char="O", fg=10, danger=12, move_speed=20, attack_speed=40, sight_range=10, health=17, damage=10, armor=0, accuracy=40, evasion=0, category=CreatureCategory.HUMANOID, desc="A cannibalistic, ill-tempered giant. Its weapon is a rather unwieldy tree trunk.", attack_str=["clubs", "clobbers", "cudgels", "beats", "smashes"], biomes=[Map.Biome.CAVE, Map.Biome.TOWN]},
	{name="necrosavant", char="N", danger=20, fg=13, move_speed=20, attack_speed=20, sight_range=10, health=13, damage=4, armor=0, accuracy=80, evasion=1, category=CreatureCategory.UNHOLY, desc="An undead blood-mage.", attack_str=["slashes", "slices", "cuts", "bleeds"], traits=["Draining", "Blinking", "No Regeneration"], biomes=[Map.Biome.ROOMS]},
	{name="revenant", char="R", danger=17, fg=15, move_speed=20, attack_speed=20, sight_range=10, health=8, damage=6, armor=3, accuracy=60, evasion=1, category=CreatureCategory.UNHOLY, desc="A relatively lucid, armed walking corpse.", attack_str=[], traits=["No Regeneration"], resistances=["poison"], biomes=[Map.Biome.ROOMS, Map.Biome.ICE]},
	{name="leech lich", char="L", danger=30, fg=8, move_speed=20, attack_speed=20, sight_range=9, health=14, damage=6, armor=0, accuracy=80, evasion=2, category=CreatureCategory.UNHOLY, desc="The self-reanimated corpse of a huge, wormlike bloodsucker.", attack_str=["curses", "drains", "dooms"], traits=["No Regeneration", "Draining", "Weakening"], resistances=["poison"], biomes=[Map.Biome.SLIME, Map.Biome.ROOMS]},
	{name="viper", char="v", danger=5, fg=9, move_speed=20, attack_speed=20, sight_range=8, health=2, damage=2, armor=0, accuracy=60, evasion=5, category=CreatureCategory.ANIMAL, desc="A snake with a venomous bite.", attack_str=["bites"], traits=["Venomous"], biomes=[Map.Biome.CAVE, Map.Biome.WATER, Map.Biome.FOREST, Map.Biome.COLOSSAL, Map.Biome.ROOMS]},
	{name="fire wyrm", char="F", danger=40, fg=10, move_speed=20, attack_speed=20, sight_range=12, health=50, damage=10, armor=3, accuracy=90, evasion=0, category=CreatureCategory.ANIMAL, desc="A huge, fire-breathing dragon.", attack_str=["burns", "bites", "claws"], traits=["Fire Breath", "Flying"], resistances=["fire"], biomes=[Map.Biome.FIRE]},
	{name="troll", char="T", danger=18, fg=13, move_speed=20, attack_speed=20, sight_range=10, health=16, damage=5, armor=0, accuracy=70, evasion=0, category=CreatureCategory.HUMANOID, desc="Though not much larger than their Orc cousins, Trolls are considerably tougher and even more irascible.", attack_str=["claws", "bites", "strikes"], traits=["Quick Regeneration"], biomes=[Map.Biome.CAVE, Map.Biome.ICE, Map.Biome.FIRE, Map.Biome.FOREST]},
	{name="unicorn", char="Ù", danger=12, fg=15, move_speed=15, attack_speed=20, sight_range=15, health=12, damage=4, armor=0, accuracy=65, evasion=1, category=CreatureCategory.ANIMAL, desc="A one-horned horse. The holy animal of the forest god, and fiercely protective of his domain.", attack_str=["gores", "impales", "tramples"], traits=["Holy"], biomes=[Map.Biome.FOREST]},
	{name="monkey", char="M", danger=5, fg=10, move_speed=19, attack_speed=20, sight_range=10, health=4, damage=2, armor=0, accuracy=60, evasion=7, category=CreatureCategory.ANIMAL, desc="A nimble, mischievous animal.", attack_str=[], traits=["Thief"], biomes=[Map.Biome.FOREST, Map.Biome.CAVE, Map.Biome.WATER]},
	{name="eel", char="e", danger=8, fg=8, move_speed=15, attack_speed=15, sight_range=10, health=5, damage=3, armor=0, accuracy=75, evasion=4, category=CreatureCategory.ANIMAL, desc="A fish with sharp teeth and a snake-like body.", attack_str=["bites", "shocks"], traits=["Aquatic", "Flitting"], biomes=[Map.Biome.WATER]},
	{name="caustic slime", char="c", danger=14, fg=9, move_speed=30, attack_speed=20, sight_range=8, health=12, damage=5, armor=0, accuracy=50, evasion=0, category=CreatureCategory.ANIMAL, traits=["Corrosive", "Mindless"], resistances=["poison"], desc="An animate, highly alkaline sludge.", attack_str=["corrodes", "slimes", "drenches", "engulfs"], biomes=[Map.Biome.SLIME]},
	{name="bear", char="b", danger=22, fg=8, move_speed=20, attack_speed=20, sight_range=10, health=18, damage=11, armor=1, accuracy=60, evasion=0, category=CreatureCategory.ANIMAL, desc="A large, thick-furred predator.", attack_str=["mauls", "bites", "claws"], biomes=[Map.Biome.CAVE, Map.Biome.CAVE]},
	{name="shark", char="s", danger=16, fg=15, move_speed=20, attack_speed=20, sight_range=10, health=15, damage=7, armor=0, accuracy=75, evasion=2, category=CreatureCategory.ANIMAL, desc="", traits=["Aquatic"], attack_str=[], biomes=[Map.Biome.WATER]},
	{name="crocodile", char="C", danger=17, fg=9, move_speed=20, attack_speed=20, sight_range=10, health=11, damage=6, armor=1, accuracy=70, evasion=1, category=CreatureCategory.ANIMAL, desc="", traits=["Amphibious"], attack_str=[], biomes=[Map.Biome.WATER]},
	{name="phantom blade", char="†", danger=1, fg=13, move_speed=10, attack_speed=20, sight_range=20, health=1, damage=1, armor=0, accuracy=100, evasion=10, category=CreatureCategory.UNHOLY, desc="A shimmering, floating blade that seems to move and strike by itself.", traits=["Mindless", "Flying", "Ephemeral"], resistances=["poison"], attack_str=["slashes", "cuts", "stabs", "slices", "punctures", "hits", "strikes"], biomes=[]},
]

static func get_creatures_by_biome(biome: Map.Biome) -> Array[Dictionary]:
	var results = []
	for creature in creatures:
		if biome == Map.Biome.WATER_AND_FOREST:
			if Map.Biome.WATER in creature.biomes or Map.Biome.FOREST in creature.biomes:
				results.append(creature)
		elif biome in creature.biomes:
			results.append(creature)
	return results

static func get_creature_definition(index: int) -> Dictionary:
	return creatures[index].duplicate(true)

static func get_description(creature: Creature, player: PlayerCreature) -> String:
	var description: String = creature.description
	if description.is_empty():
		description = "A creature."
	var player_accuracy: int = player.accuracy
	var player_damage: int = player.damage
	var player_weapon: Weapon
	var weapon_ego: String = ""
	var weapon_enchantment: int = 0
	var player_inventory: Array = player.inventory
	var weapon_index: int = PlayerData.equipped_weapon
	if weapon_index >= 0 and weapon_index < player_inventory.size():
		player_weapon = player_inventory[weapon_index] as Weapon
		weapon_ego = player_weapon.ego
		weapon_enchantment = player_weapon.enchantment
		player_damage += weapon_enchantment
	var creature_evasion: int = creature.evasion
	var creature_armor: int = creature.armor
	var player_evasion: int = player.evasion
	var player_armor: int = player.armor
	if weapon_ego == "penetration":
		creature_armor = maxi(0, creature_armor - weapon_enchantment)
	var armor_index: int = PlayerData.equipped_armor
	if armor_index >= 0 and armor_index < player_inventory.size():
		var armor_item: Armor = player_inventory[armor_index]
		var armor_ego_name: String = armor_item.ego
		if armor_ego_name == "evasion":
			player_evasion += armor_item.enchantment
	var creature_helpless: bool = StatusData.has_status(creature, "Helpless")
	var player_helpless: bool = StatusData.has_status(player, "Helpless")
	var player_hit_probability: float = _hit_probability(player_accuracy, creature_evasion, creature_helpless)
	var creature_hit_probability: float = _hit_probability(creature.accuracy, player_evasion, player_helpless)
	var player_hits_to_kill: String = _format_attack_estimate(creature.health, player_damage, creature_armor, player_hit_probability)
	var creature_hits_to_kill_player: String = _format_attack_estimate(player.health, creature.damage, player_armor, creature_hit_probability)
	description += " You do %.1f damage to it with an average attack, and need about %s attacks to kill it." % [player_hit_probability * player_damage, player_hits_to_kill]
	description += " It does %.1f damage to you with an average attack, and would need about %s attacks to kill you." % [creature_hit_probability * creature.damage, creature_hits_to_kill_player]
	description += " " + _active_status_description(creature)
	return description

static func _hit_probability(accuracy: int, evasion: int, helpless: bool = false) -> float:
	if helpless:
		return 1.0
	return clampf(accuracy * 0.01 * pow(0.933033, evasion), 0.1, 1.0)

static func _average_attacks_to_kill(health: int, damage: int, armor: int, hit_probability: float) -> float:
	var attack_damage: int = maxi(1, damage)
	var armor_deflection: int = mini(maxi(0, armor), attack_damage - 1)
	var expected_damage_per_attack: float = float(attack_damage - armor_deflection) * hit_probability
	if expected_damage_per_attack <= 0.0:
		return INF
	return float(maxi(1, health)) / expected_damage_per_attack

static func _format_attack_estimate(health: int, damage: int, armor: int, hit_probability: float) -> String:
	var average_attacks: float = _average_attacks_to_kill(health, damage, armor, hit_probability)
	if is_inf(average_attacks):
		return "impossible"
	return str(ceili(average_attacks))

static func _active_status_description(creature: Creature) -> String:
	var active_statuses: Array[String] = []
	for status: StatusData.Status in creature.status:
		var status_name: String = status.status_name
		if status_name != "Sleeping":
			status_name += " (%d turns)" % status.duration
		active_statuses.append(status_name)
	if active_statuses.is_empty():
		return ""
	return "Status effects: %s." % ", ".join(active_statuses)

static func get_behavior_state_description(creature: EnemyCreature) -> String:
	if StatusData.has_status(creature, "Enraged"):
		return "is berserking"
	if StatusData.has_status(creature, "Frightened"):
		return "is afraid"
	if StatusData.has_status(creature, "Sleeping"):
		return "is sleeping"
	if creature.awareness_mode == "aware":
		return "has seen you"
	return "hasn't seen you yet"

class_name PlayerData
extends Node

enum Race {ORC, HUMAN, GNOME, DAR, BEASTMAN}
enum Stat {STRENGTH, DEXTERITY, INTELLIGENCE, CONSTITUTION}

static var player_race: Race = Race.GNOME
static var run_highest_level: int = 1
static var run_enemies_killed: int = 0

static func reset_run_stats() -> void:
	run_highest_level = 1
	run_enemies_killed = 0

static var wand_recharge_time: int = 400
static var charm_recharge_time: int = 1000
static var equipped_weapon: int = -1
static var equipped_armor: int = -1

static var stats: Dictionary = {
	Stat.STRENGTH: 1, Stat.DEXTERITY: 1, Stat.INTELLIGENCE: 1, Stat.CONSTITUTION: 1
}

static var racial_stats = {
	Race.BEASTMAN: {Stat.STRENGTH: 3},
	Race.DAR: {Stat.DEXTERITY: 3},
	Race.GNOME: {Stat.INTELLIGENCE: 3},
	Race.HUMAN: {Stat.CONSTITUTION: 3},
	Race.ORC: {Stat.STRENGTH: 1, Stat.DEXTERITY: 1, Stat.INTELLIGENCE: 1, Stat.CONSTITUTION: 1}
}

# Starting equipment: each entry is {type: "weapon"/"armor"/etc", name: subtype name}.
# The actual subtype dicts are resolved at runtime in init_player.
# Equipment is different per race - see the starting_equilibrium dictionary.
static var starting_equipment = {
	Race.BEASTMAN: [{"type": "weapon", "name": "shortsword"}],
	Race.DAR: [{"type": "weapon", "name": "dagger"}, {"type": "charm", "name": "haste"}],
	Race.GNOME: [{"type": "weapon", "name": "dagger"}, {"type": "wand", "name": "frost"}],
	Race.HUMAN: [{"type": "weapon", "name": "dagger"}, {"type": "armor", "name": "leather armor"}],
	Race.ORC: [{"type": "weapon", "name": "dagger"}, {"type": "projectile", "name": "throwing axe"}]
}

static func init_player(race: Race) -> PlayerCreature:
	# Initialize a new player creature of the given race.
	# Sets up stats, inventory, starting equipment, and class properties.
	# Returns a new PlayerCreature instance ready for play.
	player_race = race
	equipped_weapon = -1
	equipped_armor = -1
	stats = {
		Stat.STRENGTH: 1,
		Stat.DEXTERITY: 1,
		Stat.INTELLIGENCE: 1,
		Stat.CONSTITUTION: 1
	}
	# Recharge is measured in the same action-time units as player.time.
	wand_recharge_time = 400
	charm_recharge_time = 1000
	var player: PlayerCreature = PlayerCreature.new(Vector2i(0, 0))
	for stat: Stat in racial_stats[race]:
		change_stat(stat, racial_stats[race][stat], player)
	# Build starting inventory from starting_equipment
	for item_def in starting_equipment[race]:
		var type_str: String = item_def.type
		var name_str: String = item_def.name
		# Resolve the subtype dictionary from ItemData
		var subtypes: Array = ItemData.ITEM_SUBTYPES.get(type_str, [])
		var subtype = null
		for s in subtypes:
			if s.name == name_str:
				subtype = s
				break
		if not subtype:
			continue

		# Create the appropriate item instance via subclass constructor
		var item: Item = Item.create_from_subtype(type_str, subtype, 0)
		if item != null:
			item.identify_fully()
			player.inventory.append(item)
			# Auto-equip weapons and armor
			var idx: int = player.inventory.size() - 1
			if type_str == "weapon":
				equip_weapon(player, idx)
			elif type_str == "armor":
				equip_armor(player, idx)
	return player

static func change_stat(stat: Stat, change: int, player: PlayerCreature) -> void:
	var weapon_index: int = equipped_weapon
	var armor_index: int = equipped_armor
	if stat == Stat.STRENGTH and weapon_index >= 0:
		_unequip_weapon(player, weapon_index)
	if stat == Stat.CONSTITUTION and armor_index >= 0:
		_unequip_armor(player, armor_index)
	match stat:
		Stat.STRENGTH:
			pass
		Stat.DEXTERITY:
			player.accuracy += 5 * change
			player.acc_thrown += 10 * change
			player.evasion += change
		Stat.INTELLIGENCE:
			wand_recharge_time -= 25 * change
			charm_recharge_time -= 50 * change
		Stat.CONSTITUTION:
			player.max_health += change
			player.health += change
	stats[stat] = int(stats[stat]) + change
	if stat == Stat.STRENGTH and weapon_index >= 0:
		_equip_weapon(player, weapon_index)
	if stat == Stat.CONSTITUTION and armor_index >= 0:
		_equip_armor(player, armor_index)

static func equip_weapon(player: PlayerCreature, inventory_index: int) -> bool:
	var inventory: Array = player.inventory
	if inventory_index < 0 or inventory_index >= inventory.size():
		return false
	var weapon: Item = inventory[inventory_index]
	if weapon.get_type() != "weapon":
		return false
	if equipped_weapon == inventory_index:
		_unequip_weapon(player, equipped_weapon)
		return true
	if equipped_weapon >= 0:
		_unequip_weapon(player, equipped_weapon)
	_equip_weapon(player, inventory_index)
	return true

static func equip_armor(player: PlayerCreature, inventory_index: int) -> bool:
	var inventory: Array = player.inventory
	if inventory_index < 0 or inventory_index >= inventory.size():
		return false
	var armor: Item = inventory[inventory_index]
	if armor.get_type() != "armor":
		return false
	if equipped_armor == inventory_index:
		_unequip_armor(player, equipped_armor)
		return true
	if equipped_armor >= 0:
		_unequip_armor(player, equipped_armor)
	_equip_armor(player, inventory_index)
	return true

static func _weapon_ego_name(weapon: Item) -> String:
	if weapon.ego != null and weapon.ego != "":
		return str(weapon.ego).to_lower()
	return ""

static func _weapon_ego_bonus(weapon: Item, ego_name: String) -> int:
	if _weapon_ego_name(weapon) != ego_name:
		return 0
	return int(weapon.enchantment)

static func equipped_weapon_ego_bonus(player: PlayerCreature, ego_name: String) -> int:
	var weapon: Item = _inventory_item(player, equipped_weapon)
	return _weapon_ego_bonus(weapon, ego_name.to_lower())

static func _weapon_strength_penalty(weapon: Item) -> int:
	return maxi(0, weapon.str_req - int(stats[Stat.STRENGTH]))

static func _inventory_item(player: PlayerCreature, inventory_index: int) -> Item:
	var inventory: Array = player.inventory
	if inventory_index < 0 or inventory_index >= inventory.size():
		return null
	return inventory[inventory_index]

static func _equip_weapon(player: PlayerCreature, inventory_index: int) -> void:
	var weapon: Weapon = _inventory_item(player, inventory_index)
	if not weapon:
		return
	equipped_weapon = inventory_index
	player.damage = weapon.damage
	player.accuracy += weapon.acc_mod - 10 * _weapon_strength_penalty(weapon) + 5 * _weapon_ego_bonus(weapon, "precision")
	var base_attack_delay: int = player.attack_speed + weapon.delay_mod + _weapon_strength_penalty(weapon)
	var applied_speed_reduction: int = mini(maxi(0, _weapon_ego_bonus(weapon, "speed")), maxi(0, base_attack_delay - 1))
	player.attack_speed = base_attack_delay - applied_speed_reduction
	weapon.speed_ego_reduction_applied = applied_speed_reduction

static func _unequip_weapon(player: PlayerCreature, inventory_index: int) -> void:
	var weapon: Weapon = _inventory_item(player, inventory_index)
	if weapon:
		player.accuracy -= int(weapon.acc_mod) - 10 * _weapon_strength_penalty(weapon) + 5 * _weapon_ego_bonus(weapon, "precision")
		player.attack_speed += int(weapon.speed_ego_reduction_applied)
		weapon.speed_ego_reduction_applied = 0
		player.attack_speed -= int(weapon.delay_mod) + _weapon_strength_penalty(weapon)
	player.damage = 1
	equipped_weapon = -1

static func _armor_delay_penalty(armor: Item) -> int:
	return maxi(0, int(armor.delay) - 2 * int(stats[Stat.CONSTITUTION]))

static func _armor_ego_name(armor: Item) -> String:
	if armor and armor.ego != "":
		return str(armor.ego).to_lower()
	return ""

static func _armor_ego_bonus(armor: Item, ego_name: String) -> int:
	if _armor_ego_name(armor) != ego_name:
		return 0
	return int(armor.enchantment)

static func equipped_armor_ego_bonus(player: PlayerCreature, ego_name: String) -> int:
	var armor: Item = _inventory_item(player, equipped_armor)
	return _armor_ego_bonus(armor, ego_name.to_lower())

static func _equip_armor(player: PlayerCreature, inventory_index: int) -> void:
	var armor: Armor = _inventory_item(player, inventory_index)
	if not armor:
		return
	equipped_armor = inventory_index
	player.armor = int(armor.armor)
	var delay: int = _armor_delay_penalty(armor)
	player.move_speed += delay
	var requested_speed_reduction: int = maxi(0, _armor_ego_bonus(armor, "speed"))
	var applied_speed_reduction: int = mini(requested_speed_reduction, maxi(0, int(player.move_speed) - 1))
	player.move_speed -= applied_speed_reduction
	armor.speed_ego_reduction_applied = applied_speed_reduction
	player.attack_speed += delay
	player.evasion = int(player.get("evasion")) + _armor_ego_bonus(armor, "evasion")
	var health_bonus: int = _armor_ego_bonus(armor, "health")
	if health_bonus != 0:
		player.max_health = maxi(1, int(player.get("max_health")) + health_bonus)

static func _unequip_armor(player: PlayerCreature, inventory_index: int) -> void:
	var armor: Armor = _inventory_item(player, inventory_index)
	if armor:
		var delay: int = _armor_delay_penalty(armor)
		player.move_speed += int(armor.speed_ego_reduction_applied)
		armor.speed_ego_reduction_applied = 0
		player.move_speed -= delay
		player.attack_speed -= delay
		player.evasion = int(player.get("evasion")) - _armor_ego_bonus(armor, "evasion")
		var health_bonus: int = _armor_ego_bonus(armor, "health")
		if health_bonus != 0:
			player.max_health = maxi(1, int(player.get("max_health")) - health_bonus)
			player.health = mini(int(player.get("health")), int(player.max_health))
	player.armor = 0
	equipped_armor = -1

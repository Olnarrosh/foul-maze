class_name StatusPanel
extends Node

## Right-hand panel of the console. Shows either the status page (race, stats, health,
## status effects, commands) or the inventory page, depending on Map.show_inventory.
## Console draws the rows returned by get_panel_lines().
##
## The panel reads the Map on every draw instead of listening for signals, because stats and
## inventory change in many places without a redraw. The text builders are static so Map can
## map cursor rows back to inventory items with the same layout.

## The Map whose state is displayed. Set by Console whenever the active map changes.
var map: Map

var _cached_source_text: String = ""
var _cached_lines: PackedStringArray = PackedStringArray()
var _cached_width: int = -1
var _cached_height: int = -1

## Sets the map this panel displays, or null to show nothing.
func bind_map(next_map: Map) -> void:
	map = next_map
	_cached_source_text = ""
	_cached_lines = PackedStringArray()

## Returns the panel rows for a panel of the given size, including box-drawing borders.
## Row 0 is the top border and the second-to-last row is the bottom border.
## The rows are cached and rebuilt only when the panel text or size changes.
func get_panel_lines(panel_width: int, panel_height: int) -> PackedStringArray:
	if map == null:
		return PackedStringArray()
	var text: String = build_inventory_text(map) if map.show_inventory else build_status_text(map)
	if text == _cached_source_text and panel_width == _cached_width and panel_height == _cached_height and not _cached_lines.is_empty():
		return _cached_lines
	_cached_source_text = text
	_cached_width = panel_width
	_cached_height = panel_height
	var border_str: String = "═".repeat(panel_width - 2)
	var content_lines: PackedStringArray = text.split("\n")
	content_lines.resize(panel_height)
	for row: int in range(panel_height - 2):
		content_lines[row] = "║" + content_lines[row].rpad(panel_width - 2) + "║"
	content_lines.insert(0, "╔" + border_str + "╗")
	content_lines[content_lines.size() - 2] = "╚" + border_str + "╝"
	_cached_lines = content_lines
	return _cached_lines

## Returns the letter used to select an inventory slot: a-z, then the following characters for slots 26 and up.
static func inventory_letter(inventory_index: int) -> String:
	if inventory_index < 26:
		return String.chr(97 + inventory_index)
	return String.chr(22 + inventory_index)

## Returns the display name for a carried item, with its wand/charm cooldown appended when it is recharging.
static func inventory_item_label(source: Map, item_data: Item) -> String:
	var item_label: String = item_data.get_item_name()
	var item_type: String = item_data.get_type()
	if (item_type == "wand" or item_type == "charm") and item_data.get_id_status() == ItemData.ID_STATUS.FULL_ID:
		var cooldown_remaining: float = item_data.cooldown - source._player_entity.time
		if cooldown_remaining > 0.0:
			var turn_length: int = maxi(1, source._player_entity.move_speed)
			item_label += " [CD %dt]" % ceili(cooldown_remaining / float(turn_length))
	return item_label

## Builds the inventory page: equipped items, carried items, and the command help.
static func build_inventory_text(source: Map) -> String:
	var lines: Array[String] = ["You are equipped with:"]
	var sel_mode: bool = source.inspect_item_selection_active or source.equip_selection_active or source.drop_selection_active or source.throw_item_selection_active or source.activate_item_selection_active
	var inventory: Array = source.inventory
	if PlayerData.equipped_weapon >= 0 and PlayerData.equipped_weapon < inventory.size():
		var weapon_letter: String = inventory_letter(PlayerData.equipped_weapon)
		var weapon_name: String = inventory[PlayerData.equipped_weapon].get_item_name()
		lines.append(("(%s) %s" % [weapon_letter, weapon_name]) if sel_mode else "    %s" % weapon_name)
	else:
		lines.append("    a pair of fists")
	if PlayerData.equipped_armor >= 0 and PlayerData.equipped_armor < inventory.size():
		var armor_letter: String = inventory_letter(PlayerData.equipped_armor)
		var armor_name: String = inventory[PlayerData.equipped_armor].get_item_name()
		lines.append(("(%s) %s" % [armor_letter, armor_name]) if sel_mode else "    %s" % armor_name)
	else:
		lines.append("    shabby clothes")
	lines.append("You are carrying:")
	var carried_count: int = 0
	for i in range(inventory.size()):
		if i == PlayerData.equipped_weapon or i == PlayerData.equipped_armor:
			continue
		var item_letter: String = inventory_letter(i)
		var item_name: String = inventory_item_label(source, inventory[i])
		lines.append(("(%s) %s" % [item_letter, item_name]) if sel_mode else "    %s" % item_name)
		carried_count += 1
	if carried_count == 0:
		lines.append("Nothing.")
	# Fixed command-help rows allow a full 26-item inventory to end at row 30,
	# leave row 31 blank, and show commands beginning at row 32.
	lines.resize(38)
	lines[31] = "Commands:"
	lines[32] = "(X) Examine"
	lines[33] = "(W) Wear/wield/remove"
	lines[34] = "(A) Activate wand/charm"
	lines[35] = "(D) Drop"
	lines[36] = "(T) Throw"
	lines[37] = "(I) Close inventory"
	if source.inspect_item_selection_active:
		lines[32] = "Choose an item to examine."
	if source.equip_selection_active:
		lines[33] = "Choose an item to wear/wield/remove."
	elif source.activate_item_selection_active:
		lines[34] = "Choose a wand or charm to activate."
	elif source.wand_target_mode:
		lines[34] = "Choose a visible creature to target."
	elif source.drop_selection_active:
		lines[35] = "Choose an item to drop."
	elif source.throw_item_selection_active:
		lines[36] = "Choose an item to throw."
	elif source.throw_target_mode:
		lines[36] = "Choose a tile to throw to."
	return "\n".join(lines)

## Returns the equipped-item ego bonus as the player sees it, which is zero once the item is fully identified.
static func _unidentified_equipped_ego_bonus(item_info: Item, ego_name: String) -> int:
	if item_info.get_id_status() == ItemData.ID_STATUS.FULL_ID:
		return 0
	var ego: String = item_info.ego
	if ego != ego_name.to_lower():
		return 0
	return item_info.enchantment

## Builds the status page: race, level, attributes, derived combat values, status effects, and the command help.
static func build_status_text(source: Map) -> String:
	var p: Creature = source._player_entity
	var inventory: Array = source.inventory
	var race_string: String
	match PlayerData.player_race:
		PlayerData.Race.BEASTMAN:
			race_string = "a werebull"
		PlayerData.Race.DAR:
			race_string = "a dar"
		PlayerData.Race.GNOME:
			race_string = "a gnome"
		PlayerData.Race.HUMAN:
			race_string = "a human"
		PlayerData.Race.ORC:
			race_string = "an orc"
	var displayed_armor: int = p.armor
	if PlayerData.equipped_armor >= 0 and PlayerData.equipped_armor < inventory.size():
		displayed_armor = inventory[PlayerData.equipped_armor].get_display_combat_value()
	var displayed_damage: int = p.damage
	var unidentified_weapon_precision_bonus: int = 0
	var unidentified_weapon_speed_bonus: int = 0
	if PlayerData.equipped_weapon >= 0 and PlayerData.equipped_weapon < inventory.size():
		var equipped_weapon: Weapon = inventory[PlayerData.equipped_weapon]
		displayed_damage = equipped_weapon.get_display_combat_value()
		unidentified_weapon_precision_bonus = _unidentified_equipped_ego_bonus(equipped_weapon, "precision") * 5
		if equipped_weapon.get_id_status() != ItemData.ID_STATUS.FULL_ID:
			unidentified_weapon_speed_bonus = equipped_weapon.speed_ego_reduction_applied
	var displayed_accuracy: int = p.accuracy - unidentified_weapon_precision_bonus
	var displayed_attack_speed: int = p.attack_speed + unidentified_weapon_speed_bonus
	var displayed_move_speed: int = p.move_speed
	var displayed_evasion: int = p.evasion
	var displayed_max_health: int = p.max_health
	var displayed_health: int = p.health
	if PlayerData.equipped_armor >= 0 and PlayerData.equipped_armor < inventory.size():
		var equipped_armor: Armor = inventory[PlayerData.equipped_armor]
		var armor_evasion_bonus: int = _unidentified_equipped_ego_bonus(equipped_armor, "evasion")
		var armor_health_bonus: int = _unidentified_equipped_ego_bonus(equipped_armor, "health")
		displayed_move_speed += equipped_armor.speed_ego_reduction_applied if equipped_armor.get_id_status() != ItemData.ID_STATUS.FULL_ID else 0
		displayed_evasion -= armor_evasion_bonus
		displayed_max_health -= armor_health_bonus
		displayed_health -= armor_health_bonus
	@warning_ignore("integer_division")
	var lines: Array[String] = ["You are %s. You are currently" % race_string,
		"on the %s level of the Foul Maze." % source.level_ordinal,
		"",
		"Strength: %d" % PlayerData.stats[PlayerData.Stat.STRENGTH],
		"Dexterity: %d" % PlayerData.stats[PlayerData.Stat.DEXTERITY],
		"Intelligence: %d" % PlayerData.stats[PlayerData.Stat.INTELLIGENCE],
		"Constitution: %d" % PlayerData.stats[PlayerData.Stat.CONSTITUTION],
		"",
		"Health: %d/%d" % [displayed_health, displayed_max_health],
		"Armor: %d" % displayed_armor,
		"Damage: %d" % displayed_damage,
		"Evasion: %d (%d%%)" % [displayed_evasion, 100 - pow(.933033, displayed_evasion) * 100],
		"Accuracy (melee): %d%%" % displayed_accuracy,
		"Accuracy (thrown): %d%%" % p.acc_thrown,
		"Movement speed: %d%%" % (10000 / (displayed_move_speed * 5)),
		"Attack speed: %d%%" % (10000 / (displayed_attack_speed * 5)),
		"Status effects:"]
	if p.status.size() > 0:
		for s in p.status:
			lines.append("%s %d" % [s.status_name, s.duration])
	else:
		lines.append("(none)")
	lines.resize(38)
	lines[30] = "Commands:"
	lines[31] = "Move with Keypad/HJKLYUBN/Mouse"
	lines[34] = "(X) Examine"
	lines[36] = "(Z) Look"
	lines[32] = "(.) or (5) Wait"
	lines[35] = "(Tab) Auto-attack"
	lines[37] = "(R) Rest"
	lines[33] = "(I) Open inventory"
	return "\n".join(lines)

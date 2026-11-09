@abstract
class_name Item
extends Node

# Base class for all items in the game.
# Items can be weapons, armors, wands, charms, grenades, or projectiles.
# Items go through an identification system:
#   NO_ID: base item, unidentified
#   PARTIAL_ID: partially identified (subtype/ego known, enchantment unknown)
#   FULL_ID: fully identified (all properties known)
#
# Items have enchantment levels that improve their power,
# egos (special properties), and can be identified by use.
var item_name: String
var id_status: ItemData.ID_STATUS = ItemData.ID_STATUS.NO_ID
var glyph: String
var color: int
var enchantment: int = 0
var identification_progress: int = 0

# Class-level state shared across all items for identification tracking
static var PARTIALLY_IDENTIFIED_SUBTYPES: Dictionary[String, bool] = ItemData.PARTIALLY_IDENTIFIED_SUBTYPES
static var ITEM_SUBTYPES_UNKNOWN: Dictionary = ItemData.ITEM_SUBTYPES_UNKNOWN

# Item identification status levels
enum ID_STATUS {NO_ID, PARTIAL_ID, FULL_ID}

func identify_partially() -> void:
	if get_type() in ["wand", "charm", "grenade"]:
		PARTIALLY_IDENTIFIED_SUBTYPES[_subtype_identification_key()] = true
	if id_status != ItemData.ID_STATUS.NO_ID:
		return
	set("id_status", ItemData.ID_STATUS.PARTIAL_ID)

func get_type() -> String:
	if self is Armor:
		return "armor"
	elif self is Weapon:
		return "weapon"
	elif self is Grenade:
		return "grenade"
	elif self is Wand:
		return "wand"
	elif self is Charm:
		return "charm"
	elif self is Projectile:
		return "projectile"
	else:
		printerr("Unknown item type: " + item_name)
		return "unknown"

func identify_fully() -> void:
	identify_partially()
	set("id_status", ItemData.ID_STATUS.FULL_ID)

func get_id_status() -> int:
	if PARTIALLY_IDENTIFIED_SUBTYPES.has(_subtype_identification_key()) and id_status != ItemData.ID_STATUS.FULL_ID:
		return ItemData.ID_STATUS.PARTIAL_ID
	return id_status

func _subtype_identification_key() -> String:
	return "%s:%s" % [get_type(), item_name]

func record_identification_progress(progress: int, threshold: int) -> void:
	if progress <= 0 or threshold <= 0 or get_id_status() == ItemData.ID_STATUS.FULL_ID:
		return
	identification_progress += progress
	if identification_progress >= threshold:
		identify_fully()

func get_display_combat_value() -> int:
	var item_type: String = get_type()
	var value_key: String = "damage" if item_type == "weapon" else "armor" if item_type == "armor" else ""
	if value_key.is_empty():
		return 0
	var actual_value: int = int(get(value_key))
	if get_id_status() == ItemData.ID_STATUS.FULL_ID:
		return actual_value
	return actual_value - enchantment

@abstract
func get_description() -> String

@abstract
func get_item_name() -> String

## Item kinds, using the same strings as ItemData.ITEM_SUBTYPES and ItemData.ITEM_CHAR keys.
const ITEM_KINDS: Array[String] = ["weapon", "armor", "wand", "charm", "grenade", "projectile"]

## Creates an item of the given kind from a random subtype in ItemData.ITEM_SUBTYPES[kind].
## Enchantment, egos and identification state are rolled according to the dungeon level.
static func create_random(item_kind: String, level: int) -> Item:
	var subtype_options: Array = ItemData.ITEM_SUBTYPES.get(item_kind, [])
	if subtype_options.is_empty():
		return null
	var subtype: Dictionary = subtype_options.pick_random()
	return create_from_subtype(item_kind, subtype, level)

## Creates an item of the given kind from a specific subtype dictionary, rolling its random state.
## Use a level below 1 to create the base version (no egos, no enchantment).
static func create_from_subtype(item_kind: String, subtype: Dictionary, level: int) -> Item:
	match item_kind:
		"weapon":
			var ego: Dictionary = {}
			if level > 0 and randf() < level / 50.0:
				var eligible_egos: Array[Dictionary] = ItemData.get_weapon_egos_for_subtype(subtype.name)
				if not eligible_egos.is_empty():
					ego = eligible_egos.pick_random()
			var weapon: Weapon = Weapon.new(subtype, ego)
			weapon.enchantment = _roll_melee_enchantment(level) if level > 0 else 0
			weapon.damage += weapon.enchantment
			return weapon
		"armor":
			var ego: Dictionary = {}
			if level > 0 and randf() < level / 50.0:
				ego = ItemData.ARMOR_EGOS.pick_random()
			var armor: Armor = Armor.new(subtype, ego)
			armor.enchantment = _roll_melee_enchantment(level) if level > 0 else 0
			armor.armor += armor.enchantment
			return armor
		"wand":
			var wand: Wand = Wand.new(subtype)
			@warning_ignore("integer_division")
			wand.enchantment = randi_range(0, 2 + level / 9) if level > 0 else 0
			return wand
		"charm":
			var charm: Charm = Charm.new(subtype)
			@warning_ignore("integer_division")
			charm.enchantment = randi_range(0, 2 + level / 9) if level > 0 else 0
			return charm
		"grenade":
			var grenade: Grenade = Grenade.new(subtype)
			return grenade
		"projectile":
			var projectile: Projectile = Projectile.new(subtype)
			return projectile
	return null

static func _roll_melee_enchantment(level: int) -> int:
	var ench: int = 0
	for _decrease_roll: int in range(2):
		if randf() < 0.05:
			ench -= 1
	@warning_ignore("integer_division")
	var increase_roll_count: int = 1 + level / 6
	for _increase_roll: int in range(increase_roll_count):
		if randf() < 0.10:
			ench += 1
	return ench

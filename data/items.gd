class_name ItemData
extends Node

enum ID_STATUS {NO_ID, PARTIAL_ID, FULL_ID}
static var PARTIALLY_IDENTIFIED_SUBTYPES: Dictionary[String, bool] = {}
const ITEM_CHAR = {"weapon": "†", "armor": "Ω", "wand": "ᛣ", "charm": "Ϭ", "grenade": "ө", "projectile": "↓"}

static var ITEM_SUBTYPES_UNKNOWN = {
	"wand": ["alicorn", "bone", "thorium", "tin", "silver", "golden", "copper", "iron", "tungsten", "ebony", "oaken", "rosewood", "birch", "teak", "reed", "glass"],
	"charm": ["diamond", "emerald", "amethyst", "malachite", "sapphire", "ruby", "quartz", "tourmaline", "pyrite", "turquoise", "obsidian", "flintstone", "aquamarine", "peridot", "alexandrite", "amber", "garnet"],
	"grenade": ["crimson", "vermilion", "magenta", "amaranthine", "mauve", "periwinkle", "eburnean", "ochre", "chartreuse", "croceous", "ecru", "verdigris", "khaki", "azure", "mazarine", "filemot", "perse", "atrous"],
}

# Item subtypes define the base properties for each kind of item.
# Each subtype dictionary contains: name, stat requirements, effects, and descriptions.
# Subtypes are organized by item type: weapon, armor, wand, charm, grenade, projectile.
# Weapon subtypes define damage, accuracy, delay, reach, and attack strings.
# Armor subtypes define armor value and delay.
# Wand subtypes define the kind of magic the wand contains.
# Charm subtypes define the kind of effect the charm provides.
# Grenade subtypes define explosion effects and properties.
# Projectile subtypes define throwing weapons with damage, accuracy, and range.
# The specific effects of wands, charms, grenades, and weapon/armor egos (see below)
# are implemented in their activation methods in ui/Map.gd for now.
static var ITEM_SUBTYPES = {
	"weapon": [
		{name="dagger", str_req=1, damage=2, acc_mod=5, delay_mod=-5, reach=false, attack_str=PackedStringArray(["stab", "cut", "slice", "prick", "jab", "puncture", "hit", "strike"])},
		{name="hatchet", str_req=2, damage=5, acc_mod=-5, delay_mod=0, reach=false, attack_str=PackedStringArray(["chop", "hack", "cleave", "hit", "strike"])},
		{name="spear", str_req=3, damage=4, acc_mod=0, delay_mod=0, reach=true, attack_str=PackedStringArray(["spear", "pierce", "impale", "skewer", "lancinate", "enthrill", "hit"])},
		{name="shortsword", str_req=4, damage=5, acc_mod=5, delay_mod=0, reach=false, attack_str=PackedStringArray(["slash", "cut", "stab", "slice", "pink", "hit", "strike"])},
		{name="mace", str_req=5, damage=10, acc_mod=-10, delay_mod=10, reach=false, attack_str=PackedStringArray(["bludgeon", "clobber", "cudgel", "pummel", "mace", "hit", "strike"])},
		{name="halberd", str_req=6, damage=6, acc_mod=0, delay_mod=0, reach=true, attack_str=PackedStringArray(["pierce", "stab", "hack", "chop", "hit", "strike"])},
		{name="longsword", str_req=7, damage=7, acc_mod=5, delay_mod=0, reach=false, attack_str=PackedStringArray(["cleave", "rive", "split", "rend", "cut", "slash", "slice", "hit", "strike"])},
		{name="battle axe", str_req=8, damage=10, acc_mod=-5, delay_mod=0, reach=false, attack_str=PackedStringArray(["chop", "hack", "cleave", "rend", "hit", "strike"])},
		{name="warhammer", str_req=9, damage=25, acc_mod=-10, delay_mod=20, reach=false, attack_str=PackedStringArray(["bludgeon", "clobber", "bash", "pummel", "smash", "hit", "strike"])}],
	"armor": [
		{name="gambeson", armor=1, delay=5, desc="padded cloth"},
		{name="leather armor", armor=2, delay=8, desc="leather scales"},
		{name="chainmail", armor=3, delay=11, desc="iron rings"},
		{name="mirror armor", armor=4, delay=14, desc="iron rings and disks"},
		{name="plate armor", armor=5, delay=17, desc="iron plates"}],
	"wand": [
		{name="fire"},
		{name="frost"},
		{name="fear"},
		{name="rage"},
		{name="paralysis"},
		{name="confusion"},
		{name="repulsion"},
		{name="blinding"},
		{name="transference"}],
	"charm": [
		{name="sight"},
		{name="healing"},
		{name="haste"},
		{name="invisibility"},
		{name="detection"},
		{name="stoneskin"},
		{name="magic"},
		{name="teleportation"},
		{name="repulsion"}],
	"grenade": [
		{name="poison"},
		{name="shattering"},
		{name="holy"},
		{name="fire"},
		{name="frost"},
		{name="healing"},
		{name="noise"},
		{name="smoke"},
		{name="seed"}],
	"projectile": [
		{name="throwing knife", damage=3, acc_mod=10, range_mod=2.0, desc="A knife-like blade made for throwing. It is accurate and can be thrown far."},
		{name="throwing axe", damage=6, acc_mod=-5, range_mod=1.0, desc="An axe balanced for throwing. It is not very accurate and has short range."},
		{name="javelin", damage=5, acc_mod=0, range_mod=1.5, desc="A throwing spear."},
		{name="poison dart", damage=1, poison_duration=20, acc_mod=0, range_mod=2.0, desc="A poison dart that can be thrown far."}]
}

# Runic egos are special properties that can be added to weapons.
# Each ego has a name and may have weapon_subtypes that limit which weapons
# can receive this ego. Egos modify weapon behavior when fully identified.
static var WEAPON_EGOS = [
	{name="precision"},
	{name="speed"},
	{name="draining"},
	{name="fire"},
	{name="frost"},
	{name="quietus", weapon_subtypes=["dagger"]},
	{name="exorcism"},
	{name="penetration"},
	{name="stunning"},
	{name="lunging", weapon_subtypes=["shortsword", "longsword"]},
	{name="cleaving", weapon_subtypes=["hatchet", "battle axe"]},
	{name="piercing", weapon_subtypes=["spear", "halberd"]},
	{name="force", weapon_subtypes=["mace", "warhammer"]},
]

# Runic egos are special properties that can be added to armor.
# Each ego has a name and may provide various defensive or utility benefits.
# When fully identified, egos provide descriptive text about their effects.
static var ARMOR_EGOS = [
	{name="stealth"},
	{name="speed"},
	{name="evasion"},
	{name="reflection"},
	{name="insulation"},
	{name="stunning"},
	{name="clarity"},
	{name="health"},
	{name="sorcery"}
]

static func get_weapon_egos_for_subtype(weapon_subtype: String) -> Array[Dictionary]:
	var eligible_egos: Array[Dictionary] = []
	for ego: Dictionary in WEAPON_EGOS:
		var allowed_subtypes: Array = ego.get("weapon_subtypes", [])
		if allowed_subtypes.is_empty() or allowed_subtypes.has(weapon_subtype):
			eligible_egos.append(ego)
	return eligible_egos

static func get_runic_name() -> String:
	var first := _get_runic_syllable(true, false, false)
	var middle: String
	match randi() % 4:
		0:
			middle = _get_runic_syllable(true, true, false)
		1:
			middle = _get_runic_syllable(true, false, true)
		2:
			middle = _get_runic_syllable(false, true, true)
		3:
			middle = _get_runic_syllable(false, false, false) + _get_runic_syllable(false, false, false)
	var last := _get_runic_syllable(false, true, false)
	return first + middle + last

static func _get_runic_syllable(require_onset: bool, require_coda: bool, allow_long: bool) -> String:
	var onset := ['ᴥ', 'ᛥ', 'Բ', 'Ѳ', 'ᥤ', 'ʥ', 'Ξ', 'Ʌ', 'Ⴟ', 'Ѫ', 'Ϡ', 'ΰ', 'ᛤ', 'Ϟ', 'ʠ', 'ξ']
	var nucleus := ['Ϯ', 'ɬ', '҂', 'Ⴕ', 'ᛄ', 'ᛡ', 'ֆ']
	var coda := ['ƾ', 'ᵹ', 'ʢ', 'Ⴆ', 'ᛢ', 'ᴟ', 'Ⴞ', 'Ϣ', 'ᛃ', 'ᴤ', 'Ջ', 'Ҕ', 'ᛪ', 'Բ', 'Ⴟ', 'Ѫ']
	var syllable: String = nucleus.pick_random()
	if allow_long and randi() % 2:
		syllable += nucleus.pick_random()
	if require_onset or randi() % 2:
		syllable = onset.pick_random() + syllable
	if require_coda or randi() % 2:
		syllable += coda.pick_random()
	return syllable

static func init_unid_names() -> void:
	PARTIALLY_IDENTIFIED_SUBTYPES.clear()
	for type: String in ITEM_SUBTYPES_UNKNOWN.keys():
		var unknown_names: Array = ITEM_SUBTYPES_UNKNOWN[type].duplicate()
		unknown_names.shuffle()
		for subtype_value: Variant in ITEM_SUBTYPES[type]:
			var subtype: Dictionary = subtype_value
			subtype.erase("id_status")
			subtype.name_unid = unknown_names.pop_back()

static func get_projectile_base_damage(projectile_name: String) -> int:
	for projectile_value: Variant in ITEM_SUBTYPES["projectile"]:
		var projectile: Dictionary = projectile_value
		if str(projectile.get("name", "")) == projectile_name:
			return int(projectile.get("damage", 1))
	return 1

static func get_projectile_base_poison_duration(projectile_name: String) -> int:
	for projectile_value: Variant in ITEM_SUBTYPES["projectile"]:
		var projectile: Dictionary = projectile_value
		if str(projectile.get("name", "")) == projectile_name:
			return int(projectile.get("poison_duration", 0))
	return 0

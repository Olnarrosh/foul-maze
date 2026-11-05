class_name Armor
extends Item

var armor: int
var delay: int
var description: String
var ego: String
var ego_unid: String
var speed_ego_reduction_applied: int = 0

func _init(subtype: Dictionary, ego_dict: Dictionary = {}):
	color = 15
	glyph = "Ω"
	item_name = subtype.name
	description = subtype.desc
	armor = subtype.armor
	delay = subtype.delay
	ego = ego_dict.get("name", "")
	ego_unid = ItemData.get_runic_name() if ego else ""

func get_description() -> String:
	var constitution: int = int(PlayerData.stats[PlayerData.Stat.CONSTITUTION])
	var delay_penalty: int = maxi(0, delay - 2 * constitution)
	var desc: String = "A suit of armor made of %s. It provides %d armor." % [description, get_display_combat_value()]
	if delay_penalty > 0:
		desc += " Wearing it slows you down by %d%%. You need %s more constitution" % [roundi(float(delay_penalty) * 5.0), ceili(delay_penalty / 2.0)]
	else:
		desc += " You are strong enough"
	desc += " to wear it without being encumbered."
	if ego and id_status != ItemData.ID_STATUS.NO_ID:
		var armor_ego_name: String = ego
		var armor_ego_effect: String = _ego_effect_description()
		desc += " It is imbued with the power of %s, which %s." % [armor_ego_name, armor_ego_effect if not armor_ego_effect.is_empty() else ""]
	return desc

func get_item_name() -> String:
	var full_name = item_name
	if ego:
		if id_status != ItemData.ID_STATUS.NO_ID:
			full_name += " of " + ego
		else:
			full_name += " inscribed " + ego_unid
	if id_status == ItemData.ID_STATUS.FULL_ID:
		full_name += " "
		if enchantment >= 0:
			full_name += "+"
		full_name += str(enchantment)
	return full_name

func _ego_effect_description() -> String:
	var fully_identified = id_status == ItemData.ID_STATUS.FULL_ID
	match ego:
		"stealth": return "helps you avoid notice"
		"speed": return "makes you move faster%s" % (" by up to %s%%" % (5 * enchantment) if fully_identified else "")
		"evasion": return "helps you evade attacks%s" % (" by %s points" % enchantment if fully_identified else "")
		"reflection": return "reflects %s damage back at attackers" % ("up to %s points of" % enchantment if fully_identified else "some")
		"insulation": return "reduces the duration of burning and freezing"
		"stunning": return "delays attackers that hit you%s" % (" by %s%% of a standard turn" % str(25 * enchantment) if fully_identified else "")
		"clarity": return "reduces the duration of blindness and confusion"
		"health": return "increases your maximum health%s" % (" by %s" % enchantment if fully_identified else "")
		"sorcery": return "shortens wand and charm cooldowns when you take damage%s" % (" by %s%% of a standard turn per point of damage" % (25 * enchantment) if fully_identified else "")
		_: return ""

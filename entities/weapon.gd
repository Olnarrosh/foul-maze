class_name Weapon
extends Item

var str_req: int
var damage: int
var acc_mod: int
var delay_mod: int
var reach: bool
var attack_str: PackedStringArray
var ego: String
var ego_unid: String
var speed_ego_reduction_applied: int = 0

func _init(subtype: Dictionary, ego_dict: Dictionary = {}):
	glyph = "†"
	color = 15
	item_name = subtype.name
	str_req = subtype.str_req
	damage = subtype.damage
	acc_mod = subtype.acc_mod
	delay_mod = subtype.delay_mod
	reach = subtype.reach
	attack_str = subtype.attack_str
	ego = ego_dict.get("name", "")
	ego_unid = ItemData.get_runic_name() if ego else ""

func get_description() -> String:
	var description: String = "This %s does up to %d damage." % [item_name, get_display_combat_value()]
	if reach:
		description += " It can be used for diagonal attacks."
	var qualities: Array[String] = []
	if delay_mod < 0:
		qualities.append("quick")
	elif delay_mod >= 20:
		qualities.append("very slow")
	elif delay_mod >= 10:
		qualities.append("slow")
	if acc_mod >= 5:
		qualities.append("precise")
	elif acc_mod <= -10:
		qualities.append("very imprecise")
	elif acc_mod < 0:
		qualities.append("imprecise")
	if not qualities.is_empty():
		description += " Its attacks are %s." % " and ".join(qualities)
	var strength_difference: int = str_req - int(PlayerData.stats[PlayerData.Stat.STRENGTH])
	if strength_difference > 0:
		description += " You need %d more strength to use it effectively." % strength_difference
	var weapon_id_status: int = get_id_status()
	if ego and weapon_id_status != ItemData.ID_STATUS.NO_ID:
		var weapon_ego_name: String = ego
		var weapon_ego_effect: String = _ego_effect_description()
		description += " It is imbued with the power of %s, which %s." % [weapon_ego_name, weapon_ego_effect if not weapon_ego_effect.is_empty() else ""]
	return description

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
		"precision": return "improves attack accuracy%s" % (" by %s%%" % str(5 * enchantment) if fully_identified else "")
		"speed": return "makes attacks faster%s" % (" by %s%% of a standard turn" % str(5 * enchantment) if fully_identified else "")
		"draining": return "drains vitality from foes%s" % (" (heals up to %s health per hit)" % str(floori(float(enchantment) / 2.0)) if fully_identified else "")
		"fire": return "deals half its damage as fire damage and sets its target aflame%s" % (" for %s turns" % enchantment if fully_identified else "")
		"frost": return "deals half its damage as cold damage and freezes its target%s" % (" for %s turns" % enchantment if fully_identified else "")
		"quietus": return "deals extra damage to helpless or unaware foes"
		"exorcism": return "is especially potent against unholy foes"
		"penetration": return "pierces%s armor" % (" up to %s points of" % enchantment if fully_identified else "")
		"stunning": return "delays foes it hits%s" % (" by %s%% of a standard turn" % str(25 * enchantment) if fully_identified else "")
		"lunging": return "can strike nearby foes as you approach them"
		"cleaving": return "can hit additional foes adjacent to the target"
		"piercing": return "can strike through a foe and hit one behind it"
		"force": return "can knock foes backward%s" % (" by up to %s tiles" % str(floori(float(enchantment) / 2.0)) if fully_identified else "")
		_: return ""

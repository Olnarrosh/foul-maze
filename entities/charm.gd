class_name Charm
extends Item

var name_unid: String
var cooldown: int

func _init(subtype: Dictionary):
	color = 15
	glyph = "Ϭ"
	item_name = subtype.name
	name_unid = subtype.name_unid
	cooldown = 0

func get_description() -> String:
	var item_id_status: int = get_id_status()
	if item_id_status == ItemData.ID_STATUS.NO_ID:
		return "A charm with an unknown magical effect."
	var fully_identified = id_status == ItemData.ID_STATUS.FULL_ID
	match item_name:
		"sight": return "Improves your vision%s." % (" for %s turns" % str(3 * (enchantment + 4)) if fully_identified else "")
		"healing": return "Restores your health%s." % (" by up to %s" % str(enchantment + 1) if fully_identified else "")
		"haste": return "Quickens your actions%s." % (" for %s turns" % str(enchantment + 3) if fully_identified else "")
		"invisibility": return "Makes you invisible%s." % (" for %s turns" % str(enchantment + 3) if fully_identified else "")
		"detection": return "Reveals hidden portions of the map%s." % (" (up to %s tiles)" % str(4 * (4 + enchantment)) if fully_identified else "")
		"stoneskin": return "Protects you from harm%s." % (" for %s turns or until it fully absorbs a hit" % str(2 * (enchantment + 1)) if fully_identified else "")
		"magic": return "Speeds the recharge of your other magical items%s." % (" by %s standard turns" % str(enchantment + 1) if fully_identified else "")
		"teleportation": return "Teleports you to a distant location%s." % (" within %s tiles" % str(10 * (enchantment + 1)) if fully_identified else "")
		"repulsion": return "Repels nearby creatures%s." % (" within radius %s, pushing them up to %s tiles" % [str(1 + ceili(enchantment / 2.0)), str(1 + floori(enchantment / 2.0))] if fully_identified else "")
		_: return "Its magical effect is not yet clear."

func get_item_name() -> String:
	var id: int = get_id_status()
	if id == ItemData.ID_STATUS.NO_ID:
		return name_unid + " charm"
	var full_name: String = "charm of " + item_name
	if id == ItemData.ID_STATUS.FULL_ID:
		full_name += " +" + str(enchantment)
	return full_name

class_name Wand
extends Item

var name_unid: String
var cooldown: int

func _init(subtype: Dictionary):
	color = 15
	glyph = "ᛣ"
	item_name = subtype.name
	name_unid = subtype.name_unid
	cooldown = 0

func get_description() -> String:
	var item_id_status: int = get_id_status()
	if item_id_status == ItemData.ID_STATUS.NO_ID:
		return "A wand with an unknown magical effect."
	var fully_identified = id_status == ItemData.ID_STATUS.FULL_ID
	match item_name:
		"fire": return "Damages the target and sets it ablaze%s." % (" for %s turns" % str(enchantment + 2) if fully_identified else "")
		"frost": return "Damages and freezes the target%s." % (" (up to %s cold damage; freeze lasts %s turns)" % [str(ceili(float(enchantment + 1) / 2.0)), str(floori(float(enchantment + 3) / 2.0))] if fully_identified else "")
		"fear": return "Sends the target fleeing%s." % (" for %s turns" % str(2 * (enchantment + 2)) if fully_identified else "")
		"rage": return "Quickens the target and makes it unable to distinguish between friend and foe%s." % (" for %s turns" % enchantment if fully_identified else "")
		"paralysis": return "Leaves the target immobolized and helpless%s." % (" for %s%% of a standard turn" % str(45 * (enchantment + 2)) if fully_identified else "")
		"confusion": return "Confuses the target%s." % (" for %s turns" % str(2 * (enchantment + 2)) if fully_identified else "")
		"repulsion": return "Pushes the target away%s." % (" up to %s tiles" % str(enchantment + 3) if fully_identified else "")
		"transference": return "Splits damage and healing between you and the target%s." % (" for %s standard turns" % str((enchantment + 1) * 2) if fully_identified else "")
		"blinding": return "Blinds the target%s." % (" for %s turns" % str(enchantment + 3) if fully_identified else "")
		_:  return "Its magical effect is not yet clear."

func get_item_name() -> String:
	var id: int = get_id_status()
	if id == ItemData.ID_STATUS.NO_ID:
		return name_unid + " wand"
	var full_name: String = "wand of " + item_name
	if id == ItemData.ID_STATUS.FULL_ID:
		full_name += " +" + str(enchantment)
	return full_name

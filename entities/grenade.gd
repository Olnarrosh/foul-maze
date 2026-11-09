class_name Grenade
extends Item

var name_unid: String

func _init(subtype: Dictionary):
	color = 15
	glyph = "ө"
	item_name = subtype.name
	name_unid = subtype.name_unid

func get_description() -> String:
	var item_id_status: int = get_id_status()
	if item_id_status == ItemData.ID_STATUS.NO_ID:
		return "A bomb that releases an unknown effect when thrown."
	var fully_identified = id_status == ItemData.ID_STATUS.FULL_ID
	var radius: int = enchantment + 4
	match item_name:
		"poison": return "Poisons creatures in its blast%s." % (" (radius %s)" % str(radius) if fully_identified else "")
		"shattering": return "Shatters walls in its blast%s." % (" (radius %s)" % str(radius) if fully_identified else "")
		"holy": return "Damages unholy creatures in its blast%s." % (" (radius %s)" % str(radius) if fully_identified else "")
		"fire": return "Burns creatures and terrain in its blast%s." % (" (radius %s)" % str(radius) if fully_identified else "")
		"frost": return "Freezes creatures and chills its blast area%s." % (" (radius %s)" % str(radius) if fully_identified else "")
		"healing": return "Heals creatures and eases poison in its blast%s." % (" (radius %s)" % str(radius) if fully_identified else "")
		"noise": return "Delays and incapacitates nearby creatures, and attracts creatures in a wider radius%s." % (" (blast radius %s)" % str(radius) if fully_identified else "")
		"smoke": return "Fills its blast area with smoke%s." % (" (radius %s)" % str(radius) if fully_identified else "")
		"seed": return "Turns floors into moss and nearby dense patches into shrubs%s." % (" (blast radius %s)" % str(radius) if fully_identified else "")
		_: return "Its magical effect is not yet clear."

func get_item_name() -> String:
	var full_name: String = (name_unid if get_id_status() == ItemData.ID_STATUS.NO_ID else item_name) + " bomb"
	if enchantment != 0:
		full_name += " +%d" % enchantment
	return full_name

func grenade_flash_color() -> int:
	match name_unid:
		"crimson":
			return 10
		"vermilion":
			return 10
		"magenta":
			return 13
		"amaranthine":
			return 2
		"mauve":
			return 13
		"periwinkle":
			return 14
		"eburnean":
			return 15
		"ochre":
			return 3
		"chartreuse":
			return 9
		"croceous":
			return 11
		"ecru":
			return 7
		"verdigris":
			return 6
		"khaki":
			return 1
		"azure":
			return 12
		"mazarine":
			return 4
		"filemot":
			return 3
		"perse":
			return 5
		"atrous":
			return 0
		_:
			return 8

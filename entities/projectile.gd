class_name Projectile
extends Item

var damage: int
var acc_mod: int
var range_mod: float
var description: String
var poison_duration: int

func _init(subtype: Dictionary):
	color = 15
	glyph = "↓"
	item_name = subtype.name
	damage = subtype.damage
	acc_mod = subtype.acc_mod
	range_mod = subtype.range_mod
	description = subtype.desc
	poison_duration = subtype.get("poison_duration", 0)

func get_description() -> String:
	var damage_text: String = "It can deal up to %d damage." % damage
	if poison_duration:
		return "%s %s On a damaging hit, it poisons the target for %d turns." % [description, damage_text, poison_duration]
	return "%s %s" % [description, damage_text]
	
func get_item_name() -> String:
	var full_name = item_name
	if enchantment:
		full_name += " +%s" % enchantment
	return full_name

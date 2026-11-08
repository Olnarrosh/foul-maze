class_name PlayerCreature
extends Creature

var acc_thrown: int

func _init(position: Vector2i):
	creature_name = "you"
	glyph = "@"
	color = 15
	max_health = 9
	health = 9
	damage = 1
	armor = 0
	accuracy = 60
	acc_thrown = 40
	evasion = 0
	move_speed = 20
	attack_speed = 20
	sight_range = 10
	description = "You are here."
	category = CreatureData.CreatureCategory.HUMANOID
	traits = []
	pos = position
	super()

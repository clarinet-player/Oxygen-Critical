extends RigidBody3D
class_name ItemBase



signal on_equip
signal on_unequip


@export var equip_pos := Transform3D(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(0.207, -0.15, -0.205))
@export var unequip_pos := Transform3D(Vector3(-0.96, -0.26, -0.04), Vector3(0.251, -0.83, -0.48), Vector3(0.089, -0.47, 0.873), Vector3(0.157, -0.434, 0.187))
@export var equip_speed := 250


enum istate {
	unequipped,
	equipped,
	equipping,
	unequipping,
	dropped
}
var state := istate.unequipped
var equip_time : int


@export var right_target : Node3D
@export var left_target : Node3D



func equip():
	equip_time = Time.get_ticks_msec()
	state = istate.equipping



func unequip():
	equip_time = Time.get_ticks_msec()
	state = istate.unequipping



func _process(delta):
	match state:
		istate.unequipped:
			transform = unequip_pos
		istate.equipped:
			transform = transform.interpolate_with(equip_pos, delta)
		istate.equipping:
			transform = unequip_pos.interpolate_with(equip_pos, (Time.get_ticks_msec() - equip_time) / equip_speed)
		istate.unequipping:
			transform = equip_pos.interpolate_with(unequip_pos, (Time.get_ticks_msec() - equip_time) / equip_speed)



func _physics_process(delta):
	if state == istate.equipping:
		if Time.get_ticks_msec() - equip_time > equip_speed:
			state = istate.equipped
			on_equip.emit()
	if state == istate.unequipping:
		if Time.get_ticks_msec() - equip_time > equip_speed:
			state = istate.unequipped
			on_unequip.emit()

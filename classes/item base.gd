extends RigidBody3D
class_name ItemBase



signal on_equip
signal on_unequip



@export var grip1 : Node3D
@export var grip2 : Node3D

@export var equip_speed := 200

@export var item_id : int
@export var inventory_size : int

var equip_pos : Node3D
var unequip_pos : Node3D

enum istate {
	unequipped,
	equipped,
	equipping,
	unequipping,
	dropped,
	override
}
var state := istate.unequipped
var equip_time : int

var velocity : Vector3
var angular : Vector3



func equip():
	equip_time = Time.get_ticks_msec()
	state = istate.equipping
	show()



func unequip():
	equip_time = Time.get_ticks_msec()
	state = istate.unequipping



func drop(pos : Vector3, vel : Vector3):
	state = istate.dropped
	show()
	
	get_parent().get_parent().inventory.erase(self)
	get_parent().get_parent().active_item = null
	get_parent().remove_child(self)
	Gamemanager.add_child(self)
	
	global_position = pos
	velocity = vel
	angular = Vector3.ZERO
	look_at(global_position + velocity)



func pick(equip_p : Node3D, unequip_p : Node3D):
	get_parent().remove_child(self)
	equip_pos = equip_p
	unequip_pos = unequip_p
	state = istate.unequipped



func _process(delta):
	match state:
		istate.unequipped:
			global_transform = unequip_pos.global_transform
		istate.equipping:
			global_transform = unequip_pos.global_transform.interpolate_with(equip_pos.global_transform, (Time.get_ticks_msec() - equip_time) / equip_speed)
		istate.unequipping:
			global_transform = equip_pos.global_transform.interpolate_with(unequip_pos.global_transform, (Time.get_ticks_msec() - equip_time) / equip_speed)



func _physics_process(delta):
	if state == istate.equipping and Time.get_ticks_msec() - equip_time > equip_speed:
		state = istate.equipped
		on_equip.emit()
		global_transform = equip_pos.global_transform
	
	elif state == istate.unequipping and Time.get_ticks_msec() - equip_time > equip_speed:
		state = istate.unequipped
		on_unequip.emit()
		hide()
	
	elif state == istate.dropped:
		if !angular.is_zero_approx():
			global_rotate(angular.normalized(), angular.length() * delta)
		var collision = move_and_collide(velocity * delta)
		if collision:
			velocity = velocity.bounce(collision.get_normal()) * 0.5
			var vel = velocity.length()
			angular = Vector3(randf_range(-vel, vel), randf_range(-vel, vel), randf_range(-vel, vel))

extends RigidBody3D

var centrifuge_angular_velocity := Vector3(0.1, 0, 0)

func _physics_process(delta):
	global_rotate(centrifuge_angular_velocity.normalized(), centrifuge_angular_velocity.length() * delta)

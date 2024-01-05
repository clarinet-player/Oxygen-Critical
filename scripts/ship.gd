extends RigidBody3D

func _physics_process(delta):
	rotate(global_transform.basis.z, delta / 10)

extends RigidBody3D

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			var anchored_body = get_parent()
			var offset : Vector3 = position
			
			reparent($"../..")
			
			apply_central_impulse( anchored_body.linear_velocity )
			apply_central_impulse( position.cross( anchored_body.angular_velocity ) )

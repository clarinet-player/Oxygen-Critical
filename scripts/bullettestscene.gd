extends Node3D


func _input(event):
	if event is InputEventMouseButton:
		var _bullet = preload("res://classes/bullet.tscn")
		_bullet = _bullet.instantiate()
		add_child(_bullet)
		_bullet.global_position = Vector3(20, 0, 5)
		_bullet.velocity = Vector3(-100, 0, -24)

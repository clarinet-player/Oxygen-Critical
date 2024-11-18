extends RigidBody3D



@export var fov := 1.5
@export var target_distance := 10.0
@export var wall_avoidance_distance := 4.0
@export var keep_distance_strength := 0.8
@export var max_influence_strength := 8.0
@export var update_delay := 0.1


var output_velocity := Vector3.ZERO
var output_direction := Vector3.ZERO
var target_node : Node3D
var target_point : Vector3






func _ready():
	while true:
		await get_tree().create_timer(randf()).timeout
		ai()



func ai():
	var influences := Array()
	var raycasts := Array()
	var visible_players := Array()
	
	output_velocity = Vector3.ZERO
	output_direction = Vector3.ZERO
	
	
	
	# Raycasting to find nearby walls
	for axis in [global_basis.x + global_basis.z, -global_basis.x + global_basis.z, global_basis.y + global_basis.z, -global_basis.y + global_basis.z, 
				global_basis.x - global_basis.z, -global_basis.x - global_basis.z, global_basis.y - global_basis.z, -global_basis.y - global_basis.z]:
		var space = get_world_3d().direct_space_state
		var ray = PhysicsRayQueryParameters3D.create(global_position, global_position + axis * 10)
		var cast = space.intersect_ray(ray)
		if !cast.is_empty():
			raycasts.append(axis * (cast.position.distance_to(global_position)))
	
	# Raycasting to find visible players
	for player in get_tree().get_nodes_in_group("Players"):
		if acos(global_position.direction_to(player.camera.global_position).dot(-global_basis.z)) > fov:
			continue
		if randi_range(1, 10) + global_position.distance_to(player.global_position) < 15 and !Input.is_action_pressed("Control"):
			visible_players.append(player)
		var space = get_world_3d().direct_space_state
		var ray = PhysicsRayQueryParameters3D.create(global_position, player.global_position)
		var cast = space.intersect_ray(ray)
		if !cast.is_empty():
			if "owning" in cast.collider:
				if cast.collider.owning == player:
					visible_players.append(player)
	
	
	
	# Choosing a target
	if target_node == null and target_point != null and global_position.distance_to(target_point) < 1:
		target_point = Vector3.ZERO
	if target_node != null and !visible_players.has(target_node):
		target_node = null
	if !visible_players.is_empty() and target_node == null:
		var closest = 1000000
		for player in visible_players:
			if !closest or global_position.distance_to(player.global_position) < closest:
				target_node = player
	if target_node != null:
		target_point = target_node.global_position
	
	
	
	# No target, wander
	if target_node == null and target_point.is_zero_approx():
		influences.append(Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)))
		
		for ray in raycasts:
			if ray.length() < wall_avoidance_distance:
				influences.append(ray.normalized() * (ray.length() - wall_avoidance_distance) * keep_distance_strength * 2)
		
		#for ai in get_tree().get_nodes_in_group("AI"):
		#	if ai == self:
		#		continue
		#	influences.append(ai.global_position.direction_to(global_position) * keep_distance_strength / global_position.distance_squared_to(ai.global_position))
		
		for ghost in get_tree().get_nodes_in_group("Ghosts"):
			influences.append(global_position.direction_to(ghost.global_position) * (global_position.distance_to(ghost.global_position) - target_distance) * keep_distance_strength / global_position.distance_to(ghost.global_position))
			
			output_direction += global_position.direction_to(ghost.global_position)
		output_direction = output_direction.normalized()
	
	
	
	# follow target
	else:
		if target_node != null:
			influences.append(global_position.direction_to(target_point) * (global_position.distance_to(target_point) - target_distance) * keep_distance_strength)
		else:
			influences.append(global_position.direction_to(target_point) * keep_distance_strength * 10)
		output_direction = global_position.direction_to(target_point)
		
		for player in visible_players:
			if player == target_node:
				continue
			influences.append(player.global_position.direction_to(global_position) * keep_distance_strength / global_position.distance_to(player.global_position))
			output_direction += global_position.direction_to(player) * 0.5
		output_direction = output_direction.normalized()
		
		for ray in raycasts:
			if ray.length() < wall_avoidance_distance:
				influences.append(ray.normalized() * (ray.length() - wall_avoidance_distance) * keep_distance_strength * 2)
		
		#for ai in get_tree().get_nodes_in_group("AI"):
		#	if ai == self:
		#		continue
		#	influences.append(ai.global_position.direction_to(global_position) * keep_distance_strength / global_position.distance_squared_to(ai.global_position))
	
	
	for i in influences:
		output_velocity += i.limit_length(max_influence_strength)
	if output_direction == Vector3.ZERO:
		output_direction = output_velocity.normalized()

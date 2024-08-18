extends Node3D



@export var item_id : int
@export var firerate : Array
@export var shots : Array
@export var mag_size : int
@export var reload_time : float
@export var muzzle_vel : float
@export var damage : Array
@export var tearing : float
@export var tagging : float
@export var effective_range : float
@export var recovery : float
@export var recoil : float
@export var spray : float
@export var inventory_size : int
@export var weight : float
@export var camera_movement : float
@export var casing : int
@export var equip_pos : Node3D
@export var unequip_pos : Node3D
@export var equip_speed := 200.0

@export var audio : AudioStreamPlayer3D
@export var light : SpotLight3D
@export var ejection : Marker3D
@export var grip1 : Marker3D
@export var grip2 : Marker3D


enum wstate {
	unequipped,
	equipped,
	equipping,
	unequipping
}
var state := wstate.unequipped
var equip_time : int

var firemode := 0

var magazine : int

var _mouse_down := false
var _fire_time_ms := 0

var _heat := 0.0
var _burst := 0

var reloading := false
var reload_start_time := 0


@onready var _firedelay = 1000 / firerate[firemode]
@onready var hud = UiManager.playerhud


signal on_equip
signal on_unequip



func _ready():
	Settings.settings_changed.connect(_load_settings)
	_load_settings()



func equip():
	equip_time = Time.get_ticks_msec()
	state = wstate.equipping
	show()
	
	if !Gamemanager.mp_active or is_multiplayer_authority():
		hud.set_ammo(true, magazine)
		hud.alt_fire(shots[firemode])
		get_parent().get_parent().using_objective = false
		hud.stop_progress("Planting")



func unequip():
	equip_time = Time.get_ticks_msec()
	state = wstate.unequipping
	
	reloading = false
	_heat = 0
	_burst = 0
	_mouse_down = false
	if !Gamemanager.mp_active or is_multiplayer_authority():
		hud.stop_progress("reloading")



func _load_settings():
	light.shadow_enabled = Settings.shadows_enabled



func _process(delta):
	match state:
		wstate.unequipped:
			transform = unequip_pos.transform
		wstate.equipping:
			if Input.is_action_pressed("Mouse1"):
				_mouse_down = true
			else:
				_mouse_down = false
			transform = unequip_pos.transform.interpolate_with(equip_pos.transform, (Time.get_ticks_msec() - equip_time) / equip_speed)
		wstate.unequipping:
			transform = equip_pos.transform.interpolate_with(unequip_pos.transform, (Time.get_ticks_msec() - equip_time) / equip_speed)
	
	if Time.get_ticks_msec() > _fire_time_ms + _firedelay * 0.6:
		light.light_energy = 0
	else:
		light.light_energy = 0.35



func _physics_process(delta):
	if Gamemanager.mp_active and !is_multiplayer_authority():
		return
	
	var time = Time.get_ticks_msec()
	
	
	if state == wstate.equipping and Time.get_ticks_msec() - equip_time > equip_speed:
		state = wstate.equipped
		on_equip.emit()
		transform = equip_pos.transform
		get_parent().get_node("Crosshair").rotation = Vector3.ZERO
	if state == wstate.unequipping and Time.get_ticks_msec() - equip_time > equip_speed:
		state = wstate.unequipped
		on_unequip.emit()
		hide()
	if state != wstate.equipped:
		return
	
	
	# Reloading
	if Input.is_action_just_pressed("R") and !reloading and !UiManager.paused:
		if magazine < mag_size and _burst == 0:
			reloading = true
			reload_start_time = time
			magazine = min(magazine, 1)
			hud.set_ammo(true, magazine)
			hud.start_progress(reload_time / 1000, "reloading")
			$"../..".sound_time = Time.get_ticks_msec() + 300
			$"../..".play_sound.rpc(4)
	
	if reloading and time - reload_start_time > reload_time:
		reloading = false
		magazine += mag_size
		hud.set_ammo(true, magazine)
	
	
	# Alt Fire
	if Input.is_action_just_pressed("Mouse2"):
		firemode += 1
		if firemode >= firerate.size():
			firemode = 0
		
		_firedelay = 1000 / firerate[firemode]
		hud.alt_fire(shots[firemode])
		Audiomanager.play("res://assets/alt_fire.mp3")
	
	
	# Trigger Input
	if Input.is_action_just_pressed("Mouse1") and !UiManager.paused:
		_mouse_down = true
		if time > _fire_time_ms + _firedelay * shots[firemode]:
			_burst = shots[firemode]
	
	if !Input.is_action_pressed("Mouse1") and _mouse_down:
		_mouse_down = false
	
	if shots[firemode] == 0:
		if _mouse_down and !UiManager.paused:
			_burst = 1
		else:
			_burst = 0
	
	
	# Checking for remaining ammo
	if magazine < 1 or reloading:
		_burst = 0
	
	
	var player = $"../.."
	var crosshair = get_parent().get_node("Crosshair")
	
	
	# Firing
	if _burst > 0 and time > _fire_time_ms + _firedelay:
		
		var camera = get_parent()
		var inaccuracy = player.velocity.length()
		if !player.is_anchored():
			inaccuracy = 3.0
		inaccuracy = (inaccuracy + _heat) * spray / 400
		
		if Gamemanager.mp_active:
			fire.rpc(get_parent().global_position, player.get_velocity() + muzzle_vel * (-crosshair.global_basis.z + (crosshair.global_basis.y * inaccuracy * randf()).rotated(crosshair.global_basis.z.normalized(), randf_range(0, TAU))).normalized())
		else:
			fire(get_parent().global_position, player.get_velocity() + muzzle_vel * (-crosshair.global_basis.z + (crosshair.global_basis.y * inaccuracy * randf()).rotated(crosshair.global_basis.z.normalized(), randf_range(0, TAU))))
		
		
		if !player.is_anchored() or player.velocity.length() > 1:
			rotate(basis.x.normalized(), recoil * 0.005)
			camera.rotate(camera.basis.x.normalized(), recoil * 0.005 * camera_movement)
			crosshair.rotate(camera.basis.x.normalized(), recoil * 0.005)
		else:
			rotate(basis.x.normalized(), recoil * 0.004)
			camera.rotate(camera.basis.x.normalized(), recoil * 0.004 * camera_movement)
			crosshair.rotate(camera.basis.x.normalized(), recoil * 0.004)
		
		_heat += 1
		_burst -= 1
		magazine -= 1
		
		hud.set_ammo(true, magazine)
	
	
	# Recovering heat after firing
	if time - _fire_time_ms > _firedelay:
		rotation.x = move_toward(rotation.x, 0.0, recovery * delta)
		get_parent().rotation.x = move_toward(get_parent().rotation.x, 0.0, recovery * delta * camera_movement)
		crosshair.rotation.x = move_toward(crosshair.rotation.x, 0.0, recovery * delta)
		_heat = move_toward(_heat, 0.0, recovery * delta * 100)


@rpc("any_peer", "call_local", "reliable")
func fire(pos : Vector3, velocity : Vector3):
	audio.pitch_scale = randf_range(0.94, 1.06)
	audio.play()
	
	_fire_time_ms -= _firedelay
	if Time.get_ticks_msec() > _fire_time_ms + _firedelay:
		_fire_time_ms = Time.get_ticks_msec()
	
	var _bullet = preload("res://classes/bullet.tscn").instantiate()
	_bullet.set_multiplayer_authority(get_multiplayer_authority())
	add_child(_bullet)
	_bullet.look_at(pos + velocity)
	_bullet.global_position = pos + velocity.normalized()
	_bullet.velocity = velocity
	_bullet.mass = damage
	_bullet.tearing = tearing
	_bullet.tagging = tagging
	_bullet.effective_range = effective_range
	_bullet.owning_player = get_parent().get_parent()
	
	var _smoke = preload("res://classes/smoke.tscn").instantiate()
	_smoke.size = Vector3(0.01, 0.01, 4)
	_smoke.fade_speed = 0.15
	_smoke.start_density = 0.002
	Gamemanager.add_child(_smoke)
	_smoke.global_position = light.global_position + velocity.normalized() * 3
	_smoke.look_at(light.global_position)
	
	await get_tree().create_timer(0.05).timeout
	
	if get_parent():
		var case = preload("res://classes/casing.tscn").instantiate()
		case.type = casing
		case.velocity = ejection.global_basis.z.normalized() * 5 + Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-0.3, 0.3)) + get_parent().get_parent().velocity
		case.angular = Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
		Gamemanager.add_child(case)
		case.global_position = ejection.global_position
		case.look_at(case.global_position + velocity)
		case.global_rotate(case.angular.normalized(), 0.25)

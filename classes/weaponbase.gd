extends Node3D



@export var item_id : int
@export var firerate : Array
@export var shots : Array
@export var mag_size : int
@export var reload_time : float
@export var muzzle_vel : float
@export var damage : float
@export var tearing : float
@export var effective_range : float
@export var recovery : float
@export var recoil : float
@export var spray : float
@export var inventory_size : int
@export var handling_time : float

@export var audio : AudioStreamPlayer3D
@export var light : SpotLight3D


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



#region entry/exit
func _enter_tree():
	set_multiplayer_authority(get_parent().get_multiplayer_authority())



func _ready():
	if !Gamemanager.mp_active or is_multiplayer_authority():
		hud.set_ammo(true, magazine)
		hud.alt_fire(shots[firemode])
		get_parent().get_parent().using_bomb = false
		hud.stop_progress("Planting")
	
	rotation = Vector3.ZERO
	position = Vector3(0.207, -0.15, -0.205)
	
	Settings.settings_changed.connect(_load_settings)
	_load_settings()




func _exit_tree():
	reloading = false
	_heat = 0
	_burst = 0
	_mouse_down = false
	if is_multiplayer_authority():
		hud.stop_progress("reloading")
		hud.set_ammo(0, false)
	audio.stop()
	
	request_ready()
#endregion



func _load_settings():
	light.shadow_enabled = Settings.shadows_enabled



func _process(delta):
	if Time.get_ticks_msec() > _fire_time_ms + 35:
		light.light_energy = 0
	else:
		light.light_energy = 0.2



func _physics_process(delta):
	if Gamemanager.mp_active and !is_multiplayer_authority():
		return
	
	var time = Time.get_ticks_msec()
	
	
	# Reloading
	if Input.is_action_just_pressed("R") and !reloading and !UiManager.paused:
		if magazine < mag_size and _burst == 0:
			reloading = true
			reload_start_time = time
			hud.start_progress(reload_time / 1000, "reloading")
			$"../..".sound_time = Time.get_ticks_msec() + 300
			$"../..".play_sound.rpc(4)
	
	if reloading and time - reload_start_time > reload_time:
		reloading = false
		magazine = mag_size
		hud.set_ammo(true, magazine)
	
	
	# Alt Fire
	if Input.is_action_just_pressed("F"):
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
	
	
	# Firing
	if _burst > 0 and time > _fire_time_ms + _firedelay:
		
		var inaccuracy := 2.0
		var player = $"../.."
		if !player.is_anchored() or player.velocity.length() > 0.1:
			inaccuracy = 7.0
		inaccuracy = (inaccuracy + _heat) * spray / 490
		
		if Gamemanager.mp_active:
			fire.rpc(get_parent().global_position, player.get_velocity() + muzzle_vel * (-global_basis.z + (global_basis.y * inaccuracy * randf()).rotated(global_basis.z.normalized(), randf_range(0, TAU))).normalized())
		else:
			fire(get_parent().global_position, player.get_velocity() + muzzle_vel * (-global_basis.z + (global_basis.y * inaccuracy * randf()).rotated(global_basis.z.normalized(), randf_range(0, TAU))))
		
		
		
		if !player.is_anchored() or player.velocity.length() > 1:
			rotate(basis.x.normalized(), recoil * 0.006)
			get_parent().rotate(basis.x.normalized(), recoil * 0.006)
		else:
			rotate(basis.x.normalized(), recoil * 0.004)
			get_parent().rotate(basis.x.normalized(), recoil * 0.004)
		
		_heat += 1
		_burst -= 1
		magazine -= 1
		
		hud.set_ammo(true, magazine)
	
	
	# Recovering heat after firing
	if time - _fire_time_ms > _firedelay:
		rotation.x = move_toward(rotation.x, 0.0, recovery * delta)
		get_parent().rotation.x = move_toward(rotation.x, 0.0, recovery * delta)
		_heat = move_toward(_heat, 0.0, recovery * delta * 100)


@rpc("any_peer", "call_local", "reliable")
func fire(pos : Vector3, velocity : Vector3):
	audio.pitch_scale = randf_range(0.94, 1.06)
	audio.play()
	
	_fire_time_ms -= _firedelay
	if Time.get_ticks_msec() > _fire_time_ms + _firedelay:
		_fire_time_ms = Time.get_ticks_msec()
	
	var _bullet = preload("res://classes/bullet.tscn").instantiate()
	add_child(_bullet)
	_bullet.look_at(pos + velocity)
	_bullet.global_position = pos + velocity.normalized()
	_bullet.velocity = velocity
	_bullet.mass = damage
	_bullet.tearing = tearing
	_bullet.effective_range = effective_range
	_bullet.owning_player = get_parent().get_parent()
	
	var _smoke = preload("res://classes/smoke.tscn").instantiate()
	_smoke.size = Vector3(0.01, 0.01, 4)
	_smoke.fade_speed = 0.15
	_smoke.start_density = 0.002
	Gamemanager.add_child(_smoke)
	_smoke.global_position = light.global_position + velocity.normalized() * 3
	_smoke.look_at(light.global_position)
	

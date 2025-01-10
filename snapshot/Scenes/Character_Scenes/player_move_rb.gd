extends RigidBody3D

@onready var mesh = get_node("Player_Mesh")
@onready var grab_ray = mesh.get_node("Ray")

# How fast the player accelerates.
#@export var speed_lerp : float
@export var walk_speed : float
@export var swing_force : float
@export var input_influence_move : float
@export var input_influence_face : float
#@onready var walk_speed = Vector3(0,0,0)

@export var floor_check_height : float
@export var speed_damp : float

@export var rotation_speed : float
@export var rotation_thresh : float
@export var rotation_lerp : float
@onready var constant_interp = mesh.rotation.y
@onready var ray = get_node("Ray")
@onready var ground_norm = Vector3(0,1,0)

@onready var grounded = false
	
#@onready var cam : Camera3D = get_viewport().get_camera_3d()

@onready var last_global_pos = global_position

@onready var navigation = $PlayerNavigation

signal force_added()

func _physics_process(delta):
	#var direction =  Vector3(0,0,0)
	#if navigation.navigate:
		#direction = Vector3(1,0,1) * (navigation.marker.global_position - global_position)
		
		
	var input_direction = Vector3(Input.get_axis("move_left","move_right"),0,Input.get_axis("move_forward","move_back"))
	if input_direction.length() > 0:
		input_direction = input_direction.normalized()
	var raw_input_direction = input_direction
	
	#detect ground
	grounded = false
	ground_norm = Vector3(0,1,0)
	#ray.target_position = Vector3(0,-10,0)
	#ray.force_raycast_update()
	if ray.is_colliding():
		var collision_norm = ray.get_collision_normal()
		var check_height = abs(ray.position.y) / Vector3(0,1,0).dot(collision_norm) + floor_check_height
		if (ray.global_position - ray.get_collision_point()).length() <= check_height:
			grounded = true
			ground_norm = collision_norm
				
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	apply_central_force(9.8 * -ground_norm * mass)
	
	var walk_dir = input_direction.cross(ground_norm).cross(-ground_norm).normalized() * input_direction.length()
			
	#$DebugText/Label.text = str(walk_dir)
	var last_direction = (global_position - last_global_pos).normalized()
	if last_direction.dot(walk_dir) > 0:
		walk_dir = lerp(last_direction * walk_dir.length(),walk_dir,input_influence_move * delta)
		
			
	var grabbed = grab_ray.grabbed
	
	#rotate the mesh
	var target_dir_3D
	var target_dir
	if !grabbed:
		target_dir_3D = global_position - last_global_pos
		target_dir = lerp(Vector2(target_dir_3D.x,target_dir_3D.z),Vector2(raw_input_direction.x,raw_input_direction.z),input_influence_face)
	else:
		target_dir_3D = grabbed.linear_velocity * delta
		var grabbed_difference = grabbed.global_position + grab_ray.anchor_offset_object - grab_ray.global_position
		target_dir = Vector2(grabbed_difference.x,grabbed_difference.z)
	var length_scaled = target_dir_3D.length()
	var turn = length_scaled >= rotation_thresh * 0.01
	var ang_dis = abs(angle_difference(mesh.rotation.y,atan2(target_dir.x,target_dir.y)))
	if turn && ang_dis > 0:
		var lerp_weight_constant = min(1,length_scaled * rotation_speed * delta / ang_dis)
		constant_interp = lerp_angle(constant_interp,atan2(target_dir.x,target_dir.y),lerp_weight_constant)
		mesh.rotation.y = lerp_angle(mesh.rotation.y,constant_interp,rotation_lerp)
	#update position for rotation
	last_global_pos = global_position
	
	#move the player
	if grounded:
		#var walk_dir
		#if grabbed:
		#else:
			#todo: dot comparison here to determine magnitude of walk_dir
			#walk_dir = -mesh.global_basis.z.normalized().cross(ground_norm).cross(ground_norm) * input_direction.length()
			#var mesh_forward = -mesh.global_basis.z.normalized()
			#walk_dir = lerp(mesh_forward,input_direction.normalized(),input_influence).cross(ground_norm).cross(ground_norm) * input_direction.length()
		#walk_speed = lerp(walk_speed,walk_dir * max_walk_speed,speed_lerp * delta)
		var force_add = walk_dir * walk_speed * delta
		if !grabbed:
			apply_central_impulse.call_deferred(force_add)
		emit_signal("force_added",force_add)
		#apply_central_force(Vector3(max_walk_speed,0,0))
		#damp movement
		#apply_central_force(-linear_velocity * delta * speed_damp)
		linear_velocity /= 1 + speed_damp * delta
	elif grabbed:
		var force_add = input_direction * swing_force * delta
		apply_central_impulse.call_deferred(force_add)
		grabbed.apply_central_impulse.call_deferred(-force_add)
		#print_debug("swing force added")

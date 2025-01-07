extends Node3D

@onready var character : RigidBody3D = get_parent()
@export var step_time : float
@onready var left_target = $IKTarget_Leg_Left
@onready var right_target = $IKTarget_Leg_Right
var cycle_position = 0
@export var stance_radius : float
@export var step_height : float
@export var foot_radius : float
@export var bob_height : float
@export var bob_effect : float
var armature_offset = $Armature.position
@export var lerp_speed : float
var ground_norm = Vector3(0,1,0)
var character_velocity = Vector3(0,0,0)

#var stance_offset = Vector3(0,0,0)
#var radius_offset = Vector3(0,0,0)

func get_lift(x : float,height : float):
	var r = (1 + pow(height,2)) / (2 * height)
	var c = height - r
	return sqrt(pow(r,2) - pow(x,2)) + c
	
func _process(delta):
	cycle_position = fmod(cycle_position + delta / step_time,2)
	var stance_offset = stance_radius * global_basis.x.cross(ground_norm).cross(ground_norm)
	var radius_offset = foot_radius * Vector3(0,1,0) * scale
	#stance_offset = lerp(stance_offset,stance_radius * global_basis.x.cross(ground_norm).cross(ground_norm),lerp_speed * delta)
	#radius_offset = lerp(radius_offset,foot_radius * Vector3(0,1,0) * scale,lerp_speed * delta)
	ground_norm = lerp(ground_norm,character.ground_norm,lerp_speed * delta)
	var target_velocity
	if character.linear_velocity:
		target_velocity = character.linear_velocity
	else:
		target_velocity = Vector3(0,0,0)
	character_velocity = lerp(character_velocity,target_velocity,lerp_speed * delta)
	#var ground_norm = character.ground_norm
	#var character_velocity = character.linear_velocity
	
	var spread_left = Vector3(0,0,0)
	var spread_right = Vector3(0,0,0)
	var lift_left = Vector3(0,0,0)
	var lift_right = Vector3(0,0,0)
	var bob = Vector3(0,0,0)
	
	#wtf is Vector3(nan,nan,nan)???
	if character_velocity:
		var step_radius = character_velocity.length() * step_time / 2
		var move_direction = character_velocity.normalized()
		var step_position_right = abs(1 - cycle_position) * 2 - 1
		var step_position_left = (1 - abs(1 - cycle_position)) * 2 - 1
		var step_radius_left = step_radius * step_position_left
		var step_radius_right = step_radius * step_position_right
		spread_left = step_radius_left * move_direction
		spread_right = step_radius_right * move_direction
		var lift_cycle_left = 0 if sign(fmod(cycle_position,1) - cycle_position) < 0 else 1
		var lift_cycle_right = 1 if sign(fmod(cycle_position,1) - cycle_position) < 0 else 0
		lift_left = get_lift(spread_left.length() / step_radius,step_height) * step_radius * lift_cycle_left * Vector3(0,1,0)
		lift_right = get_lift(spread_right.length() / step_radius,step_height) * step_radius * lift_cycle_right * Vector3(0,1,0)
		bob = (get_lift(fmod(cycle_position,1) * 2 - 1,bob_height) * bob_effect - bob_effect * bob_height) * Vector3(0,1,0) * step_radius
		
	#spread_left = lerp(spread_left,new_spread_left,lerp_speed * delta)
	#spread_right = lerp(spread_right,new_spread_right,lerp_speed * delta)
	#lift_left = lerp(lift_left,new_lift_left,lerp_speed * delta)
	#lift_right = lerp(lift_right,new_lift_right,lerp_speed * delta)
	#bob = lerp(bob,new_bob,lerp_speed * delta)
		
	#todo: clamp relative travel
	var global_transform_interpolated = get_global_transform_interpolated()
	#var origin_interpolated = global_transform_interpolated.origin
	#
	#var position_armature = $Armature.global_position - origin_interpolated
	#var new_position_armature = lerp(position_armature,(armature_offset + bob) * scale,lerp_speed * delta)
	$Armature.global_transform = global_transform_interpolated.translated((armature_offset + bob) * scale)
	
	#var position_left = left_target.global_position - origin_interpolated
	#var new_position_left = lerp(position_left,spread_left + lift_left + radius_offset - stance_offset,lerp_speed * delta)
	left_target.global_transform = global_transform_interpolated.translated(spread_left + lift_left + radius_offset - stance_offset)
	
	#var position_right = right_target.global_position - origin_interpolated
	#var new_position_right = lerp(position_right,spread_right + lift_right + radius_offset + stance_offset,lerp_speed * delta)
	right_target.global_transform = global_transform_interpolated.translated(spread_right + lift_right + radius_offset + stance_offset)

#func _physics_process(delta):
	##todo: clamp relative travel
	#left_target.position = (spread_left + lift_left + radius_offset - stance_offset).rotated(basis.y.normalized(),-rotation.y) / scale
	#right_target.position = (spread_right + lift_right + radius_offset + stance_offset).rotated(basis.y.normalized(),-rotation.y) / scale
	

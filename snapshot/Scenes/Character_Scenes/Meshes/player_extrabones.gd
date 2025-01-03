extends Node3D

@onready var character : RigidBody3D = get_parent()
@export var step_time : float
@onready var left_target = $Armature/IKTarget_Leg_Left
@onready var right_target = $Armature/IKTarget_Leg_Right
var cycle_position = 0
@export var stance_radius : float
@export var step_height : float

func get_lift(x : float):
	var r = (1 + pow(step_height,2)) / (2 * step_height)
	var c = step_height - r
	return sqrt(pow(r,2) - pow(x,2)) + c

func _physics_process(delta):
	cycle_position = fmod(cycle_position + delta / step_time,2)
	var ground_norm = character.ground_norm
	var character_velocity = character.linear_velocity
	var step_radius = character_velocity.length() * step_time / 2
	var move_direction = character_velocity.normalized()
	var step_position_right = abs(1 - cycle_position) * 2 - 1
	var step_position_left = (1 - abs(1 - cycle_position)) * 2 - 1
	var spread_left = Vector3(0,0,0)
	var spread_right = Vector3(0,0,0)
	var stance_offset = stance_radius * global_basis.x.cross(ground_norm).cross(ground_norm)
	if move_direction.length() > 0:
		var step_radius_left = step_radius * step_position_left
		var step_radius_right = step_radius * step_position_right
		spread_left = step_radius_left * move_direction
		spread_right = step_radius_right * move_direction
	var lift_cycle_left = 0 if sign(fmod(cycle_position,1) - cycle_position) < 0 else 1
	var lift_cycle_right = 1 if sign(fmod(cycle_position,1) - cycle_position) < 0 else 0
	var lift_left = get_lift(spread_left.length() / step_radius) * step_radius * lift_cycle_left * ground_norm
	var lift_right = get_lift(spread_right.length() / step_radius) * step_radius * lift_cycle_right * ground_norm
	left_target.global_position = global_position - stance_offset + spread_left + lift_left
	right_target.global_position = global_position + stance_offset + spread_right + lift_right

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

var stance_offset = Vector3(0,0,0)
var radius_offset = Vector3(0,0,0)
var spread_left = Vector3(0,0,0)
var spread_right = Vector3(0,0,0)
var lift_left = Vector3(0,0,0)
var lift_right = Vector3(0,0,0)

func get_lift(x : float,height : float):
	var r = (1 + pow(height,2)) / (2 * height)
	var c = height - r
	return sqrt(pow(r,2) - pow(x,2)) + c
	
func _process(delta):
	cycle_position = fmod(cycle_position + delta / step_time,2)
	var ground_norm = character.ground_norm
	stance_offset = stance_radius * global_basis.x.cross(ground_norm).cross(ground_norm)
	radius_offset = foot_radius * Vector3(0,1,0) * scale
	var bob = Vector3(0,0,0)
	var character_velocity = character.linear_velocity
	
	if character_velocity.length() > 0:
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
	else:
		spread_left = Vector3(0,0,0)
		spread_right = Vector3(0,0,0)
		lift_left = Vector3(0,0,0)
		lift_right = Vector3(0,0,0)
		
	#todo: clamp relative travel
	$Armature.global_transform = get_global_transform_interpolated().translated((armature_offset + bob) * scale)

func _physics_process(delta):
	#todo: clamp relative travel
	left_target.position = (spread_left + lift_left + radius_offset - stance_offset).rotated(basis.y.normalized(),-rotation.y) / scale
	right_target.position = (spread_right + lift_right + radius_offset + stance_offset).rotated(basis.y.normalized(),-rotation.y) / scale
	

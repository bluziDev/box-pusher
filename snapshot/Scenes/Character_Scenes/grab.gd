extends RayCast3D

var grabbed : RigidBody3D = null
#var anchor = Vector3(0,0,0)
var explicit_grabbed = null
var anchor_offset_character = Vector3(0,0,0)
var anchor_offset_object = Vector3(0,0,0)
@export var connection_strength : float
@export var control_force : float

@onready var character : RigidBody3D = get_parent().get_parent()

func _input(event):
	if event.is_action_pressed("interact"):
		toggle_grab()

func toggle_grab():
	if grabbed:
		set_grabbed(null)
	elif is_colliding():
		var object = get_collider()
		if object.is_in_group("grabbable"):
			set_grabbed(object)

func set_grabbed(object,explicit : bool = true):
	if explicit:
		explicit_grabbed = object
	grabbed = object
	if grabbed:
		set_anchor(grabbed,get_collision_point())

func set_anchor(object,anchor : Vector3):
	anchor_offset_character = anchor - character.global_position
	anchor_offset_object = anchor - object.global_position
	
func character_force_added(force : Vector3):
	if grabbed:
		var force_per_mass = force / character.mass
		grabbed.apply_central_force(force_per_mass * grabbed.mass * control_force)
	
func _ready():
	add_exception(character)
	character.connect("force_added",character_force_added)

func _physics_process(delta):
	$DebugText/Label.text = str(grabbed)
	if grabbed:
		var character_mass = character.mass
		var object_mass = grabbed.mass
		var character_anchor = character.global_position + anchor_offset_character
		var object_anchor = grabbed.global_position + anchor_offset_object
		var character_weighted_anchor = character_anchor * character.mass
		var object_weighted_anchor = object_anchor * object_mass
		var anchor = (character_weighted_anchor + object_weighted_anchor) / (character_mass + object_mass)
		var anchor_difference_character = anchor - character_anchor
		var anchor_difference_object = anchor - object_anchor
		var desired_projected_velocity_character = anchor_difference_character / delta
		var desired_projected_velocity_object = anchor_difference_object / delta
		character.linear_velocity = lerp(character.linear_velocity,desired_projected_velocity_character,connection_strength * delta)
		grabbed.linear_velocity = lerp(grabbed.linear_velocity,desired_projected_velocity_object,connection_strength * delta)
		#character.linear_velocity += (desired_projected_velocity_character\
									#- character.linear_velocity.project(anchor_difference_character.normalized())\
									 #) * connection_strength
		#grabbed.linear_velocity += (desired_projected_velocity_object\
									#- grabbed.linear_velocity.project(anchor_difference_object.normalized())\
									 #) * connection_strength
	pass

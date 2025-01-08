extends RayCast3D

var grabbed : RigidBody3D = null
#var anchor = Vector3(0,0,0)
var explicit_grabbed = null
var anchor_offset_object = Vector3(0,0,0)
@export var connection_strength : float
@export var control_force : float
@export var slack : float
#var slack = target_position.length()
@export var straightness : float

@onready var mesh = get_parent()
@onready var character : RigidBody3D = mesh.get_parent()
var anchor_normal : Vector3 = Vector3(0,0,0)


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
	anchor_offset_object = anchor - object.global_position
	anchor_normal = get_collision_normal()
	
func character_force_added(force : Vector3):
	if grabbed:
		var force_per_mass = force / character.mass
		grabbed.apply_central_impulse.call_deferred(force_per_mass * grabbed.mass * control_force)
	
func _ready():
	add_exception(character)
	character.connect("force_added",character_force_added)
	scale /= mesh.scale

func _physics_process(delta):
	$DebugText/Label.text = str(grabbed)
	if grabbed:
		var character_mass = character.mass
		var object_mass = grabbed.mass
		var object_anchor = grabbed.global_position + anchor_offset_object
		var shoulder_to_object = object_anchor - global_position
		var character_anchor = global_position + min(slack,shoulder_to_object.length()) * shoulder_to_object.normalized()
		if character.grounded:
			character_anchor = lerp(character_anchor,global_position - slack * anchor_normal,straightness)
		#character_anchor = lerp(character_anchor,object_anchor + (character_anchor - object_anchor).length() * anchor_normal,straighten_force * delta)
		var character_weighted_anchor = character_anchor * character.mass
		var object_weighted_anchor = object_anchor * object_mass
		var anchor = (character_weighted_anchor + object_weighted_anchor) / (character_mass + object_mass)
		var anchor_difference_character = anchor - character_anchor
		var anchor_difference_object = anchor - object_anchor
		var desired_projected_velocity_character = anchor_difference_character / delta
		var desired_projected_velocity_object = anchor_difference_object / delta
		character.linear_velocity = lerp(character.linear_velocity,desired_projected_velocity_character,connection_strength * delta)
		grabbed.linear_velocity = lerp(grabbed.linear_velocity,desired_projected_velocity_object,connection_strength * delta)
		#if character.grounded:
			#var straight_position = object_anchor + slack * anchor_normal
			#var straighten_velocity = (straight_position - global_position) / delta
			#character.linear_velocity = lerp(character.linear_velocity,Vector3(straighten_velocity.x\
																			  #,character.linear_velocity.y\
																			  #,straighten_velocity.z),straighten_force * delta)
		#character.linear_velocity += (desired_projected_velocity_character\
									#- character.linear_velocity.project(anchor_difference_character.normalized())\
									 #) * connection_strength
		#grabbed.linear_velocity += (desired_projected_velocity_object\
									#- grabbed.linear_velocity.project(anchor_difference_object.normalized())\
									 #) * connection_strength
	pass

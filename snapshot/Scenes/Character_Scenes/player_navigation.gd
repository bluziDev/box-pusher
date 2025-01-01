extends Node

@onready var player = get_parent()
@onready var target = player.global_position
@export var pick_distance : float
@onready var ray = $Ray
@onready var marker = $Marker
var navigate = false
@export var minimum_distance : float

func _ready():
	ray.add_exception(player)

func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		find_target(event.position)
		
func find_target(mouse_position):
	var camera = get_tree().root.get_camera_3d()
	ray.global_position = camera.project_ray_origin(mouse_position)
	ray.global_rotation = Vector3(0,0,0)
	ray.target_position = camera.project_ray_normal(mouse_position) * pick_distance
	ray.force_raycast_update()
	if ray.is_colliding():
		target = ray.get_collision_point()
		marker.global_position = target
		navigate = true

func _physics_process(_delta):
	var position_difference = marker.global_position - player.global_position
	if Vector2(position_difference.x,position_difference.z).length() <= minimum_distance:
		navigate = false

extends Node3D

@export var left_ik : Marker3D
@export var right_ik : Marker3D

@export var step_height : float
@export var step_radius : float
@export var step_arc : float

@onready var left_target = left_ik.global_position
@onready var right_target = right_ik.global_position

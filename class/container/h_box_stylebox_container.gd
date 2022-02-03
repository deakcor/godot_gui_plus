extends HBoxContainer

class_name HBoxStyleBoxContainer

var multi_stylebox_cont := StyleboxContainer.new(self)

export var outside_corner_radius := 5
export var inside_corner_radius := 2
export var exception := ["selected","selected_focus"]

func _ready():
	multi_stylebox_cont.outside_corner_radius=outside_corner_radius
	multi_stylebox_cont.inside_corner_radius=inside_corner_radius
	multi_stylebox_cont.exception=exception
	multi_stylebox_cont.init_children()

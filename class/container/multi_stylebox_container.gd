class_name MultiStyleboxContainer

# Used to fit styleboxes together by changing border radius

var cont:Control

var outside_border_radius := 5
var inside_border_radius := 0


func init_children():
	for new_child in cont.get_children():
		_init_child(new_child)
	_update_styleboxs()

func init_child(new_child:Node):
	_init_child(new_child)
	_update_styleboxs()

#private

func _init(new_cont):
	cont=new_cont

func _init_child(new_child:Node):
	if new_child is Control:
		var styleboxes_path := _get_child_styleboxes(new_child)
		var valid:=false
		for path in styleboxes_path:
			var stylebox:StyleBox = new_child.get(path)
			if stylebox is StyleBoxFlat:
				new_child.set(path,stylebox.duplicate())
				valid=true
		if valid:
			if !new_child.is_connected("visibility_changed",self,"_update_styleboxs"):
				new_child.connect("visibility_changed",self,"_update_styleboxs")

func _get_child_styleboxes(child:Control)->Array:
	var tmp:=[]
	for k in (child.get_property_list()):
		if "custom_styles" in k.name:
			tmp.push_back(k.name)
	return tmp

func _update_styleboxs():
	for new_child in cont.get_children():
		if new_child is Control and new_child.visible:
			for path in _get_child_styleboxes(new_child):
				var stylebox:StyleBox = new_child.get(path)
				if stylebox is StyleBoxFlat:
					stylebox.corner_radius_bottom_left=outside_border_radius
					stylebox.corner_radius_bottom_right=outside_border_radius
					stylebox.corner_radius_top_left=outside_border_radius
					stylebox.corner_radius_top_right=outside_border_radius
					if new_child.get_index()>_get_first_index_visible():
						if cont is HBoxContainer:
							stylebox.corner_radius_bottom_left=inside_border_radius
						elif cont is VBoxContainer:
							stylebox.corner_radius_top_right=inside_border_radius
						stylebox.corner_radius_top_left=inside_border_radius
					if new_child.get_index()<_get_last_index_visible():
						stylebox.corner_radius_bottom_right=inside_border_radius
						if cont is HBoxContainer:
							stylebox.corner_radius_top_right=inside_border_radius
						elif cont is VBoxContainer:
							stylebox.corner_radius_bottom_left=inside_border_radius
func _get_first_index_visible()->int:
	for new_child in cont.get_children():
		if new_child is Control and new_child.visible:
			return new_child.get_index()
	return -1



func _get_last_index_visible()->int:
	var i=-1
	for new_child in cont.get_children():
		if new_child is Control and new_child.visible:
			i= new_child.get_index()
	return i

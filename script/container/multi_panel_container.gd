class_name MultiPanelContainer

# 

var cont:Control
var mode:int

enum MODE{
	h,
	v
}

func init_children():
	for new_child in cont.get_children():
		_init_child(new_child)
	_update_panels()

func init_child(new_child:Node):
	_init_child(new_child)
	_update_panels()

#private

func _init(new_cont,new_mode=MODE.h):
	cont=new_cont
	mode=new_mode

func _init_child(new_child:Node):
	if new_child is Control:
		var panel:StyleBoxFlat = new_child.get("custom_styles/panel")
		if panel:
			new_child.set("custom_styles/panel",panel.duplicate())
			if !new_child.is_connected("visibility_changed",self,"_update_panels"):
				new_child.connect("visibility_changed",self,"_update_panels")

func _update_panels():
	for new_child in cont.get_children():
		if new_child is Control and new_child.visible:
			var panel:StyleBoxFlat = new_child.get("custom_styles/panel")
			if panel:
				panel.corner_radius_bottom_left=cont.normal_borders
				panel.corner_radius_bottom_right=cont.normal_borders
				panel.corner_radius_top_left=cont.normal_borders
				panel.corner_radius_top_right=cont.normal_borders
				if new_child.get_index()>_get_first_index_visible():
					if mode==MODE.h:
						panel.corner_radius_bottom_left=cont.inside_borders
					else:
						panel.corner_radius_top_right=cont.inside_borders
					panel.corner_radius_top_left=cont.inside_borders
				if new_child.get_index()<_get_last_index_visible():
					panel.corner_radius_bottom_right=cont.inside_borders
					if mode==MODE.h:
						panel.corner_radius_top_right=cont.inside_borders
					else:
						panel.corner_radius_bottom_left=cont.inside_borders
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

extends Tree

# tree with more functionalities

class_name TreePlus

signal drag_tree_items()
signal drop_tree_items(tree_items,to_tree_item,shift)
signal selection_updated()
signal show_menu(menu,rect)

export var default_drop_mode:int = Tree.DROP_MODE_INBETWEEN

export var search_parent_show_children :bool = false
export var search_children_show_parent :bool = true

export var custom_filter_parent_show_children :bool = false
export var custom_filter_children_show_parent :bool = true

export var search_disable_item = false
export var custom_filter_disable_item = true

export var assure_visiblity:bool = true

export var change_color_button:bool = true

export var popup_menu_display:bool = true

export var reselect_by_metadata:bool =true

export var deselect_when_click_nothing:bool = true

export var modulate_icon_color:Color = Color("699ce8")

export var shortcut_select_all:ShortCut

var selected_items:=[]

var old_relevant_items:=[]

var menu:PopupMenu

var last_hover_item:TreeItem=null
var last_hover_column:int=0

var drag_pos:Vector2
var drag:bool=false

class TreeitemData:
	var selected := []
	var checked := []
	var metadata := []
	var collapsed := false
	func is_selected(column:int):
		return array_value(selected,column)
	func is_checked(column:int):
		return array_value(checked,column)
	func get_metadata(column:int):
		return array_value(metadata,column)
	func array_value(array:Array,column:int):
		if array.size()>column:
			return array[column]
		return null

class DragData:
	var items:=[]
	var tree:Tree
	func _init(new_tree,new_items):
		items=new_items
		tree=new_tree

#public

func clear():
	old_relevant_items.clear()
	for item in get_all_items():
		var relevant:=false
		if item in selected_items:
			relevant=true
		elif item.collapsed:
			relevant=true
		else:
			for k in columns:
				if item.is_checked(k):
					relevant=true
			
		if relevant:
			var tmp:=TreeitemData.new()
			tmp.collapsed=item.collapsed
			for k in columns:
				tmp.selected.push_back(item.is_selected(k))
				tmp.checked.push_back(item.is_checked(k))
				tmp.metadata.push_back(item.get_metadata(k))
			old_relevant_items.push_back(tmp)
	selected_items.clear()
	.clear()

func get_item_children(parent_item:TreeItem=null)-> Array:
	var items:=[]
	if parent_item==null:
		parent_item=get_root()
	if parent_item is TreeItem:
		var item:TreeItem = parent_item.get_children()
		while item != null:
			items.push_back(item)
			item=item.get_next()
	return items

func get_all_items(from_item:TreeItem=null):
	var items:=[]
	if from_item==null:
		from_item=get_root()
		if from_item is TreeItem:
			items.push_back(from_item)
	if from_item is TreeItem:
		for k in get_item_children(from_item):
			items.push_back(k)
			items+=get_all_items(k)
	return items

func toggle_collapse_all(from_item:TreeItem):
	if from_item is TreeItem:
		from_item.collapsed=!from_item.collapsed
		for k in get_all_items(from_item):
			k.collapsed=from_item.collapsed

func select(item,column):
	if is_instance_valid(item):
		item.select(column)
		_multi_selected(item,column,true)

func select_by_metadata(metadata):
	for i in get_all_items():
		for column in columns:
			var m=i.get_metadata(column)
			if m==metadata and !i.is_selected(column):
				select(i,column)

func select_all():
	for i in get_all_items():
		for column in columns:
			select(i,column)

func deselect(item,column):
	if is_instance_valid(item):
		item.deselect(column)
		_multi_selected(item,column,false)

func deselect_by_metadata(metadata):
	for i in selected_items:
		for column in columns:
			if is_instance_valid(i):
				var m=i.get_metadata(column)
				if m==metadata and i.is_selected(column):
					deselect(i,column)

func deselect_all():
	for item in selected_items:
		for column in columns:
			if is_instance_valid(item) and item.is_selected(column):
				deselect(item,column)
				
func finish_init(new_search_text:String="",custom_filters=null,additional_selected_metadata:=[]):
	for item in get_all_items():
		call_deferred("_update_icon_color",item)
		for k in old_relevant_items:
			for i in columns:
				if reselect_by_metadata and item.get_metadata(i)!=null and typeof(item.get_metadata(i))==typeof(k.get_metadata(i)):
					var valid:=false
					valid=item.get_metadata(i)==k.get_metadata(i)
					if !valid:
						valid=_custom_metadata_check(item.get_metadata(i),k.get_metadata(i))
					if valid:
						item.collapsed=k.collapsed
						item.set_checked(i,k.is_checked(i))
						if k.is_selected(i):
							select(item,i)
		for k in additional_selected_metadata:
			for i in columns:
				if reselect_by_metadata and item.get_metadata(i)!=null and typeof(item.get_metadata(i))==typeof(k) and item.get_metadata(i)==k:
					var valid:=false
					valid=item.get_metadata(i)==k
					if !valid:
						valid=_custom_metadata_check(item.get_metadata(i),k)
					if valid:
						select(item,i)
		
	_apply_filter(get_root(),new_search_text,custom_filters)

#override this to make custom metadata check
func _custom_metadata_check(a,b):
	return false

#override this to make custom filter
func _apply_custom_filter(item:TreeItem,column:int,custom_filters)->bool:
	return true

func get_selected_items_by_pos(without_children:=false)->Array:
	var new_selected_items:Array=get_items_without_children(selected_items) if without_children else selected_items
	new_selected_items.sort_custom(self,"_sort_by_pos")
	return new_selected_items

func get_all_parent_items(from_item:TreeItem)->Array:
	var res:=[]
	var tmp:TreeItem=from_item
	while tmp is TreeItem:
		tmp=tmp.get_parent()
		if tmp is TreeItem:
			res.push_back(tmp)
	return res

func get_items_without_children(items:Array)->Array:
	var tmp:=items.duplicate()
	for n in tmp:
		for k in get_all_items(n):
			if k in tmp:
				tmp.erase(k)
	return tmp

func get_items_by_metadata(metadata)->Array:
	var tmp:=[]
	if metadata:
		for i in get_all_items():
			for column in columns:
				var m=i.get_metadata(column)
				if m==metadata:
					tmp.push_back(i)
	return tmp

func get_last_selected()->TreeItem:
	if is_instance_valid(last_hover_item) and last_hover_item in selected_items and last_hover_item.is_selected(last_hover_column):
		return last_hover_item
	elif !selected_items.empty():
		if is_instance_valid(selected_items.back()):
			return selected_items.back()
	return null

#private

func _apply_filter(item:TreeItem,new_search_text:String,custom_filters,parent:TreeItem=null,parent_search_result:=false,parent_filter_result:=false):
	var is_pass_filter:=false
	var is_pass_search:=false
	if item==get_root() and hide_root:
		for child in get_item_children(item):
			if _apply_filter(child,new_search_text,custom_filters,item,true,true):
				is_pass_filter=true
				is_pass_search=true
	elif item:
		for k in columns:
			if !is_pass_search:
				if parent_search_result and search_parent_show_children and (parent!=get_root() or !hide_root):
					is_pass_search=true
				elif parent_search_result or search_children_show_parent:
					if new_search_text=="" or new_search_text.to_lower() in item.get_text(k).to_lower():
						is_pass_search=true
			if !is_pass_filter:
				if parent_filter_result and custom_filter_parent_show_children and (parent!=get_root() or !hide_root):
					is_pass_filter=true
				elif parent_filter_result or custom_filter_children_show_parent:
					if _apply_custom_filter(item,k,custom_filters):
						is_pass_filter=true
		if ((is_pass_filter or custom_filter_children_show_parent) and (search_children_show_parent or is_pass_search)):
			for child in get_item_children(item):
				if _apply_filter(child,new_search_text,custom_filters,item,is_pass_search,is_pass_filter):
					if !is_pass_filter and custom_filter_disable_item:
						item.set_selectable(0,false)
					if !is_pass_search and search_disable_item:
						item.set_selectable(0,false)
					if custom_filter_children_show_parent:
						is_pass_filter=true
					if search_children_show_parent:
						is_pass_search=true
		if !is_pass_filter or !is_pass_search:
			selected_items.erase(item)
			item.free()
	return is_pass_filter and is_pass_search

func _ready():
	connect("gui_input",self,"_gui_input")
	connect("multi_selected",self,"_multi_selected")
	connect("item_selected",self,"_item_selected")
	connect("button_pressed",self,"_item_button_pressed")
	connect("nothing_selected",self,"_nothing_selected")
	connect("item_rmb_selected",self,"_item_rmb_selected")
	connect("item_collapsed",self,"_item_collapsed")
	for k in get_children():
		if k is MenuButton or k is PopupMenu:
			if k is MenuButton:
				menu=k.get_popup()
			else:
				menu=k

func _nothing_selected():
	if deselect_when_click_nothing:
		deselect_all()

func _item_rmb_selected(position:Vector2):
	if get_item_at_position(position)!=null:
		_show_menu(position+rect_global_position+Vector2.DOWN*8)

func _show_menu(position:Vector2):
	if menu:
		if popup_menu_display:
			menu.popup(Rect2(position,Vector2.ONE))
		emit_signal("show_menu",menu,Rect2(position,Vector2.ONE))

func _sort_by_pos(a:TreeItem,b:TreeItem):
	return get_item_area_rect(a).position.y<get_item_area_rect(b).position.y

func _multi_selected(item: TreeItem, column: int, selected: bool):
	var old_selected_items:=selected_items.duplicate()
	if item:
		if selected:
			if assure_visiblity:
				var parent := item.get_parent()
				while parent:
					parent.collapsed=false
					parent = parent.get_parent()
			if selected_items.find_last(item)==-1:
				selected_items.push_back(item)
			call_deferred("_update_icon_color",item)
#				if show_buttons_only_selected:
#					for k in item.get_button_count(column):
#						item.set_button()
			if assure_visiblity:
				scroll_to_item(item)
		else:
			var valid:=true
			for i in selected_items:
				for k in columns:
					if is_instance_valid(i) and i.is_selected(k) and i==item and k!=column:
						valid=false
			if valid:
				selected_items.erase(item)
			call_deferred("_update_icon_color",item)
	emit_signal("selection_updated",old_selected_items)

func _item_selected():
	for k in selected_items:
		call_deferred("_update_icon_color",k)
	var item:=get_selected()
	call_deferred("_update_icon_color",item)
	selected_items=[item]

func _item_collapsed(item:TreeItem):
	for tree_item in selected_items.duplicate():
		if tree_item and is_instance_valid(tree_item):
			for k in columns:
				if !tree_item.is_selected(k):
					selected_items.erase(tree_item)
		call_deferred("_update_icon_color",tree_item)

func _gui_input(event):
	if select_mode==Tree.SELECT_MULTI and shortcut_select_all.is_shortcut(event):
		if has_focus():
			select_all()
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if !event.pressed:
				if get_item_at_position(event.position) == null:
					emit_signal("nothing_selected")
		if event.button_index == BUTTON_RIGHT:
			if get_item_at_position(event.position) == null:
				emit_signal("nothing_selected")
				emit_signal("item_rmb_selected",event.position)
			elif !allow_rmb_select:
				emit_signal("item_rmb_selected",event.position)
	if event is InputEventMouseMotion:
		var item := get_item_at_position(event.position)
		var column := get_column_at_position(event.position)
		if item!=last_hover_item or last_hover_column!=column :
			
			last_hover_item=item
			last_hover_column=column

func _update_icon_color(tree_item:TreeItem):
	if tree_item and is_instance_valid(tree_item):
		for k in columns:
			var modulate := Color(1.0,1.0,1.0)
			if !tree_item.is_selectable(k):
				modulate.a = 0.5
			elif tree_item.is_selected(k):
				modulate = modulate_icon_color
			tree_item.set_icon_modulate(k, modulate)

func get_drag_data(position): # begin drag
	var items := get_selected_items_by_pos()
	if items.empty() or default_drop_mode==DROP_MODE_DISABLED:
		set_drop_mode_flags(DROP_MODE_DISABLED)
		return null
	else:
		set_drop_mode_flags(default_drop_mode)

#		var preview = preload("res://scene/editor/tooltip/tooltip_multi_drag.tscn").instance()
#		for k in items:
#			preview.add_data(k.get_text(0),k.get_icon(0))
#		set_drag_preview(preview) # not necessary
#		for k in selected_items:
#			_update_icon_color(k,true,true)
		return DragData.new(self,items)

func can_drop_data(position, data):
	if data is DragData:
		if drop_mode_flags!=0:
			return data.tree==self
	return false

func drop_data(position, data): # end drag
	var items = data.items
#	for k in items:
#		_update_icon_color(k,true,false)
	var to_item:TreeItem
	var shift = get_drop_section_at_position(position)
	if (shift!=0 and (drop_mode_flags & DROP_MODE_INBETWEEN!=0)) || (shift==0 and (drop_mode_flags & DROP_MODE_ON_ITEM!=0)):
		to_item = get_item_at_position(position)
	if shift>0:
		items.invert()
	emit_signal('drop_tree_items', items, to_item, shift)
	set_drop_mode_flags(DROP_MODE_DISABLED)

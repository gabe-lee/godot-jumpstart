class_name CanvasStack extends RefCounted

static func NOOP() -> void:
    pass

var stack: Array[CanvasItem] = []
var meta_stack: Array[Meta] = []
var lowest_visible_index: int = 0
var lowest_active_index: int = 0

class Meta:
    var name: String = ""
    var hidden_nodes_start: int = 0
    var hidden_nodes_end: int = 0
    var deactivated_nodes_start: int = 0
    var deactivated_nodes_end: int = 0
    var always_visible: bool = false
    var always_active: bool = false
    var release_callback: Callable = CanvasStack.NOOP
    
func hide_item_by_index(idx: int) -> void:
    var meta = meta_stack[idx]
    var item = stack[idx]
    hide_item(meta, item)
func show_item_by_index(idx: int) -> void:
    var item = stack[idx]
    show_item(item)

func show_item(item: CanvasItem) -> void:
    item.show()
func hide_item(meta: Meta, item: CanvasItem) -> void:
    if !meta.always_visible:
        item.hide()

func deactivate_item_by_index(idx: int) -> void:
    var meta = meta_stack[idx]
    var item = stack[idx]
    deactivate_item(meta, item)
func activate_item_by_index(idx: int) -> void:
    var item = stack[idx]
    activate_item(item)

static func deactivate_item(meta: Meta, item: CanvasItem) -> void:
    if !meta.always_active:
        item.set_process(false)
        item.set_process_input(false)
        item.set_process_unhandled_input(false)
static func activate_item(item: CanvasItem) -> void:
    item.set_process(true)
    item.set_process_input(true)
    item.set_process_unhandled_input(true)
static func deactivate_item_unconditional(item: CanvasItem) -> void:
    item.set_process(false)
    item.set_process_input(false)
    item.set_process_unhandled_input(false)
    
func push_canvas_item(name: String, item: CanvasItem, release_callback: Callable = CanvasStack.NOOP, node_should_hide_lower: bool = false, node_should_deactivate_lower: bool = true, always_visible: bool = false, always_active: bool = false) -> void:
    var meta = Meta.new()
    meta.hidden_nodes_start = lowest_visible_index
    if node_should_hide_lower:
        meta.hidden_nodes_end = stack.size()
        for i in range(lowest_visible_index, stack.size()):
            hide_item_by_index(i)
        lowest_visible_index = stack.size()
    else:
        meta.hidden_nodes_end = lowest_visible_index
    meta.deactivated_nodes_start = lowest_active_index
    if node_should_deactivate_lower:
        meta.deactivated_nodes_end = stack.size()
        for i in range(lowest_active_index, stack.size()):
            deactivate_item_by_index(i)
        lowest_active_index = stack.size()
    else:
        meta.deactivated_nodes_end = lowest_active_index
    meta.release_callback = release_callback
    meta.always_active = always_active
    meta.always_visible = always_visible
    meta.name = name
    meta_stack.push_back(meta)
    stack.push_back(item)
    show_item(item)
    activate_item(item)

func pop_item(retain_root: bool = true) -> void:
    if stack.size() == 0: return
    if retain_root and stack.size() == 1:
        assert(false, "cannot pop CanvasItem `" + meta_stack.back().name + "`")
        return
    var meta = meta_stack.pop_back()
    var item = stack.pop_back()
    item.hide()
    meta.release_callback.call()
    item.set_process(false)
    item.set_process_unhandled_input(false)
    var i: int = meta.hidden_nodes_start
    while i < meta.hidden_nodes_end:
        show_item_by_index(i)
        i += 1
    i = meta.deactivated_nodes_start
    while i < meta.deactivated_nodes_end:
        activate_item_by_index(i)
        i += 1
    lowest_active_index = meta.deactivated_nodes_start
    lowest_visible_index = meta.hidden_nodes_start

func pop_all(retain_root: bool = true) -> void:
    var limit: int = 0
    if retain_root:
        limit = 1
    var count = stack.size()
    while count > limit:
        pop_item(retain_root)
        count -= 1

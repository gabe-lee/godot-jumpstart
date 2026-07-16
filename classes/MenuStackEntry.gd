class_name MenuStackEntry extends RefCounted

var callback: Callable = Callable()
var return_values: Dictionary = {}
var refocus: Control = null
var parent: Node = null
var child: Node = null
var child_is_singleton: bool = false

func _init(menu: GameResource) -> void:
    assert(menu.type == GameResource.TYPE.SCENE)
    child = menu.get_scene_node()
    child_is_singleton = menu.usage == GameResource.USAGE.SINGLETON

func with_callback(cb: Callable) -> MenuStackEntry:
    assert(cb.get_argument_count() == 3)
    callback = cb
    return self

func refocus_when_closed(control: Control) -> MenuStackEntry:
    refocus = control
    return self

func close() -> void:
    if not callback.is_null():
        assert(callback.is_valid())
        callback.call(parent, child, return_values)
    if refocus != null:
        refocus.grab_focus.call_deferred()
    if !child_is_singleton:
        child.queue_free()

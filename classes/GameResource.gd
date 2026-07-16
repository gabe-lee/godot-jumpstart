class_name GameResource extends RefCounted

enum TYPE {
    RESOURCE,
    THEME,
    SCENE,
}

enum USAGE {
    INFREQUENT,
    FREQUENT,
    SINGLETON,
}

enum REQ {
    REQUIRED,
    OPTIONAL,
}

enum EXISTS {
    UNKNOWN,
    EXISTS,
    DOES_NOT_EXIST,
}

var game: Game = null
var path: String = ""
var usage: USAGE = USAGE.INFREQUENT
var type: TYPE = TYPE.RESOURCE
var req: REQ = REQ.REQUIRED
var exists: EXISTS = EXISTS.UNKNOWN
var ref: Object = null

func _init(path_: String, type_: TYPE, usage_: USAGE, req_: REQ = REQ.REQUIRED) -> void:
    game = Engine.get_main_loop().current_scene
    path = path_
    assert(path.begins_with("res://") or path.begins_with("user://"))
    usage = usage_
    type = type_
    req = req_
    if usage == USAGE.SINGLETON:
        var res = load(path)
        if res == null:
            if req == REQ.REQUIRED:
                Game.main.post_fatal_error(Game.ERR.MISSING_GAME_RESOURCE, "could not load required resource `%s` from disk" % path)
            else: 
                exists = EXISTS.DOES_NOT_EXIST
                return
        exists = EXISTS.EXISTS
        if type == TYPE.THEME:
            ref = res as Theme
        elif type == TYPE.RESOURCE:
            ref = res
        else:
            assert(type == TYPE.SCENE)
            ref = (res as PackedScene).instantiate()
    elif usage == USAGE.FREQUENT:
        var res = load(path)
        if res == null:
            if req == REQ.REQUIRED:
                Game.main.post_fatal_error(Game.ERR.MISSING_GAME_RESOURCE, "could not load required resource `%s` from disk" % path)
            else: 
                exists = EXISTS.DOES_NOT_EXIST
                return
        exists = EXISTS.EXISTS
        match type:
            TYPE.THEME: assert(res is Theme)
            TYPE.SCENE: assert(res is PackedScene)
            _: pass
        ref = res
    else:
        assert(usage == USAGE.INFREQUENT)
        Game.main.check_weak_resource_refs.connect(__weak_cleanup)

func __weak_cleanup() -> void:
    if ref != null:
        if usage == USAGE.INFREQUENT:
            assert(ref is WeakRef)
            if (ref as WeakRef).get_ref() == null:
                ref = null
                exists = EXISTS.UNKNOWN

func __get_any() -> Object:
    var obj: Object = null
    if ref != null:
        match usage:
            USAGE.INFREQUENT:
                assert(ref is WeakRef)
                obj = (ref as WeakRef).get_ref()
            USAGE.FREQUENT, USAGE.SINGLETON:
                obj = ref
    if obj == null:
        var res = load(path)
        if res == null:
            if req == REQ.REQUIRED:
                Game.main.post_fatal_error(Game.ERR.MISSING_GAME_RESOURCE, "could not load required resource `%s` from disk" % path)
            exists = EXISTS.DOES_NOT_EXIST
            return null
        match usage:
            USAGE.INFREQUENT:
                ref = weakref(res)
                obj = res
            USAGE.FREQUENT:
                ref = res
                obj = res
            USAGE.SINGLETON:
                assert(res is PackedScene)
                ref = (res as PackedScene).instantiate()
                obj = ref
    assert(obj != null)
    exists = EXISTS.EXISTS
    match type:
        TYPE.RESOURCE: assert(obj is Resource)
        TYPE.THEME: assert(obj is Theme)
        TYPE.SCENE:
            match usage:
                USAGE.INFREQUENT, USAGE.FREQUENT: assert(obj is PackedScene)
                USAGE.SINGLETON: assert(obj is Node)
    return obj
    
func get_resource() -> Resource:
    assert(type == TYPE.RESOURCE)
    var obj = __get_any()
    if obj == null: return null
    assert(obj is Resource)
    return obj as Resource

func get_theme() -> Theme:
    assert(type == TYPE.THEME)
    var obj = __get_any()
    if obj == null: return null
    assert(obj is Theme)
    return obj as Theme

func get_packed_scene() -> PackedScene:
    assert(type == TYPE.SCENE and usage != USAGE.SINGLETON)
    var obj = __get_any()
    if obj == null: return null
    assert(obj is PackedScene)
    return obj as PackedScene

func get_scene_node() -> Node:
    assert(type == TYPE.SCENE)
    var obj = __get_any()
    if usage == USAGE.SINGLETON:
        assert(obj is Node)
        return obj as Node
    if obj == null: return null
    assert(obj is PackedScene)
    return (obj as PackedScene).instantiate()

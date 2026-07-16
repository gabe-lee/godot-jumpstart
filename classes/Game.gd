class_name Game extends Node

const PASS = false
const FAIL = true

const USER_DIR: String = "user://"
const RES_DIR: String = "res://"
const TEXT_SCENE_EXT: String = ".tscn"
const BIN_SCENE_EXT: String = ".scn"
const TEXT_RES_EXT: String = ".tres"
const BIN_RES_EXT: String = ".res"
const THEME_EXT: String = ".theme"

static var main: Game = null

@onready var game_layer: Node2D = $game_layer

@onready var game_ui_layer: CanvasLayer = $game_ui_layer
@onready var game_ui_root: MarginContainer = $game_ui_layer/game_ui_root
@onready var game_ui_area: MarginContainer = $game_ui_layer/game_ui_root/game_ui_area

@onready var menu_ui_layer: CanvasLayer = $menu_ui_layer
@onready var menu_ui_root: MarginContainer = $menu_ui_layer/menu_ui_root
@onready var menu_ui_block: ModalBlock = $menu_ui_layer/menu_ui_root/menu_modal_block
@onready var menu_ui_area: MarginContainer = $menu_ui_layer/menu_ui_root/menu_ui_area

@onready var menu_popup_ui_layer: CanvasLayer = $menu_popup_layer
@onready var menu_popup_ui_root: MarginContainer = $menu_popup_layer/menu_popup_root
@onready var menu_popup_ui_block: ModalBlock = $menu_popup_layer/menu_popup_root/menu_popup_block
@onready var menu_popup_ui_area: MarginContainer = $menu_popup_layer/menu_popup_root/menu_popup_area

@onready var notif_ui_layer: CanvasLayer = $notif_ui_layer
@onready var notif_ui_root: MarginContainer = $notif_ui_layer/notif_ui_root
@onready var notif_ui_block: ModalBlock = $notif_ui_layer/notif_ui_root/notif_modal_block
@onready var notif_ui_area: CenterContainer = $notif_ui_layer/notif_ui_root/notif_ui_area

static var IS_DEBUG = OS.is_debug_build():
    get: return IS_DEBUG
    set(v): assert(false)

enum NOTIFICATION_KIND {
    INFO,
    WARNING,
    ERROR,
    FATAL,
}

@warning_ignore_start("unused_signal")

#region Resource Manager

const RES_CLEANUP_TIMEOUT: float = 10.0 # seconds to wait before cleaning up unused resources
var res_cleanup_timer: float = RES_CLEANUP_TIMEOUT
signal check_weak_resource_refs

var Ref_GameTheme: GameResource
var Ref_NotificationPanel: GameResource

func init_resource_manager() -> void:
    Ref_GameTheme = GameResource.new("res://user_interface/GameTheme.theme", GameResource.TYPE.THEME, GameResource.USAGE.SINGLETON)
    Ref_NotificationPanel = GameResource.new("res://user_interface/NotificationPanel.scn", GameResource.TYPE.SCENE, GameResource.USAGE.INFREQUENT)

func resource_manager_process(delta: float) -> void:
    res_cleanup_timer -= delta
    if res_cleanup_timer <= 0:
        res_cleanup_timer += RES_CLEANUP_TIMEOUT
        check_weak_resource_refs.emit()

func resource_manager_pre_quit() -> void:
    pass
#endregion

#region Game Lifecycle

func fatal_quit() -> void:
    get_tree().quit(1)

const LC_CLOSED = 0
const LC_STARTING = 1
const LC_RUNNING = 2
const LC_CLOSING = 3
var lifecycle_state: int = LC_CLOSED

func _init() -> void:
    Game.main = self
    
func _ready() -> void:
    startup_actions()
    post_info_notification("The game has started!")

func _process(delta: float) -> void:
    if lifecycle_state == LC_RUNNING:
        resolution_manager_process(delta)
        settings_manager_process(delta)
        save_manager_process(delta)
        resource_manager_process(delta)
        scene_tree_manager_process(delta)
        game_logic_process(delta)

func quit_actions(suspend: bool = false) -> void:
    if lifecycle_state != LC_RUNNING: return
    lifecycle_state = LC_CLOSING
    game_logic_pre_quit()
    scene_tree_manager_pre_quit()
    resource_manager_pre_quit()
    save_manager_pre_quit() 
    settings_manager_pre_quit()
    resolution_manager_pre_quit()
    lifecycle_state = LC_CLOSED
    if !suspend:
        get_tree().quit()

func startup_actions() -> void:
    if lifecycle_state != LC_CLOSED: return
    lifecycle_state = LC_STARTING
    Result.handle_info = _result_handle_info
    Result.handle_warn = _result_handle_warn
    Result.handle_error = _result_handle_error
    Result.handle_fatal = _result_handle_fatal
    Result.err_str = _result_err_str
    init_resolution_manager()
    init_settings_manager()
    init_save_manager()
    init_resource_manager()
    init_scene_tree_manager()
    init_game_logic()
    lifecycle_state = LC_RUNNING

func _notification(what: int) -> void:
    match what:
        NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_PREDELETE:
            quit_actions(false)
        NOTIFICATION_APPLICATION_PAUSED:
            quit_actions(true)
        NOTIFICATION_APPLICATION_RESUMED:
            startup_actions()
        _: pass

#endregion

#region Resolution Manager

func init_resolution_manager() -> void:
    pass

func resolution_manager_process(_delta: float) -> void:
    pass

func resolution_manager_pre_quit() -> void:
    pass

#endregion

#region Save Manager
const SAVE_MANIFEST_FILENAME: String = "save_manifest.dat" 
const SAVE_MANIFEST_PATH: String =  USER_DIR + SAVE_MANIFEST_FILENAME
const SAVE_FOLDER_NAME: String = "saves"
const SAVE_FOLDER_PATH: String = USER_DIR + SAVE_FOLDER_NAME
const SAVE_SUFFIX = ".sav"

var save_manifest: SaveManifest
var game_state_name: String
var game_state: GameState
var game_state_open: bool = false
var game_state_path: String

signal save_manifest_changed

func init_save_manager() -> void:
    create_saves_folder()
    load_save_file_manifest()

func save_manager_process(delta: float) -> void:
    if game_state_open:
        game_state._process(delta)
    save_manifest._process(delta)

func save_manager_pre_quit() -> void:
    if game_state_open:
        game_state.save(true).handle_fail()
    save_manifest.save(true).handle_fail()

func create_saves_folder() -> void:
    Result.new_check_and_handle(DirAccess.make_dir_recursive_absolute(SAVE_FOLDER_PATH), "Could not create save directory on filesystem", Result.FATAL)

func load_save_file_manifest() -> void:
    save_manifest = SaveManifest.new(SAVE_MANIFEST_PATH)
    var result = Result.cache_first_failure()
    var rebuild_manifest: bool = false
    var manifest_created: bool = false
    var save_dir
    var save_dir_list: PackedStringArray
    if !save_manifest.exists():
        save_dir = DirAccess.open(SAVE_FOLDER_PATH)
        manifest_created=true
        if save_dir:
            save_dir_list = save_dir.get_files()
            if save_dir_list.size() > 0:
                rebuild_manifest = true
    else:
        if result.failed(save_manifest.load()):
            rebuild_manifest = true
            save_manifest = SaveManifest.new(SAVE_MANIFEST_PATH)
    
    if rebuild_manifest:
        manifest_created = true
        post_error(ERR.FAILED_TO_LOAD_MANIFEST, "The save manifest was corrupted or was not present while saves WERE present. Manifest will be rebuilt.")
        result.handle_fail_with_level(Result.WARN)
        result.clear()
        for save_file in save_dir_list:
            var sv_path = make_save_path_with_filename(save_file)
            var sv = GameState.new(sv_path)
            var res = sv.load()
            if res.is_failing():
                post_warning(ERR.CORRUPTED_SAVE_FILE, "Save file `%s` was corrupted, it will be not be available in the rebuilt manifest" % sv_path)
            else:
                save_manifest.add_new_save_to_manifest(sv)
    if manifest_created:
        save_manifest.save().handle_fail(Result.ANY_IS_UPGRADED, Result.TO_FATAL)

func create_new_game_state_file(save_name: String) -> void:
    close_current_game_state()
    var path = make_save_path(save_name)
    var new_save_file = GameState.new(path)
    new_save_file.created_time = Time.get_unix_time_from_system()
    new_save_file.close_time = new_save_file.created_time
    new_save_file.save_name = save_name
    var result = save_manifest.add_new_save_to_manifest(new_save_file)
    if result.handle_fail():
        return 
    result = new_save_file.save(true)
    if result.handle_fail():
        save_manifest.delete_game_state_manifest(new_save_file.save_name).handle_fail()
    return

static func make_save_path_with_filename(save_filename: String) -> String:
    return SAVE_FOLDER_PATH + "/" + save_filename

static func make_save_path(save_name: String) -> String:
    return SAVE_FOLDER_PATH + "/" + make_save_filename(save_name)

static func make_save_filename(save_name: String) -> String:
    return save_name + SAVE_SUFFIX

func save_current_game_state() -> void:
    var result = Result.cache_first_failure()
    if game_state_open:
        result = game_state.save()
        if result.is_failing():
            result.handle_fail()
            return
    else:
        post_error(ERR.FAILED, "no save file is loaded as current save")
        return
    result = save_manifest.update_save_data_in_manifest(game_state)
    if result.is_failing():
        result.handle_fail()
    return

func load_game_state(state_name: String) -> void:
    close_current_game_state()
    var result = Result.cache_first_failure()
    if !save_manifest.has_save_name(state_name):
        post_error(ERR.NO_SAVE_NAME, "Save `%` does not exist in the save manifest to load" % state_name)
        return
    var path = make_save_path(state_name)
    game_state = GameState.new(path)
    result = game_state.load()
    if result.is_failing():
        result.handle_fail()
        close_current_game_state()
    else:
        game_state_open = true
    return

func delete_game_state(save_name: String, send_to_trash: bool = false) -> void:
    if game_state_open and save_name == game_state.save_name:
        game_state.delete(send_to_trash)
        game_state = null
        game_state_open = false
    else:
        var file = GameState.new(make_save_path(save_name))
        file.delete(send_to_trash).handle_fail()
    save_manifest.delete_game_state_manifest(save_name).handle_fail()

func close_current_game_state() -> void:
    if game_state_open:
        save_current_game_state()
    game_state = null
    game_state_open = false
    return

#endregion

#region Error Manager
#region Error Codes
enum ERR {
    # Builtin Error analogs
    NONE = 0,
    FAILED = 1,
    GODOT_UNAVAILABLE = 2,
    GODOT_UNCONFIGURED = 3,
    GODOT_UNAUTHORIZED = 4,
    GODOT_PARAMETER_RANGE_ERROR = 5,
    GODOT_OUT_OF_MEMORY = 6,
    GODOT_FILE_NOT_FOUND = 7,
    GODOT_FILE_BAD_DRIVE = 8,
    GODOT_FILE_BAD_PATH = 9,
    GODOT_FILE_NO_PERMISSION = 10,
    GODOT_FILE_ALREADY_IN_USE = 11,
    GODOT_FILE_CANT_OPEN = 12,
    GODOT_FILE_CANT_WRITE = 13,
    GODOT_FILE_CANT_READ = 14,
    GODOT_FILE_UNRECOGNIZED = 15,
    GODOT_FILE_CORRUPT = 16,
    GODOT_FILE_MISSING_DEPENDENCIES = 17,
    GODOT_FILE_EOF = 18,
    GODOT_CANT_OPEN = 19,
    GODOT_CANT_CREATE = 20,
    GODOT_QUERY_FAILED = 21,
    GODOT_ALREADY_IN_USE = 22,
    GODOT_LOCKED = 23,
    GODOT_TIMEOUT = 24,
    GODOT_CANT_CONNECT = 25,
    GODOT_CANT_RESOLVE = 26,
    GODOT_CONNECTION_ERROR = 27,
    GODOT_CANT_ACQUIRE_RESOURCE = 28,
    GODOT_CANT_FORK = 29,
    GODOT_INVALID_DATA = 30,
    GODOT_INVALID_PARAMETER = 31,
    GODOT_ALREADY_EXISTS = 32,
    GODOT_DOES_NOT_EXIST = 33,
    GODOT_DATABASE_CANT_READ = 34,
    GODOT_DATABASE_CANT_WRITE = 35,
    GODOT_COMPILATION_FAILED = 36,
    GODOT_METHOD_NOT_FOUND = 37,
    GODOT_LINK_FAILED = 38,
    GODOT_SCRIPT_FAILED = 39,
    GODOT_CYCLIC_LINK = 40,
    GODOT_INVALID_DECLARATION = 41,
    GODOT_DUPLICATE_SYMBOL = 42,
    GODOT_PARSE_ERROR = 43,
    GODOT_BUSY = 44,
    GODOT_SKIP = 45,
    GODOT_HELP = 46,
    GODOT_BUG = 47,
    GODOT_PRINTER_ON_FIRE = 48,
    # Game Errors
    MENU_CALLBACK_ERROR,
    MISSING_GAME_RESOURCE,
    NO_SAVE_NAME,
    SAVE_NOT_IN_MANIFEST,
    SAVE_ALREADY_EXISTS,
    MISSING_CHECKSUM,
    FAILED_TO_LOAD_MANIFEST,
    CORRUPTED_SAVE_FILE,
}
static func err_string(err: ERR) -> String:
    return ERR.find_key(err)
#endregion

func _post_error(err: ERR, msg: String, kind: NOTIFICATION_KIND, prev_focus: Control = null):
    var full_msg = "%s\n(%s)" % [msg, err_string(err)]
    push_error(full_msg)
    open_notification(full_msg, kind, prev_focus)

func post_info_notification(msg: String, prev_focus: Control = null):
    print(msg)
    open_notification(msg, NOTIFICATION_KIND.INFO, prev_focus)

func post_fatal_error(err: ERR, msg: String, prev_focus: Control = null) -> void:
    _post_error(err, msg, NOTIFICATION_KIND.FATAL, prev_focus)

func post_error(err: ERR, msg: String, prev_focus: Control = null):
    _post_error(err, msg, NOTIFICATION_KIND.ERROR, prev_focus)

func post_warning(err: ERR, msg: String, prev_focus: Control = null):
    _post_error(err, msg, NOTIFICATION_KIND.WARNING, prev_focus)

func _result_handle_info(result: Result) -> void:
    post_info_notification(result.err_msg, get_viewport().gui_get_focus_owner())

func _result_handle_warn(result: Result) -> void:
    post_warning(result.err, result.err_msg, get_viewport().gui_get_focus_owner())

func _result_handle_error(result: Result) -> void:
    post_error(result.err, result.err_msg, get_viewport().gui_get_focus_owner())

func _result_handle_fatal(result: Result) -> void:
    post_fatal_error(result.err, result.err_msg, get_viewport().gui_get_focus_owner())

func _result_err_str(_err: int) -> String:
    return ""

#endregion


#region Setting Manager
var settings: SettingsData

signal settings_changed

const SETTINGS_FILENAME := "settings.cfg"
const SETTINGS_PATH := USER_DIR + SETTINGS_FILENAME

func init_settings_manager() -> void:
    settings = SettingsData.new(SETTINGS_PATH)
    if !settings.exists():
        var res = settings.save()
        if res.is_failing():
            res.handle_fail()
            return
    else:
        var res = settings.load()
        if res.is_failing():
            res.handle_fail()
    return

func settings_manager_process(delta: float) -> void:
    settings._process(delta)

func settings_manager_pre_quit() -> void:
    settings.save().handle_fail()

#endregion

#region Theme Manager
const THEME_FILENAME := "GameTheme.theme"
const THEME_PATH := RES_DIR + "/user_interface/" + THEME_FILENAME

func update_theme() -> void:
    var theme: Theme = ResourceLoader.load(THEME_PATH, "Theme", ResourceLoader.CACHE_MODE_IGNORE)
    # update for screen edges
    var safe_area: Rect2i = DisplayServer.get_display_safe_area()
    var window_size: Vector2i = get_window().size 
    
    var top_safe = safe_area.position.y
    var left_safe = safe_area.position.x
    var bot_safe = maxi(0, window_size.y - safe_area.end.y)
    var right_safe = maxi(0, window_size.x - safe_area.end.x)
    
    var top_theme: int = 0
    var left_theme: int = 0
    var bot_theme: int = 0
    var right_theme: int = 0

    if theme:
        top_theme = theme.get_constant(&"margin_top", THEME.VARIANT.MARGIN_CONTAINER_SCREEN_EDGE)
        left_theme = theme.get_constant(&"margin_left", THEME.VARIANT.MARGIN_CONTAINER_SCREEN_EDGE)
        bot_theme = theme.get_constant(&"margin_bottom", THEME.VARIANT.MARGIN_CONTAINER_SCREEN_EDGE)
        right_theme = theme.get_constant(&"margin_right", THEME.VARIANT.MARGIN_CONTAINER_SCREEN_EDGE)
    
    var top = max(top_safe, top_theme)
    var left = max(left_safe, left_theme)
    var bot = max(bot_safe, bot_theme)
    var right = max(right_safe, right_theme)

    theme.set_constant(&"margin_top",  THEME.VARIANT.MARGIN_CONTAINER_SCREEN_EDGE, top)
    theme.set_constant(&"margin_left", THEME.VARIANT.MARGIN_CONTAINER_SCREEN_EDGE, left)
    theme.set_constant(&"margin_bottom",  THEME.VARIANT.MARGIN_CONTAINER_SCREEN_EDGE, bot)
    theme.set_constant(&"margin_right",  THEME.VARIANT.MARGIN_CONTAINER_SCREEN_EDGE, right)
    
    game_ui_root.theme = theme
    menu_ui_root.theme = theme
    notif_ui_root.theme = theme
#endregion

#region Scene Tree Manager
var menu_stack: Array[MenuStackEntry] = []

func init_scene_tree_manager() -> void:
    update_theme()
    # Add initial scenese to game/ui

func scene_tree_manager_process(_delta: float) -> void:
    pass

func scene_tree_manager_pre_quit() -> void:
    pass

func close_notification(node: NotificationPanel, kind: NOTIFICATION_KIND) -> void:
    notif_ui_area.remove_child(node)
    if node.prev_focus != null:
        node.prev_focus.grab_focus.call_deferred()
    node.queue_free()
    if kind == NOTIFICATION_KIND.FATAL:
        fatal_quit()
    if notif_ui_area.get_child_count() == 0:
        notif_ui_block.disable()
        unpause_game_logic()

func open_notification(msg: String, kind: NOTIFICATION_KIND, prev_focus: Control = null, front: bool = false) -> void:
    if is_node_ready():
        assert(notif_ui_root != null and notif_ui_area != null and notif_ui_block != null)
        var notif = Ref_NotificationPanel.get_scene_node()
        notif.set_message(msg, kind, prev_focus)
        notif_ui_area.add_child(notif)
        if !front:
            notif_ui_area.move_child(notif, 0)
        notif_ui_block.enable()
        pause_game_logic()

func close_all_menus() -> void:
    while menu_stack.size() > 0:
        close_current_menu()

func close_all_menus_then_open_menu(menu: GameResource) -> void:
    close_all_menus()
    open_child_menu(menu)

func close_all_menus_then_open_menu_advanced(entry: MenuStackEntry) -> void:
    close_all_menus()
    open_child_menu_advanced(entry)

func close_current_menu() -> void:
    if menu_stack.size() > 0:
        var entry = menu_stack.pop_back()
        menu_ui_area.remove_child(entry.child)
        if menu_stack.size() > 0:
            var check_prev = menu_stack.back()
            assert(check_prev.child == entry.parent)
            menu_ui_area.add_child(entry.parent)
        entry.close()

func open_child_menu_advanced(entry: MenuStackEntry) -> Node:
    var prev_node: Node = null
    if menu_stack.size() > 0:
        prev_node = menu_stack.back().child
    entry.parent = prev_node
    if prev_node != null:
        menu_ui_area.remove_child(prev_node)
    menu_ui_area.add_child(entry.child)
    menu_ui_block.enable()
    menu_stack.push_back(entry)
    return entry.child

func open_child_menu(menu: GameResource) -> Node:
    return open_child_menu_advanced(MenuStackEntry.new(menu))


#endregion

#region Game Logic
var game_layer_paused: bool = false;

func pause_game_logic() -> void:
    game_layer_paused = true
    get_tree().paused = true

func unpause_game_logic() -> void:
    game_layer_paused = false
    get_tree().paused = false

func init_game_logic() -> void:
    pass

func game_logic_process(delta: float) -> void:
    if game_layer_paused and game_state != null:
        game_state.banked_time += delta
    else:
        pass

func game_logic_pre_quit() -> void:
    pass

func get_manifest_banked_time() -> float:
    return save_manifest.banked_time

#endregion

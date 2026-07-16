class_name SettingsData extends RefCounted

const DATA_MODE := FileFormatUtil.DATA_MODE.TEXT_CONFIG
const AUTO_SAVE_SOFT_DELAY_SECS: float = 15.0
const AUTO_SAVE_MAX_DELAY_SECS: float = 30.0
const FMT_SIG: PackedByteArray = [83, 69, 84, 84]
const MAX_VERSION: int = 0

enum WIN_MODE {
    WINDOWED = 0,
    BORDERLESS = 1,
    FULLSCREEN = 2,
}

signal file_saved(file: SettingsData)
signal file_loaded(file: SettingsData)


var file_path: String = ""
var format_version: int = MAX_VERSION
var is_open: bool = true
var auto_save_soft_timeout: float = -1.0
var auto_save_max_timeout: float = -1.0
var disable_auto_save: bool = false
var disable_extra_integrity_check: bool = false

var window_width: int = 1200:
    set(val):
        window_width = val
        Game.main.settings_changed.emit()
        queue_save()
var window_height: int = 800:
    set(val):
        window_height = val
        Game.main.settings_changed.emit()
        queue_save()
var window_x: int = 0:
    set(val):
        window_x = val
        Game.main.settings_changed.emit()
        queue_save()
var window_y: int = 0:
    set(val):
        window_y = val
        Game.main.settings_changed.emit()
        queue_save()
var window_mode: WIN_MODE = 0 as WIN_MODE:
    set(val):
        window_mode = val
        Game.main.settings_changed.emit()
        queue_save()

func exists() -> bool:
    return FileAccess.file_exists(file_path)

func load(_is_integrity_check: bool = false, _is_integrity_check_on_auto_save: bool = false) -> Result:
    var result := FileFormatUtil.load_common(file_path, DATA_MODE, FileAccess.CompressionMode.COMPRESSION_FASTLZ, PackedByteArray(), PackedByteArray(), FMT_SIG, MAX_VERSION, false)
    if result.is_failing(): return result
    var did_upgrade = format_version < MAX_VERSION
    if format_version == MAX_VERSION:
        _load_directly(result.value.cfg_file)
    else:
        _load_to_dict_then_upgrade(result.value.cfg_file)
    if result.is_failing(): return result
    if did_upgrade:
        result.check(queue_save())
    file_loaded.emit(self)
    is_open = true
    return result

func _load_to_dict_then_upgrade(file: ConfigFile) -> void:
    assert(format_version < MAX_VERSION)
    var read_routine: Callable = SettingsData.PREV_VERSION_READ_ROUTINES[format_version]
    var vals: Dictionary = {}
    read_routine.call(file, vals)
    while format_version < MAX_VERSION:
        var upgrade_routine: Callable = SettingsData.PREV_VERSION_UPGRADE_ROUTINES[format_version]
        upgrade_routine.call(vals)
        format_version += 1
    window_width = vals["window_width"]
    window_height = vals["window_height"]
    window_x = vals["window_x"]
    window_y = vals["window_y"]
    window_mode = vals["window_mode"]
    return

func _load_directly(file: ConfigFile) -> void:
    assert(format_version == MAX_VERSION)
    window_width = file.get_value("WINDOW", "window_width", 1200)
    window_height = file.get_value("WINDOW", "window_height", 800)
    window_x = file.get_value("WINDOW", "window_x", 0)
    window_y = file.get_value("WINDOW", "window_y", 0)
    window_mode = file.get_value("WINDOW", "window_mode", 0)
    return

func check_valid() -> Result:
    var result := FileFormatUtil.load_common(file_path, DATA_MODE, FileAccess.CompressionMode.COMPRESSION_FASTLZ, PackedByteArray(), PackedByteArray(), FMT_SIG, MAX_VERSION, false)
    return result

func queue_save() -> Result:
    var result := Result.cache_first_failure()
    if !is_open: return result
    if !disable_auto_save:
        if auto_save_max_timeout <= 0.0:
            auto_save_max_timeout = AUTO_SAVE_MAX_DELAY_SECS
        auto_save_soft_timeout = AUTO_SAVE_SOFT_DELAY_SECS
        if auto_save_soft_timeout <= 0.0 or auto_save_max_timeout <= 0.0:
            result.check(save(false, true))
    return result

func save_and_close() -> Result:
    return save(true, false)

func save(close_after_save: bool = false, _is_auto_save: bool = false) -> Result:
    assert(format_version == MAX_VERSION)
    var result := Result.cache_first_failure()
    if !is_open: return result
    result.check(FileFormatUtil.save_common_one(file_path, DATA_MODE, FileAccess.CompressionMode.COMPRESSION_FASTLZ, PackedByteArray(), PackedByteArray(), FMT_SIG, MAX_VERSION, false))
    if result.is_failing(): return result
    var file = result.value
    file.set_value("WINDOW", "window_width", window_width)
    file.set_value("WINDOW", "window_height", window_height)
    file.set_value("WINDOW", "window_x", window_x)
    file.set_value("WINDOW", "window_y", window_y)
    file.set_value("WINDOW", "window_mode", window_mode)
    FileFormatUtil.save_common_two(result, file, file_path, DATA_MODE)
    if result.is_passing() and !disable_extra_integrity_check:
        var check_clone = clone_metadata_only(true)
        check_clone.file_path = check_clone.file_path + ".tmp"
        result.check(check_clone.load(true))
        result.check(self.data_equals(check_clone), FileFormatUtil.DATA_INTEGRITY_FAIL % file_path)
    FileFormatUtil.save_common_three(result, file_path)
    if result.is_passing():
        auto_save_max_timeout = -1.0
        auto_save_soft_timeout = -1.0
        if !close_after_save:
            file_saved.emit(self)
        else:
            is_open = false
    return result

func delete(send_to_trash: bool = false) -> Result:
    var result := Result.cache_first_failure()
    if !FileAccess.file_exists(file_path): return result.with_err(ERR_FILE_NOT_FOUND, FileFormatUtil.FILE_DOESNT_EXIST % file_path)
    if send_to_trash:
        result.check(OS.move_to_trash(file_path), FileFormatUtil.COULDNT_SEND_FILE_TO_TRASH % file_path)
    else:
        result.check(DirAccess.remove_absolute(file_path), FileFormatUtil.COULDNT_DELETE_FILE % file_path)
    return result

func clone_metadata_only(disable_autosave_on_clone: bool = false) -> SettingsData:
    var new_self := SettingsData.new(self.file_path)
    new_self.format_version = self.format_version
    new_self.disable_auto_save = self.disable_auto_save or disable_autosave_on_clone
    new_self.disable_extra_integrity_check = self.disable_extra_integrity_check
    return new_self

func data_equals(other: SettingsData, _is_integrity_check: bool = false) -> bool:
    if other.window_width != self.window_width: return false
    if other.window_height != self.window_height: return false
    if other.window_x != self.window_x: return false
    if other.window_y != self.window_y: return false
    if other.window_mode != self.window_mode: return false
    return true


func _init(path: String) -> void:
    file_path = path
    # # USER INIT
    game = Engine.get_main_loop().current_scene
    # # END USER INIT
    return 

func _process(delta: float) -> void:
    if !disable_auto_save:
        var need_save := false
        if auto_save_max_timeout >= 0.0:
            auto_save_max_timeout -= delta
            need_save = true
        if auto_save_soft_timeout >= 0.0:
            auto_save_soft_timeout -= delta
            need_save = true
        if need_save and (auto_save_soft_timeout <= 0.0 or auto_save_max_timeout <= 0.0):
            var result = save(false, true)
            result.handle_fail()
    return 


var game: Game = null
static var PREV_VERSION_READ_ROUTINES: Array[Callable] = [
]:
    set(v): assert(false)

static var PREV_VERSION_UPGRADE_ROUTINES: Array[Callable] = [
]:
    set(v): assert(false)

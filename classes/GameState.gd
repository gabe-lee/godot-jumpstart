class_name GameState extends RefCounted

const DATA_MODE := FileFormatUtil.DATA_MODE.HMAC_ENCRYPTED
const AUTO_SAVE_SOFT_DELAY_SECS: float = 15.0
const AUTO_SAVE_MAX_DELAY_SECS: float = 60.0
const HMAC_KEY: PackedByteArray = [149, 245, 46, 172, 238, 147, 182, 152, 201, 139, 168, 208, 91, 44, 97, 177, 188, 196, 81, 29, 190, 246, 184, 24, 4, 131, 130, 206, 147, 164, 19, 75]
const ENCRYPTION_KEY: PackedByteArray = [141, 15, 227, 30, 127, 234, 179, 101, 30, 58, 158, 46, 34, 10, 246, 192, 149, 98, 109, 180, 192, 118, 231, 78, 170, 212, 111, 106, 156, 152, 108, 47]
const FMT_SIG: PackedByteArray = [83, 65, 86, 69]
const BIG_ENDIAN: bool = false
const MAX_VERSION: int = 0


signal file_saved(file: GameState)
signal file_loaded(file: GameState)


var file_path: String = ""
var format_version: int = MAX_VERSION
var is_open: bool = true
var auto_save_soft_timeout: float = -1.0
var auto_save_max_timeout: float = -1.0
var disable_auto_save: bool = false
var disable_extra_integrity_check: bool = false

var save_name: String = "<no_save_name>":
    set(val):
        save_name = val
        queue_save()
var save_cleanliness: int = 0
var save_probation: float = -1.0
var progress: float = 0.0:
    set(val):
        progress = val
        queue_save()
var created_time: float = 0.0:
    set(val):
        created_time = val
        queue_save()
var close_time: float = 0.0
var play_time: float = 0.0:
    set(val):
        play_time = val
        queue_save()
var banked_time: float = 0.0:
    set(val):
        banked_time = val
        queue_save()
var player_max_hp: float = 100.0:
    set(val):
        player_max_hp = val
        queue_save()
var player_hp: float = 100.0:
    set(val):
        player_hp = val
        queue_save()
var resources: PackedFloat64Array = []

func exists() -> bool:
    return FileAccess.file_exists(file_path)

func load(_is_integrity_check: bool = false, _is_integrity_check_on_auto_save: bool = false) -> Result:
    var result := FileFormatUtil.load_common(file_path, DATA_MODE, FileAccess.CompressionMode.COMPRESSION_FASTLZ, HMAC_KEY, ENCRYPTION_KEY, FMT_SIG, MAX_VERSION, BIG_ENDIAN)
    if result.is_failing(): return result
    var did_upgrade = format_version < MAX_VERSION
    if format_version == MAX_VERSION:
        _load_directly(result, result.value.bin_file)
    else:
        _load_to_dict_then_upgrade(result, result.value.bin_file)
    if result.is_failing(): return result
    if did_upgrade:
        result.check(queue_save())
    #region USER POST LOAD
    if !_is_integrity_check:
        save_cleanliness = Game.main.save_manifest.get_max_cleanliness(self)
        save_cleanliness = mini(save_cleanliness + 1, 2)
        if save_cleanliness > 1 and save_probation <= 0.0:
            Game.main.post_user_error(Game.ERR.FAILED, "Loaded an auto-save that was not saved cleanly, for " + SAVE_PROBATION_MSG + " of playtime, future saves will be immediately saved to disk to prevent data loss and save-scumming.")
            save_probation = SAVE_PROBATION_SECS
            save_cleanliness = 1
        var time_now = Time.get_unix_time_from_system()
        var banked_delta = time_now - close_time
        banked_time += banked_delta
        Game.main.save_manifest.update_save_data_in_manifest(self, true)
    #endregion END USER POST LOAD
    file_loaded.emit(self)
    is_open = true
    return result

func _load_to_dict_then_upgrade(result: Result, file: BinaryFile) -> void:
    assert(format_version < MAX_VERSION)
    var read_routine: Callable = GameState.PREV_VERSION_READ_ROUTINES[format_version]
    var vals: Dictionary = {}
    read_routine.call(file, vals)
    if result.failed(file.last_error(), FileFormatUtil.FILE_READ_ERROR % file_path ): return
    while format_version < MAX_VERSION:
        var upgrade_routine: Callable = GameState.PREV_VERSION_UPGRADE_ROUTINES[format_version]
        upgrade_routine.call(vals)
        format_version += 1
    save_name = vals["save_name"]
    save_cleanliness = vals["save_cleanliness"]
    save_probation = vals["save_probation"]
    progress = vals["progress"]
    created_time = vals["created_time"]
    close_time = vals["close_time"]
    play_time = vals["play_time"]
    banked_time = vals["banked_time"]
    player_max_hp = vals["player_max_hp"]
    player_hp = vals["player_hp"]
    resources = vals["resources"]
    return

func _load_directly(result: Result, file: BinaryFile) -> void:
    assert(format_version == MAX_VERSION)
    save_name = file.read_len_prefix_string_utf8()
    save_cleanliness = file.read_u8()
    save_probation = file.read_f32()
    progress = file.read_f32()
    created_time = file.read_f64()
    close_time = file.read_f64()
    play_time = file.read_f64()
    banked_time = file.read_f64()
    player_max_hp = file.read_f32()
    player_hp = file.read_f32()
    resources = file.read_f64_array_len_prefix()
    result.check(file.last_error(), FileFormatUtil.FILE_READ_ERROR % file_path)
    return

func check_valid() -> Result:
    var result := FileFormatUtil.load_common(file_path, DATA_MODE, FileAccess.CompressionMode.COMPRESSION_FASTLZ, ENCRYPTION_KEY, HMAC_KEY, FMT_SIG, MAX_VERSION, BIG_ENDIAN)
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
    # USER PRE SAVE
    close_time = Time.get_unix_time_from_system()
    if !_is_auto_save:
        save_cleanliness = 0
    Game.main.save_manifest.update_save_data_in_manifest(self, true)
    # END USER PRE SAVE
    result.check(FileFormatUtil.save_common_one(file_path, DATA_MODE, FileAccess.CompressionMode.COMPRESSION_FASTLZ, HMAC_KEY, ENCRYPTION_KEY, FMT_SIG, MAX_VERSION, BIG_ENDIAN))
    if result.is_failing(): return result
    var file = result.value
    file.write_len_prefix_string_utf8(save_name)
    file.write_u8(save_cleanliness)
    file.write_f32(save_probation)
    file.write_f32(progress)
    file.write_f64(created_time)
    file.write_f64(close_time)
    file.write_f64(play_time)
    file.write_f64(banked_time)
    file.write_f32(player_max_hp)
    file.write_f32(player_hp)
    file.write_f64_array_len_prefix(resources)
    FileFormatUtil.save_common_two(result, file, file_path, DATA_MODE)
    if result.is_passing() and !disable_extra_integrity_check:
        var check_clone = clone_metadata_only(true)
        check_clone.file_path = check_clone.file_path + ".tmp"
        result.check(check_clone.load(true))
        result.check(self.data_equals(check_clone), FileFormatUtil.DATA_INTEGRITY_FAIL % file_path)
    FileFormatUtil.save_common_three(result, file_path)
    # USER POST SAVE
    save_cleanliness = 1
    if result.is_passing() and !close_after_save:
        Game.main.save_manifest.update_save_data_in_manifest(self, true)
    # END USER POST SAVE
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

func clone_metadata_only(disable_autosave_on_clone: bool = false) -> GameState:
    var new_self := GameState.new(self.file_path)
    new_self.format_version = self.format_version
    new_self.disable_auto_save = self.disable_auto_save or disable_autosave_on_clone
    new_self.disable_extra_integrity_check = self.disable_extra_integrity_check
    return new_self

func data_equals(other: GameState, _is_integrity_check: bool = false) -> bool:
    # USER PRE INTEGRITY CHECK
    other.save_cleanliness = self.save_cleanliness
    other.save_probation = self.save_probation
    # END USER PRE INTEGRITY CHECK
    if other.save_name != self.save_name: return false
    if other.save_cleanliness != self.save_cleanliness: return false
    if other.save_probation != self.save_probation: return false
    if other.progress != self.progress: return false
    if other.created_time != self.created_time: return false
    if other.close_time != self.close_time: return false
    if other.play_time != self.play_time: return false
    if other.banked_time != self.banked_time: return false
    if other.player_max_hp != self.player_max_hp: return false
    if other.player_hp != self.player_hp: return false
    if other.resources != self.resources: return false
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


const SAVE_PROBATION_SECS := 60.0 * 60.0 # 1 hour
const SAVE_PROBATION_MSG := "1 hour"

var game: Game = null
static var PREV_VERSION_READ_ROUTINES: Array[Callable] = [
]:
    set(v): assert(false)

static var PREV_VERSION_UPGRADE_ROUTINES: Array[Callable] = [
]:
    set(v): assert(false)

extends RefCounted

const ExampleSaveFileBuilderResult = preload("res://addons/file_gen_utils/EDITOR_ONLY/examples/ExampleSaveFileBuilderResult.gd")
const DATA_MODE := FileFormatUtil.DATA_MODE.ENCRYPTED
const AUTO_SAVE_SOFT_DELAY_SECS: float = 15.0
const AUTO_SAVE_MAX_DELAY_SECS: float = 60.0
const ENCRYPTION_KEY: PackedByteArray = [1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239]
const FMT_SIG: PackedByteArray = [77, 89, 83, 65, 86, 69]
const BIG_ENDIAN: bool = false
const MAX_VERSION: int = 1


signal file_saved(file: ExampleSaveFileBuilderResult)
signal file_loaded(file: ExampleSaveFileBuilderResult)


var file_path: String = ""
var format_version: int = MAX_VERSION
var is_open: bool = true
var auto_save_soft_timeout: float = -1.0
var auto_save_max_timeout: float = -1.0
var disable_auto_save: bool = false
var disable_extra_integrity_check: bool = false

var player_hp: float = 100.0:
    set(val):
        player_hp = val
        queue_save()
var player_max_hp: float = 100.0:
    set(val):
        player_max_hp = val
        queue_save()
var player_level: int = 1:
    set(val):
        player_level = val
        queue_save()

func exists() -> bool:
    return FileAccess.file_exists(file_path)

func load(_is_integrity_check: bool = false, _is_integrity_check_on_auto_save: bool = false) -> Result:
    var result := FileFormatUtil.load_common(file_path, DATA_MODE, FileAccess.CompressionMode.COMPRESSION_FASTLZ, PackedByteArray(), ENCRYPTION_KEY, FMT_SIG, MAX_VERSION, BIG_ENDIAN)
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
    # this happens immediately after load
    #endregion END USER POST LOAD
    file_loaded.emit(self)
    is_open = true
    return result

func _load_to_dict_then_upgrade(result: Result, file: BinaryFile) -> void:
    assert(format_version < MAX_VERSION)
    var read_routine: Callable = ExampleSaveFileBuilderResult.PREV_VERSION_READ_ROUTINES[format_version]
    var vals: Dictionary = {}
    read_routine.call(file, vals)
    if result.failed(file.last_error(), FileFormatUtil.FILE_READ_ERROR % file_path ): return
    while format_version < MAX_VERSION:
        var upgrade_routine: Callable = ExampleSaveFileBuilderResult.PREV_VERSION_UPGRADE_ROUTINES[format_version]
        upgrade_routine.call(vals)
        format_version += 1
    player_hp = vals["player_hp"]
    player_max_hp = vals["player_max_hp"]
    player_level = vals["player_level"]
    return

func _load_directly(result: Result, file: BinaryFile) -> void:
    assert(format_version == MAX_VERSION)
    player_hp = file.read_f32()
    player_max_hp = file.read_f32()
    player_level = file.read_u16()
    result.check(file.last_error(), FileFormatUtil.FILE_READ_ERROR % file_path)
    return

func check_valid() -> Result:
    var result := FileFormatUtil.load_common(file_path, DATA_MODE, FileAccess.CompressionMode.COMPRESSION_FASTLZ, ENCRYPTION_KEY, PackedByteArray(), FMT_SIG, MAX_VERSION, BIG_ENDIAN)
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
    # this happens immediately before save
    # END USER PRE SAVE
    result.check(FileFormatUtil.save_common_one(file_path, DATA_MODE, FileAccess.CompressionMode.COMPRESSION_FASTLZ, PackedByteArray(), ENCRYPTION_KEY, FMT_SIG, MAX_VERSION, BIG_ENDIAN))
    if result.is_failing(): return result
    var file = result.value
    file.write_f32(player_hp)
    file.write_f32(player_max_hp)
    file.write_u16(player_level)
    FileFormatUtil.save_common_two(result, file, file_path, DATA_MODE)
    if result.is_passing() and !disable_extra_integrity_check:
        var check_clone = clone_metadata_only(true)
        check_clone.file_path = check_clone.file_path + ".tmp"
        result.check(check_clone.load(true))
        result.check(self.data_equals(check_clone), FileFormatUtil.DATA_INTEGRITY_FAIL % file_path)
    FileFormatUtil.save_common_three(result, file_path)
    # USER POST SAVE
    # this happens immediately after save
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

func clone_metadata_only(disable_autosave_on_clone: bool = false) -> ExampleSaveFileBuilderResult:
    var new_self := ExampleSaveFileBuilderResult.new(self.file_path)
    new_self.format_version = self.format_version
    new_self.disable_auto_save = self.disable_auto_save or disable_autosave_on_clone
    new_self.disable_extra_integrity_check = self.disable_extra_integrity_check
    return new_self

func data_equals(other: ExampleSaveFileBuilderResult, _is_integrity_check: bool = false) -> bool:
    # USER PRE INTEGRITY CHECK
    # this happens before the save integrity check
    # END USER PRE INTEGRITY CHECK
    if other.player_hp != self.player_hp: return false
    if other.player_max_hp != self.player_max_hp: return false
    if other.player_level != self.player_level: return false
    return true


func _init(path: String) -> void:
    file_path = path
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

static func read_ver_0(file: BinaryFile, vals: Dictionary) -> void:
    vals["player_max_hp"] = file.read_f32()
    vals["player_hp"] = file.read_f32()

static func upgrade_ver_0(vals: Dictionary) -> void:
    pass


signal player_died

const HP_REGEN := 5.0

func hurt_player(amount: float) -> void:
    player_hp -= amount
    if player_hp <= 0.0:
        player_hp = 0.0
        player_died.emit()
static var PREV_VERSION_READ_ROUTINES: Array[Callable] = [
    read_ver_0,
]:
    set(v): assert(false)

static var PREV_VERSION_UPGRADE_ROUTINES: Array[Callable] = [
    upgrade_ver_0,
]:
    set(v): assert(false)


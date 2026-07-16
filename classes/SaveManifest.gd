class_name SaveManifest extends RefCounted

const DATA_MODE := FileFormatUtil.DATA_MODE.HMAC_ENCRYPTED
const AUTO_SAVE_SOFT_DELAY_SECS: float = 1.0
const AUTO_SAVE_MAX_DELAY_SECS: float = 5.0
const HMAC_KEY: PackedByteArray = [36, 68, 153, 173, 13, 100, 242, 170, 215, 99, 198, 255, 47, 245, 89, 23, 156, 221, 232, 225, 8, 122, 148, 209, 254, 133, 220, 115, 241, 208, 250, 141]
const ENCRYPTION_KEY: PackedByteArray = [186, 88, 219, 67, 19, 175, 152, 35, 92, 227, 232, 244, 110, 158, 24, 105, 2, 207, 209, 156, 185, 148, 56, 33, 245, 242, 90, 241, 18, 255, 70, 170]
const FMT_SIG: PackedByteArray = [77, 65, 78, 73]
const BIG_ENDIAN: bool = false
const MAX_VERSION: int = 0


signal file_saved(file: SaveManifest)
signal file_loaded(file: SaveManifest)


var file_path: String = ""
var format_version: int = MAX_VERSION
var is_open: bool = true
var auto_save_soft_timeout: float = -1.0
var auto_save_max_timeout: float = -1.0
var disable_auto_save: bool = false
var disable_extra_integrity_check: bool = false

var records: Array = [] as Array
var last_played_idx: int = -1
var last_played_name: String = ""
var close_time: float = 0.0
var banked_time: float = 0.0

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
        update_banked_time()
    #endregion END USER POST LOAD
    file_loaded.emit(self)
    is_open = true
    return result

func _load_to_dict_then_upgrade(result: Result, file: BinaryFile) -> void:
    assert(format_version < MAX_VERSION)
    var read_routine: Callable = SaveManifest.PREV_VERSION_READ_ROUTINES[format_version]
    var vals: Dictionary = {}
    read_routine.call(file, vals)
    if result.failed(file.last_error(), FileFormatUtil.FILE_READ_ERROR % file_path ): return
    while format_version < MAX_VERSION:
        var upgrade_routine: Callable = SaveManifest.PREV_VERSION_UPGRADE_ROUTINES[format_version]
        upgrade_routine.call(vals)
        format_version += 1
    records = vals["records"]
    last_played_idx = vals["last_played_idx"]
    last_played_name = vals["last_played_name"]
    close_time = vals["close_time"]
    banked_time = vals["banked_time"]
    return

func _load_directly(result: Result, file: BinaryFile) -> void:
    assert(format_version == MAX_VERSION)
    records = file.read_custom_array_len_prefix(custom_read_records)
    last_played_idx = file.read_i32()
    last_played_name = file.read_len_prefix_string_utf8()
    close_time = file.read_f64()
    banked_time = file.read_f64()
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
    result.check(FileFormatUtil.save_common_one(file_path, DATA_MODE, FileAccess.CompressionMode.COMPRESSION_FASTLZ, HMAC_KEY, ENCRYPTION_KEY, FMT_SIG, MAX_VERSION, BIG_ENDIAN))
    if result.is_failing(): return result
    var file = result.value
    file.write_custom_array_len_prefix(custom_write_records, records)
    file.write_i32(last_played_idx)
    file.write_len_prefix_string_utf8(last_played_name)
    file.write_f64(close_time)
    file.write_f64(banked_time)
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

func clone_metadata_only(disable_autosave_on_clone: bool = false) -> SaveManifest:
    var new_self := SaveManifest.new(self.file_path)
    new_self.format_version = self.format_version
    new_self.disable_auto_save = self.disable_auto_save or disable_autosave_on_clone
    new_self.disable_extra_integrity_check = self.disable_extra_integrity_check
    return new_self

func data_equals(other: SaveManifest, _is_integrity_check: bool = false) -> bool:
    if other.records.size() != self.records.size(): return false
    var i1 := 0
    while i1 < self.records.size():
        var other1 = other.records[i1]
        var self1 = self.records[i1]
        if other1.save_name != self1.save_name: return false
        if other1.play_time != self1.play_time: return false
        if other1.banked_time != self1.banked_time: return false
        if other1.close_time != self1.close_time: return false
        if other1.progress != self1.progress: return false
        if other1.cleanliness != self1.cleanliness: return false
        i1 += 1
    if other.last_played_idx != self.last_played_idx: return false
    if other.last_played_name != self.last_played_name: return false
    if other.close_time != self.close_time: return false
    if other.banked_time != self.banked_time: return false
    return true


func _init(path: String) -> void:
    file_path = path
    # # USER INIT
    var time_now = Time.get_unix_time_from_system()
    close_time = time_now
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

static func custom_write_records(file: BinaryFile, val_: SaveRecord) -> bool:
    file.write_len_prefix_string_utf8(val_.save_name)
    file.write_f64(val_.play_time)
    file.write_f64(val_.banked_time)
    file.write_f64(val_.close_time)
    file.write_f32(val_.progress)
    file.write_u8(val_.cleanliness)
    return file.last_error() == OK

static func custom_read_records(file: BinaryFile) -> SaveRecord:
    var val_ := SaveRecord.new()
    val_.save_name = file.read_len_prefix_string_utf8()
    val_.play_time = file.read_f64()
    val_.banked_time = file.read_f64()
    val_.close_time = file.read_f64()
    val_.progress = file.read_f32()
    val_.cleanliness = file.read_u8()
    return val_


const SAVE_ALREADY_EXISTS = "save `%s` already exists"
const SAVE_DOES_NOT_EXIST_ON_FILESYSTEM = "save `%s` does not exist on filesystem"
const SAVE_DOES_NOT_EXIST_IN_MANIFEST = "save `%s` does not exist in save manifest"
const COULDNT_OPEN_SAVE_DIR = "could not open save directory `%s` on filesystem"
const COULDNT_DELETE_SAVE = "could not delete save `%s` from filesystem"

var game: Game = null

class SaveRecord:
    var save_name: String = ""
    var play_time: float = -INF
    var banked_time: float = -INF
    var close_time: float = -INF
    var progress: float = -INF
    var cleanliness: int = 0

    func _init(save_data: GameState = null) -> void:
        if save_data != null:
            self.save_name = save_data.save_name
            self.play_time = save_data.play_time
            self.banked_time = save_data.banked_time
            self.close_time = save_data.close_time
            self.progress = save_data.progress
            self.cleanliness = save_data.save_cleanliness

func update_banked_time() -> void:
    var time_now = Time.get_unix_time_from_system()
    var banked_delta = time_now - close_time
    close_time = time_now
    add_banked_time(banked_delta)

func add_banked_time(delta: float) -> void:
    banked_time += delta
    queue_save().handle_fail()
    Game.main.save_manifest_changed.emit()

func has_save_name(save_name: String) -> bool:
    return index_for_save_name(save_name) >= 0

func index_for_save_name(save_name: String) -> int:
    if last_played_idx >= 0 and last_played_idx < records.size() and last_played_name == save_name:
        if last_played_name != records[last_played_idx].save_name:
            last_played_name = records[last_played_idx].save_name
            queue_save().handle_fail()
        else:
            return last_played_idx
    var i: int = records.size() - 1
    while i >= 0:
        if records[i].save_name == save_name:
            return i
        i -= 1
    return i

func get_max_cleanliness(save_: GameState) -> int:
    var idx = index_for_save_name(save_.save_name)
    if idx < 0:
        Result.new_check_and_handle(Game.ERR.SAVE_NOT_IN_MANIFEST, SAVE_DOES_NOT_EXIST_IN_MANIFEST % save_.save_name)
        return save_.save_cleanliness
    return maxi(records[idx].cleanliness, save_.save_cleanliness)

func has_last_played() -> bool:
    if last_played_idx >= 0 and last_played_idx < records.size():
        if last_played_name != records[last_played_idx].save_name:
            last_played_name = records[last_played_idx].save_name
            queue_save().handle_fail()
        return true
    return false

func add_new_save_to_manifest(save_data: GameState, set_as_last_played: bool = false) -> Result:
    var result = Result.cache_first_failure()
    if last_played_name == save_data.save_name or has_save_name(save_data.save_name):
        return result.with_err(Game.ERR.GODOT_ALREADY_EXISTS, SAVE_ALREADY_EXISTS % save_data.save_name)
    var record = SaveRecord.new(save_data)
    records.push_back(record)
    if records.size() == 1 or set_as_last_played:
        last_played_idx = records.size() - 1
        last_played_name = save_data.save_name
    Game.main.save_manifest_records_changed.emit()
    result.check(queue_save())
    return result

func update_save_data_in_manifest(save_data: GameState, set_as_last_played: bool = false) -> Result:
    var result = Result.cache_first_failure()
    var save_idx: int
    if last_played_name == save_data.save_name:
        save_idx = last_played_idx
    else:
        save_idx = index_for_save_name(save_data.save_name)
    if result.failed(save_idx >= 0, SAVE_DOES_NOT_EXIST_ON_FILESYSTEM % save_data.save_name): return result
    var record = SaveRecord.new(save_data)
    records[save_idx] = record
    if set_as_last_played:
        last_played_idx = save_idx
        last_played_name = save_data.save_name
    Game.main.save_manifest_records_changed.emit()
    result.check(queue_save())
    return result

func get_last_played_record() -> SaveRecord:
    if has_last_played():
        return records[last_played_idx]
    return null

func delete_save_from_manifest(save_name: String) -> Result:
    var result = Result.cache_first_failure()
    var i: int = 0
    while i < records.size():
        if records[i] == save_name:
            records.remove_at(i)
            if last_played_name == save_name:
                last_played_name = ""
                last_played_idx = -1
            Game.main.save_manifest_records_changed.emit()
            result.check(queue_save())
            return result
        i += 1
    return result.with_error(Game.ERR.FAILED, SAVE_DOES_NOT_EXIST_IN_MANIFEST % save_name)
static var PREV_VERSION_READ_ROUTINES: Array[Callable] = [
]:
    set(v): assert(false)

static var PREV_VERSION_UPGRADE_ROUTINES: Array[Callable] = [
]:
    set(v): assert(false)

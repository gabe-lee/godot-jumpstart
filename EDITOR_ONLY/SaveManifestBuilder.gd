@tool
class_name SaveManifestBuilder extends FileFormatBuilder

enum VAL {
    RECORDS,
    LAST_PLAYED_IDX,
    LAST_PLAYED_NAME,
    CLOSE_TIME,
    BANKED_TIME,
}

func _set_config() -> void:
    self.script_class = "SaveManifest"
    self.format_ext = ".dat"
    self.script_path = "res://classes/SaveManifest.gd"
    self.data_mode = FileFormatBuilder.DATA_MODE.HMAC_ENCRYPTED
    self.hmac_key = "244499ad0d64f2aad763c6ff2ff559179cdde8e1087a94d1fe85dc73f1d0fa8d".hex_decode()
    self.encrypt_key = "ba58db4313af98235ce3e8f46e9e186902cfd19cb9943821f5f25af112ff46aa".hex_decode()
    self.extra_data_integrity_checks = true
    self.format_magic_signature = "MANI".to_utf8_buffer()
    self.all_values_omit_setters = true
    self.auto_save_soft_delay = 1.0
    self.auto_save_max_delay = 5.0
    # self.debug_print_during_save_and_load = true
    self.user_init_body = """
var time_now = Time.get_unix_time_from_system()
close_time = time_now
game = Engine.get_main_loop().current_scene
"""
    self.user_process_body = """
if !Game.main.current_save_file_open:
    add_banked_time(delta)
"""
    self.user_post_load_body = """
if !_is_integrity_check:
    update_banked_time()
"""
    self.user_script_body = """
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
"""

func _register_properties() -> void:
    register_named_value(Val.array(VAL.RECORDS, "records", TYPE_UTIL.T.CustomType, []).custom_type("SaveRecord").run_code_after_val_set("save_manifest_changed.emit()").custom_sub_layout([
        Val.single_val(0, "save_name", TYPE_UTIL.T.String_Utf8, ""),
        Val.single_val(0, "play_time", TYPE_UTIL.T.Float64, -INF),
        Val.single_val(0, "banked_time", TYPE_UTIL.T.Float64, -INF),
        Val.single_val(0, "close_time", TYPE_UTIL.T.Float64, -INF),
        Val.single_val(0, "progress", TYPE_UTIL.T.Float32, -INF),
        Val.single_val(0, "cleanliness", TYPE_UTIL.T.Uint8, 0),
    ]))
    register_named_value(Val.single_val(VAL.LAST_PLAYED_IDX, "last_played_idx", TYPE_UTIL.T.Int32, -1).run_code_after_val_set("save_manifest_changed.emit()"))
    register_named_value(Val.single_val(VAL.LAST_PLAYED_NAME, "last_played_name", TYPE_UTIL.T.String_Utf8, "").run_code_after_val_set("save_manifest_changed.emit()"))
    register_named_value(Val.single_val(VAL.CLOSE_TIME, "close_time", TYPE_UTIL.T.Float64, 0.0).run_code_after_val_set("save_manifest_changed.emit()"))
    register_named_value(Val.single_val(VAL.BANKED_TIME, "banked_time", TYPE_UTIL.T.Float64, 0.0).run_code_after_val_set("save_manifest_changed.emit()"))

func _register_versions() -> void:
    register_version_layout(0, [
        VAL.RECORDS,
        VAL.LAST_PLAYED_IDX,
        VAL.LAST_PLAYED_NAME,
        VAL.CLOSE_TIME,
        VAL.BANKED_TIME,
    ])

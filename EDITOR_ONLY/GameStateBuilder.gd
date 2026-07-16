@tool
class_name GameStateBuilder extends FileFormatBuilder

enum VAL {
    SAVE_NAME,
    SAVE_CLEANLINESS,
    SAVE_PROBATION,
    PROGRESS,
    CREATED_TIME,
    CLOSE_TIME,
    PLAY_TIME,
    BANKED_TIME,
    PLAYER_MAX_HP,
    PLAYER_HP,
    RESOURCE_INVENTORY,
}

func _set_config() -> void:
    self.script_class = "GameState"
    self.format_ext = ".dat"
    self.script_path = "res://classes/GameState.gd"
    self.data_mode = FileFormatBuilder.DATA_MODE.HMAC_ENCRYPTED
    self.hmac_key = "95f52eacee93b698c98ba8d05b2c61b1bcc4511dbef6b818048382ce93a4134b".hex_decode()
    self.encrypt_key = "8d0fe31e7feab3651e3a9e2e220af6c095626db4c076e74eaad46f6a9c986c2f".hex_decode()
    self.extra_data_integrity_checks = true
    self.format_magic_signature = "SAVE".to_utf8_buffer()
    self.auto_save_soft_delay = 15.0
    self.auto_save_max_delay = 60.0
    # self.debug_print_during_save_and_load = true
    self.user_post_load_body = """
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
"""
    self.user_pre_save_body = """
close_time = Time.get_unix_time_from_system()
if !_is_auto_save:
    save_cleanliness = 0
Game.main.save_manifest.update_save_data_in_manifest(self, true)
"""
    self.user_post_save_body = """
save_cleanliness = 1
if result.is_passing() and !close_after_save:
    Game.main.save_manifest.update_save_data_in_manifest(self, true)
"""
    self.user_pre_integrity_check_body = """
other.save_cleanliness = self.save_cleanliness
other.save_probation = self.save_probation
"""
    self.user_process_body = """
if save_probation > 0.0:
    # loaded a save that was not saved cleanly, force immediate saving
    # to prevent future loss of progress and/or save-scumming
    save_probation -= delta
    if auto_save_soft_timeout > 0.0 or auto_save_max_timeout > 0.0:
        save(false, true)
"""
    self.user_script_body = """
const SAVE_PROBATION_SECS := 60.0 * 60.0 # 1 hour
const SAVE_PROBATION_MSG := "1 hour"

var game: Game = null
"""
    self.user_init_body = """
game = Engine.get_main_loop().current_scene
"""

func _register_properties() -> void:
    register_named_value(Val.single_val(VAL.SAVE_NAME, "save_name", TYPE_UTIL.T.String_Utf8, "<no_save_name>"))
    register_named_value(Val.single_val(VAL.SAVE_CLEANLINESS, "save_cleanliness", TYPE_UTIL.T.Uint8, 0).omit_setter())
    register_named_value(Val.single_val(VAL.SAVE_PROBATION, "save_probation", TYPE_UTIL.T.Float32, -1.0).omit_setter())
    register_named_value(Val.single_val(VAL.PROGRESS, "progress", TYPE_UTIL.T.Float32, 0.0))
    register_named_value(Val.single_val(VAL.CREATED_TIME, "created_time", TYPE_UTIL.T.Float64, 0.0))
    register_named_value(Val.single_val(VAL.CLOSE_TIME, "close_time", TYPE_UTIL.T.Float64, 0.0).omit_setter())
    register_named_value(Val.single_val(VAL.PLAY_TIME, "play_time", TYPE_UTIL.T.Float64, 0.0))
    register_named_value(Val.single_val(VAL.BANKED_TIME, "banked_time", TYPE_UTIL.T.Float64, 0.0))
    register_named_value(Val.single_val(VAL.PLAYER_MAX_HP, "player_max_hp", TYPE_UTIL.T.Float32, 100.0))
    register_named_value(Val.single_val(VAL.PLAYER_HP, "player_hp", TYPE_UTIL.T.Float32, 100.0))
    register_named_value(Val.array(VAL.RESOURCE_INVENTORY, "resources", TYPE_UTIL.T.Float64, []).omit_setter())

func _register_versions() -> void:
    register_version_layout(0, [
        VAL.SAVE_NAME,
        VAL.SAVE_CLEANLINESS,
        VAL.SAVE_PROBATION,
        VAL.PROGRESS,
        VAL.CREATED_TIME,
        VAL.CLOSE_TIME,
        VAL.PLAY_TIME,
        VAL.BANKED_TIME,
        VAL.PLAYER_MAX_HP,
        VAL.PLAYER_HP,
        VAL.RESOURCE_INVENTORY,
    ])

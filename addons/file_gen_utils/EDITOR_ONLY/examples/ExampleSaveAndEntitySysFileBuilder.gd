@tool
extends FileFormatBuilder

func _set_config() -> void:
    self.script_class = "ExampleSaveFileAndEntitySysBuilderResult"
    self.write_class_name = false # to prevent the examples from polluting the project namespace
    self.format_ext = ".sav"
    self.script_path = "res://addons/file_gen_utils/EDITOR_ONLY/examples/ExampleSaveFileAndEntitySysBuilderResult.gd"
    self.data_mode = FileFormatBuilder.DATA_MODE.ENCRYPTED
    self.encrypt_key = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef".hex_decode()
    self.extra_data_integrity_checks = true
    self.format_magic_signature = "MYSAVE".to_utf8_buffer()
    self.auto_save_soft_delay = 15.0
    self.auto_save_max_delay = 60.0
    self.user_post_load_body = """
# this happens immediately after load
"""
    self.user_pre_save_body = """
# this happens immediately before save
"""
    self.user_post_save_body = """
# this happens immediately after save
"""
    self.user_pre_integrity_check_body = """
# this happens before the save integrity check
"""
    self.user_process_body = """
# this happens in the _process(delta) function
player_hp += delta * HP_REGEN
"""
    self.user_script_body = """
signal player_died

const HP_REGEN := 5.0

func hurt_player(amount: float) -> void:
    player_hp -= amount
    if player_hp <= 0.0:
        player_hp = 0.0
        player_died.emit()
"""

enum VAL {
    PLAYER_MAX_HP,
    PLAYER_HP,
    PLAYER_LEVEL,
}

func _register_properties() -> void:
    register_named_value(Val.single_val(VAL.PLAYER_MAX_HP, "player_max_hp", TYPE_UTIL.T.Float32, 100.0))
    register_named_value(Val.single_val(VAL.PLAYER_HP, "player_hp", TYPE_UTIL.T.Float32, 100.0))
    register_named_value(Val.single_val(VAL.PLAYER_LEVEL, "player_level", TYPE_UTIL.T.Uint16, 1))

func _register_versions() -> void:
    register_version_layout(0, [
        VAL.PLAYER_MAX_HP,
        VAL.PLAYER_HP,
    ])
    register_version_layout(1, [ # Version 1 swaps the order of PLAYER_HP and PLAYER_MAX_HP and adds PLAYER_LEVEL
        VAL.PLAYER_HP,
        VAL.PLAYER_MAX_HP,
        VAL.PLAYER_LEVEL,
    ])

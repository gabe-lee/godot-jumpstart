@tool
class_name SettingsBuilder extends FileFormatBuilder

enum VAL {
    WINDOW_WIDTH,
    WINDOW_HEIGHT,
    WINDOW_X,
    WINDOW_Y,
    WINDOW_MODE,
}

enum WIN_MODE {
    WINDOWED,
    BORDERLESS,
    FULLSCREEN,
}

func _set_config() -> void:
    self.script_class = "SettingsData"
    self.format_ext = ".cfg"
    self.script_path = "res://classes/SettingsData.gd"
    self.data_mode = FileFormatBuilder.DATA_MODE.TEXT_CONFIG
    self.extra_data_integrity_checks = true
    self.format_magic_signature = "SETT".to_utf8_buffer()
    self.all_values_omit_setters = false
    self.auto_save_soft_delay = 15.0
    self.auto_save_max_delay = 30.0

func _serialize_constants(out: ScriptFileBuilder) -> void:
    super._serialize_constants(out)
    out._enum("WIN_MODE", WIN_MODE)

func _register_properties() -> void:
    register_named_value(Val.single_val(VAL.WINDOW_WIDTH, "window_width", TYPE_UTIL.T.Uint32, 1200).run_code_after_val_set("Game.main.settings_changed.emit()").config_section("WINDOW"))
    register_named_value(Val.single_val(VAL.WINDOW_HEIGHT, "window_height", TYPE_UTIL.T.Uint32, 800).run_code_after_val_set("Game.main.settings_changed.emit()").config_section("WINDOW"))
    register_named_value(Val.single_val(VAL.WINDOW_X, "window_x", TYPE_UTIL.T.Uint32, 0).run_code_after_val_set("Game.main.settings_changed.emit()").config_section("WINDOW"))
    register_named_value(Val.single_val(VAL.WINDOW_Y, "window_y", TYPE_UTIL.T.Uint32, 0).run_code_after_val_set("Game.main.settings_changed.emit()").config_section("WINDOW"))
    register_named_value(Val.single_val(VAL.WINDOW_MODE, "window_mode", TYPE_UTIL.T.Uint32, 0).custom_type("WIN_MODE").run_code_after_val_set("Game.main.settings_changed.emit()").config_section("WINDOW"))

func _register_versions() -> void:
    register_version_layout(0, [
        VAL.WINDOW_WIDTH,
        VAL.WINDOW_HEIGHT,
        VAL.WINDOW_X,
        VAL.WINDOW_Y,
        VAL.WINDOW_MODE,
    ])

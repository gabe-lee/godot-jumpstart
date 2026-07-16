@tool
extends FileFormatBuilder

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
    self.script_class = "ExampleSettingsBuilderResult"
    self.write_class_name = false # to prevent the examples from polluting the project namespace
    self.format_ext = ".cfg"
    self.script_path = "res://addons/file_gen_utils/EDITOR_ONLY/examples/ExampleSettingsBuilderResult.gd"
    self.data_mode = FileFormatBuilder.DATA_MODE.TEXT_CONFIG
    self.extra_data_integrity_checks = true
    self.format_magic_signature = "SCAVSETT".to_utf8_buffer()
    self.all_values_omit_setters = false
    self.auto_save_soft_delay = 15.0
    self.auto_save_max_delay = 30.0
    self.user_script_body = """
signal settings_changed
"""

func _serialize_constants(out: ScriptFileBuilder) -> void:
    super._serialize_constants(out)
    out._enum("WIN_MODE", WIN_MODE)

func _register_properties() -> void:
    register_named_value(Val.single_val(VAL.WINDOW_WIDTH, "window_width", TYPE_UTIL.T.Uint32, 1200).run_code_after_val_set("settings_changed.emit()").config_section("WINDOW"))
    register_named_value(Val.single_val(VAL.WINDOW_HEIGHT, "window_height", TYPE_UTIL.T.Uint32, 800).run_code_after_val_set("settings_changed.emit()").config_section("WINDOW"))
    register_named_value(Val.single_val(VAL.WINDOW_X, "window_x", TYPE_UTIL.T.Uint32, 0).run_code_after_val_set("settings_changed.emit()").config_section("WINDOW"))
    register_named_value(Val.single_val(VAL.WINDOW_Y, "window_y", TYPE_UTIL.T.Uint32, 0).run_code_after_val_set("settings_changed.emit()").config_section("WINDOW"))
    register_named_value(Val.single_val(VAL.WINDOW_MODE, "window_mode", TYPE_UTIL.T.Uint32, 0).custom_type("WIN_MODE").run_code_after_val_set("settings_changed.emit()").config_section("WINDOW"))

func _register_versions() -> void:
    register_version_layout(0, [
        VAL.WINDOW_WIDTH,
        VAL.WINDOW_HEIGHT,
        VAL.WINDOW_X,
        VAL.WINDOW_Y,
        VAL.WINDOW_MODE,
    ])

##This class is an editor-only `EditorScript` that is run in the editor to automatically
##generate a binary-format script that automatically handles encrypting, reading, writing,
##upgrading (from an older version to a newer one), and triggering saves (or queued saves)
##when values change
##
## WARNING:
## ALTERING YOUR BUILD FILE MUST BE DONE CAREFULLY IF YOUR FILE FORMAT IS BEING USED IN PRODUCTION!
## IN GENERAL, YOU SHOULD ALWAYS ONLY EDIT THE CURRENT VERSION YOU ARE DEVELOPING ON AND NEVER EDIT
## ANY VERSIONS OR VALUE PROPERTIES THAT ARE ALREADY IN USE ON YOUR FILESYSTEM OR THE FILESYSTEMS OF YOUR USERS. 
## ALTERING PRIOR VERSIONS MAY RESULT IN UNRECOVERABLE FILE CORRUPTION!
@tool
class_name FileFormatBuilder extends ScriptBuilder

## Enabling this adds an extra layer of data integrity check when saving a file.
## [br]
## Even when `true`, you will have the option to disable this behavior in the
## generated script file
## [br]
## Before the temp save file is finalized and overwrites the real save file,
## a separate instance of the script format is loaded from
## the newly written temp file, and every property is checked to exactly equal the current
## instance to prove that a future read from disk will also match the current state
var extra_data_integrity_checks := false:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        extra_data_integrity_checks = v
## The tab style to use when generating the resulting file format script
var tab_mode := StringBuilder.TAB_MODE.SPACE_4:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        tab_mode = v
## The newline style to use when generating the resulting file format script
var newline_mode := StringBuilder.NEWLINE_MODE.CRLF:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        newline_mode = v
## Whether to store the fole as plain binray, compressed binary, or encrypted binary.
var data_mode: DATA_MODE = DATA_MODE.PLAIN_BINARY:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        data_mode = v
## The kind of compression to use when `data_mode == DATA_MODE.COMPRESSED`
## [br]
## See [FileAccess].CompressionMode
var compression_kind: FileAccess.CompressionMode = FileAccess.CompressionMode.COMPRESSION_ZSTD:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        compression_kind = v
## The encryption key to use when `data_mode == DATA_MODE.ENCRYPTED` to use for encryption. MUST be 32 bytes exactly. Example:
## [codeblock]
## encrypt_key = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF".hex_decode()
## [/codeblock]
var encrypt_key: PackedByteArray = []:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        assert(v.size() == 32, "encryption key MUST be 32 bytes long")
        encrypt_key = v
## The MAC key to use when `data_mode == DATA_MODE.HMAC_ENCRYPTED` to use for HMAC authentication. MUST be 32 bytes exactly. Example:
## [codeblock]
## encrypt_key = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF".hex_decode()
## [/codeblock]
var hmac_key: PackedByteArray = []:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        assert(v.size() == 32, "hmac key MUST be 32 bytes long")
        hmac_key = v
## The file extension to use for this file format
var format_ext = ".dat":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        format_ext = v
## When using automatic saving, any time a value is updated,
## it will set a timer to this value. If no other values are changed
## before the timer runs out, it triggers a save
## [br]
## NOTE: Requires that the script's `_process()` function is called somewhere
## in the game loop. If the script is a `RefCounted` you must call this manually
var auto_save_soft_delay: float = 1.0:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        auto_save_soft_delay = v
## When using automatic saving, this is the MAXIMUM time that the file will wait
## after an update is queued before triggering a save,
## even if values have been recently changed and the soft delay is still pending
## [br]
## NOTE: Requires that the script's `_process()` function is called somewhere
## in the game loop. If the script is a `RefCounted` you must call this manually
var auto_save_max_delay: float = 5.0:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        auto_save_max_delay = v
## The endian-ness of the file format. In almost all cases this should remain `false`
var big_endian: bool = false:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        big_endian = v
## Enables automatically saving when values are changed. Can be disabled in the generated script
## [br]
## NOTE: Requires that the script's `_process()` function is called somewhere
## in the game loop. If the script is a `RefCounted` you must call this manually
var automatically_save: bool = true:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        automatically_save = v
## A string of bytes located at the very beginning of the file to
## provide a quick sanity-check that the file you are opening is the
## expected format
var format_magic_signature: PackedByteArray = []:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        format_magic_signature = v
## Optional code that will be added to the script
var user_script_body: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_script_body = v
## Optional code that will be added to the script in the `_init()` function
var user_init_body: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_init_body = v
## Optional code that will be added to the script in the `_process(delta: float)` function
var user_process_body: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_process_body = v
## Optional code that will be added to the script in the `_physics_process(delta: float)` function
var user_physics_process_body: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_physics_process_body = v
## Optional code that will be added to the script in the `_enter_tree()` function
var user_enter_tree_body: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_enter_tree_body = v
## Optional code that will be added to the script in the `_exit_tree()` function
var user_exit_tree_body: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_exit_tree_body = v
## Optional code that will be added to the script in the `_ready()` function
var user_ready_body: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_ready_body = v
## Optional code that will be run immediately after the file is loaded
## [br]
## If `extra_data_integrity_checks` is enabled, in addition to the variables on the file,
## there will also be a `bool` named `_is_integrity_check` in scope
## [br]
## If `automatically_save` is ASLO enabled,
## there will also be a `bool` named `_is_integrity_check_on_auto_save` in scope
var user_post_load_body: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_post_load_body = v
## Optional code that will be run immediately before the file is saved
##
## If automatic saving is enabled, in addition to the variables on the file,
## there will also be a `bool` named `_is_auto_save` in scope
var user_pre_save_body: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_pre_save_body = v
## Optional code that will be run immediately after the file is saved
##
## If automatic saving is enabled, in addition to the variables on the file,
## there will also be a `bool` named `_is_auto_save` in scope
var user_post_save_body: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_post_save_body = v
## Optional code that will be run immediately before the integrity check
## if `extra_data_integrity_checks` is enabled
## [br]
## a variable named `other` will be in scope which represents the
## cloned and re-loaded file state. You can manually set `other`
## variables to equal their `self` counterpart in order to skip
## (auto pass) certain variables during integrity checks
var user_pre_integrity_check_body: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_pre_integrity_check_body = v
## Print the serialized fields immediately before saving and immediately after loading.
## [br]
## Intended for development/debug only
var debug_print_during_save_and_load: bool = false:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        debug_print_during_save_and_load = v
## If set to `true`, this will COMPLETELY skip generating code for saving/loading and version upgrading
## [br]
## You can use this to repurpose the `FileFormatBuilder` infrastructure
## to build generic scripts, altough this is probably less useful than
## just writing them manually.
## [br]
## As an example, `FatEntitySystemBuilder` sets this to `true` when generating
## a standalone non-serializable file, otherwise it merges its properties with the `FileFormatBuilder`
## prior to serialization
var completely_omit_serialization_code: bool = false:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        completely_omit_serialization_code = v
## Generate a function to print the data state (only the properties registered via ScriptBuilder,
## not any variables defined in user body strings)
var include_print_function: bool = false:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        include_print_function = v
## If set to `true`, all properties will NEVER have setter methods.
## [br]
## You can also omit the setter on individual properties when registering the values
var all_values_omit_setters: bool = false:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        all_values_omit_setters = v
## A list of sub-formats that will be combined with this one.
## [br]
## The sub formats will not execute the normal ScriptBuilder serialization procedure. Instead,
## all their properties and user code fragments will be appended to this one their versions will
## be validated to be compatible with each other in the PRE-SERIALIZE stage
var sub_file_formats: Array[FileFormatBuilder] = []:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        sub_file_formats = v
func _init(sub_formats: Array[FileFormatBuilder] = []) -> void:
    _in_mode = M_CONFIG
    self.sub_file_formats = sub_formats
    _in_mode = M_NONE

enum DATA_MODE {
    PLAIN_BINARY = 0,
    COMPRESSED = 1,
    ENCRYPTED = 2,
    HMAC_ENCRYPTED = 3,
    TEXT_CONFIG = 4,
}

enum PROP_MODE {
    NORMAL,
    OMIT_SETTER,
}

var _num_vals: int = 0
var _val_names: PackedStringArray = []
var _val_types: PackedByteArray = []
var _val_arrayness: PackedInt32Array = []
var _val_defaults: Array = []
var _val_pre_set_effects: PackedStringArray = []
var _val_post_set_effects: PackedStringArray = []
var _val_mode: PackedByteArray = []
var _val_cfg_sections: PackedStringArray = []
var _val_custom_types: PackedStringArray = []
var _val_custom_defaults: PackedStringArray = []
var _val_custom_layouts: Array = []
var _val_no_serialize: PackedByteArray = []
var _num_versions: int = 0
var _version_val_layouts: Array = []
var _version_upgrade_code: PackedStringArray = []

static func _GEN_ARRAYNESS_READ_STRING(arrayness: int) -> String:
    if arrayness == 0:
        return "()"
    elif arrayness == 1:
        return "_array_len_prefix()"
    else:
        return "_array_len_prefix_nested(%d)" % (arrayness - 1)

static func _GEN_ARRAYNESS_READ_STRING_CUSTOM(cust_func: String, arrayness: int) -> String:
    if arrayness == 0:
        return "(" + cust_func + ")"
    elif arrayness == 1:
        return "_array_len_prefix(" + cust_func + ")"
    else:
        return "_array_len_prefix_nested(%s, %d)" % [cust_func, arrayness - 1]

static func _GEN_ARRAYNESS_WRITE_STRING(arrayness: int, name: String) -> String:
    if arrayness == 0:
        return "(" + name + ")"
    elif arrayness == 1:
        return "_array_len_prefix(" + name + ")"
    else:
        return "_array_len_prefix_nested(%d, %s)" % [(arrayness - 1), name]

static func _GEN_ARRAYNESS_WRITE_STRING_CUSTOM(cust_func: String, arrayness: int, name: String) -> String:
    if arrayness == 0:
        return "(" + cust_func + ", " + name + ")"
    elif arrayness == 1:
        return "_array_len_prefix(" + cust_func + ", " + name + ")"
    else:
        return "_array_len_prefix_nested(%s, %d, %s)" % [cust_func, (arrayness - 1), name]

const _GEN_READ = "read_"
const _GEN_WRITE = "write_"

const _KEY_CFG_META_SECTION = FileFormatUtil._KEY_CFG_META_SECTION
const _KEY_CFG_SIG = FileFormatUtil._KEY_CFG_SIG
const _KEY_CFG_VER = FileFormatUtil._KEY_CFG_VER

func _post_register_props_validate() -> void:
    assert(_num_vals > 0, "no values registered for file format `%s`" % script_class)

func _post_versions_validate() -> void:
    assert(_num_versions > 0, "no format versions registered for file format `%s`" % script_class)

func combine_with_sub_file_format(sub_format_builder: FileFormatBuilder) -> void:
    assert(_in_mode == M_PRE_SERIALIZE and sub_format_builder._in_mode == M_PRE_SERIALIZE, "both the parent format and the sub-format must be in 'pre-serialize' mode, meaning they have both individually had `_set_config()`, `_register_values()`, and `_register_versions`, run on them, but have not yet called `_run_serialization()`")
    assert(sub_format_builder._num_versions == _num_versions, "both formats must have a matching number of versions. You can use `register_version_with_no_changes_from_prev()` to syncronize version numbers when either the parent or sub-format have no changes while the other does")
    _val_names.append_array(sub_format_builder._val_names)
    _val_types.append_array(sub_format_builder._val_types)
    _val_arrayness.append_array(sub_format_builder._val_arrayness)
    _val_defaults.append_array(sub_format_builder._val_defaults)
    _val_pre_set_effects.append_array(sub_format_builder._val_pre_set_effects)
    _val_post_set_effects.append_array(sub_format_builder._val_post_set_effects)
    _val_mode.append_array(sub_format_builder._val_mode)
    _val_cfg_sections.append_array(sub_format_builder._val_cfg_sections)
    _val_custom_types.append_array(sub_format_builder._val_custom_types)
    _val_custom_layouts.append_array(sub_format_builder._val_custom_layouts)
    _val_custom_defaults.append_array(sub_format_builder._val_custom_defaults)
    _val_no_serialize.append_array(sub_format_builder._val_no_serialize)
    
    
    var _parent_num_vals = _num_vals
    _num_vals += sub_format_builder._num_vals
        
    var v := 0
    while v < _num_versions:
        var parent_layout = _version_val_layouts[v]
        var s := 0
        while s < sub_format_builder._version_val_layouts[v].size():
            sub_format_builder._version_val_layouts[v][s] += _parent_num_vals
            s += 1
        parent_layout.append_array(sub_format_builder._version_val_layouts[v])
        var parent_upgrade = _version_upgrade_code[v]
        var sub_format_upgrade = sub_format_builder._version_upgrade_code[v]
        parent_upgrade = parent_upgrade + "\n" + sub_format_upgrade
        _version_upgrade_code[v] = parent_upgrade
        var used_names: PackedStringArray
        for id in parent_layout:
            var val_name = _val_names[id]
            assert(!used_names.has(val_name), "when combining file formats, value name `%s` was used more than once in the same version (ver `%d`) (name overlap between parent format and sub-format being combined)" % [val_name, v])
            used_names.push_back(val_name)
        v += 1
    _in_mode = M_CONFIG
    if !sub_format_builder.user_script_body.is_empty():
        self.user_script_body += "\n" + sub_format_builder.user_script_body
    if !sub_format_builder.user_init_body.is_empty():
        self.user_init_body += "\n" + sub_format_builder.user_init_body
    if !sub_format_builder.user_post_load_body.is_empty():
        self.user_post_load_body += "\n" + sub_format_builder.user_post_load_body
    if !sub_format_builder.user_post_save_body.is_empty():
        self.user_post_save_body += "\n" + sub_format_builder.user_post_save_body
    if !sub_format_builder.user_pre_integrity_check_body.is_empty():
        self.user_pre_integrity_check_body += "\n" + sub_format_builder.user_pre_integrity_check_body
    if !sub_format_builder.user_pre_save_body.is_empty():
        self.user_pre_save_body += "\n" + sub_format_builder.user_pre_save_body
    if !sub_format_builder.user_process_body.is_empty():
        self.user_process_body += "\n" + sub_format_builder.user_process_body
    if !sub_format_builder.user_physics_process_body.is_empty():
        self.user_physics_process_body += "\n" +sub_format_builder.user_physics_process_body
    if !sub_format_builder.user_enter_tree_body.is_empty():
        self.user_enter_tree_body += "\n" + sub_format_builder.user_enter_tree_body
    if !sub_format_builder.user_exit_tree_body.is_empty():
        self.user_exit_tree_body += "\n" + sub_format_builder.user_exit_tree_body
    _in_mode = M_PRE_SERIALIZE

func _set_config() -> void:
    pass

func _register_properties() -> void:
    pass

func _register_versions() -> void:
    pass

func _pre_serialize() -> void:
    pass

func _run_config() -> void:
    super._run_config()
    for sub in sub_file_formats:
        sub._run_config()

func _run_register_properties() -> void:
    super._run_register_properties()
    for sub in sub_file_formats:
        sub._run_register_properties()

func _run_register_versions() -> void:
    super._run_register_versions()
    for sub in sub_file_formats:
        sub._run_register_versions()

func _run_pre_serialize() -> void:
    super._run_pre_serialize()
    if !completely_omit_serialization_code:
        _in_mode = M_CONFIG
        if init_func_args.is_empty():
            init_func_args = "path: String"
        else:
            init_func_args += ", path: String"
        _in_mode = M_PRE_SERIALIZE
    for sub in sub_file_formats:
        sub._run_pre_serialize()
        combine_with_sub_file_format(sub)

func _serialize_enter_tree(out: ScriptFileBuilder) -> void:
    if !user_enter_tree_body.is_empty():
        out._multiline_raw(user_enter_tree_body)
    
func _serialize_exit_tree(out: ScriptFileBuilder) -> void:
    if !user_exit_tree_body.is_empty():
        out._multiline_raw(user_exit_tree_body)

func _serialize_physics_process(out: ScriptFileBuilder) -> void:
    if !user_physics_process_body.is_empty():
        out._multiline_raw(user_physics_process_body)

func _serialize_ready(out: ScriptFileBuilder) -> void:
    if !user_ready_body.is_empty():
        out._multiline_raw(user_ready_body)

func _serialize_constants(out: ScriptFileBuilder) -> void:
    if !completely_omit_serialization_code:
        out.raw.write_line("const DATA_MODE := FileFormatUtil.DATA_MODE.", DATA_MODE.find_key(data_mode))
        if automatically_save:
            out.raw.write_line("const AUTO_SAVE_SOFT_DELAY_SECS: float = ", auto_save_soft_delay)
            out.raw.write_line("const AUTO_SAVE_MAX_DELAY_SECS: float = ", auto_save_max_delay)
        if data_mode == DATA_MODE.HMAC_ENCRYPTED:
            out.raw.write_line("const HMAC_KEY: PackedByteArray = ", hmac_key)
        match data_mode:
            DATA_MODE.ENCRYPTED, DATA_MODE.HMAC_ENCRYPTED:
                out.raw.write_line("const ENCRYPTION_KEY: PackedByteArray = ", encrypt_key)
            DATA_MODE.COMPRESSED:
                out.raw.write_line("const COMPRESS_MODE: FileAccess.CompressionMode = ", compression_kind)
            _: pass
        out.raw.write_line("const FMT_SIG: PackedByteArray = ", format_magic_signature)
        if data_mode != DATA_MODE.TEXT_CONFIG:
            out.raw.write_line("const BIG_ENDIAN: bool = ", big_endian)
        out.raw.write_line("const MAX_VERSION: int = ", _num_versions - 1)
        out.raw.write_newline()

func _serialize_init(out: ScriptFileBuilder) -> void:
    if !completely_omit_serialization_code:
        out._line("file_path = path")
    if !user_init_body.is_empty():
        out._comment("# USER INIT")
        out._multiline_raw(user_init_body)
        out._comment("# END USER INIT")

func _serialize_properties(out: ScriptFileBuilder) -> void:
    if !completely_omit_serialization_code:
        out.raw.write_line("var file_path: String = \"\"")
        out.raw.write_line("var format_version: int = MAX_VERSION")
        out.raw.write_line("var is_open: bool = true")
        if automatically_save:
            out.raw.write_line("var auto_save_soft_timeout: float = -1.0")
            out.raw.write_line("var auto_save_max_timeout: float = -1.0")
            out.raw.write_line("var disable_auto_save: bool = false")
        if extra_data_integrity_checks:
            out.raw.write_line("var disable_extra_integrity_check: bool = false")
        out.raw.write_newline()
    var max_ver_layout = _version_val_layouts[_num_versions - 1]
    for id in max_ver_layout:
        _gen_property(out.raw, 0, id)

func _serialize_static_properties(out: ScriptFileBuilder) -> void:
    if !completely_omit_serialization_code:
        out.raw.write_line("signal file_saved(file: ", script_class, ")")
        out.raw.write_line("signal file_loaded(file: ", script_class, ")")
        out.raw.write_newline()

func _serialize_methods(out: ScriptFileBuilder) -> void:
    var max_ver_layout = _version_val_layouts[_num_versions - 1]
    if !completely_omit_serialization_code:
        out.raw.write_line("func exists() -> bool:")
        out.raw.write_indented_line(1, "return FileAccess.file_exists(file_path)")
        out.raw.write_newline()
    
        out.raw.write("func load(")
        if extra_data_integrity_checks:
            out.raw.write("_is_integrity_check: bool = false")
            if automatically_save:
                out.raw.write(", _is_integrity_check_on_auto_save: bool = false")
        out.raw.write_line(") -> Result:")
        out.raw.write_indented_line(1, "var result := FileFormatUtil.load_common(file_path, DATA_MODE, ", "COMPRESS_MODE" if data_mode == DATA_MODE.COMPRESSED else "FileAccess.CompressionMode.COMPRESSION_FASTLZ" , ", ", "HMAC_KEY" if data_mode == DATA_MODE.HMAC_ENCRYPTED else "PackedByteArray()",  ", ",  "ENCRYPTION_KEY" if (data_mode == DATA_MODE.HMAC_ENCRYPTED or data_mode == DATA_MODE.ENCRYPTED) else "PackedByteArray()",", FMT_SIG, MAX_VERSION, ", "BIG_ENDIAN" if data_mode != DATA_MODE.TEXT_CONFIG else "false", ")")
        out.raw.write_indented_line(1, "if result.is_failing(): return result")
        if automatically_save:
            out.raw.write_indented_line(1, "var did_upgrade = format_version < MAX_VERSION")
        out.raw.write_indented_line(1, "if format_version == MAX_VERSION:")
        out.raw.write_indented_line(2, "_load_directly(", "result, " if data_mode != DATA_MODE.TEXT_CONFIG else "", "result.value.", "bin_file" if data_mode != DATA_MODE.TEXT_CONFIG else "cfg_file",")")
        out.raw.write_indented_line(1, "else:")
        out.raw.write_indented_line(2, "_load_to_dict_then_upgrade(", "result, " if data_mode != DATA_MODE.TEXT_CONFIG else "", "result.value.", "bin_file" if data_mode != DATA_MODE.TEXT_CONFIG else "cfg_file",")")
        out.raw.write_indented_line(1, "if result.is_failing(): return result")
        if automatically_save:
            out.raw.write_indented_line(1, "if did_upgrade:")
            out.raw.write_indented_line(2, "result.check(queue_save())")
        if user_post_load_body.length() > 0:
            out.raw.write_indented_line(1, "#region USER POST LOAD")
            out._multiline_raw_indent(1, user_post_load_body)
            out.raw.write_indented_line(1, "#endregion END USER POST LOAD")
        if debug_print_during_save_and_load:
            out.raw.write_indented_line(1, "print_state(\"LOADED: ", script_class, "\") # DEBUG")
        out.raw.write_indented_line(1, "file_loaded.emit(self)")
        out.raw.write_indented_line(1, "is_open = true")
        out.raw.write_indented_line(1, "return result")
        out.raw.write_newline()

        out.raw.write_line("func _load_to_dict_then_upgrade(", "result: Result, " if data_mode != DATA_MODE.TEXT_CONFIG else "","file: ", "BinaryFile" if data_mode != DATA_MODE.TEXT_CONFIG else "ConfigFile", ") -> void:")
        out.raw.write_indented_line(1, "assert(format_version < MAX_VERSION)")
        out.raw.write_indented_line(1, "var read_routine: Callable = ", script_class,".PREV_VERSION_READ_ROUTINES[format_version]")
        out.raw.write_indented_line(1, "var vals: Dictionary = {}")
        out.raw.write_indented_line(1, "read_routine.call(file, vals)")
        if data_mode != DATA_MODE.TEXT_CONFIG:
            out.raw.write_indented_line(1, "if result.failed(file.last_error(), FileFormatUtil.FILE_READ_ERROR % file_path ): return")
        out.raw.write_indented_line(1, "while format_version < MAX_VERSION:")
        out.raw.write_indented_line(2, "var upgrade_routine: Callable = ", script_class,".PREV_VERSION_UPGRADE_ROUTINES[format_version]")
        out.raw.write_indented_line(2, "upgrade_routine.call(vals)")
        out.raw.write_indented_line(2, "format_version += 1")
        for id in max_ver_layout:
            _gen_final_upgrade_dict_to_prop(out.raw, 1, id)
        out.raw.write_indented_line(1, "return")
        out.raw.write_newline()

        out.raw.write_line("func _load_directly(", "result: Result, " if data_mode != DATA_MODE.TEXT_CONFIG else "","file: ", "BinaryFile" if data_mode != DATA_MODE.TEXT_CONFIG else "ConfigFile", ") -> void:")
        out.raw.write_indented_line(1, "assert(format_version == MAX_VERSION)")
        for id in max_ver_layout:
            _gen_read_op(out.raw, 1, id, _READ_MODE.READ_TO_PROP)
        if data_mode != DATA_MODE.TEXT_CONFIG:
            out.raw.write_indented_line(1, "result.check(file.last_error(), FileFormatUtil.FILE_READ_ERROR % file_path)")
        out.raw.write_indented_line(1, "return")
        out.raw.write_newline()

        out.raw.write_line("func check_valid() -> Result:")
        out.raw.write_indented_line(1, "var result := FileFormatUtil.load_common(file_path, DATA_MODE, ", "COMPRESS_MODE" if data_mode == DATA_MODE.COMPRESSED else "FileAccess.CompressionMode.COMPRESSION_FASTLZ" , ", ", "ENCRYPTION_KEY" if (data_mode == DATA_MODE.HMAC_ENCRYPTED or data_mode == DATA_MODE.ENCRYPTED) else "PackedByteArray()",  ", ", "HMAC_KEY" if data_mode == DATA_MODE.HMAC_ENCRYPTED else "PackedByteArray()",", FMT_SIG, MAX_VERSION, ", "BIG_ENDIAN" if data_mode != DATA_MODE.TEXT_CONFIG else "false", ")")
        out.raw.write_indented_line(1, "return result")
        out.raw.write_newline()

        if automatically_save:
            out.raw.write_line("func queue_save() -> Result:")
            out.raw.write_indented_line(1, "var result := Result.cache_first_failure()")
            out.raw.write_indented_line(1, "if !is_open: return result")
            out.raw.write_indented_line(1, "if !disable_auto_save:")
            out.raw.write_indented_line(2, "if auto_save_max_timeout <= 0.0:")
            out.raw.write_indented_line(3, "auto_save_max_timeout = AUTO_SAVE_MAX_DELAY_SECS")
            out.raw.write_indented_line(2, "auto_save_soft_timeout = AUTO_SAVE_SOFT_DELAY_SECS")
            out.raw.write_indented_line(2, "if auto_save_soft_timeout <= 0.0 or auto_save_max_timeout <= 0.0:")
            out.raw.write_indented_line(3, "result.check(save(false, true))")
            out.raw.write_indented_line(1, "return result")
            out.raw.write_newline()

        out.raw.write_line("func save_and_close() -> Result:")
        out.raw.write_indented_line(1, "return save(true, false)")
        out.raw.write_newline()

        out.raw.write("func save(close_after_save: bool = false")
        if automatically_save:
            out.raw.write(", _is_auto_save: bool = false")
        out.raw.write_line(") -> Result:")
        out.raw.write_indented_line(1, "assert(format_version == MAX_VERSION)")
        out.raw.write_indented_line(1, "var result := Result.cache_first_failure()")
        out.raw.write_indented_line(1, "if !is_open: return result")
        if user_pre_save_body.length() > 0:
            out.raw.write_indented_line(1, "# USER PRE SAVE")
            var pre_save = ScriptFileBuilder.clean_and_indent_string(user_pre_save_body, out.raw, 1)
            out.raw.write_line(pre_save)
            out.raw.write_indented_line(1, "# END USER PRE SAVE")
        if debug_print_during_save_and_load:
            out.raw.write_indented_line(1, "print_state(\"SAVING: ", script_class, "\") # DEBUG")
        out.raw.write_indented_line(1, "result.check(FileFormatUtil.save_common_one(file_path, DATA_MODE, ", "COMPRESS_MODE" if data_mode == DATA_MODE.COMPRESSED else "FileAccess.CompressionMode.COMPRESSION_FASTLZ" , ", ", "HMAC_KEY" if data_mode == DATA_MODE.HMAC_ENCRYPTED else "PackedByteArray()" ,  ", ", "ENCRYPTION_KEY" if (data_mode == DATA_MODE.HMAC_ENCRYPTED or data_mode == DATA_MODE.ENCRYPTED) else "PackedByteArray()",", FMT_SIG, MAX_VERSION, ", "BIG_ENDIAN" if data_mode != DATA_MODE.TEXT_CONFIG else "false", "))")
        out.raw.write_indented_line(1, "if result.is_failing(): return result")
        out.raw.write_indented_line(1, "var file = result.value")
        for id in max_ver_layout:
            _gen_write_op(out.raw, 1, id)
        out.raw.write_indented_line(1, "FileFormatUtil.save_common_two(result, file, file_path, DATA_MODE)")
        if extra_data_integrity_checks:
            out.raw.write_indented_line(1, "if result.is_passing() and !disable_extra_integrity_check:")
            if automatically_save:
                out.raw.write_indented_line(2, "var check_clone = clone_metadata_only(true)")
            else:
                out.raw.write_indented_line(2, "var check_clone = clone_metadata_only()")
            out.raw.write_indented_line(2, "check_clone.file_path = check_clone.file_path + \".tmp\"")
            out.raw.write_indented_line(2, "result.check(check_clone.load(true))")
            out.raw.write_indented_line(2, "result.check(self.data_equals(check_clone), FileFormatUtil.DATA_INTEGRITY_FAIL % file_path)")
        out.raw.write_indented_line(1, "FileFormatUtil.save_common_three(result, file_path)")
        if user_post_save_body.length() > 0:
            out.raw.write_indented_line(1, "# USER POST SAVE")
            var post_save = ScriptFileBuilder.clean_and_indent_string(user_post_save_body, out.raw, 1)
            out.raw.write_line(post_save)
            out.raw.write_indented_line(1, "# END USER POST SAVE")
        out.raw.write_indented_line(1, "if result.is_passing():")
        if automatically_save:
            out.raw.write_indented_line(2, "auto_save_max_timeout = -1.0")
            out.raw.write_indented_line(2, "auto_save_soft_timeout = -1.0")
        out.raw.write_indented_line(2, "if !close_after_save:")
        out.raw.write_indented_line(3, "file_saved.emit(self)")
        out.raw.write_indented_line(2, "else:")
        out.raw.write_indented_line(3, "is_open = false")
        out.raw.write_indented_line(1, "return result")
        out.raw.write_newline()

        out.raw.write_line("func delete(send_to_trash: bool = false) -> Result:")
        out.raw.write_indented_line(1, "var result := Result.cache_first_failure()")
        out.raw.write_indented_line(1, "if !FileAccess.file_exists(file_path): return result.with_err(ERR_FILE_NOT_FOUND, FileFormatUtil.FILE_DOESNT_EXIST % file_path)")
        out.raw.write_indented_line(1, "if send_to_trash:")
        out.raw.write_indented_line(2, "result.check(OS.move_to_trash(file_path), FileFormatUtil.COULDNT_SEND_FILE_TO_TRASH % file_path)")
        out.raw.write_indented_line(1, "else:")
        out.raw.write_indented_line(2, "result.check(DirAccess.remove_absolute(file_path), FileFormatUtil.COULDNT_DELETE_FILE % file_path)")
        out.raw.write_indented_line(1, "return result")
        out.raw.write_newline()

    if (!completely_omit_serialization_code and debug_print_during_save_and_load) or include_print_function:
        out.raw.write_line("func print_state(var_name: String = \"<val>\") -> void:")
        out.raw.write_indented_line(1, "print(var_name, \":\")")
        for id in max_ver_layout:
            _gen_print_op(out.raw, 1, id)
        out.raw.write_newline()
    
    if !completely_omit_serialization_code:
        out.raw.write("func clone_metadata_only(")
        if automatically_save:
                out.raw.write("disable_autosave_on_clone: bool = false")
        out.raw.write_line(") -> ", script_class, ":")
        out.raw.write_indented_line(1, "var new_self := ", script_class, ".new(self.file_path)")
        out.raw.write_indented_line(1, "new_self.format_version = self.format_version")
        if automatically_save:
            out.raw.write_indented_line(1, "new_self.disable_auto_save = self.disable_auto_save or disable_autosave_on_clone")
        if extra_data_integrity_checks:
            out.raw.write_indented_line(1, "new_self.disable_extra_integrity_check = self.disable_extra_integrity_check")
        out.raw.write_indented_line(1, "return new_self")
        out.raw.write_newline()

        out.raw.write("func data_equals(other: ", script_class)
        if extra_data_integrity_checks:
            out.raw.write(", _is_integrity_check: bool = false")
        out.raw.write_line(") -> bool:")
        if extra_data_integrity_checks and user_pre_integrity_check_body.length() > 0:
            out.raw.write_indented_line(1, "# USER PRE INTEGRITY CHECK")
            var pre_check = ScriptFileBuilder.clean_and_indent_string(user_pre_integrity_check_body, out.raw, 1)
            out.raw.write_line(pre_check)
            out.raw.write_indented_line(1, "# END USER PRE INTEGRITY CHECK")
        for id in max_ver_layout:
            _gen_compare_op(out.raw, 1, id)
        out.raw.write_indented_line(1, "return true")
        out.raw.write_newline()

func _serialize_process(out: ScriptFileBuilder) -> void:
    if automatically_save and !completely_omit_serialization_code:
        out._line_indent(0, "if !disable_auto_save:")
        out._line_indent(1, "var need_save := false")
        out._line_indent(1, "if auto_save_max_timeout >= 0.0:")
        out._line_indent(2, "auto_save_max_timeout -= delta")
        out._line_indent(2, "need_save = true")
        out._line_indent(1, "if auto_save_soft_timeout >= 0.0:")
        out._line_indent(2, "auto_save_soft_timeout -= delta")
        out._line_indent(2, "need_save = true")
        out._line_indent(1, "if need_save and (auto_save_soft_timeout <= 0.0 or auto_save_max_timeout <= 0.0):")
        out._line_indent(2, "var result = save(false, true)")
        out._line_indent(2, "result.handle_fail()")

func _serialize_static_functions(out: ScriptFileBuilder) -> void:
    if !completely_omit_serialization_code:
        var v: int = 0
        while v < _num_versions - 1:
            out.raw.write_line("static func read_ver_", v, "(file: ", "BinaryFile", ", vals: Dictionary) -> void:")
            for id in _version_val_layouts[v]:
                _gen_read_op(out.raw, 1, id, _READ_MODE.READ_TO_DICT)
            out.raw.write_newline()
            v += 1
        v = 0
        while v < _num_versions - 1:
            out.raw.write_line("static func upgrade_ver_", v, "(vals: Dictionary) -> void:")
            var up_code = _version_upgrade_code[v]
            up_code = up_code.lstrip(" \t\n\r") 
            up_code = up_code.rstrip(" \t\n\r") 
            up_code = up_code.indent(out.raw.get_indent_string())
            out.raw.write_line(up_code)
            out.raw.write_newline()
            v += 1
        v = 0
        while v < _num_vals:
            var cust = _val_custom_layouts[v]
            if cust.size() > 0:
                _gen_sub_routine_write(out.raw, v)
                out.raw.write_newline()
                _gen_sub_routine_read(out.raw, v)
                out.raw.write_newline()
            v += 1
        out.raw.write_newline()

func _serialize_miscelaneous(out: ScriptFileBuilder) -> void:
    if !user_script_body.is_empty():
        out._multiline_raw(user_script_body)
    if !completely_omit_serialization_code:
        var v = 0
        out.raw.write_line("static var PREV_VERSION_READ_ROUTINES: Array[Callable] = [")
        while v < _num_versions - 1:
            out.raw.write_indented_line(1, "read_ver_", v, ",")
            v += 1
        out.raw.write_line("]:")
        out.raw.write_indented_line(1, "set(v): assert(false)")
        out.raw.write_newline()
        v = 0
        out.raw.write_line("static var PREV_VERSION_UPGRADE_ROUTINES: Array[Callable] = [")
        while v < _num_versions - 1:
            out.raw.write_indented_line(1, "upgrade_ver_", v, ",")
            v += 1
        out.raw.write_line("]:")
        out.raw.write_indented_line(1, "set(v): assert(false)")
        out.raw.write_newline()

func _check_and_add_default_value(type: TYPE_UTIL.T, arrayness: int, default: Variant, custom_default: String, root: bool = false) -> void:
    TYPE_UTIL.check_default_value(type, arrayness, default, custom_default, root)
    if root:
        _val_defaults.push_back(default)

const SINGLE_VALUE := 0
const ARRAY := 1
const ARRAY_OF_ARRAYS := 2
const ARRAY_OF_ARRAYS_OF_ARRAYS := 3

class Val:
    var _id: int = 0
    var _type: TYPE_UTIL.T = TYPE_UTIL.T.Bool
    var _name: String = ""
    var _default: Variant = null
    var _run_code_before_val_set: String = ""
    var _run_code_after_val_set: String = ""
    var _omit_setter: bool = false
    var _config_section: String = "MISC"
    var _arrayness: int = 0
    var _custom_type: String = ""
    var _custom_default: String = ""
    var _custom_sub_layout: Array[Val] = []
    var _no_serialize: int = 0

    func _init(id: int, name: String, type: TYPE_UTIL.T, default: Variant) -> void:
        _id = id
        _name = name
        _type = type
        _default = default

    static func single_val(id: int, name: String, type: TYPE_UTIL.T, default: Variant) -> Val:
        return Val.new(id, name, type, default)
    static func array(id: int, name: String, type: TYPE_UTIL.T, default: Variant) -> Val:
        var vset = Val.new(id, name, type, default)
        vset._arrayness = 1
        return vset
    static func nested_arrays(id: int, name: String, type: TYPE_UTIL.T, default: Variant, depth: int) -> Val:
        var vset = Val.new(id, name, type, default)
        vset._arrayness = depth
        return vset
    
    func run_code_before_val_set(code: String) -> Val:
        var new_set = self
        new_set._run_code_before_val_set = code
        return new_set

    func run_code_after_val_set(code: String) -> Val:
        var new_set = self
        new_set._run_code_after_val_set = code
        return new_set
    
    func omit_setter() -> Val:
        var new_set = self
        new_set._omit_setter = true
        return new_set

    func config_section(section: String) -> Val:
        var new_set = self
        new_set._config_section = section
        return new_set
    
    func custom_type(type_name: String) -> Val:
        var new_set = self
        new_set._custom_type = type_name
        return new_set
    
    func custom_default(default: String) -> Val:
        var new_set = self
        new_set._custom_default = default
        return new_set
    
    func custom_sub_layout(layout: Array[Val]) -> Val:
        var new_set = self
        new_set._custom_sub_layout = layout
        return new_set
    
    func do_not_serialize() -> Val:
        var new_set = self
        new_set._no_serialize = 1
        return new_set

func register_named_value(val: Val) -> void:
    assert(_in_mode == M_REGISTER_PROPS, "you can ONLY register named values inside the `_register_properties()` function")
    assert(val._id == _num_vals, "you must register val ids EXPLICITLY and EXACTLY in ascending order, starting from id 0, expected next id to register `%d`, but got id `%d`" % [_num_vals, val._id])
    assert(_val_names.size() == _num_vals)
    assert(val._arrayness >= 0, "'arrayness' must be greater than or equal to 0. 0 = single value, 1 = array, 2+ = nested arrays with this exact nesting depth")
    _val_names.push_back(val._name)
    _val_types.push_back(val._type)
    _val_arrayness.push_back(val._arrayness)
    _val_pre_set_effects.push_back(val._run_code_before_val_set)
    _val_post_set_effects.push_back(val._run_code_after_val_set)
    _val_custom_types.push_back(val._custom_type)
    _val_custom_defaults.push_back(val._custom_default)
    _val_custom_layouts.push_back(val._custom_sub_layout)
    _val_no_serialize.push_back(val._no_serialize)
    _val_mode.push_back(1 if all_values_omit_setters else int(val._omit_setter))
    if data_mode == DATA_MODE.TEXT_CONFIG:
        _val_cfg_sections.push_back(val._config_section)
    _check_and_add_default_value(val._type, val._arrayness, val._default, val._custom_default, true)
    _num_vals += 1
    
func register_version_layout(version: int, val_id_layout: PackedInt32Array, code_to_upgrade_to_next_version: String = "pass") -> void:
    assert(_in_mode == M_REGISTER_VERSIONS, "you can ONLY register version layouts inside the `_register_versions()` function")
    assert(version == _num_versions, "you must specify versions EXPLICITLY and EXACTLY in ascending order starting from version 0, expected next version to register `%d`, but got version `%d`" % [_num_versions, version])
    _num_versions += 1
    var used_ids: PackedByteArray
    used_ids.resize(_num_vals)
    used_ids.fill(0)
    var used_names: PackedStringArray
    for id in val_id_layout:
        assert(id < _num_vals, "id `%d` is greater than the largest registered id (`%d`)" % [id, _num_vals - 1])
        var already_used = used_ids[id]
        assert(already_used == 0, "id `%d` was already added to version `%d`" % [id, version])
        var val_name = _val_names[id]
        assert(!used_names.has(val_name), "value name `%s` was used more than once in the same version (ver `%d`)" % [val_name, version])
        used_names.push_back(val_name)
    _version_val_layouts.push_back(val_id_layout)
    _version_upgrade_code.push_back(code_to_upgrade_to_next_version)

func register_version_with_no_changes_from_prev(version: int) -> void:
    assert(_in_mode == M_REGISTER_VERSIONS, "you can ONLY register version layouts inside the `_register_versions()` function")
    assert(version == _num_versions, "you must specify versions EXPLICITLY and EXACTLY in ascending order starting from version 0, expected next version to register `%d`, but got version `%d`" % [_num_versions, version])
    var prev_version = _version_val_layouts[_num_versions - 1]
    _num_versions += 1
    _version_val_layouts.push_back(prev_version.duplicate())
    _version_upgrade_code.push_back("pass")
    
const _GEN_FILE = "file"

func _gen_sub_routine_write(out: StringBuilder, val_id: int) -> void:
    var no_serial = _val_no_serialize[val_id]
    if no_serial == 1: return
    var name: String = _val_names[val_id]
    var custom_type: String = _val_custom_types[val_id]
    var layout: Array[Val] = _val_custom_layouts[val_id]
    var section: String = "" if data_mode != DATA_MODE.TEXT_CONFIG else _val_cfg_sections[val_id]
    if custom_type == "":
        custom_type = "Variant"
    out.write_line("static func custom_write_", name, "(file: ", "BinaryFile", ", val_: ", custom_type, ") -> bool:")
    _gen_sub_routine_write_inner(out, section, "val_", layout)
    out.write_indented_line(1, "return file.last_error() == OK")
    
func _gen_sub_routine_write_inner(out: StringBuilder, section: String, parent: String, layout: Array[Val]) -> void:
    for v in layout:
        var path = parent + "." + v._name
        if v._custom_sub_layout.size() > 0:
            _gen_sub_routine_write_inner(out, section, path, v._custom_sub_layout)
        else:
            _gen_write_op_inner(out, 1, v._custom_sub_layout, v._type, section, path, v._arrayness)

func _gen_sub_routine_read(out: StringBuilder, val_id: int) -> void:
    var no_serial = _val_no_serialize[val_id]
    if no_serial == 1: return
    var name: String = _val_names[val_id]
    var custom_type: String = _val_custom_types[val_id]
    var layout: Array[Val] = _val_custom_layouts[val_id]
    var section: String = "" if data_mode != DATA_MODE.TEXT_CONFIG else _val_cfg_sections[val_id]
    if custom_type == "":
        custom_type = "Variant"
    out.write_line("static func custom_read_", name, "(file: ", "BinaryFile", ") -> ", custom_type,":")
    out.write_indented_line(1, "var val_ := ", custom_type, ".new()")
    _gen_sub_routine_read_inner(out, section, "val_", layout)
    out.write_indented_line(1, "return val_")
    
func _gen_sub_routine_read_inner(out: StringBuilder, section: String, parent: String, layout: Array[Val]) -> void:
    for v in layout:
        var path = parent + "." + v._name
        if v._custom_sub_layout.size() > 0:
            _gen_sub_routine_read_inner(out, section, path, v._custom_sub_layout)
        else:
            _gen_read_op_inner(out, 1, v._type, v._custom_sub_layout, path + " = ", section, v._default, path, v._arrayness)

func _gen_write_op(out: StringBuilder, indent: int, val_id: int) -> void:
    var no_serial = _val_no_serialize[val_id]
    if no_serial == 1: return
    var name: String = _val_names[val_id]
    var type: int = _val_types[val_id]
    var arrayness: int = _val_arrayness[val_id]
    var custom_layout: Array = _val_custom_layouts[val_id]
    var section = "" if data_mode != DATA_MODE.TEXT_CONFIG else _val_cfg_sections[val_id]
    if type == TYPE_UTIL.T.CustomType: 
        assert(custom_layout.size() > 0)
    else:
        assert(custom_layout.size() == 0)
    _gen_write_op_inner(out, indent, custom_layout, type, section, name, arrayness)

func _gen_write_op_inner(out: StringBuilder, indent: int, custom_layout: Array, type: TYPE_UTIL.T, section: String, name: String, arrayness: int) -> void:
    if custom_layout.size() > 0:
        assert(type == TYPE_UTIL.T.CustomType)
        out.write_indented_line(indent, _GEN_FILE, ".", _GEN_WRITE, "custom", _GEN_ARRAYNESS_WRITE_STRING_CUSTOM("custom_write_" + name, arrayness, name))
    elif data_mode == DATA_MODE.TEXT_CONFIG:
        
        out.write_indented_line(indent, _GEN_FILE, ".set_value(\"", section, "\", \"", name, "\", ", name, ")")
    else:
        out.write_indented_line(indent, _GEN_FILE, ".", _GEN_WRITE, TYPE_UTIL.T_NAME_GEN[type], _GEN_ARRAYNESS_WRITE_STRING(arrayness, name))

func _gen_compare_op(out: StringBuilder, indent: int, id: int) -> void:
    var name = _val_names[id]
    var custom = _val_custom_layouts[id]
    var arrayness = _val_arrayness[id]
    var type_name = _val_custom_types[id]
    var type = _val_types[id]
    var gd_base_type = TYPE_UTIL.T_GD_NAME[type]
    if gd_base_type == "Variant":
        _gen_compare_op_inner(out, indent, arrayness, name, type, type_name, "", "", custom)
    else:
        out.write_indented_line(indent, "if other.", name, " != self.", name, ": return false")

func _gen_compare_op_inner(out: StringBuilder, indent: int, arrayness: int, name: String, type: TYPE_UTIL.T, type_name: String, self_path: String, other_path: String, custom: Array[Val]) -> void:
    var o_val_name = other_path if other_path.length() > 0 else "other." + name
    var s_val_name = self_path if self_path.length() > 0 else "self." + name
    if arrayness > 0:
        var nested_i = "i" + str(indent)
        var nested_o = "other" + str(indent)
        var nested_s = "self" + str(indent)
        out.write_indented_line(indent, "if ", o_val_name, ".size() != ", s_val_name, ".size(): return false")
        out.write_indented_line(indent, "var ", nested_i, " := 0")
        out.write_indented_line(indent, "while ", nested_i, " < ", s_val_name, ".size():")
        out.write_indented_line(indent + 1, "var ", nested_o, " = ", o_val_name, "[", nested_i ,"]")
        out.write_indented_line(indent + 1, "var ", nested_s, " = ", s_val_name, "[", nested_i ,"]")
        _gen_compare_op_inner(out, indent + 1, arrayness - 1, "", type, type_name, nested_s, nested_o, custom)
        out.write_indented_line(indent + 1, nested_i, " += 1")
    else:
        if type == TYPE_UTIL.T.CustomType or custom.size() > 0:
            assert(type == TYPE_UTIL.T.CustomType and custom.size() > 0)
            for val in custom:
                _gen_compare_op_inner(out, indent, arrayness, val._name, val._type, TYPE_UTIL.T_GD_NAME[val._type], self_path + "." + val._name, other_path + "." + val._name, val._custom_sub_layout)
        elif type == TYPE_UTIL.T.Variant_AllowObject:
            var nested_p = "p" + str(indent)
            var nested_n = "n" + str(indent)
            out.write_indented_line(indent, "if ", o_val_name, " is Object and ", s_val_name, " is Object:")
            out.write_indented_line(indent + 1, "if ", o_val_name, ".get_script() !=  ", s_val_name, ".get_script(): return false")
            out.write_indented_line(indent + 1, "var props_", o_val_name, " = ", o_val_name, ".get_property_list()")
            out.write_indented_line(indent + 1, "var props_", s_val_name, " = ", s_val_name, ".get_property_list()")
            out.write_indented_line(indent + 1, "if props_", s_val_name, ".size() != props_", o_val_name, ".size(): return false")
            out.write_indented_line(indent + 1, "for ", nested_p, " in props_", s_val_name, ":")
            out.write_indented_line(indent + 2, "if ", nested_p, ".usage & PROPERTY_USAGE_CATEGORY or ", nested_p, " & PROPERTY_USAGE_GROUP:")
            out.write_indented_line(indent + 3, "continue")
            out.write_indented_line(indent + 2, "var ", nested_n, " = ", nested_p, ".name")
            out.write_indented_line(indent + 2, "if ", o_val_name, ".get(", nested_n, ") != ", s_val_name, ".get(", nested_n, "): return false")
            out.write_indented_line(indent, "else:")
            out.write_indented_line(indent + 1, "if ", o_val_name, " != ", s_val_name, ": return false")
        else:
            out.write_indented_line(indent, "if ", o_val_name, " != ", s_val_name, ": return false")

enum _READ_MODE {
    READ_TO_DICT,
    READ_TO_PROP,
}

func _gen_read_op(out: StringBuilder, indent: int, val_id: int, mode: _READ_MODE) -> void:
    var no_serial = _val_no_serialize[val_id]
    if no_serial == 1: return
    var name: String = _val_names[val_id]
    var type: int = _val_types[val_id]
    var arrayness: int = _val_arrayness[val_id]
    var reciever: String
    match mode:
        _READ_MODE.READ_TO_DICT:
            reciever = "vals[\"" + name +"\"] = "
        _READ_MODE.READ_TO_PROP:
            reciever = name + " = "
    var custom_layout: Array = _val_custom_layouts[val_id]
    var default = _val_defaults[val_id]
    var section = "" if data_mode != DATA_MODE.TEXT_CONFIG else _val_cfg_sections[val_id]
    _gen_read_op_inner(out, indent, type, custom_layout, reciever, section, default, name, arrayness)

func _gen_read_op_inner(out: StringBuilder, indent: int, type: TYPE_UTIL.T, custom_layout: Array, reciever: String, section: String, default: Variant, name: String, arrayness: int) -> void:
    if type == TYPE_UTIL.T.CustomType: 
        assert(custom_layout.size() > 0)
    else:
        assert(custom_layout.size() == 0)
    if custom_layout.size() > 0:
        assert(type == TYPE_UTIL.T.CustomType)
        out.write_indented_line(indent,  reciever, _GEN_FILE, ".", _GEN_READ, "custom", _GEN_ARRAYNESS_READ_STRING_CUSTOM("custom_read_" + name, arrayness))
    elif data_mode == DATA_MODE.TEXT_CONFIG:
        var def: String
        var gdtype = TYPE_UTIL.T_GD_TYPE[type]
        if gdtype == Variant.Type.TYPE_STRING:
            def = "\"" + str(default) + "\""
        else:
            def = str(default)
        out.write_indented_line(indent, reciever, _GEN_FILE, ".get_value(\"", section, "\", \"", name, "\", ", def, ")")
    else:
        out.write_indented_line(indent, reciever, _GEN_FILE, ".", _GEN_READ, TYPE_UTIL.T_NAME_GEN[type], _GEN_ARRAYNESS_READ_STRING(arrayness))

func _gen_print_op(out: StringBuilder, indent: int, id: int) -> void:
    var name = _val_names[id]
    var custom = _val_custom_layouts[id]
    var arrayness = _val_arrayness[id]
    var type_name = _val_custom_types[id]
    _gen_print_op_inner(out, indent, 1, arrayness, name, type_name, "", custom)

func _gen_print_op_inner(out: StringBuilder, indent: int, text_indent: int, arrayness: int, name: String, type_name: String, path: String, custom: Array[Val]) -> void:
    if arrayness > 0:
        out.write_indented_line(indent, "print(\"" + "\\t".repeat(text_indent), name, ": (Array)\")")
        var nested_i = "i" + str(indent)
        var nested_v = "v" + str(indent)
        out.write_indented_line(indent, "var ", nested_i, " := 0")
        out.write_indented_line(indent, "while ", nested_i, " < ", name, ".size():")
        out.write_indented_line(indent + 1, "var ", nested_v, " = ", name, "[", nested_i ,"]")
        _gen_print_op_inner(out, indent + 1, text_indent + 1, arrayness - 1, type_name + " (\", str(" + nested_i + "), \")", type_name, nested_v, custom)
        out.write_indented_line(indent + 1, nested_i, " += 1")
    else:
        if custom.size() > 0:
            out.write_indented_line(indent, "print(\"" + "\\t".repeat(text_indent), name, ":\")")
            for val in custom:
                _gen_print_op_inner(out, indent, text_indent + 1, arrayness, val._name, val._custom_type if val._custom_type.length() > 0 else TYPE_UTIL.T_GD_NAME[val._type], path + "." + val._name, val._custom_sub_layout)
        else:
            out.write_indented_line(indent, "print(\"" + "\\t".repeat(text_indent), name, " = \", str(", path if path.length() > 0 else name, "))")

func _gen_final_upgrade_dict_to_prop(out: StringBuilder, indent: int, val_id: int) -> void:
    var no_serial = _val_no_serialize[val_id]
    if no_serial == 1: return
    var name: String = _val_names[val_id]
    out.write_indented_line(indent, name, " = vals[\"", name, "\"]")

func _gen_property(out: StringBuilder, indent: int, val_id: int) -> void:
    var name: String = _val_names[val_id]
    var type = _val_types[val_id]
    var arrayness = _val_arrayness[val_id]
    var default = _val_defaults[val_id]
    var custom_type = _val_custom_types[val_id]
    var pre_set = _val_pre_set_effects[val_id]
    var post_set = _val_post_set_effects[val_id]
    var mode = _val_mode[val_id]
    if custom_type.is_empty():
        if arrayness == 0:
            var gd_type = TYPE_UTIL.T_GD_TYPE[type]
            if gd_type == Variant.Type.TYPE_STRING:
                out.write_indented(indent, "var ", name, ": ",TYPE_UTIL.T_GD_NAME[type]," = \"", str(default), "\"")
            else:
                out.write_indented(indent, "var ", name, ": ",TYPE_UTIL.T_GD_NAME[type]," = ", str(default))
        elif arrayness == 1:
            out.write_indented(indent, "var ", name, ": ",TYPE_UTIL.T_GD_NAME_ARRAY[type]," = ", str(default))
        else:
            out.write_indented(indent, "var ", name, ": Array = ", str(default))
    else:
        if arrayness > 0:
            custom_type = "Array"
        var gd_type = TYPE_UTIL.T_GD_TYPE[type]
        if gd_type == Variant.Type.TYPE_STRING:
            out.write_indented(indent, "var ", name, ": ",custom_type," = \"", str(default), "\" as ", custom_type)
        else:
            out.write_indented(indent, "var ", name, ": ",custom_type," = ", str(default), " as ", custom_type)
    if mode != PROP_MODE.OMIT_SETTER and ((automatically_save and !completely_omit_serialization_code) or pre_set.length() > 0 or post_set.length() > 0):
        out.write_line(":")
        out.write_indented_line(indent + 1, "set(val):")
        if pre_set.length() > 0:
            pre_set = pre_set.lstrip(" \n\t\r")
            pre_set = pre_set.rstrip(" \n\t\r")
            pre_set = pre_set.indent(out.get_indent_string() + out.get_indent_string())
            out.write_line(pre_set)
        out.write_indented_line(indent + 2, name, " = val")
        if post_set.length() > 0:
            post_set = post_set.lstrip(" \n\t\r")
            post_set = post_set.rstrip(" \n\t\r")
            post_set = post_set.indent(out.get_indent_string() + out.get_indent_string())
            out.write_line(post_set)
        if automatically_save and !completely_omit_serialization_code:
            out.write_indented_line(indent + 2, "queue_save()")
    else:
        out.write_newline()

func default_val_string(val_id: int) -> String:
    var default_cust = _val_custom_defaults[val_id]
    if default_cust.length() > 0: return default_cust
    var type = _val_types[val_id]
    var default = _val_defaults[val_id]
    if type == TYPE_UTIL.T.String_Ascii or type == TYPE_UTIL.T.String_Utf8:
        return "\"" + str(default) + "\""
    return var_to_str(default)

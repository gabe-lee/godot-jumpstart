@tool
class_name ScriptFragmentBuilder extends EditorScript

const Arg = ScriptFileBuilder.Arg
const CONST_MODE = ScriptFileBuilder.CONST_MODE
const ENUM_MODE = ScriptFileBuilder.ENUM_MODE
const ARRAY_MODE = ScriptFileBuilder.ARRAY_MODE
const VAR = ScriptFileBuilder.VAR
const SCOPE = ScriptFileBuilder.SCOPE
const FSM_MODE = ScriptFileBuilder.FSM_MODE
const COMMENT_MODE = ScriptFileBuilder.COMMENT_MODE
const FuncSignature = ScriptFileBuilder.FuncSignature
static func concat_args(args: Array) -> String:
    return ScriptFileBuilder.concat_args(args)
static func argify(vals: Variant) -> Array:
    return ScriptFileBuilder.argify(vals)
static func str_lit(string: String) -> String:
    return ScriptFileBuilder.str_lit(string)

enum MODE {
    OVERWRITE_BLOCK = 0,
    APPEND_BLOCK = 1,
    # OVERWRITE_LINE = 2,
}

class FragTarget:
    var path: String
    var entry: String
    var exit: String
    var mode: int

    func _init(path_: String, entry_: String, exit_: String, mode_: MODE = MODE.OVERWRITE_BLOCK) -> void:
        path = path_
        entry = entry_
        exit = exit_
        mode = mode_

const M_NONE = 0
const M_CONFIG = 1
const M_CODE = 2
const M_TARGETS = 3
const M_SERIALIZE = 4

var _in_mode := M_NONE
var all_targets: Array[FragTarget] = []:
    set(v):
        assert(_in_mode == M_TARGETS, "you can only set the fragment targets inside the `_define_targets()` function")
        all_targets = v
var code: String = "":
    set(v):
        assert(_in_mode == M_CODE, "you can only set the fragment code inside the `_define_code()` function")
        code = v
var fragment_name: String = "Unnamed Fragment":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the config variables inside the `_define_config()` function")
        fragment_name = v
var log_generation_time: bool = true:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the config variables inside the `_define_config()` function")
        log_generation_time = v

func _define_config() -> void:
    pass

func _define_code(out: ScriptFileBuilder) -> void:
    pass

func _define_targets() -> void:
    pass

func add_target(path_: String, entry_: String, exit_: String, mode_: MODE = MODE.OVERWRITE_BLOCK) -> void:
    assert(_in_mode == M_TARGETS, "can only add targets within the `_define_targets()` function")
    all_targets.append(FragTarget.new(path_, entry_, exit_, mode_))

func _run() -> void:
    _run_define_config()
    _run_define_code()
    _run_define_targets()
    _run_serialize()

func _run_define_config() -> void:
    _in_mode = M_CONFIG
    _define_config()

func _run_define_code() -> void:
    _in_mode = M_CODE
    var out = ScriptFileBuilder.new()
    ScriptFileBuilder.push_scope_no_indent(out, ScriptFileBuilder.SCOPE.INLINE)
    _define_code(out)
    code = out.finish_script_text_and_clear()
    code = code.lstrip(" \n\r\t")
    code = code.rstrip(" \n\r\t")

func _run_define_targets() -> void:
    _in_mode = M_TARGETS
    _define_targets()

func _run_serialize() -> void:
    _in_mode = M_SERIALIZE
    
    var err = OK
    for tar in all_targets:
        err = OK
        if !FileAccess.file_exists(tar.path):
            push_error("(script frag `%s`) no script file `%s` for script fragment target" % [fragment_name, tar.path])
            continue
        var tmp_path = tar.path + ".tmp"
        
        err = DirAccess.copy_absolute(tar.path, tmp_path)
        if err:
            push_error("(script frag `%s`) could not create temp file for safe alteration of script file `%s` (%s)" % [fragment_name, tar.path, error_string(err)])
            continue
        var file_size = FileAccess.get_size(tmp_path)
        if file_size < 0:
            push_error("(script frag `%s`) error getting file size for temp file `%s`" % [fragment_name, tmp_path])
            DirAccess.remove_absolute(tmp_path)
            continue
        var tmp_file = FileAccess.open(tmp_path, FileAccess.READ_WRITE)
        if tmp_file == null:
            err = FileAccess.get_open_error()
            push_error("(script frag `%s`) could not open temp file `%s` for safe alteration of script file" % [fragment_name, tmp_path, error_string(err)] )
            DirAccess.remove_absolute(tmp_path)
            continue
        var tar_result = scan_file_for_target(tmp_file, file_size, tar.entry, tar.exit, tar.mode)
        if !tar_result.valid:
            if tar_result.enter_loc < 0:
                push_error("(script frag `%s`) did not find entry pattern `%s` in script file `%s`" % [fragment_name, tar.entry, tar.path])
            elif tar_result.exit_end_loc < 0 or tar_result.exit_end_loc > file_size:
                push_error("(script frag `%s`) did not find exit pattern `%s` in script file `%s`" % [fragment_name, tar.exit, tar.path])
            else:
                push_error("(script frag `%s`) error when scanning for entry and exit patterns in script file `%s` (%s)\ntarget_result: %s" % [fragment_name, tar.path, error_string(tar_result.err), var_to_str(tar_result)])
            tmp_file.close()
            DirAccess.remove_absolute(tmp_path)
            continue
        err = insert_code_at_target(tmp_file, file_size, tar_result, code, tar.mode)
        if err:
            push_error("(script frag `%s`) error when inserting code fragment into temp file `%s`" % [fragment_name, tmp_path])
            DirAccess.remove_absolute(tmp_path)
            continue
        err = DirAccess.rename_absolute(tmp_path, tar.path)
        if err:
            push_error("(script frag `%s`) error when renaming temp file `%s` to `%s`" % [fragment_name, tmp_path, tar.path])
        elif log_generation_time:
            print("%s: Generate Fragment `%s` to `%s`" % [Time.get_time_string_from_system(), fragment_name, tar.path])


const NL: int = 0x0A
const CR: int = 0x0D
const SP: int = 0x20
const TB: int = 0x09

class TargetResult:
    var enter_loc: int = -1
    var newline_after_enter_loc : int = -1
    var newline_before_exit_loc : int = -1
    var exit_start_loc: int = -1
    var exit_end_loc: int = -1
    var indent_bytes: PackedByteArray = []
    var err: Error = OK
    var found_any_cr: bool = false
    var valid: bool = false

static func scan_file_for_target(file: FileAccess, file_size: int, enter_pattern: String, exit_pattern: String, mode: MODE) -> TargetResult:
    var result = TargetResult.new()
    var enter_bytes := enter_pattern.to_utf8_buffer()
    var exit_bytes := exit_pattern.to_utf8_buffer()
    var enter_len = enter_bytes.size()
    var exit_len = exit_bytes.size()
    var pattern_idx := 0
    var first_newline_pos_after_enter := 0
    var last_newline_pos_before_exit := 0
    var exit_start_pos := 0
    var pos := 0
    var byte := 0
    var find_enter := true
    var find_exit := true
    var after_newline := false
    var line_indent: PackedByteArray = []
    var line_indent_len: int = 0
    file.seek(0)
    while result.err == OK and (find_enter or find_exit) and pos < file_size:
        while result.err == OK and find_enter and pos < file_size:
            while result.err == OK and byte != enter_bytes[0] and pos < file_size:
                byte = file.get_8()
                result.err = file.get_error()
                pos += 1
                if byte == CR:
                    result.found_any_cr = true
                elif byte == NL:
                    after_newline = true
                    line_indent_len = 0
                elif after_newline and byte != SP and byte != TB:
                    after_newline = false
                elif after_newline:
                    if line_indent_len >= line_indent.size():
                        line_indent.append(byte)
                    else:
                        line_indent[line_indent_len] = byte
                    line_indent_len += 1
            pattern_idx = 0
            while result.err == OK and byte == enter_bytes[pattern_idx] and pos < file_size:
                pattern_idx += 1
                if pattern_idx == enter_len:
                    find_enter = false
                    result.enter_loc = pos 
                    result.indent_bytes = line_indent.slice(0, line_indent_len)
                    line_indent_len = 0
                    after_newline = false
                    break
                byte = file.get_8()
                result.err = file.get_error()
                pos += 1
                if byte == CR:
                    result.found_any_cr = true
                elif byte == NL:
                    after_newline = true
                    line_indent_len = 0
                elif after_newline and byte != SP and byte != TB:
                    after_newline = false
                elif after_newline:
                    if line_indent_len >= line_indent.size():
                        line_indent.append(byte)
                    else:
                        line_indent[line_indent_len] = byte
                    line_indent_len += 1
            pattern_idx = 0
        while result.err == OK and find_exit and pos < file_size:
            while result.err == OK and byte != exit_bytes[0] and pos < file_size:
                byte = file.get_8()
                result.err = file.get_error()
                pos += 1
                if byte == CR:
                    result.found_any_cr = true
                elif byte == NL:
                    after_newline = true
                    line_indent_len = 0
                    if first_newline_pos_after_enter == 0:
                        first_newline_pos_after_enter = pos
                    last_newline_pos_before_exit = pos
                elif after_newline and byte != SP and byte != TB:
                    after_newline = false
                elif after_newline:
                    if line_indent_len >= line_indent.size():
                        line_indent.append(byte)
                    else:
                        line_indent[line_indent_len] = byte
                    line_indent_len += 1
            pattern_idx = 0
            exit_start_pos = pos
            while result.err == OK and byte == exit_bytes[pattern_idx] and pos < file_size:
                pattern_idx += 1
                if pattern_idx == exit_len:
                    find_exit = false
                    result.exit_start_loc = exit_start_pos
                    result.newline_after_enter_loc = first_newline_pos_after_enter
                    result.newline_before_exit_loc = last_newline_pos_before_exit
                    result.exit_end_loc = pos
                    var exit_indent = line_indent.slice(0, line_indent_len)
                    if exit_indent != result.indent_bytes:
                        push_warning("the indent at the enter pattern ('%s') did not match the indent at the exit pattern ('%s')" % [enter_pattern, exit_pattern])
                    break
                byte = file.get_8()
                result.err = file.get_error()
                pos += 1
                if byte == CR:
                    result.found_any_cr = true
                elif byte == NL:
                    after_newline = true
                    line_indent_len = 0
                    last_newline_pos_before_exit = pos
                elif after_newline and byte != SP and byte != TB:
                    after_newline = false
                elif after_newline:
                    if line_indent_len >= line_indent.size():
                        line_indent.append(byte)
                    else:
                        line_indent[line_indent_len] = byte
                    line_indent_len += 1
            pattern_idx = 0
    if (find_enter or find_exit) and result.err == OK:
        result.err = ERR_FILE_EOF
    result.valid = \
        result.enter_loc >= 0 and \
        result.newline_after_enter_loc >= result.enter_loc and \
        result.newline_before_exit_loc >= result.newline_after_enter_loc and \
        result.exit_start_loc >= result.newline_before_exit_loc and \
        result.exit_end_loc >= result.exit_start_loc and \
        result.exit_end_loc <= file_size and \
        result.err == OK
    return result

static func insert_code_at_target(file: FileAccess, file_size: int, target: TargetResult, code: String, mode: MODE) -> Error:
    file.seek(target.newline_before_exit_loc)
    var err = file.get_error()
    if err: return err
    var all_code_after_insert = file.get_buffer(file_size - target.newline_before_exit_loc)
    err = file.get_error()
    if err: return err
    var indented_code = code.indent(target.indent_bytes.get_string_from_ascii())
    # var code_bytes: PackedByteArray = []
    # if target.found_any_cr:
    #     code_bytes.append(CR)
    # code_bytes.append(NL)
    var code_bytes = indented_code.to_utf8_buffer()
    if target.found_any_cr:
        code_bytes.append(CR)
    code_bytes.append(NL)
    var cull_size := 0
    match mode:
        MODE.OVERWRITE_BLOCK:
            cull_size = target.newline_before_exit_loc - target.newline_after_enter_loc
        MODE.APPEND_BLOCK: pass
        _: assert(false)
    err = file.resize(file_size + code_bytes.size() - cull_size)
    if err: return err
    match mode:
        MODE.OVERWRITE_BLOCK:
            file.seek(target.newline_after_enter_loc)
        MODE.APPEND_BLOCK: 
            file.seek(target.newline_before_exit_loc)
        _: assert(false)
    err = file.get_error()
    if err: return err
    file.store_buffer(code_bytes)
    err = file.get_error()
    if err: return err
    file.store_buffer(all_code_after_insert)
    err = file.get_error()
    if err: return err
    file.flush()
    err = file.get_error()
    file.close()
    return err

const RawLiteral = StringBuilder.RawLiteral
const StrLiteral = StringBuilder.StrLiteral

static func literal(lit: String) -> StringBuilder.RawLiteral:
    return StringBuilder.RawLiteral.new(lit)

static func string(lit: String) -> StringBuilder.StrLiteral:
    return StringBuilder.StrLiteral.new(lit)
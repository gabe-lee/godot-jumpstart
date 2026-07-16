@tool
class_name ScriptBuilder extends EditorScript

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

## print the time the script is generated or re-generated to the godot output
var log_generation_time: bool = true:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        log_generation_time = v
## The class name for the script
var script_class: String = "MyScript":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        script_class = v
## If true, write the header as `class_name <script_class> extends <extend_class>`
## [br]
## If false, write the header as `extends <extend_class>` [br]
## - Instead, include a `const <script_class> = preload("<script_path>")` to prevent breaking code
var write_class_name: bool = true:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        write_class_name = v
## The class that your script will inherit from.
## [br]
## In most cases `RefCounted` will be the fastest/simplest, but you
## may want the script to have some other functionality in relation
## to the scene tree. For example, you might want to inherit from `Node`
## to allow the `_process()` function to be called automatically
## while it is in the scene tree (for automatic saving)
var extend_class: String = "RefCounted":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        extend_class = v
## The path in your project to generate the format script.
## [br]
## MUST have a `.gd` extension to work correctly
var script_path := "res://MyScript.gd":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        script_path = v
## A list of additional script builders to attatch as children
var sub_script_builders: Array[ScriptBuilder] = []:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        sub_script_builders = v
## The function args of the `_init()` function: everything between the parenthesis
var init_func_args: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        init_func_args = v
## A doc-comment that is placed at the top of the script to describe it
var script_doc_comment: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        init_func_args = v
## A list of additional function signatures that this builder and
## all sub-builders can write to. The attached `Callable` must take one
## single argument, a `ScriptFileBuilder`
var common_function_routines: Dictionary[String, Callable] = {}

func add_sub_script_builder(sub_script_builder: ScriptBuilder) -> void:
    assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
    sub_script_builders.append(sub_script_builder)

func add_common_function(signature: FuncSignature, routine: Callable) -> void:
    var as_str = signature.as_string()
    assert(!common_function_routines.has(as_str), "common function `%s` was added more than once" % as_str)
    common_function_routines.set(as_str, routine)

func get_all_common_function_signatures() -> PackedStringArray:
    var arr = PackedStringArray(common_function_routines.keys())
    for sub in sub_script_builders:
        var sub_arr = sub.get_all_common_function_signatures()
        for s in sub_arr:
            if !arr.has(s):
                arr.append(s)
    return arr

func _run() -> void:
    _run_no_serial()
    _run_serialize()

func _run_no_serial() -> void:
    _run_config()
    _run_register_properties()
    _run_register_versions()
    _run_pre_serialize()

func _set_config() -> void:
    pass

func _post_config_validate() -> void:
    pass

func _register_properties() -> void:
    pass

func _post_register_props_validate() -> void:
    pass

func _register_versions() -> void:
    pass

func _post_versions_validate() -> void:
    pass

func _pre_serialize() -> void:
    pass

func _post_pre_serial_validate() -> void:
    pass

func _serialize_methods(_gen: ScriptFileBuilder) -> void:
    pass

func _serialize_static_functions(_gen: ScriptFileBuilder) -> void:
    pass

func _serialize_properties(_gen: ScriptFileBuilder) -> void:
    pass

func _serialize_static_properties(_gen: ScriptFileBuilder) -> void:
    pass

func _serialize_constants(_gen: ScriptFileBuilder) -> void:
    pass

func _serialize_init(_gen: ScriptFileBuilder) -> void:
    pass

func _serialize_ready(_gen: ScriptFileBuilder) -> void:
    pass

func _serialize_enter_tree(_gen: ScriptFileBuilder) -> void:
    pass

func _serialize_exit_tree(_gen: ScriptFileBuilder) -> void:
    pass

func _serialize_process(_gen: ScriptFileBuilder) -> void:
    pass

func _serialize_physics_process(_gen: ScriptFileBuilder) -> void:
    pass

func _serialize_miscelaneous(_gen: ScriptFileBuilder) -> void:
    pass

func serialize_common_function_if_present(signature: String, gen: ScriptFileBuilder) -> void:
    if common_function_routines.has(signature):
        var routine: Callable = common_function_routines.get(signature)
        routine.call(gen)
    for sub in sub_script_builders:
        sub.serialize_common_function_if_present(signature, gen)

func _run_config() -> void:
    _in_mode = M_CONFIG
    _set_config()
    _post_config_validate()
    for sub in sub_script_builders:
        sub._run_config()

func _run_register_properties() -> void:
    _in_mode = M_REGISTER_PROPS
    _register_properties()
    _post_register_props_validate()
    for sub in sub_script_builders:
        sub._run_register_properties()

func _run_register_versions() -> void:
    _in_mode = M_REGISTER_VERSIONS
    _register_versions()
    _post_versions_validate()
    for sub in sub_script_builders:
        sub._run_register_versions()

func _run_pre_serialize() -> void:
    _in_mode = M_PRE_SERIALIZE
    _pre_serialize()
    _post_pre_serial_validate()
    for sub in sub_script_builders:
        sub._run_pre_serialize()

func _run_serialize_core(gen: ScriptFileBuilder) -> void:
    _serialize_constants(gen)
    for sub in sub_script_builders:
        sub._serialize_constants(gen)
    gen._newline()

    _serialize_static_properties(gen)
    for sub in sub_script_builders:
        sub._serialize_static_properties(gen)
    gen._newline()

    _serialize_properties(gen)
    for sub in sub_script_builders:
        sub._serialize_properties(gen)
    gen._newline()

    _serialize_methods(gen)
    for sub in sub_script_builders:
        sub._serialize_methods(gen)
    gen._newline()

    var init_block = gen.create_inline_block_unique("init_block", true)
    _serialize_init(init_block)
    for sub in sub_script_builders:
        sub._serialize_init(init_block)
    if gen._line_start_scope_if(SCOPE.FUNC, ["func _init(", init_func_args, ") -> void:"], init_block.raw.parts.size() > 0):
        gen.indent = 1
        gen._inline_block("init_block")
        gen._return()
        gen._newline()

    var ready_block = gen.create_inline_block_unique("ready_block", true)
    _serialize_ready(ready_block)
    for sub in sub_script_builders:
        sub._serialize_ready(ready_block)
    if gen._method("_ready", [], "void", ready_block.raw.parts.size() > 0):
        gen._inline_block("ready_block")
        gen._return()
        gen._newline()
    
    var enter_tree = gen.create_inline_block_unique("enter_tree", true)
    _serialize_enter_tree(enter_tree)
    for sub in sub_script_builders:
        sub._serialize_enter_tree(enter_tree)
    if gen._method("_enter_tree", [], "void", enter_tree.raw.parts.size() > 0):
        gen._inline_block("enter_tree")
        gen._return()
        gen._newline()
    
    var exit_tree = gen.create_inline_block_unique("exit_tree", true)
    _serialize_exit_tree(exit_tree)
    for sub in sub_script_builders:
        sub._serialize_exit_tree(exit_tree)
    if gen._method("_exit_tree", [], "void", exit_tree.raw.parts.size() > 0):
        gen._inline_block("exit_tree")
        gen._return()
        gen._newline()
    
    var process = gen.create_inline_block_unique("process", true)
    _serialize_process(process)
    for sub in sub_script_builders:
        sub._serialize_process(process)
    if gen._method("_process", [Arg.new("delta", TYPE_FLOAT)], "void", process.raw.parts.size() > 0):
        gen._inline_block("process")
        gen._return()
        gen._newline()
    
    var physics_process = gen.create_inline_block_unique("physics_process", true)
    _serialize_physics_process(physics_process)
    for sub in sub_script_builders:
        sub._serialize_physics_process(physics_process)
    if gen._method("_physics_process", [Arg.new("delta", TYPE_FLOAT)], "void", physics_process.raw.parts.size() > 0):
        gen._inline_block("physics_process")
        gen._return()
        gen._newline()
    
    var all_common_signatures = get_all_common_function_signatures()
    for sig in all_common_signatures:
        var block = gen.create_inline_block_unique(sig)
        serialize_common_function_if_present(sig, block)
        if gen._line_start_scope_if(SCOPE.FUNC, [sig, ":"], !block.raw.parts.is_empty()):
            gen._inline_block(sig)
            gen._return()
            gen._newline()

    _serialize_static_functions(gen)
    for sub in sub_script_builders:
        sub._serialize_static_functions(gen)
    gen._newline_if_none()

    _serialize_miscelaneous(gen)
    for sub in sub_script_builders:
        sub._serialize_miscelaneous(gen)
    gen._newline_if_none()

func _run_serialize() -> void:
    assert(!script_class.is_empty(), "a `script_class` MUST be provided for the code to reference itself. If you dont want to define the `script_class` in the header, use `write_class_name = false`")
    if log_generation_time:
        print("%s: Generate `%s` to `%s`" % [Time.get_time_string_from_system(), script_class, script_path])
    var gen := ScriptFileBuilder.new()
    _in_mode = M_SERIALIZE
    if script_doc_comment:
        var comment = script_doc_comment.lstrip(" \n\r\t")
        comment = comment.rstrip(" \n\r\t")
        comment = "## " + comment.replace("\n", "\n## ")
        gen._line(comment)
    gen._class(script_class if write_class_name else "", extend_class)
    gen._newline()
    if !write_class_name:
        gen._line("const ", script_class, " = preload(\"",script_path,"\")")
    _run_serialize_core(gen)

    var text = gen.finish_script_text_and_clear()
    var script_dir = script_path.get_base_dir()
    var err = DirAccess.make_dir_recursive_absolute(script_dir)
    if err != OK:
        push_error("error creating directories for script `%s`, %s" % [script_path, error_string(err)])
        return
    var f: FileAccess = FileAccess.open(script_path, FileAccess.ModeFlags.WRITE)
    if f == null:
        err = FileAccess.get_open_error()
        push_error("error creating file for script `%s`, %s" % [script_path, error_string(err)])
        return
    if !f.store_string(text):
        err = f.get_error()
        push_error("error writing text for script `%s`, %s" % [script_path, error_string(err)])
        return
    f.close()

func run_to_string(include_class_header: bool = true) -> String:
    _run_no_serial()
    assert(!script_class.is_empty(), "a `script_class` MUST be provided for the code to reference itself. If you dont want to define the `script_class` in the header, use `write_class_name = false`")
    var gen := ScriptFileBuilder.new()
    _in_mode = M_SERIALIZE
    if include_class_header:
        if script_doc_comment:
            var comment = script_doc_comment.lstrip(" \n\r\t")
            comment = comment.rstrip(" \n\r\t")
            comment = "## " + comment.replace("\n", "\n## ")
            gen._line(comment)
        gen._class(script_class if write_class_name else "", extend_class)
        gen._newline()
    else:
        ScriptFileBuilder.push_scope(gen, SCOPE.CLASS)
    if !write_class_name:
        gen._line("const ", script_class, " = preload(\"",script_path,"\")")

    _run_serialize_core(gen)

    return gen.finish_script_text_and_clear()


const M_NONE = 0
const M_CONFIG = 1
const M_REGISTER_PROPS = 2
const M_REGISTER_VERSIONS = 3
const M_PRE_SERIALIZE = 4
const M_SERIALIZE = 5

const M_FIRST_UNUSED = 6

var _in_mode = M_NONE

const RawLiteral = StringBuilder.RawLiteral
const StrLiteral = StringBuilder.StrLiteral

static func literal(lit: String) -> StringBuilder.RawLiteral:
    return StringBuilder.RawLiteral.new(lit)

static func string(lit: String) -> StringBuilder.StrLiteral:
    return StringBuilder.StrLiteral.new(lit)

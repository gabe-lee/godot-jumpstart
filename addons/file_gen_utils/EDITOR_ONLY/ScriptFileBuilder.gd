class_name ScriptFileBuilder extends RefCounted

const TAB_MODE = StringBuilder.TAB_MODE
const NEWLINE_MODE = StringBuilder.NEWLINE_MODE

var raw: StringBuilder = StringBuilder.new()
var scope_stack: PackedByteArray = []
var prior_stack: PackedByteArray = []
var flags_stack: PackedByteArray = []
var pre_done_strings: PackedStringArray = []
var post_done_strings: PackedStringArray = []
var post_done_dedent: PackedByteArray = []
var continue_strings: PackedStringArray = []
var fsm_vars: PackedStringArray = []
var fsm_branches: Array = []
var fsm_modes: PackedByteArray = []
var fsm_comments: PackedByteArray = []
var sub_build_when_return_to_class: bool = false
var sub_builder_when_return_to_class: ScriptFileBuilder = null
var pre_done_len: int = 0
var post_done_len: int = 0
var continue_len: int = 0
var fsm_len: int = 0
var stack_len: int = 0
var stack_grow: int = 4
var indent: int = 0
var sub_builders: Array[ScriptFileBuilder] = []
var sub_names : PackedStringArray = []
var sub_part_idx: Array = []
var sub_indents: Array = []
var sub_ignore: PackedByteArray = []
# var sub_newlines: Array = []
var sub_len: int = 0
var is_done: bool = false
var final_string: String = "":
    get:
        assert(is_done, "ScriptFileBuilder was not finished, cannot get final string. Call one of the finish functions first")
        return final_string

# class InlinePrecondition:
#     var scope_stack_: PackedByteArray = []
#     var prior_stack_: PackedByteArray = []
#     var flags_stack_: PackedByteArray = []
#     var pre_done_strings_: PackedStringArray = []
#     var post_done_strings_: PackedStringArray = []
#     var continue_strings_: PackedStringArray = []
#     var pre_done_len_: int = 0
#     var post_done_len_: int = 0
#     var continue_len_: int = 0
#     var stack_len_: int = 0
#     var stack_grow_: int = 4
#     var indent_: int = 0

#     func _init(this: ScriptFileBuilder) -> void:
#         self.scope_stack_ = this.scope_stack.duplicate()
#         self.prior_stack_ = this.prior_stack.duplicate()
#         self.flags_stack_ = this.flags_stack.duplicate()
#         self.pre_done_strings_ = this.pre_done_strings.duplicate()
#         self.post_done_strings_ = this.post_done_strings.duplicate()
#         self.continue_strings_ = this.continue_strings.duplicate()
#         self.pre_done_len_ = this.pre_done_len
#         self.post_done_len_ = this.post_done_len
#         self.continue_len_ = this.continue_len
#         self.stack_len_ = this.stack_len
#         self.indent_ = this.indent


enum SCOPE {
    NONE,
    CLASS,
    SUBCLASS,
    DICT_LITERAL,
    ARRAY_LITERAL,
    VAR_DECL,
    PAREN_EXPR,
    IF,
    ELIF,
    ELSE,
    FUNC,
    WHILE,
    FOR,
    MATCH,
    BRANCH,
    VAR_GET_SET,
    INLINE,
    FSM,
    FSM_BRANCH,
}

enum FLAG {
    PRE_DONE = 1 << 0,
    POST_DONE = 1 << 1,
    CONTINUE = 1 << 2,
    CONTINUE_INHERIT = 1 << 3,
    FSM_VARS = 1 << 4,
    FSM_VARS_INHERIT = 1 << 5,
}

static func quick() -> ScriptFileBuilder:
    var b = ScriptFileBuilder.new()
    push_scope_no_indent(b, SCOPE.INLINE)
    return b

static func has_pre_done(flags_: int) -> bool:
    return flags_ & FLAG.PRE_DONE

static func has_post_done(flags_: int) -> bool:
    return flags_ & FLAG.POST_DONE

static func has_continue(flags_: int) -> bool:
    return flags_ & FLAG.CONTINUE

class Arg:
    var name: String = ""
    var type: Variant = null

    func _init(n: String, t: Variant) -> void:
        name = n
        type = t
    
    func write(builder: ScriptFileBuilder, trailing_comma: bool = true) -> void:
        builder.raw.write(name, "" if typeof(type) == TYPE_NIL or (type is String and type.is_empty()) else ": " + ScriptFileBuilder.type_name(self.type), ", " if trailing_comma else "")

const INDENT := 1
const NO_INDENT := 0

static func _internal_push_scope(this: ScriptFileBuilder, new_scope: SCOPE, indent_: int = INDENT, post_done_dedent_: int = 0, pre_done_string: String = "", post_done_string: String = "", continue_string: String = "", fsm_case_var: String = "", fsm_enum_var: String = "", fsm_exit_var: String = "", fsm_branches_: PackedStringArray = [], fsm_mode: int = -1, fsm_comments_: int = COMMENT_MODE.NO_HELPER_COMMENTS) -> void:
    var max_size = this.scope_stack.size()
    var flags := 0
    if this.stack_len >= this.scope_stack.size():
        var new_max_size = max_size + this.stack_grow
        this.scope_stack.resize(new_max_size)
        this.prior_stack.resize(new_max_size)
        this.flags_stack.resize(new_max_size)
        this.post_done_dedent.resize(new_max_size)
    if this.stack_len > 0:
        this.prior_stack[this.stack_len - 1] = new_scope
    this.scope_stack[this.stack_len] = new_scope
    this.prior_stack[this.stack_len] = SCOPE.NONE
    this.post_done_dedent[this.stack_len] = post_done_dedent_
    if pre_done_string:
        flags |= FLAG.PRE_DONE
        if this.pre_done_len >= this.pre_done_strings.size():
            this.pre_done_strings.resize(this.pre_done_len + this.stack_grow)
        this.pre_done_strings[this.pre_done_len] = pre_done_string
        this.pre_done_len += 1
    if post_done_string:
        flags |= FLAG.POST_DONE
        if this.post_done_len >= this.post_done_strings.size():
            this.post_done_strings.resize(this.post_done_len + this.stack_grow)
        this.post_done_strings[this.post_done_len] = post_done_string
        this.post_done_len += 1
    if continue_string:
        flags |= FLAG.CONTINUE
        if this.continue_len >= this.continue_strings.size():
            this.continue_strings.resize(this.continue_len + this.stack_grow)
        this.continue_strings[this.continue_len] = continue_string
        this.continue_len += 1
    elif (this.stack_len > 0) and (this.flags_stack[this.stack_len - 1] & FLAG.CONTINUE or this.flags_stack[this.stack_len - 1] & FLAG.CONTINUE_INHERIT) and (this.continue_len > 0):
        flags |= FLAG.CONTINUE_INHERIT
    if !fsm_case_var.is_empty() or !fsm_enum_var.is_empty() or !fsm_exit_var.is_empty() or !fsm_branches_.is_empty() or fsm_mode >= 0:
        assert(!fsm_case_var.is_empty() and !fsm_enum_var.is_empty() and !fsm_exit_var.is_empty() and !fsm_branches_.is_empty() and fsm_mode >= 0)
        if this.fsm_len * 4 >= this.fsm_vars.size():
            this.fsm_vars.resize((this.fsm_len + this.stack_grow) * 4)
        if this.fsm_len >= this.fsm_branches.size():
            this.fsm_branches.resize(this.fsm_len + this.stack_grow)
            this.fsm_modes.resize(this.fsm_len + this.stack_grow)
            this.fsm_comments.resize(this.fsm_len + this.stack_grow)
        this.fsm_vars[this.fsm_len * 4] = fsm_case_var
        this.fsm_vars[(this.fsm_len * 4) + 1] = fsm_enum_var
        this.fsm_vars[(this.fsm_len * 4) + 2] = fsm_exit_var
        this.fsm_vars[(this.fsm_len * 4) + 3] = fsm_exit_var
        this.fsm_branches[this.fsm_len] = fsm_branches_
        this.fsm_modes[this.fsm_len] = fsm_mode
        this.fsm_comments[this.fsm_len] = fsm_comments_
        this.fsm_len += 1
    elif (this.stack_len > 0) and (this.flags_stack[this.stack_len - 1] & FLAG.FSM_VARS or this.flags_stack[this.stack_len - 1] & FLAG.FSM_VARS_INHERIT) and (this.fsm_len > 0):
        flags |= FLAG.FSM_VARS_INHERIT
    this.flags_stack[this.stack_len] = flags
    this.indent += indent_
    this.stack_len += 1

static func push_scope(this: ScriptFileBuilder, new_scope: SCOPE, post_done_string_: String = "") -> void:
    _internal_push_scope(this, new_scope, 1, 0, "", post_done_string_, "", "", "", "", [], -1, 0)

static func push_scope_post_done_dedent(this: ScriptFileBuilder, new_scope: SCOPE, post_done_string_: String = "", post_done_dedent_: int = 0) -> void:
    _internal_push_scope(this, new_scope, 1, post_done_dedent_, "", post_done_string_, "", "", "", "", [], -1, 0)

static func push_scope_pre_done_and_post_done_dedent(this: ScriptFileBuilder, new_scope: SCOPE, pre_done_string_: String = "", post_done_string_: String = "", post_done_dedent_: int = 0) -> void:
    _internal_push_scope(this, new_scope, 1, post_done_dedent_, pre_done_string_, post_done_string_, "", "", "", "", [], -1, 0)

static func push_scope_no_indent(this: ScriptFileBuilder, new_scope: SCOPE, post_done_string_: String = "") -> void:
    _internal_push_scope(this, new_scope, 0, 0, "", post_done_string_, "", "", "", "", [], -1, 0)

static func push_scope_with_pre_done(this: ScriptFileBuilder, new_scope: SCOPE, pre_done_string_: String, post_done_string_: String = "") -> void:
    _internal_push_scope(this, new_scope, 1, 0, pre_done_string_, post_done_string_, "", "", "", "", [], -1, 0)

static func push_scope_with_continue(this: ScriptFileBuilder, new_scope: SCOPE, continue_string_: String, post_done_string_: String = "") -> void:
    _internal_push_scope(this, new_scope, 1, 0, "", post_done_string_, continue_string_, "", "", "", [], -1, 0)

static func push_scope_with_fsm_vars(this: ScriptFileBuilder, new_scope: SCOPE, fsm_case_var: String, fsm_enum_var: String, fsm_sxit_var: String, fsm_branches_: PackedStringArray, fsm_mode_: FSM_MODE, comments: COMMENT_MODE, pre_done_string_: String = "", post_done_string_: String = "") -> void:
    _internal_push_scope(this, new_scope, 1, 0, pre_done_string_, post_done_string_, "", fsm_case_var, fsm_enum_var, fsm_sxit_var, fsm_branches_, fsm_mode_, comments)

static func set_fsm_curr_branch(this: ScriptFileBuilder, branch: String) -> void:
    if this.fsm_len > 0:
        this.fsm_vars[(this.fsm_len * 4) - 1] = branch

static func get_fsm_vars(this: ScriptFileBuilder, delta: int = 1) -> PackedStringArray:
    if this.fsm_len >= delta:
        var start = this.fsm_len - delta
        start *= 4
        return this.fsm_vars.slice(start, start + 4)
    return []

static func get_fsm_branches(this: ScriptFileBuilder, delta: int = 1) -> PackedStringArray:
    if this.fsm_len >= delta:
        return this.fsm_branches[this.fsm_len - delta]
    return []

static func get_fsm_mode(this: ScriptFileBuilder, delta: int = 1) -> FSM_MODE:
    if this.fsm_len >= delta:
        return this.fsm_modes[this.fsm_len - delta] as FSM_MODE
    return FSM_MODE.SINGLE_PASS_NO_FALLTHROUGH

static func get_fsm_comment(this: ScriptFileBuilder, delta: int = 1) -> COMMENT_MODE:
    if this.fsm_len >= delta:
        return this.fsm_comments[this.fsm_len - delta] as COMMENT_MODE
    return COMMENT_MODE.NO_HELPER_COMMENTS

static func current_scope(this: ScriptFileBuilder) -> SCOPE:
    return SCOPE.NONE if this.stack_len == 0 else this.scope_stack[this.stack_len - 1]

static func assert_is_within_any_scope_recursive(this: ScriptFileBuilder, allowed: Array[SCOPE]) -> void:
    if !is_within_any_scope_recursive(this, allowed):
        print_stack()
        assert(false, "scope `%s` cannot be started if NONE of the following scopes are active in the stack: %s" % [current_scope_str(this), scope_list_to_str(allowed)])
static func assert_is_NOT_within_any_scope_recursive(this: ScriptFileBuilder, disallowed: Array[SCOPE]) -> void:
    if !is_NOT_within_any_scope_recursive(this, disallowed):
        print_stack()
        assert(false, "scope `%s` cannot be started if ANY of the following scopes are active in the stack: %s" % [current_scope_str(this), scope_list_to_str(disallowed)])
static func is_within_any_scope_recursive(this: ScriptFileBuilder, allowed: Array[SCOPE], invert_logic: bool = false) -> bool:
    if this.stack_len == 0:
        for scope in allowed:
            if scope == SCOPE.NONE: return false if invert_logic else true
        return true if invert_logic else false
    var s := this.stack_len
    while s > 0:
        s -= 1
        var prev_scope = this.scope_stack[s]
        for allowed_scope in allowed:
            if allowed_scope == prev_scope: return false if invert_logic else true
            if prev_scope == SCOPE.INLINE: return true
    return true if invert_logic else false
static func is_NOT_within_any_scope_recursive(this: ScriptFileBuilder, disallowed: Array[SCOPE]) -> bool:
    return is_within_any_scope_recursive(this, disallowed, true)

static func scope_list_to_str(list: Array[SCOPE]) -> String:
    var res := ""
    for s in list:
        res = res + SCOPE.find_key(s) + ", "
    return res 

static func current_scope_str(this: ScriptFileBuilder) -> String:
    if this.stack_len == 0: return "NONE"
    return SCOPE.find_key(this.scope_stack[this.stack_len - 1])

static func assert_is_within_any_immediate_scope(this: ScriptFileBuilder, allowed: Array[SCOPE]) -> void:
    if !is_within_any_immediate_scope(this, allowed):
        print_stack()
        assert(false, "scope `%s` cannot be started if NOT in any of the immediate scopes: %s" % [current_scope_str(this), scope_list_to_str(allowed)])
static func assert_is_NOT_within_any_immediate_scope(this: ScriptFileBuilder, disallowed: Array[SCOPE]) -> void:
    if !is_NOT_within_any_immediate_scope(this, disallowed):
        print_stack()
        assert(false, "scope `%s` cannot be started if in ANY of the immediate scopes: %s" % [current_scope_str(this), scope_list_to_str(disallowed)])
static func is_within_any_immediate_scope(this: ScriptFileBuilder, allowed: Array[SCOPE], invert_logic: bool = false) -> bool:
    if this.stack_len == 0:
        for scope in allowed:
            if scope == SCOPE.NONE: return false if invert_logic else true
        return false
    var prev_scope = this.scope_stack[this.stack_len - 1]
    for allowed_scope in allowed:
        if allowed_scope == prev_scope: return false if invert_logic else true
        if prev_scope == SCOPE.INLINE: return true
    return true if invert_logic else false
static func is_NOT_within_any_immediate_scope(this: ScriptFileBuilder, disallowed: Array[SCOPE]) -> bool:
    return is_within_any_immediate_scope(this, disallowed, true)

static func set_prior(this: ScriptFileBuilder, scope: SCOPE) -> void:
    if this.stack_len > 0:
        this.prior_stack[this.stack_len - 1] = scope

static func get_prior(this: ScriptFileBuilder) -> SCOPE:
    if this.stack_len > 0:
        return this.prior_stack[this.stack_len - 1] as SCOPE
    return SCOPE.NONE

static func assert_prior(this: ScriptFileBuilder, allowed: Array[SCOPE], invert_logic: bool = false) -> void:
    var prior = get_prior(this)
    if invert_logic:
        for allowed_prior in allowed:
            if prior == allowed_prior: assert(false)
        return
    else:
        for allowed_prior in allowed:
            if prior == allowed_prior: return
        assert(false)

class _CreateInlineResult:
    var builder: ScriptFileBuilder
    var sidx: int

    func _init(b: ScriptFileBuilder, i: int) -> void:
        builder = b
        sidx = i

static func _create_inline_internal(this: ScriptFileBuilder, unique: bool, identifier: String, ignore_unused: bool) -> _CreateInlineResult:
    var sidx := 0
    while sidx < this.sub_len:
        var existing_id = this.sub_names[sidx]
        if existing_id == identifier:
            if unique:
                print_stack()
                assert(false, "inline identifier `%s` was used more than once")
            else:
                break
        sidx += 1
    if sidx >= this.sub_builders.size():
        this.sub_builders.resize(sidx + this.stack_grow)
        this.sub_names.resize(sidx + this.stack_grow)
        this.sub_part_idx.resize(sidx + this.stack_grow)
        this.sub_indents.resize(sidx + this.stack_grow)
        this.sub_ignore.resize(sidx + this.stack_grow)
        var ss := this.sub_len
        while ss < this.sub_builders.size():
            this.sub_builders[ss] = ScriptFileBuilder.new()
            push_scope_no_indent(this.sub_builders[ss], SCOPE.INLINE)
            this.sub_names[ss] = ""
            this.sub_part_idx[ss] = PackedInt32Array([])
            this.sub_indents[ss] = PackedInt32Array([])
            this.sub_ignore[ss] = false
            ss += 1
    if sidx >= this.sub_len:
        this.sub_names[sidx] = identifier
        this.sub_len = sidx + 1
        this.sub_ignore[sidx] = int(ignore_unused)
    return _CreateInlineResult.new(this.sub_builders[sidx], sidx)

static func _inline_internal(this: ScriptFileBuilder, unique: bool, identifier: String, is_block: bool, ignore_unused: bool = false, gen_cond: bool = true) -> String:
    if gen_cond:
        var result = _create_inline_internal(this, unique, identifier, ignore_unused)
        this.sub_part_idx[result.sidx].append(this.raw.length)
        if unique:
            assert(this.sub_indents[result.sidx].size() == 0, "unique inline block `%s` was used in more than one place in the generated script" % identifier)
            this.sub_builders[result.sidx].indent = this.indent
            this.sub_indents[result.sidx].append(0)
        else:
            this.sub_indents[result.sidx].append(this.indent)
        if is_block:
            this.raw.write("")
    return ""

# func _inline_expr_unique(identifier: String, gen_cond: bool = true) -> String:
#     return _inline_internal(self, true, identifier, false, gen_cond)

# func _inline_expr(identifier: String, gen_cond: bool = true) -> String:
#     return _inline_internal(self, false, identifier, false, gen_cond)

func _inline_block_unique(identifier: String, ignore_unused: bool = false, gen_cond: bool = true) -> void:
    _inline_internal(self, true, identifier, true, ignore_unused, gen_cond)

func _inline_block(identifier: String, ignore_unused: bool = false, gen_cond: bool = true) -> void:
    _inline_internal(self, false, identifier, true, ignore_unused, gen_cond)
    
func get_inline_by_id(identifier: String) -> ScriptFileBuilder:
    var sidx := 0
    while sidx < sub_len:
        var existing_id = sub_names[sidx]
        if existing_id == identifier:
            return sub_builders[sidx]
        sidx += 1
    return null

func create_inline_block(identifier: String, ignore_unused: bool = false) -> ScriptFileBuilder:
    var result = _create_inline_internal(self, false, identifier, ignore_unused)
    return result.builder

func create_inline_block_unique(identifier: String, ignore_unused: bool = false) -> ScriptFileBuilder:
    var result = _create_inline_internal(self, true, identifier, ignore_unused)
    return result.builder

func _class(name: String, extend: String, is_tool: bool = false, icon_path: String = "") -> bool:
    assert_is_within_any_immediate_scope(self, [SCOPE.NONE])
    assert(indent == 0)
    if is_tool:
        raw.write_line("@tool")
    if icon_path:
        raw.write_line("@icon(\"", icon_path, "\")")
    raw.write_line( "" if name.is_empty() else "class_name ", name, "extends " if name.is_empty() else " extends ", extend)
    push_scope_no_indent(self, SCOPE.CLASS)
    return true

func _sub_class(name: String, extend: String = "", gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.CLASS, SCOPE.SUBCLASS])
        raw.write_indented(indent, "class ", name)
        if !extend.is_empty():
            raw.write(" extends ", extend)
        raw.write_line(":")
        push_scope(self, SCOPE.SUBCLASS)
    return gen_cond

func _method(name: String, args: Array[Arg], return_type: Variant, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.CLASS, SCOPE.SUBCLASS])
        raw.write_indented(indent, "func ", name, "(")
        for arg in args:
            arg.write(self)
        if args.size() > 0:
            raw.trim_last_part()
        raw.write_line(") -> ", type_name(return_type), ":")
        push_scope(self, SCOPE.FUNC)
    return gen_cond

func _func(name: String, args: Array[Arg], return_type: Variant, gen_cond: bool = true) -> bool:
    return _method(name, args, return_type, gen_cond)

func _signal(name: String, args: Array[Arg], gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.CLASS, SCOPE.SUBCLASS])
        raw.write_indented(indent, "signal ", name, "(")
        for arg in args:
            arg.write(self)
        if args.size() > 0:
            raw.trim_last_part()
        raw.write_line(")")
        set_prior(self, SCOPE.VAR_DECL)
    return gen_cond

func _var_lambda(name: String, args: Array[Arg], return_type: Variant, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.CLASS, SCOPE.SUBCLASS, SCOPE.FUNC])
        raw.write_indented(indent, "var ", name, " = func(")
        for arg in args:
            arg.write(self)
        if args.size() > 0:
            raw.trim_last_part()
        raw.write_line(") -> ", type_name(return_type), ":")
        push_scope(self, SCOPE.FUNC)
    return gen_cond

func _static_var_lambda(name: String, args: Array[Arg], return_type: Variant, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.CLASS, SCOPE.SUBCLASS, SCOPE.FUNC])
        raw.write_indented(indent, "static var ", name, " = func(")
        for arg in args:
            arg.write(self)
        if args.size() > 0:
            raw.trim_last_part()
        raw.write_line(") -> ", type_name(return_type), ":")
        push_scope(self, SCOPE.FUNC)
    return gen_cond

func _static_func(name: String, args: Array[Arg], return_type: Variant, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.CLASS, SCOPE.SUBCLASS])
        raw.write_indented(indent, "static func ", name, "(")
        for arg in args:
            arg.write(self)
        if args.size() > 0:
            raw.trim_last_part()
        raw.write_line(") -> ", type_name(return_type), ":")
        push_scope(self, SCOPE.FUNC)
    return gen_cond

func _func_with_const_mode(mode: CONST_MODE, name: String, args: Array[Arg], return_type: Variant, gen_cond: bool = true) -> bool:
    match mode:
        CONST_MODE.CONST, CONST_MODE.STATIC_VAR: return _static_func(name, args, return_type, gen_cond)
        CONST_MODE.VAR: return _method(name, args, return_type, gen_cond)
        _: return false

func _const_dict(name: String, t_key: Variant = "", t_val: Variant = "", gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.CLASS, SCOPE.SUBCLASS])
        raw.write_indented(indent, "const ", name, ": Dictionary")
        if !t_key.is_empty() or !t_val.is_empty():
            if t_key.is_empty(): t_key = "Variant"
            if t_val.is_empty(): t_val = "Variant"
            var n_key = type_name(t_key)
            var n_val = type_name(t_val)
            raw.write("[", n_key, ", ", n_val, "]")
        raw.write_line(" = {")
        push_scope(self, SCOPE.DICT_LITERAL, "}")
    return gen_cond

func _var_dict(name: String, t_key: Variant = "", t_val: Variant = "", gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.CLASS, SCOPE.SUBCLASS, SCOPE.FUNC])
        assert_is_NOT_within_any_immediate_scope(self, [SCOPE.ARRAY_LITERAL ,SCOPE.DICT_LITERAL])
        raw.write_indented(indent, "var ", name, ": Dictionary")
        if !t_key.is_empty() or !t_val.is_empty():
            if t_key.is_empty(): t_key = "Variant"
            if t_val.is_empty(): t_val = "Variant"
            var n_key = type_name(t_key)
            var n_val = type_name(t_val)
            raw.write("[", n_key, ", ", n_val, "]")
        raw.write_line(" = {")
        push_scope(self, SCOPE.DICT_LITERAL, "}")
    return gen_cond

func _static_var_dict(name: String, t_key: Variant = "", t_val: Variant = "", gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.CLASS, SCOPE.SUBCLASS, SCOPE.FUNC])
        raw.write_indented(indent, "static var ", name, ": Dictionary")
        if !t_key.is_empty() or !t_val.is_empty():
            if t_key.is_empty(): t_key = "Variant"
            if t_val.is_empty(): t_val = "Variant"
            var n_key = type_name(t_key)
            var n_val = type_name(t_val)
            raw.write("[", n_key, ", ", n_val, "]")
        raw.write_line(" = {")
        push_scope(self, SCOPE.DICT_LITERAL, "}")
    return gen_cond

func _dict_with_const_mode(mode: CONST_MODE, name: String, t_key: Variant = "", t_val: Variant = "", gen_cond: bool = true) -> bool:
    match mode:
        CONST_MODE.CONST: return _const_dict(name, t_key, t_val, gen_cond)
        CONST_MODE.STATIC_VAR: return _static_var_dict(name, t_key, t_val, gen_cond)
        CONST_MODE.VAR: return _var_dict(name, t_key, t_val, gen_cond)
        _: return false

func _dict_entry(key: Variant, val: Variant, gen_cond: bool = true) -> void:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.DICT_LITERAL])
        raw.write_indented_line(indent, var_to_str(key), ": ", var_to_str(val), ",")
        set_prior(self, SCOPE.VAR_DECL)

func _dict_entry_dict(key: Variant, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.DICT_LITERAL])
        raw.write_indented_line(indent, var_to_str(key), ": {")
        push_scope(self, SCOPE.DICT_LITERAL, "},")
    return gen_cond

func _dict_entry_array(key: Variant, packed_type: int = TYPE_ARRAY, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.DICT_LITERAL])
        var packed_name: String = packed_name_from_type(packed_type)
        var is_packed: bool = !packed_name.is_empty()
        if is_packed:
            raw.write_indented_line(indent, var_to_str(key), ": ", packed_name, "([")
            push_scope(self, SCOPE.ARRAY_LITERAL, "]),")
        else:
            raw.write_indented_line(indent, var_to_str(key), ": [")
            push_scope(self, SCOPE.ARRAY_LITERAL, "],")
    return gen_cond

func _dict_entry_lambda(key: Variant, args: Array[Arg], return_type: Variant, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.DICT_LITERAL])
        raw.write_indented_line(indent, var_to_str(key), ": (func(")
        for arg in args:
            arg.write(self)
        if args.size() > 0:
            raw.trim_last_part()
        raw.write_line(") -> ", type_name(return_type), ":")
        push_scope(self, SCOPE.FUNC, "),")
    return gen_cond

func _const_array(name: String, elem_or_packed_type: Variant = TYPE_NIL, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.CLASS, SCOPE.SUBCLASS])
        var arr_name = elem_or_packed_type if elem_or_packed_type is String else array_name_from_elem_type_or_packed_type(elem_or_packed_type)
        raw.write_indented_line(indent, "const ", name, ": ", arr_name, " = [")
        push_scope(self, SCOPE.ARRAY_LITERAL, "]")
    return gen_cond

func _static_var_array(name: String, elem_or_packed_type: Variant = TYPE_NIL, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.CLASS, SCOPE.SUBCLASS])
        var arr_name = elem_or_packed_type if elem_or_packed_type is String else array_name_from_elem_type_or_packed_type(elem_or_packed_type)
        raw.write_indented_line(indent, "static var ", name, ": ", arr_name, " = [")
        push_scope(self, SCOPE.ARRAY_LITERAL, "]")
    return gen_cond

func _var_array(name: String, elem_or_packed_type: Variant = TYPE_NIL, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.CLASS, SCOPE.SUBCLASS, SCOPE.FUNC])
        assert_is_NOT_within_any_immediate_scope(self, [SCOPE.ARRAY_LITERAL, SCOPE.DICT_LITERAL, SCOPE.PAREN_EXPR])
        var arr_name = elem_or_packed_type if elem_or_packed_type is String else array_name_from_elem_type_or_packed_type(elem_or_packed_type)
        raw.write_indented_line(indent, "var ", name, ": ", arr_name, " = [")
        push_scope(self, SCOPE.ARRAY_LITERAL, "]")
    return gen_cond

func _array_with_const_mode(mode: CONST_MODE, name: String, elem_or_packed_type: Variant = TYPE_NIL, gen_cond: bool = true) -> bool:
    match mode:
        CONST_MODE.CONST: return _const_array(name, elem_or_packed_type, gen_cond)
        CONST_MODE.STATIC_VAR: return _static_var_array(name, elem_or_packed_type, gen_cond)
        CONST_MODE.VAR: return _var_array(name, elem_or_packed_type, gen_cond)
        _: return false

func _array_entry(val: Variant, gen_cond: bool = true) -> void:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.ARRAY_LITERAL])
        raw.write_indented_line(indent, var_to_str(val), ",")
        set_prior(self, SCOPE.VAR_DECL)

func _array_entry_dict(gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.ARRAY_LITERAL])
        raw.write_indented_line(indent, "{")
        push_scope(self, SCOPE.DICT_LITERAL, "},")
    return gen_cond

func _array_entry_array(elem_or_packed_type: int = TYPE_NIL, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.ARRAY_LITERAL])
        var packed_name = array_name_from_elem_type_or_packed_type(elem_or_packed_type)
        var is_packed = packed_name.begins_with("Packed")
        if is_packed:
            raw.write_indented_line(indent, packed_name, "([")
            push_scope(self, SCOPE.ARRAY_LITERAL, "]),")
        else:
            raw.write_indented_line(indent, "[")
            push_scope(self, SCOPE.ARRAY_LITERAL, "],")
    return gen_cond

func _array_entry_lambda(args: Array[Arg], return_type: Variant, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.ARRAY_LITERAL])
        raw.write_indented_line(indent, "(func(")
        for arg in args:
            arg.write(self)
        if args.size() > 0:
            raw.trim_last_part()
        raw.write_line(") -> ", type_name(return_type), ":")
        push_scope(self, SCOPE.FUNC, "),")
    return gen_cond

func _const(name: String, type: Variant, val: Variant, gen_cond: bool = true) -> void:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.CLASS, SCOPE.SUBCLASS])
        raw.write_indented_line(indent, "const ", name, colon_type_name(type), " = ", var_to_str(val))
        set_prior(self, SCOPE.VAR_DECL)

func _var(name: String, type: Variant, val: Variant, gen_cond: bool = true) -> void:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.CLASS, SCOPE.SUBCLASS, SCOPE.FUNC])
        assert_is_NOT_within_any_immediate_scope(self, [SCOPE.ARRAY_LITERAL, SCOPE.DICT_LITERAL, SCOPE.PAREN_EXPR])
        raw.write_indented_line(indent, "var ", name, colon_type_name(type), " = ", var_to_str(val))
        set_prior(self, SCOPE.VAR_DECL)

func _static_var(name: String, type: Variant, val: Variant, gen_cond: bool = true) -> void:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.CLASS, SCOPE.SUBCLASS])
        raw.write_indented_line(indent, "static var ", name, colon_type_name(type), " = ", var_to_str(val))
        set_prior(self, SCOPE.VAR_DECL)

func _var_with_const_mode(mode: CONST_MODE, name: String, type: Variant, val: Variant, gen_cond: bool = true) -> void:
    match mode:
        CONST_MODE.CONST: return _const(name, type, val, gen_cond)
        CONST_MODE.STATIC_VAR: return _static_var(name, type, val, gen_cond)
        CONST_MODE.VAR: return _var(name, type, val, gen_cond)
        _: return

func _pass(gen_cond: bool = true) -> void:
    if gen_cond:
        raw.write_indented_line(indent, "pass")

func _if(condition: Variant, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.FUNC])
        assert_is_NOT_within_any_immediate_scope(self, [SCOPE.ARRAY_LITERAL, SCOPE.DICT_LITERAL, SCOPE.PAREN_EXPR])
        raw.write_indented(indent, "if ")
        raw.writev(argify(condition))
        raw.write_line(":")
        push_scope(self, SCOPE.IF)
    return gen_cond

func _elif(condition: Variant, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.FUNC])
        assert_is_NOT_within_any_immediate_scope(self, [SCOPE.ARRAY_LITERAL, SCOPE.DICT_LITERAL, SCOPE.PAREN_EXPR])
        assert_prior(self, [SCOPE.IF, SCOPE.ELIF])
        raw.write_indented(indent, "elif ")
        raw.writev(argify(condition))
        raw.write_line(":")
        push_scope(self, SCOPE.ELIF)
    return gen_cond

func _else(gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.FUNC])
        assert_is_NOT_within_any_immediate_scope(self, [SCOPE.ARRAY_LITERAL, SCOPE.DICT_LITERAL, SCOPE.PAREN_EXPR])
        assert_prior(self, [SCOPE.IF, SCOPE.ELIF])
        raw.write_indented_line(indent, "else:")
        push_scope(self, SCOPE.ELSE)
    return gen_cond

func _match(variable: Array, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.FUNC])
        assert_is_NOT_within_any_immediate_scope(self, [SCOPE.ARRAY_LITERAL, SCOPE.DICT_LITERAL, SCOPE.PAREN_EXPR])
        raw.write_indented(indent, "match ")
        raw.writev(variable)
        raw.write_line(":")
        push_scope(self, SCOPE.MATCH)
    return gen_cond

func _branch(branch: Variant, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.MATCH])
        raw.write_indentedv(indent, argify(branch))
        raw.write_line(":")
        push_scope(self, SCOPE.BRANCH)
    return gen_cond

func _default_branch(gen_cond: bool = true) -> bool:
    if gen_cond:
        raw.write_indented_line(indent, "_:")
        push_scope(self, SCOPE.BRANCH)
    return gen_cond

func _default_branch_pass(gen_cond: bool = true) -> void:
    if gen_cond:
        raw.write_indented_line(indent, "_: pass")
        set_prior(self, SCOPE.BRANCH)

func _default_branch_assert_false(msg: Variant, gen_cond: bool = true) -> void:
    if gen_cond:
        raw.write_indented(indent, "_: assert(false, ")
        raw.writev(argify(msg))
        raw.write_line(")")
        set_prior(self, SCOPE.BRANCH)

func _while(condition: Variant, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.FUNC])
        assert_is_NOT_within_any_immediate_scope(self, [SCOPE.ARRAY_LITERAL, SCOPE.DICT_LITERAL, SCOPE.PAREN_EXPR])
        raw.write_indented(indent, "while ")
        raw.writev(argify(condition))
        raw.write_line(" :")
        push_scope(self, SCOPE.WHILE)
    return gen_cond

func _for_in(elem_var_name: String, list_name: String, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.FUNC])
        assert_is_NOT_within_any_immediate_scope(self, [SCOPE.ARRAY_LITERAL, SCOPE.DICT_LITERAL, SCOPE.PAREN_EXPR])
        raw.write_indented_line(indent, "for ", elem_var_name, " in ", list_name, ":")
        push_scope(self, SCOPE.FOR)
    return gen_cond

enum VAR {
    NEW,
    EXISTS,
}

func _while_auto_loop(mode: VAR, var_name: String, var_type: Variant, initial_val: Variant, compare: Variant, continue_block: Variant, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.FUNC])
        assert_is_NOT_within_any_immediate_scope(self, [SCOPE.ARRAY_LITERAL, SCOPE.DICT_LITERAL, SCOPE.PAREN_EXPR])
        if mode == VAR.NEW:
            _var(var_name, var_type, initial_val)
        else:
            _line(var_name, " = ", var_to_str(initial_val))
        raw.write_indented(indent, "while ")
        raw.writev(argify(compare))
        raw.write_line(":")
        push_scope_with_continue(self, SCOPE.WHILE, concat_args(argify(continue_block)))
    return gen_cond

func _for_in_auto_loop_with_index(mode: VAR, index_var_name: String, var_type: Variant, elem_var_name: String, list_name: String, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.FUNC])
        assert_is_NOT_within_any_immediate_scope(self, [SCOPE.ARRAY_LITERAL, SCOPE.DICT_LITERAL, SCOPE.PAREN_EXPR])
        if mode == VAR.NEW:
            _var(index_var_name, var_type, 0)
        else:
            _line(index_var_name, " = ", var_to_str(0))
        raw.write_indented_line(indent, "for ", elem_var_name, " in ", list_name, ":")
        push_scope_with_continue(self, SCOPE.FOR, concat_args([index_var_name, " += 1"]))
    return gen_cond

func _multi_for_in_auto_loop(mode: VAR, index_var_name: String, index_var_type: Variant, max_mode: VAR, max_var_name: String, elem_var_names: PackedStringArray, list_names: PackedStringArray, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.FUNC])
        assert_is_NOT_within_any_immediate_scope(self, [SCOPE.ARRAY_LITERAL, SCOPE.DICT_LITERAL, SCOPE.PAREN_EXPR])
        if mode == VAR.NEW:
            _var(index_var_name, index_var_type, 0)
        else:
            _line(index_var_name, " = ", var_to_str(0))
        if max_mode == VAR.NEW:
            _line("var ", max_var_name, " := ", list_names[0], ".size()")
        else:
            _line(max_var_name, " = ", list_names[0], ".size()")
        raw.write_indented_line(indent, "while ", index_var_name, " < ", max_var_name, ":")
        push_scope_with_continue(self, SCOPE.FOR, concat_args([index_var_name, " += 1"]))
        var n := 0
        while n < elem_var_names.size():
            var elem = elem_var_names[n]
            var list = list_names[n]
            _line("var ", elem, " = ", list, "[", index_var_name, "]")
            n += 1
    return gen_cond

func _done() -> void:
    assert(stack_len > 0, "not in any scope, no scope to 'end'")
    var flags = flags_stack[stack_len - 1]
    var post_dedent = post_done_dedent[stack_len - 1]
    if flags & FLAG.CONTINUE:
        continue_len -= 1
        var cont_str = continue_strings[continue_len]
        raw.write_indented_line(indent, cont_str)
    if flags & FLAG.PRE_DONE:
        pre_done_len -= 1
        var pre_str = pre_done_strings[pre_done_len]
        raw.write_indented_line(indent, pre_str)
    indent -= 1
    if flags & FLAG.POST_DONE:
        post_done_len -= 1
        var post_str = post_done_strings[post_done_len]
        raw.write_indented_line(indent, post_str)
    indent -= post_dedent
    if flags & FLAG.FSM_VARS:
        fsm_len -= 1
    stack_len -= 1
    handle_sub_build_on_return_to_class(self)

func _continue() -> void:
    assert(stack_len > 0, "not in any scope, no scope to 'end'")
    assert_is_within_any_scope_recursive(self, [SCOPE.WHILE, SCOPE.FOR])
    var flags = flags_stack[stack_len - 1]
    var post_dedent = post_done_dedent[stack_len - 1]
    if flags & FLAG.CONTINUE or flags & FLAG.CONTINUE_INHERIT:
        var cont_str = continue_strings[continue_len - 1]
        raw.write_indented_line(indent, cont_str)
    if flags & FLAG.PRE_DONE:
        pre_done_len -= 1
        var pre_str = pre_done_strings[pre_done_len]
        raw.write_indented_line(indent, pre_str)
    raw.write_indented_line(indent, "continue")
    indent -= 1
    if flags & FLAG.POST_DONE:
        post_done_len -= 1
        var post_str = post_done_strings[post_done_len]
        raw.write_indented_line(indent, post_str)
    indent -= post_dedent
    if flags & FLAG.CONTINUE:
        continue_len -= 1
    if flags & FLAG.FSM_VARS:
        fsm_len -= 1
    stack_len -= 1
    handle_sub_build_on_return_to_class(self)

func _continue_ignore_auto() -> void:
    assert(stack_len > 0, "not in any scope, no scope to 'end'")
    assert_is_within_any_scope_recursive(self, [SCOPE.WHILE, SCOPE.FOR])
    var flags = flags_stack[stack_len - 1]
    var post_dedent = post_done_dedent[stack_len - 1]
    if flags & FLAG.PRE_DONE:
        pre_done_len -= 1
        var pre_str = pre_done_strings[pre_done_len]
        raw.write_indented_line(indent, pre_str)
    raw.write_indented_line(indent, "continue")
    indent -= 1
    if flags & FLAG.POST_DONE:
        post_done_len -= 1
        var post_str = post_done_strings[post_done_len]
        raw.write_indented_line(indent, post_str)
    indent -= post_dedent
    if flags & FLAG.CONTINUE:
        continue_len -= 1
    if flags & FLAG.FSM_VARS:
        fsm_len -= 1
    stack_len -= 1
    handle_sub_build_on_return_to_class(self)

func _break() -> void:
    assert(stack_len > 0, "not in any scope, no scope to 'end'")
    assert_is_within_any_scope_recursive(self, [SCOPE.WHILE, SCOPE.FOR])
    var flags = flags_stack[stack_len - 1]
    var post_dedent = post_done_dedent[stack_len - 1]
    if flags & FLAG.PRE_DONE:
        pre_done_len -= 1
        var pre_str = pre_done_strings[pre_done_len]
        raw.write_indented_line(indent, pre_str)
    raw.write_indented_line(indent, "break")
    indent -= 1
    if flags & FLAG.POST_DONE:
        post_done_len -= 1
        var post_str = post_done_strings[post_done_len]
        raw.write_indented_line(indent, post_str)
    indent -= post_dedent
    if flags & FLAG.CONTINUE:
        continue_len -= 1
    if flags & FLAG.FSM_VARS:
        fsm_len -= 1
    stack_len -= 1
    handle_sub_build_on_return_to_class(self)

func _return(...args: Array) -> void:
    assert_is_within_any_scope_recursive(self, [SCOPE.FUNC])
    raw.write_indented(indent, "return ")
    raw.write_linev(args)
    _done()

static func handle_sub_build_on_return_to_class(this: ScriptFileBuilder) -> void:
    if this.stack_len > 0 and this.sub_build_when_return_to_class:
        var curr_scope = this.scope_stack[this.stack_len - 1]
        if curr_scope == SCOPE.CLASS or curr_scope == SCOPE.SUBCLASS:
            var text = this.sub_builder_when_return_to_class.finish_script_text_and_reset()
            this.sub_build_when_return_to_class = false
            this.raw.write_line(text)

func _var_get_set(name: String, type: Variant, val: Variant, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.CLASS, SCOPE.SUBCLASS])
        raw.write_indented_line(indent, "var ", name, colon_type_name(type), " = ", var_to_str(val), ":")
        push_scope(self, SCOPE.VAR_GET_SET)
    return gen_cond

func _static_var_get_set(name: String, type: Variant, val: Variant, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.CLASS, SCOPE.SUBCLASS])
        raw.write_indented_line(indent, "static var ", name, colon_type_name(type), " = ", var_to_str(val), ":")
        push_scope(self, SCOPE.VAR_GET_SET)
    return gen_cond

func _var_get_set_with_const_mode(mode: CONST_MODE, name: String, type: Variant, val: Variant, gen_cond: bool = true) -> bool:
    match mode:
        CONST_MODE.CONST, CONST_MODE.STATIC_VAR: return _static_var_get_set(name, type, val, gen_cond)
        CONST_MODE.VAR: return _var_get_set(name, type, val, gen_cond)
        _: return false

func _getter(gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.VAR_GET_SET])
        raw.write_indented_line(indent, "get:")
        push_scope(self, SCOPE.FUNC)
    return gen_cond

func _getter_inline(var_result: Array, gen_cond: bool = true) -> void:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.VAR_GET_SET])
        raw.write_indented(indent, "get: ")
        raw.write_linev(var_result)

func _setter(var_name: String, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.VAR_GET_SET])
        raw.write_indented_line(indent, "set(",var_name,"):")
        push_scope(self, SCOPE.FUNC)
    return gen_cond
        
func _newline(count: int = 1) -> void:
    while count > 0:
        count -= 1
        raw.write_indented_newline(indent)

func _newline_if_none() -> void:
    var last_part = raw.parts[raw.length - 1]
    if last_part.ends_with(raw.get_newline_string()): return
    raw.write_indented_newline(indent)

enum ENUM_MODE {
    NATIVE,
    NATIVE_BITFLAG,
    SCALAR_MIXED,
    SCALAR_SAME,
    SCALAR_BITFLAG,
    ARRAYS_MIXED,
    ARRAYS_SAME,
}

func _enum(enum_name: String, enum_entries: Variant, gen_cond: bool = true) -> void:
    _enum_advanced(ENUM_MODE.NATIVE, enum_name, "", enum_entries, gen_cond)

func _enum_advanced(mode: ENUM_MODE, enum_name: String, enum_array_name: String, enum_entries: Variant, gen_cond: bool = true) -> void:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.CLASS, SCOPE.SUBCLASS])
        var enum_dict := {}
        if enum_entries is Dictionary:
            enum_dict = enum_entries
        elif enum_entries is Array or enum_entries is PackedStringArray:
            var i := 0
            for e in enum_entries:
                enum_dict.set(e, i)
                i += 1
        var d_types := {}
        var d_val_max := {}
        var d_val_min := {}
        var d_first := {}
        var first_set: bool = false
        var v_type: int = TYPE_NIL
        for k in enum_dict.keys():
            var v = enum_dict.get(k)
            var t = typeof(v)
            match t:
                TYPE_DICTIONARY:
                    assert(mode == ENUM_MODE.ARRAYS_MIXED or mode == ENUM_MODE.ARRAYS_SAME)
                    for kk in v.keys():
                        var key_first = d_first.get(kk, false)
                        var vv = v.get(kk)
                        var tt = typeof(vv)
                        if vv is RawLiteral: continue
                        if vv is StrLiteral:
                            vv = vv.lit
                        if !key_first:
                            d_types.set(kk, tt)
                            d_first.get(kk, true)
                            if tt == TYPE_INT:
                                d_val_max.set(kk, 0)
                                d_val_min.set(kk, 0)
                            elif tt == TYPE_FLOAT:
                                d_val_max.set(kk, 0.0)
                                d_val_min.set(kk, 0.0)
                        elif mode == ENUM_MODE.ARRAYS_SAME:
                            assert(tt == d_types.get(kk))
                        if tt == TYPE_INT or tt == TYPE_FLOAT:
                            var new_min = d_val_min.get(kk)
                            var new_max = d_val_max.get(kk)
                            new_min = min(new_min, vv)
                            new_max = max(new_max, vv)
                            d_val_min.set(kk, new_min)
                            d_val_max.set(kk, new_max)
                _:
                    assert(mode == ENUM_MODE.SCALAR_MIXED or mode == ENUM_MODE.SCALAR_SAME or mode == ENUM_MODE.SCALAR_BITFLAG or mode == ENUM_MODE.NATIVE or mode == ENUM_MODE.NATIVE_BITFLAG)
                    if !first_set:
                        v_type = t
                        first_set = true
                    elif mode != ENUM_MODE.SCALAR_MIXED:
                        assert(t == v_type)
        match mode:
            ENUM_MODE.NATIVE, ENUM_MODE.NATIVE_BITFLAG:
                assert(v_type == TYPE_INT)
                raw.write_line("enum ", enum_name, " {")
                for k in enum_dict.keys():
                    var v = enum_dict.get(k)
                    raw.write_indented_line(1, k, " = ", "1 << " if mode == ENUM_MODE.NATIVE_BITFLAG else "", str(v), ",")
                raw.write_line("}")
            ENUM_MODE.SCALAR_MIXED, ENUM_MODE.SCALAR_SAME, ENUM_MODE.SCALAR_BITFLAG:
                if mode == ENUM_MODE.SCALAR_BITFLAG:
                    assert(v_type == TYPE_INT)
                for k in enum_dict.keys():
                    var v = enum_dict.get(k)
                    raw.write_line("const ",enum_name, "_",k, ": ",type_string(typeof(v))," = ", "1 << " if mode == ENUM_MODE.SCALAR_BITFLAG else "", v)
            _:
                raw.write_line("enum ", enum_name, " {")
                for k in enum_dict.keys():
                    raw.write_indented_line(1, k, ",")
                raw.write_line("}")
                raw.write_indented_newline(indent)
                for kk in d_types.keys():
                    var t = d_types.get(kk)
                    var t_min = d_val_min.get(kk, 0)
                    var t_max = d_val_max.get(kk, 0)
                    var t_name: String = "Array"
                    if mode == ENUM_MODE.ARRAYS_SAME:
                        t_name = packed_name_from_elem_type_and_min_max(t, t_min, t_max)
                    raw.write_line("const ",enum_array_name, "_" if !enum_array_name.is_empty() else "",kk, ": ", t_name, " = [")
                    for k in enum_dict.keys():
                        var v: Dictionary = enum_dict.get(k)
                        var is_default = !v.has(kk)
                        var vv = v.get(kk, type_convert("", t))
                        raw.write_indented_line(1, vv, ", # ", k, " (DEFAULT)" if is_default else "")
                    raw.write_line("]")
                    raw.write_indented_newline(indent)

enum ARRAY_MODE {
    SAME_TYPES,
    MIXED_TYPES,
}

enum CONST_MODE {
    CONST,
    STATIC_VAR,
    VAR,
}

static func check_const_n_array_keys_and_types_recurse(name: String, min_max: Dictionary, level_keys: Dictionary[String, PackedStringArray], level: int, values: Dictionary, type: Variant, check_type: bool) -> void:
    var this_level_name = level_keys.keys()[level]
    var this_level = level_keys.get(this_level_name)
    if level == level_keys.size() - 1:
        for k in values.keys():
            var v = values.get(k)
            var t = typeof(v)
            assert(this_level.has(k), "key `%s` is not a valid key for N-dimension array `%s` level %d, allowed keys: `%s`" % [k, name, level, var_to_str(this_level)])
            if check_type:
                assert(t == type, "when array mode is `SAME_TYPES`, all types must match the specified type (expected %s, got %s)" % [type_string(type), type_string(t)])
                match type:
                    TYPE_INT, TYPE_FLOAT:
                        var val_max = min_max.get("max")
                        var val_min = min_max.get("min")
                        val_max = max(val_max, v)
                        val_min = min(val_min, v)
                        min_max.set("max", val_max)
                        min_max.set("min", val_min)
                    _: pass
    else:
        for k in values.keys():
            assert(this_level.has(k), "key `%s` is not a valid key for N-dimension array `%s` level %d, allowed keys: `%s`" % [k, name, level, var_to_str(this_level)])
            var sub_vals = values.get(k)
            check_const_n_array_keys_and_types_recurse(name, min_max, level_keys, level + 1, sub_vals, type, check_type)

static func write_const_n_array_entries_recurse(this: ScriptFileBuilder, empty: Variant, level_keys: Dictionary[String, PackedStringArray], level: int, values: Dictionary) -> void:
    var this_level_name = level_keys.keys()[level]
    var this_level = level_keys.get(this_level_name)
    if level == level_keys.size() - 1:
        for k in this_level:
            var v = values.get(k, empty)
            this._array_entry(v)
    else:
        for k in this_level:
            var sub_vals = values.get(k, {})
            write_const_n_array_entries_recurse(this, empty, level_keys, level + 1, sub_vals)

func _auto_n_dimension_array(constness: CONST_MODE, mode: ARRAY_MODE, type: Variant, name: String, key_prefix: String, level_keys_in_order: Dictionary[String, PackedStringArray], values: Dictionary, custom_empty: Variant = null, flat_suffix: String = "_FLAT_VALS", gen_cond: bool = true) -> void:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.CLASS, SCOPE.SUBCLASS])
        var total_entries := 1
        var multipliers: PackedInt32Array = []
        var num_levels = level_keys_in_order.size()
        multipliers.resize(num_levels)
        multipliers.fill(1)
        var l := 0
        for level_name in level_keys_in_order.keys():
            var level_keys = level_keys_in_order.get(level_name)
            var level_size = level_keys.size()
            var ll := 0
            while ll < l:
                multipliers[ll] *= level_size
                ll += 1
            total_entries *= level_size
            l += 1
        if total_entries == 0: return
        var empty_val = custom_empty if custom_empty != null else type_convert("", type)
        var min_max := {
            "min": type_convert("", type),
            "max": type_convert("", type),
        }
        check_const_n_array_keys_and_types_recurse(name, min_max, level_keys_in_order, 0, values, type, (type is int) and (mode == ARRAY_MODE.SAME_TYPES))
        var arr_t_name: String = "Array"
        if mode == ARRAY_MODE.SAME_TYPES:
            arr_t_name = packed_name_from_elem_type_and_min_max(type, min_max.get("min"), min_max.get("max"))
        if _array_with_const_mode(constness, name + flat_suffix, arr_t_name):
            write_const_n_array_entries_recurse(self, empty_val, level_keys_in_order, 0, values)
            _done()
        _newline()
        var func_args: Array[Arg] = []
        for level_name in level_keys_in_order.keys():
            var level = level_keys_in_order.get(level_name)
            var e_name = ((key_prefix + "_") if !key_prefix.is_empty() else "") + level_name
            _enum(e_name, level)
            _newline()
            func_args.append(Arg.new(level_name.to_lower(), e_name))
        var get_set_return_t = "Variant"
        if mode == ARRAY_MODE.SAME_TYPES:
            if type is String:
                get_set_return_t = type
            else:
                get_set_return_t = type_string(type)
        if _func_with_const_mode(constness, "get_" + name, func_args, get_set_return_t):
            _line("var idx = 0")
            l = 0
            for arg in func_args:
                if l < num_levels - 1:
                    _line("idx += (", arg.name, " * ", str(multipliers[l]), ") # array stride for level ", arg.name)
                else:
                    _line("idx += ", arg.name)
                l += 1
            _return(name, flat_suffix, "[idx]")
        _newline()
        if constness != CONST_MODE.CONST:
            func_args.append(Arg.new("value", get_set_return_t))
            if _func_with_const_mode(constness, "set_" + name, func_args, "void"):
                _line("var idx = 0")
                l = 0
                for arg in func_args:
                    if l < num_levels - 1:
                        _line("idx += (", arg.name, " * ", str(multipliers), ") # array stride for level ", arg.name)
                    else:
                        _line("idx += ", arg.name)
                    l += 1
                _line(name, flat_suffix, "[idx] = value")
                _done()
            _newline()

enum FSM_MODE {
    LOOP_WITH_SHORT_CIRCUIT,
    LOOP_WITH_SHORT_CIRCUIT_EXTRA_GUARDS,
    LOOP_NO_SHORT_CIRCUIT,
    SINGLE_PASS,
    SINGLE_PASS_NO_FALLTHROUGH,
}

enum COMMENT_MODE {
    NO_HELPER_COMMENTS,
    INCLUDE_HELPER_COMMENTS,
}

func _finite_state_machine(mode: FSM_MODE, case_var: String, case_enum_name: String, exit_case: String, logic_cases: PackedStringArray, comments: COMMENT_MODE = COMMENT_MODE.INCLUDE_HELPER_COMMENTS, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.FUNC])
        assert_is_NOT_within_any_scope_recursive(self, [SCOPE.DICT_LITERAL, SCOPE.ARRAY_LITERAL, SCOPE.PAREN_EXPR])
        var on_exit = get_sub_builder_for_when_not_in_func()
        assert(!logic_cases.has(exit_case), "the logic cases cannot contain the exit case")
        logic_cases.append(exit_case)
        on_exit._newline()
        on_exit._enum(case_enum_name, logic_cases)
        match mode:
            FSM_MODE.LOOP_WITH_SHORT_CIRCUIT, FSM_MODE.LOOP_WITH_SHORT_CIRCUIT_EXTRA_GUARDS, FSM_MODE.LOOP_NO_SHORT_CIRCUIT:
                raw.write_indented_line(indent, "while ", case_var, " != ", case_enum_name, ".", exit_case, ":")
            FSM_MODE.SINGLE_PASS, FSM_MODE.SINGLE_PASS_NO_FALLTHROUGH:
                raw.write_indented_line(indent, "if ", case_var, " != ", case_enum_name, ".", exit_case, ":")
            _: pass
        push_scope_with_fsm_vars(self, SCOPE.FSM, case_var, case_enum_name, exit_case, logic_cases, mode, comments)
    return gen_cond

func _fsm_branch(branch_name: String, gen_cond: bool = true) -> bool:
    if gen_cond:
        assert_is_within_any_immediate_scope(self, [SCOPE.FSM])
        var fsm_vars_ = get_fsm_vars(self)
        var fsm_branches_= get_fsm_branches(self)
        var mode = get_fsm_mode(self)
        var comments = get_fsm_comment(self)
        var branch_index = fsm_branches_.find(branch_name)
        var case_var = fsm_vars_[0]
        var enum_name = fsm_vars_[1]
        var exit_branch = fsm_vars_[2]
        set_fsm_curr_branch(self, branch_name)
        assert(branch_index >= 0, "case `%s.%s` does not match any of the defined cases in the current finite state machine, valid cases are: %s" % [enum_name, branch_name, var_to_str(fsm_branches_)])
        assert(branch_name != fsm_vars[2], "cannot open the 'exit' case as a branch with logic, that case is reserved as the while loop exit condition")
        var post_done = ""
        var pre_done = ""
        if comments == COMMENT_MODE.INCLUDE_HELPER_COMMENTS:
            pre_done = "# END " + enum_name + "." + branch_name
        var dedent = 0
        if mode ==  FSM_MODE.LOOP_WITH_SHORT_CIRCUIT_EXTRA_GUARDS:
            raw.write_indented_line(indent, "if ", case_var, " == ", enum_name, ".", branch_name, ":")
            indent += 1
            dedent = 1
        match mode:
            FSM_MODE.LOOP_WITH_SHORT_CIRCUIT, FSM_MODE.LOOP_WITH_SHORT_CIRCUIT_EXTRA_GUARDS:
                post_done = "if " + case_var + " <= " + enum_name + "." + branch_name + ": continue" + raw.get_newline_string() + raw.get_indent_string().repeat(indent) + "elif " + case_var + " >= " + enum_name + "." + exit_branch + ": break"
            _: pass
        match mode:
            FSM_MODE.LOOP_NO_SHORT_CIRCUIT, FSM_MODE.LOOP_WITH_SHORT_CIRCUIT, FSM_MODE.LOOP_WITH_SHORT_CIRCUIT_EXTRA_GUARDS:
                raw.write_indented_line(indent, "while ", case_var, " == ", enum_name, ".", branch_name, ":")
            FSM_MODE.SINGLE_PASS:
                raw.write_indented_line(indent, "if ", case_var, " == ", enum_name, ".", branch_name, ":")
            FSM_MODE.SINGLE_PASS_NO_FALLTHROUGH:
                if get_prior(self) == SCOPE.FSM_BRANCH:
                    raw.write_indented_line(indent, "elif ", case_var, " == ", enum_name, ".", branch_name, ":")
                else:
                    raw.write_indented_line(indent, "if ", case_var, " == ", enum_name, ".", branch_name, ":")
            _:assert(false)
        if comments == COMMENT_MODE.INCLUDE_HELPER_COMMENTS:
            raw.write_indented_line(indent + 1, "# BEGIN ", enum_name, ".", branch_name)
        push_scope_pre_done_and_post_done_dedent(self, SCOPE.FSM_BRANCH, pre_done, post_done, dedent)
    return gen_cond

func _fsm_goto(target_branch_name: String, gen_cond: bool = true) -> void:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.FSM_BRANCH])
        assert_is_NOT_within_any_scope_recursive(self, [SCOPE.DICT_LITERAL, SCOPE.ARRAY_LITERAL, SCOPE.PAREN_EXPR])
        var fsm_vars_ = get_fsm_vars(self)
        var fsm_mode_ = get_fsm_mode(self)
        var fsm_branches_= get_fsm_branches(self)
        var case_var = fsm_vars_[0]
        var enum_name = fsm_vars_[1]
        var curr_branch = fsm_vars_[3]
        var curr_index = fsm_branches_.find(curr_branch)
        var target_index = fsm_branches_.find(target_branch_name)
        assert(curr_index >= 0, "something went wrong, current branch not found in fsm_branches")
        assert(target_index >= 0, "case `%s` does not match any of the defined cases in the current finite state machine, valid cases are: %s" % [target_branch_name, var_to_str(fsm_branches_)])
        if target_index == curr_index and fsm_mode_ != FSM_MODE.SINGLE_PASS and fsm_mode_ != FSM_MODE.SINGLE_PASS_NO_FALLTHROUGH:
            raw.write_indented_line(indent, "continue")
        else:
            raw.write_indented_line(indent, case_var, " = ", enum_name, ".", target_branch_name)
            if fsm_mode_ != FSM_MODE.SINGLE_PASS and fsm_mode_ != FSM_MODE.SINGLE_PASS_NO_FALLTHROUGH:
                raw.write_indented_line(indent, "break")
        _done()

func _fsm_exit(gen_cond: bool = true) -> void:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.FSM_BRANCH])
        assert_is_NOT_within_any_scope_recursive(self, [SCOPE.DICT_LITERAL, SCOPE.ARRAY_LITERAL, SCOPE.PAREN_EXPR])
        var fsm_vars_ = get_fsm_vars(self)
        var fsm_mode_ = get_fsm_mode(self)
        var case_var = fsm_vars_[0]
        var enum_name = fsm_vars_[1]
        var exit_name = fsm_vars_[2]
        raw.write_indented_line(indent, case_var, " = ", enum_name, ".", exit_name)
        if fsm_mode_ != FSM_MODE.SINGLE_PASS and fsm_mode_ != FSM_MODE.SINGLE_PASS_NO_FALLTHROUGH:
            raw.write_indented_line(indent, "break")
        _done()

func _fsm_goto_any(target_level_enum: String, target_branch_name: String, gen_cond: bool = true) -> void:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.FSM_BRANCH])
        assert_is_NOT_within_any_scope_recursive(self, [SCOPE.DICT_LITERAL, SCOPE.ARRAY_LITERAL, SCOPE.PAREN_EXPR])
        var fsm_vars_ = get_fsm_vars(self)
        var fsm_mode_ = get_fsm_mode(self)
        var fsm_branches_= get_fsm_branches(self)
        var enum_name = fsm_vars_[1]
        var target_index = fsm_branches_.find(target_branch_name)
        if target_index >= 0 and target_level_enum == enum_name:
            _fsm_goto(target_branch_name, true)
        var d := 1
        while target_index < 0 or target_level_enum != enum_name:
            d += 1
            assert(d <= fsm_len, "case `%s.%s` does not match ANY of the defined cases in ANY of the finite state machines in scope" % [target_level_enum, target_branch_name])
            fsm_vars_ = get_fsm_vars(self, d)
            fsm_branches_ = get_fsm_branches(self, d)
            target_index = fsm_branches_.find(target_branch_name)
            enum_name = fsm_vars_[1]
        assert(enum_name == target_level_enum and target_index >= 0)
        var case_var = fsm_vars_[0]
        raw.write_indented_line(indent, case_var, " = ", enum_name, ".", target_branch_name)
        var exit_var
        while d > 1:
            d -= 1
            fsm_vars_ = get_fsm_vars(self, d)
            case_var = fsm_vars_[0]
            enum_name = fsm_vars_[1]
            exit_var = fsm_vars_[2]
            raw.write_indented_line(indent, case_var, " = ", enum_name, ".", exit_var)
        if fsm_mode_ != FSM_MODE.SINGLE_PASS and fsm_mode_ != FSM_MODE.SINGLE_PASS_NO_FALLTHROUGH:
            raw.write_indented_line(indent, "break")
        _done()

func _fsm_exit_all(gen_cond: bool = true) -> void:
    if gen_cond:
        assert_is_within_any_scope_recursive(self, [SCOPE.FSM_BRANCH])
        assert_is_NOT_within_any_scope_recursive(self, [SCOPE.DICT_LITERAL, SCOPE.ARRAY_LITERAL, SCOPE.PAREN_EXPR])
        var fsm_vars_
        var case_var
        var enum_name
        var exit_name
        var d := 1
        while d <= fsm_len:
            fsm_vars_ = get_fsm_vars(self, d)
            case_var = fsm_vars_[0]
            enum_name = fsm_vars_[1]
            exit_name = fsm_vars_[2]
            raw.write_indented_line(indent, case_var, " = ", enum_name, ".", exit_name)
            d += 1
        var fsm_mode_ = get_fsm_mode(self)
        if fsm_mode_ != FSM_MODE.SINGLE_PASS and fsm_mode_ != FSM_MODE.SINGLE_PASS_NO_FALLTHROUGH:
            raw.write_indented_line(indent, "break")
        _done()

func _line(...vals: Array) -> void:
    raw.write_indented_linev(indent, vals)

func _line_start_scope(scope: SCOPE, ...vals: Array) -> bool:
    raw.write_indented_linev(indent, vals)
    push_scope(self, scope)
    return true

func _linev(vals: Array) -> void:
    raw.write_indented_linev(indent, vals)

func _linev_start_scope(scope: SCOPE, vals: Array) -> bool:
    raw.write_indented_linev(indent, vals)
    push_scope(self, scope)
    return true

func _line_if(vals: Variant, gen_cond: bool = true) -> void:
    if gen_cond:
        raw.write_indented_linev(indent, argify(vals))

func _line_start_scope_if(scope: SCOPE, vals: Variant, gen_cond: bool = true) -> bool:
    if gen_cond:
        raw.write_indented_linev(indent, argify(vals))
        push_scope(self, scope)
    return gen_cond

func _line_start_scope_advanced(scope: SCOPE, vals: Variant, gen_cond: bool = true, indent_: int = 1, pre_done_string: String = "", post_done_string: String = "", post_done_dedent_: int = 0) -> bool:
    if gen_cond:
        raw.write_indented_linev(indent, argify(vals))
        _internal_push_scope(self, scope, indent_, post_done_dedent_, pre_done_string, post_done_string)
    return gen_cond

func _line_indent(indent_: int, ...vals: Array) -> void:
    raw.write_indented_linev(indent + indent_, vals)

func _string(...vals: Array) -> void:
    raw.write_indentedv(indent, vals)

func _string_indent(indent_: int, ...vals: Array) -> void:
    raw.write_indentedv(indent + indent_, vals)

func _multiline_raw(multiline: String) -> void:
    clean_and_write_string(multiline, raw, indent)

func _multiline_raw_indent(indent_: int, multiline: String) -> void:
    clean_and_write_string(multiline, raw, indent_)

func _comment(...args: Array) -> void:
    raw.write_indented(indent, "# ")
    raw.writev(args)
    raw.write_indented_newline(indent)

func _commentv(args: Array) -> void:
    raw.write_indented(indent, "# ")
    raw.writev(args)
    raw.write_indented_newline(indent)

func _doc_comment(...args: Array) -> void:
    raw.write_indented(indent, "## ")
    raw.writev(args)
    raw.write_indented_newline(indent)

func _doc_commentv(args: Array) -> void:
    raw.write_indented(indent, "## ")
    raw.writev(args)
    raw.write_indented_newline(indent)

func _comment_if(gen_cond: bool, ...args: Array) -> void:
    if gen_cond:
        raw.write_indented(indent, "# ")
        raw.writev(args)
        raw.write_indented_newline(indent)

func _doc_comment_if(gen_cond: bool, ...args: Array) -> void:
    if gen_cond:
        raw.write_indented(indent, "## ")
        raw.writev(args)
        raw.write_indented_newline(indent)

# func _combine_sub_gen(sub: ScriptFileBuilder, gen_cond: bool = true) -> void:
#     if gen_cond:
#         raw.parts.append_array(sub.raw.parts)

func get_sub_builder_for_when_not_in_func() -> ScriptFileBuilder:
    if !sub_build_when_return_to_class:
        sub_build_when_return_to_class = true
        if sub_builder_when_return_to_class == null:
            sub_builder_when_return_to_class = ScriptFileBuilder.new()
        var first_class_scope = SCOPE.NONE
        var first_class_scope_indent: int = 0
        var s := stack_len
        while s > 0:
            s -= 1
            var scope = scope_stack[s]
            if scope == SCOPE.CLASS or scope == SCOPE.SUBCLASS:
                first_class_scope = scope as SCOPE
                while s > 0 and scope != SCOPE.CLASS:
                    first_class_scope_indent += 1
                    s -= 1
                break
        sub_builder_when_return_to_class.indent = first_class_scope_indent
        push_scope_no_indent(sub_builder_when_return_to_class, first_class_scope)
    return sub_builder_when_return_to_class

func finish_script_text() -> String:
    if is_done:
        return final_string
    else:
        var sidx := 0
        while sidx < sub_len:
            var sub_builder_ = sub_builders[sidx]
            var build_part_locs: PackedInt32Array = sub_part_idx[sidx]
            var build_part_indents: PackedInt32Array = sub_indents[sidx]
            assert(build_part_locs.size() == build_part_indents.size())
            var sub_str = sub_builder_.finish_script_text()
            if sub_str.is_empty() and sub_ignore[sidx] == 0:
                var unbuilt_inline_id = sub_names[sidx]
                push_warning("inline block `%s` was never written to and has no content" % unbuilt_inline_id)
            else:
                var pidx := 0
                while pidx < build_part_locs.size():
                    var loc = build_part_locs[pidx]
                    var loc_indent = build_part_indents[pidx]
                    if loc_indent > 0:
                        var indent_str = raw.get_indent_string().repeat(loc_indent)
                        var indented_sub_str = sub_str.indent(indent_str)
                        raw.parts[loc] = indented_sub_str
                    else:
                        raw.parts[loc] = sub_str
                    pidx += 1
            sidx += 1
        final_string = raw.finish()
        is_done = true
        return final_string

func finish_script_text_and_clear() -> String:
    var s = finish_script_text()
    clear()
    return s

func finish_script_text_and_reset() -> String:
    var s = finish_script_text()
    reset()
    return s

func clear() -> void:
    raw.clear()
    scope_stack.clear()
    prior_stack.clear()
    flags_stack.clear()
    indent = 0
    stack_len = 0
    pre_done_strings.clear()
    pre_done_len = 0
    post_done_strings.clear()
    post_done_len = 0
    continue_strings.clear()
    continue_len = 0
    is_done = false
    final_string = ""
    var sidx := 0
    while sidx < sub_len:
        var sub_builder_ = sub_builders[sidx]
        sub_builder_.clear()
        sidx += 1
    sub_len = 0

func reset() -> void:
    raw.reset()
    indent = 0
    stack_len = 0
    pre_done_len = 0
    post_done_len = 0
    continue_len = 0
    is_done = false
    final_string = ""
    var sidx := 0
    while sidx < sub_len:
        var sub_builder_ = sub_builders[sidx]
        sub_builder_.reset()
        sidx += 1
    sub_len = 0

static func colon_type_name(t: Variant) -> String:
    if t is String:
        return ": " + t
    elif t is int:
        return ": " + type_string(t)
    else:
        return ""

static func type_name(t: Variant) -> String:
    if t is String:
        return t
    elif t is int:
        return type_string(t)
    else:
        assert(false, "unsupported type input")
        return "<INVALID>"

static func packed_name_from_type(type: int) -> String:
    match type:
        TYPE_PACKED_BYTE_ARRAY: return "PackedByteArray"
        TYPE_PACKED_INT32_ARRAY: return "PackedInt32Array"
        TYPE_PACKED_INT64_ARRAY: return "PackedInt64Array"
        TYPE_PACKED_FLOAT32_ARRAY: return "PackedFloat32Array"
        TYPE_PACKED_FLOAT64_ARRAY: return "PackedFloat64Array"
        TYPE_PACKED_COLOR_ARRAY: return "PackedColorArray"
        TYPE_PACKED_STRING_ARRAY: return "PackedStringArray"
        TYPE_PACKED_VECTOR2_ARRAY: return "PackedVector2Array"
        TYPE_PACKED_VECTOR3_ARRAY: return "PackedVector3Array"
        TYPE_PACKED_VECTOR4_ARRAY: return "PackedVector4Array"
        _: return ""

static func packed_name_from_elem_type_and_min_max(type: int, min_: Variant, max_: Variant) -> String:
    match type:
        TYPE_BOOL:
            return "PackedByteArray"
        TYPE_INT:
            if min_ >= 0 and max_ <= UINT8_MAX:
                return "PackedByteArray"
            elif min_ >= INT32_MIN and max_ <= INT32_MAX:
                return "PackedInt32Array"
            else:
                return "PackedInt64Array"
        TYPE_FLOAT:
            if min_ > -3.402823e38 and max_ < 3.402823e38:
                return "PackedFloat32Array"
            else:
                return "PackedFloat64Array"
        TYPE_STRING:
            return "PackedStringArray"
        TYPE_VECTOR2:
            return "PackedVector2Array"
        TYPE_VECTOR3:
            return "PackedVector3Array"
        TYPE_VECTOR4:
            return "PackedVector4Array"
        TYPE_COLOR:
            return "PackedColorArray"
        _:
            return "Array"

static func array_name_from_elem_type_or_packed_type(type: int) -> String:
    match type:
        TYPE_PACKED_BYTE_ARRAY: return "PackedByteArray"
        TYPE_PACKED_INT32_ARRAY: return "PackedInt32Array"
        TYPE_PACKED_INT64_ARRAY: return "PackedInt64Array"
        TYPE_PACKED_FLOAT32_ARRAY: return "PackedFloat32Array"
        TYPE_PACKED_FLOAT64_ARRAY: return "PackedFloat64Array"
        TYPE_PACKED_COLOR_ARRAY: return "PackedColorArray"
        TYPE_PACKED_STRING_ARRAY: return "PackedStringArray"
        TYPE_PACKED_VECTOR2_ARRAY: return "PackedVector2Array"
        TYPE_PACKED_VECTOR3_ARRAY: return "PackedVector3Array"
        TYPE_PACKED_VECTOR4_ARRAY: return "PackedVector4Array"
        TYPE_NIL: return "Array"
        _: return "Array[" + type_name(type) + "]"

static func argify(args: Variant) -> Array:
    match typeof(args):
        TYPE_ARRAY: return args
        TYPE_PACKED_BYTE_ARRAY, \
        TYPE_PACKED_COLOR_ARRAY, \
        TYPE_PACKED_FLOAT32_ARRAY, \
        TYPE_PACKED_FLOAT64_ARRAY, \
        TYPE_PACKED_INT32_ARRAY, \
        TYPE_PACKED_INT64_ARRAY, \
        TYPE_PACKED_STRING_ARRAY, \
        TYPE_PACKED_VECTOR2_ARRAY, \
        TYPE_PACKED_VECTOR3_ARRAY, \
        TYPE_PACKED_VECTOR4_ARRAY: return Array(args)
        TYPE_STRING: return [args]
        _: return [var_to_str(args)]

static func str_lit(s: String) -> String:
    return "\"" + s + "\""

static func concat_args(args: Array) -> String:
    var b := StringBuilder.new()
    b.writev(args)
    return b.finish_and_clear()

class FuncSignature:
    var name: String
    var args: Array[Arg]
    var return_type: String

    func _init(name_: String, args_: Array[Arg], return_type_: String) -> void:
        name = name_
        args = args_
        return_type = return_type_
    
    func as_string() -> String:
        var s := self.name + "("
        var i := 0
        for a in self.args:
            s += a.name + ScriptFileBuilder.colon_type_name(a.type)
            if i < self.args.size() - 1:
                s += ", "
            i += 1
        s += ") -> " + self.return_type
        return s
    
    func equals(other: FuncSignature) -> bool:
        return self.as_string() == other.as_string()

static func clean_string(body: String) -> String:
    body = body.lstrip(" \n\t\r")
    body = body.rstrip(" \n\t\r")
    return body

static func clean_and_indent_string(body: String, out: StringBuilder, indent: int) -> String:
    body = body.lstrip(" \n\t\r")
    body = body.rstrip(" \n\t\r")
    if indent > 0:
        body = body.indent(out.get_indent_string().repeat(indent))
    return body

static func clean_and_write_string(body: String, out: StringBuilder, indent: int) -> void:
    body = body.lstrip(" \n\t\r")
    body = body.rstrip(" \n\t\r")
    if indent > 0:
        body = body.indent(out.get_indent_string().repeat(indent))
    out.write_line(body)

const RawLiteral = StringBuilder.RawLiteral
const StrLiteral = StringBuilder.StrLiteral

static func literal(lit: String) -> StringBuilder.RawLiteral:
    return StringBuilder.RawLiteral.new(lit)

static func string(lit: String) -> StringBuilder.StrLiteral:
    return StringBuilder.StrLiteral.new(lit)
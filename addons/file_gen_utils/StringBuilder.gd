class_name StringBuilder extends RefCounted

enum NEWLINE_MODE {
    LF,
    CRLF,
}
enum TAB_MODE {
    SPACE_2,
    SPACE_4,
    TAB,
}
var newline_mode: NEWLINE_MODE = NEWLINE_MODE.CRLF
var tab_mode: TAB_MODE = TAB_MODE.SPACE_4
var parts: PackedStringArray = []
var length: int = 0
var grow: int = 16

func _init(newline_mode_: NEWLINE_MODE = NEWLINE_MODE.CRLF, tab_mode_: TAB_MODE = TAB_MODE.SPACE_4) -> void:
    newline_mode = newline_mode_
    tab_mode = tab_mode_

func finish() -> String:
    parts.resize(length)
    return "".join(parts)

func clear() -> void:
    length = 0
    parts.clear()

func reset() -> void:
    length = 0

func finish_and_clear() -> String:
    var result = finish()
    clear()
    return result

func finish_and_reset() -> String:
    var result = finish()
    reset()
    return result

func write(...vals: Array) -> void:
    writev(vals)

func writev(vals: Array) -> void:
    for v in vals:
        if v is String:
            write_string(v)
        elif v is RawLiteral:
            write_string(v.lit)
        elif v is StrLiteral:
            write_string("\"" + v.lit + "\"")
        else:
            write_string(str(v))

func write_line(...vals: Array) -> void:
    write_linev(vals)

func write_linev(vals: Array) -> void:
    self.writev(vals)
    self.write_newline()

func write_indented(indent: int, ...vals: Array) -> void:
    write_indentedv(indent, vals)

func write_indentedv(indent: int, vals: Array) -> void:
    write_n_tabs(indent)
    writev(vals)

func write_indented_line(indent: int, ...vals: Array) -> void:
    write_indented_linev(indent, vals)

func write_indented_linev(indent: int, vals: Array) -> void:
    write_n_tabs(indent)
    write_linev(vals)

func write_newline() -> void:
    match newline_mode:
        NEWLINE_MODE.CRLF:
            write_string("\r\n")
        NEWLINE_MODE.LF:
            write_string("\n")

func write_indented_newline(indent: int) -> void:
    write_n_tabs(indent)
    write_newline()

func get_newline_string() -> String:
    match newline_mode:
        NEWLINE_MODE.CRLF: return "\r\n"
        NEWLINE_MODE.LF: return "\n"
        _: return "\n"

func write_tab() -> void:
    match tab_mode:
        TAB_MODE.SPACE_2:
            write_string("  ")
        TAB_MODE.SPACE_4:
            write_string("    ")
        TAB_MODE.TAB:
            write_string("\t")
        _: assert(false)

func get_indent_string() -> String:
    match tab_mode:
        TAB_MODE.SPACE_2: return "  "
        TAB_MODE.SPACE_4: return "    "
        TAB_MODE.TAB: return "\t"
        _: 
            assert(false)
            return ""

func write_n_tabs(n: int) -> void:
    var i: int = 0;
    while i < n:
        write_tab()
        i += 1

func write_string(string: String) -> void:
    if length >= parts.size():
        parts.resize(length + grow)
    parts[length] = string
    length += 1

func trim_last_part(count: int = 1) -> void:
    length -= count

class RawLiteral:
    var lit: String

    func _init(l: String) -> void:
        lit = l

class StrLiteral:
    var lit: String

    func _init(l: String) -> void:
        lit = l

static func literal(lit: String) -> RawLiteral:
    return RawLiteral.new(lit)

static func string(lit: String) -> StrLiteral:
    return StrLiteral.new(lit)

class_name TextFile extends RefCounted

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
var file: FileAccess = null
var failed: bool = false

func _init(newline_mode_: NEWLINE_MODE = NEWLINE_MODE.CRLF, tab_mode_: TAB_MODE = TAB_MODE.SPACE_4) -> void:
    newline_mode = newline_mode_
    tab_mode = tab_mode_

static func open(path: String, flags: FileAccess.ModeFlags, newline_mode_: NEWLINE_MODE = NEWLINE_MODE.CRLF, tab_mode_: TAB_MODE = TAB_MODE.SPACE_4) -> TextFile:
    var tf = TextFile.new(newline_mode_, tab_mode_)
    tf.file = FileAccess.open(path, flags)
    return tf

static func open_compressed(path: String, flags: FileAccess.ModeFlags, compression_mode: FileAccess.CompressionMode, newline_mode_: NEWLINE_MODE = NEWLINE_MODE.CRLF, tab_mode_: TAB_MODE = TAB_MODE.SPACE_4) -> TextFile:
    var tf = TextFile.new(newline_mode_, tab_mode_)
    tf.file = FileAccess.open_compressed(path, flags, compression_mode)
    return tf

static func open_encrypted(path: String, flags: FileAccess.ModeFlags, key: PackedByteArray, iv: PackedByteArray, newline_mode_: NEWLINE_MODE = NEWLINE_MODE.CRLF, tab_mode_: TAB_MODE = TAB_MODE.SPACE_4) -> TextFile:
    var tf = TextFile.new(newline_mode_, tab_mode_)
    tf.file = FileAccess.open_encrypted(path, flags, key, iv)
    return tf

static func open_encrypted_with_pass(path: String, flags: FileAccess.ModeFlags, pass_: String, newline_mode_: NEWLINE_MODE = NEWLINE_MODE.CRLF, tab_mode_: TAB_MODE = TAB_MODE.SPACE_4) -> TextFile:
    var tf = TextFile.new(newline_mode_, tab_mode_)
    tf.file = FileAccess.open_encrypted_with_pass(path, flags, pass_)
    return tf

func close() -> void:
    file.close()

func flush() -> void:
    file.flush()

func write(...vals: Array) -> void:
    writev(vals)

func writev(vals: Array) -> void:
    for v in vals:
        if v is String:
            write_string(v)
        elif v is int:
            write_int(v)
        elif v is float:
            write_float(v)
        elif v is Vector2:
            write_vec2(v)
        elif v is Vector2i:
            write_vec2i(v)
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
            failed = failed or !file.store_8(0x0D)
            failed = failed or !file.store_8(0x0A)
        NEWLINE_MODE.LF:
            failed = failed or !file.store_8(0x0A)

func get_newline_string() -> String:
    match newline_mode:
        NEWLINE_MODE.CRLF: return "\r\n"
        NEWLINE_MODE.LF: return "\n"
        _: return "\n"

func write_tab() -> void:
    match tab_mode:
        TAB_MODE.SPACE_2:
            failed = failed or !file.store_16(0x2020)
        TAB_MODE.SPACE_4:
            failed = failed or !file.store_32(0x20202020)
        TAB_MODE.TAB:
            failed = failed or !file.store_8(0x09)

func get_indent_string() -> String:
    match tab_mode:
        TAB_MODE.SPACE_2: return "  "
        TAB_MODE.SPACE_4: return "    "
        TAB_MODE.TAB: return "\t"
        _: return "    "

func write_n_tabs(n: int) -> void:
    var i: int = 0;
    while i < n:
        write_tab()
        i += 1

func write_string(string: String) -> void:
    failed = failed or !file.store_string(string)

func write_int(val: int) -> void:
    write_string("%d" % val)

func write_float(val: float) -> void:
    write_string("%f" % val)

func write_vec2(val: Vector2) -> void:
    write_string("Vector2(%f, %f)" % [val.x, val.y])

func write_vec2i(val: Vector2i) -> void:
    write_string("Vector2i(%d, %d)" % [val.x, val.y])

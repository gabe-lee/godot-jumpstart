class_name Translations extends RefCounted

# BEGIN TRANSLATION TABLE
const string_FLAT_VALS: PackedStringArray = [
    "continue",
    "progress",
    "play time",
    "stored time",
]

enum MSG {
    FRAG_CONTINUE = 0,
    FRAG_PROGRESS = 1,
    FRAG_PLAY_TIME = 2,
    FRAG_STORED_TIME = 3,
}

enum LANG {
    EN = 0,
}

static func get_string(msg: MSG, lang: LANG) -> String:
    var idx = 0
    idx += (msg * 1) # array stride for level msg
    idx += lang
    return string_FLAT_VALS[idx]
# END TRANSLATION TABLE

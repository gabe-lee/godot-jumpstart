@tool
class_name TranslationTableBuilder extends ScriptFragmentBuilder


func _define_config() -> void:
    self.fragment_name = "Translation Table"

func _define_targets() -> void:
    add_target("res://classes/Translations.gd", "# BEGIN TRANSLATION TABLE", "# END TRANSLATION TABLE", MODE.OVERWRITE_BLOCK)

func _define_code(out: ScriptFileBuilder) -> void:
    out._auto_n_dimension_array(CONST_MODE.CONST, ARRAY_MODE.SAME_TYPES, TYPE_STRING, "string", "", {
        "MSG": PackedStringArray([
            "FRAG_CONTINUE",
            "FRAG_PROGRESS",
            "FRAG_PLAY_TIME",
            "FRAG_STORED_TIME",
        ]),
        "LANG": PackedStringArray([
            "EN",
        ]),
    },
    {
        "FRAG_CONTINUE": {
            "EN": "continue"
        },
        "FRAG_PROGRESS": {
            "EN": "progress"
        },
        "FRAG_PLAY_TIME": {
            "EN": "play time"
        },
        "FRAG_STORED_TIME": {
            "EN": "stored time"
        },
    },
    "<MISSING TRANSLATION>"
    )

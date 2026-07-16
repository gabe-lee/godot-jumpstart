@tool
extends ScriptBuilder

func _set_config() -> void:
    script_class = "ExampleScriptBuilderResult"
    self.write_class_name = false # to prevent the examples from polluting the project namespace
    script_path = "res://addons/file_gen_utils/EDITOR_ONLY/examples/ExampleScriptBuilderResult.gd"

func _serialize_constants(gen: ScriptFileBuilder) -> void:
    gen._comment("EXAMPLE ENUMS")
    gen._enum_advanced(ENUM_MODE.ARRAYS_SAME, "E", "ENTITY", {
        "RAT": {
            "RESISTANCE" : 0.0,
            "MAX_HEALTH": 25.0,
            "SPRITE": "rat.txt",
            "FACTION": 0,
        },
        "GOBLIN": {
            "RESISTANCE" : 0.0,
            "MAX_HEALTH": 100.0,
            "SPRITE": "goblin.txt",
            "FACTION": 1,
            "FACTION_IMPORTANCE": 1.0,
        }
    })
    gen._newline()
    gen._enum_advanced(ENUM_MODE.NATIVE, "DIR", "", DIR)
    gen._newline()
    gen._enum_advanced(ENUM_MODE.NATIVE_BITFLAG, "DAMAGE", "", DAMAGE)
    gen._newline()

    gen._comment("EXAMPLE FLATTENED N-DIMENSIONAL ARRAY")
    gen._comment("THAT CAN BE ACCESSED VIA ENUM KEYS")
    gen._comment("(THIS EXAMPLE IS A TRANSLATION LOOKUP TABLE)")
    gen._auto_n_dimension_array(CONST_MODE.CONST, ARRAY_MODE.SAME_TYPES, TYPE_STRING, "translation", "S", {
        "MSG" : PackedStringArray([
            "WELCOME",
            "LOADING",
            "ERROR",
            "PLAYER_DIALOG_1",
        ]),
        "LANG": PackedStringArray([
            "EN",
            "FR",
            "ES",
            "DE",
            "JP",
        ]),
    },
    {
        "WELCOME": {
            "EN": "HELLO {player}",
            "FR": "Hon hon {player}",
            "ES": "Hola {player",
            "DE": "..."
        },
        "LOADING": {
            "EN": "Loading...",
        },
        "ERROR": {
            "EN": "An error occured: {err_string}",
            "FR": "Sacré bleu!: {err_string}",
        },
        "PLAYER_DIALOG_1": {
            "EN": "Hey, {player}, I see you are new around here"
        }
    },
    "<MISSING TRANSLATION>"
    )
    gen._comment("use the lookup val in your code somewhere like this")
    gen._line("var english_player_dialog_1 = get_translation(S_MSG.PLAYER_DIALOG_1, S_LANG.EN)")
    gen._newline()

    gen._comment("EXAMPLE INLINE CODE FRAGMENTS USED IN 2 DIFFERENT FUCTIONS")
    if gen._method("with_inline_1", [], "int"):
        gen._var("i", TYPE_INT, 0)
        gen._var("a", TYPE_INT, 0)
        gen._inline_block("func_body")
        gen._return("a")
    gen._newline()

    if gen._method("with_inline_2", [], "int"):
        gen._var("i", TYPE_INT, 0)
        gen._var("a", TYPE_INT, 0)
        if gen._while(["i < 10"]):
            gen._inline_block("func_body")
            gen._done()
        gen._return("a")
    gen._newline()

    
    var inl = gen.get_inline_by_id("func_body")
    inl._comment("inline body")
    inl._line("i += 1")
    if inl._if(["i % 2 == 0"]):
        inl._line("i += 1")
        inl._done()
    
    
    gen._comment("EXAMPLE WHILE LOOP WITH AUTO-GENERATED COUNTER AND CONTINUE BLOCKS")
    if gen._static_func("count_weird", [], "void"):
        gen._var("max_count", TYPE_INT, 10)
        if gen._while_auto_loop(VAR.NEW, "count", TYPE_INT, 0, "count < max_count", "count += 1"):
            if gen._if(["count % 5 == 0"]):
                gen._line("count += 3")
                gen._continue_ignore_auto()
            if gen._if(["count % 2 == 0"]):
                gen._continue()
            gen._done()
        gen._return()
    gen._newline()

    gen._comment("EXAMPLE AUTO FOR-IN LOOP OVER MULTIPLE PARALLEL INPUTS")
    if gen._method("test_multi_for_in_auto_loop", [], "void"):
        gen._var("names", TYPE_PACKED_STRING_ARRAY, [])
        gen._var("phone_numbers", TYPE_ARRAY, [])
        gen._var("moneys", TYPE_PACKED_FLOAT32_ARRAY, [])
        if gen._multi_for_in_auto_loop(VAR.NEW, "idx", TYPE_INT, VAR.NEW, "limit", ["name", "phone_number", "money"], ["names", "phone_numbers", "moneys"]):
            if gen._if("money < 0.0"):
                gen._line("print(\"IN DEBT!\")")
                gen._continue()
            gen._line("print(name, phone_number, money)")
            gen._done()
        gen._return()
    gen._newline()
    
    gen._comment("EXAMPLE FINITE STATE MACHINE")
    gen._line("var main: MAIN = MAIN.TITLE")
    gen._line("var game: GAME = GAME.FIELD")
    gen._line("var login_pressed := false")
    gen._line("var save_selected := false")
    gen._line("var pause_pressed := false")
    gen._line("var settings_pressed := false")
    gen._line("var goto_saves_pressed := false")
    gen._line("var quit_game_pressed := false")
    var m = FSM_MODE.LOOP_WITH_SHORT_CIRCUIT_EXTRA_GUARDS
    var c = COMMENT_MODE.INCLUDE_HELPER_COMMENTS
    if gen._func("game_loop", [], "void"):
        if gen._finite_state_machine(m, "main", "MAIN", "EXIT", ["TITLE", "LOGIN", "SELECT_SAVE", "IN_GAME"], c):
            if gen._fsm_branch("TITLE"):
                if gen._if("login_pressed"):
                    gen._fsm_goto("LOGIN")
                if gen._if("quit_game_pressed"):
                    gen._fsm_exit()
                gen._done()
            if gen._fsm_branch("LOGIN"):
                gen._fsm_goto("SELECT_SAVE")
            if gen._fsm_branch("SELECT_SAVE"):
                if gen._if("save_selected"):
                    gen._fsm_goto("IN_GAME")
                gen._done()
            if gen._fsm_branch("IN_GAME"):
                if gen._finite_state_machine(m, "game", "GAME", "EXIT", ["FIELD", "PAUSE", "SETTINGS_MENU"], c):
                    if gen._fsm_branch("FIELD"):
                        if gen._if("pause_pressed"):
                            gen._fsm_goto("PAUSE")
                        if gen._if("settings_pressed"):
                            gen._fsm_goto("SETTINGS_MENU")
                        if gen._if("goto_saves_pressed"):
                            gen._fsm_goto_any("MAIN","SELECT_SAVE")
                        if gen._if("quit_game_pressed"):
                            gen._fsm_exit_all()
                        gen._done()
                    if gen._fsm_branch("PAUSE"):
                        if gen._if("!pause_pressed"):
                            gen._fsm_goto("FIELD")
                        gen._done()
                    if gen._fsm_branch("SETTINGS_MENU"):
                        if gen._if("!settings_pressed"):
                            gen._fsm_goto("FIELD")
                        gen._done()
                    gen._done()
                gen._done()
            gen._done()
        gen._return()

    

enum DIR {
    NORTH,
    SOUTH,
    EAST,
    WEST,
}

enum DAMAGE {
    FIRE,
    POISON,
    PHYSICAL,
}

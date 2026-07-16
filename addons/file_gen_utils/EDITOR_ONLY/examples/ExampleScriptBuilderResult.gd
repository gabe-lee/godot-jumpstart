extends RefCounted

const ExampleScriptBuilderResult = preload("res://addons/file_gen_utils/EDITOR_ONLY/examples/ExampleScriptBuilderResult.gd")
# EXAMPLE ENUMS
enum E {
    RAT,
    GOBLIN,
}

const ENTITY_RESISTANCE: PackedFloat32Array = [
    0.0, # RAT
    0.0, # GOBLIN
]

const ENTITY_MAX_HEALTH: PackedFloat32Array = [
    25.0, # RAT
    100.0, # GOBLIN
]

const ENTITY_SPRITE: PackedStringArray = [
    rat.txt, # RAT
    goblin.txt, # GOBLIN
]

const ENTITY_FACTION: PackedByteArray = [
    0, # RAT
    1, # GOBLIN
]

const ENTITY_FACTION_IMPORTANCE: PackedFloat32Array = [
    0.0, # RAT (DEFAULT)
    1.0, # GOBLIN
]


enum DIR {
    NORTH = 0,
    SOUTH = 1,
    EAST = 2,
    WEST = 3,
}

enum DAMAGE {
    FIRE = 1 << 0,
    POISON = 1 << 1,
    PHYSICAL = 1 << 2,
}

# EXAMPLE FLATTENED N-DIMENSIONAL ARRAY
# THAT CAN BE ACCESSED VIA ENUM KEYS
# (THIS EXAMPLE IS A TRANSLATION LOOKUP TABLE)
const translation_FLAT_VALS: PackedStringArray = [
    "HELLO {player}",
    "Hon hon {player}",
    "Hola {player",
    "...",
    "<MISSING TRANSLATION>",
    "Loading...",
    "<MISSING TRANSLATION>",
    "<MISSING TRANSLATION>",
    "<MISSING TRANSLATION>",
    "<MISSING TRANSLATION>",
    "An error occured: {err_string}",
    "Sacré bleu!: {err_string}",
    "<MISSING TRANSLATION>",
    "<MISSING TRANSLATION>",
    "<MISSING TRANSLATION>",
    "Hey, {player}, I see you are new around here",
    "<MISSING TRANSLATION>",
    "<MISSING TRANSLATION>",
    "<MISSING TRANSLATION>",
    "<MISSING TRANSLATION>",
]

enum S_MSG {
    WELCOME = 0,
    LOADING = 1,
    ERROR = 2,
    PLAYER_DIALOG_1 = 3,
}

enum S_LANG {
    EN = 0,
    FR = 1,
    ES = 2,
    DE = 3,
    JP = 4,
}

static func get_translation(msg: S_MSG, lang: S_LANG) -> String:
    var idx = 0
    idx += (msg * 5) # array stride for level msg
    idx += lang
    return translation_FLAT_VALS[idx]

# use the lookup val in your code somewhere like this
var english_player_dialog_1 = get_translation(S_MSG.PLAYER_DIALOG_1, S_LANG.EN)

# EXAMPLE INLINE CODE FRAGMENTS USED IN 2 DIFFERENT FUCTIONS
func with_inline_1() -> int:
    var i: int = 0
    var a: int = 0
    # inline body
    i += 1
    if i % 2 == 0:
        i += 1
    return a

func with_inline_2() -> int:
    var i: int = 0
    var a: int = 0
    while i < 10 :
        # inline body
        i += 1
        if i % 2 == 0:
            i += 1
    return a

# EXAMPLE WHILE LOOP WITH AUTO-GENERATED COUNTER AND CONTINUE BLOCKS
static func count_weird() -> void:
    var max_count: int = 10
    var count: int = 0
    while count < max_count:
        if count % 5 == 0:
            count += 3
            continue
        if count % 2 == 0:
            count += 1
            continue
        count += 1
    return 

# EXAMPLE AUTO FOR-IN LOOP OVER MULTIPLE PARALLEL INPUTS
func test_multi_for_in_auto_loop() -> void:
    var names: PackedStringArray = []
    var phone_numbers: Array = []
    var moneys: PackedFloat32Array = []
    var idx: int = 0
    var limit := names.size()
    while idx < limit:
        var name = names[idx]
        var phone_number = phone_numbers[idx]
        var money = moneys[idx]
        if money < 0.0:
            print("IN DEBT!")
            idx += 1
            continue
        print(name, phone_number, money)
        idx += 1
    return 

# EXAMPLE FINITE STATE MACHINE
var main: MAIN = MAIN.TITLE
var game: GAME = GAME.FIELD
var login_pressed := false
var save_selected := false
var pause_pressed := false
var settings_pressed := false
var goto_saves_pressed := false
var quit_game_pressed := false
func game_loop() -> void:
    while main != MAIN.EXIT:
        if main == MAIN.TITLE:
            while main == MAIN.TITLE:
                # BEGIN MAIN.TITLE
                if login_pressed:
                    main = MAIN.LOGIN
                    break
                if quit_game_pressed:
                    main = MAIN.EXIT
                    break
                # END MAIN.TITLE
            if main <= MAIN.TITLE: continue
            elif main >= MAIN.EXIT: break
        if main == MAIN.LOGIN:
            while main == MAIN.LOGIN:
                # BEGIN MAIN.LOGIN
                main = MAIN.SELECT_SAVE
                break
                # END MAIN.LOGIN
            if main <= MAIN.LOGIN: continue
            elif main >= MAIN.EXIT: break
        if main == MAIN.SELECT_SAVE:
            while main == MAIN.SELECT_SAVE:
                # BEGIN MAIN.SELECT_SAVE
                if save_selected:
                    main = MAIN.IN_GAME
                    break
                # END MAIN.SELECT_SAVE
            if main <= MAIN.SELECT_SAVE: continue
            elif main >= MAIN.EXIT: break
        if main == MAIN.IN_GAME:
            while main == MAIN.IN_GAME:
                # BEGIN MAIN.IN_GAME
                while game != GAME.EXIT:
                    if game == GAME.FIELD:
                        while game == GAME.FIELD:
                            # BEGIN GAME.FIELD
                            if pause_pressed:
                                game = GAME.PAUSE
                                break
                            if settings_pressed:
                                game = GAME.SETTINGS_MENU
                                break
                            if goto_saves_pressed:
                                main = MAIN.SELECT_SAVE
                                game = GAME.EXIT
                                break
                            if quit_game_pressed:
                                game = GAME.EXIT
                                main = MAIN.EXIT
                                break
                            # END GAME.FIELD
                        if game <= GAME.FIELD: continue
                        elif game >= GAME.EXIT: break
                    if game == GAME.PAUSE:
                        while game == GAME.PAUSE:
                            # BEGIN GAME.PAUSE
                            if !pause_pressed:
                                game = GAME.FIELD
                                break
                            # END GAME.PAUSE
                        if game <= GAME.PAUSE: continue
                        elif game >= GAME.EXIT: break
                    if game == GAME.SETTINGS_MENU:
                        while game == GAME.SETTINGS_MENU:
                            # BEGIN GAME.SETTINGS_MENU
                            if !settings_pressed:
                                game = GAME.FIELD
                                break
                            # END GAME.SETTINGS_MENU
                        if game <= GAME.SETTINGS_MENU: continue
                        elif game >= GAME.EXIT: break
                # END MAIN.IN_GAME
            if main <= MAIN.IN_GAME: continue
            elif main >= MAIN.EXIT: break
    return 

enum MAIN {
    TITLE = 0,
    LOGIN = 1,
    SELECT_SAVE = 2,
    IN_GAME = 3,
    EXIT = 4,
}

enum GAME {
    FIELD = 0,
    PAUSE = 1,
    SETTINGS_MENU = 2,
    EXIT = 3,
}






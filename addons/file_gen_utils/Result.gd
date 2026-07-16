class_name Result extends RefCounted

const PASS = false
const FAIL = true

const INFO := 0
const WARN := 1
const ERROR := 2
const FATAL := 3

const TO_INFO := INFO
const TO_WARN := WARN
const TO_ERROR := ERROR
const TO_FATAL := FATAL

const ANY_IS_UPGRADED := INFO
const WARN_IS_UPGRADED := WARN
const ERROR_IS_UPGRADED := ERROR
const FATAL_IS_UPGRADED := FATAL
const DO_NOT_UPGRADE := 16

enum CACHE {
    FIRST,
    LAST,
    ALL,
}

static var handle_info: Callable = _default_handle_info
static var handle_warn: Callable = _default_handle_warn
static var handle_error: Callable = _default_handle_error
static var handle_fatal: Callable = _default_handle_fatal
static var err_str: Callable = _default_error_str

var state: bool = PASS
var err: int = OK
var err_msg: String = ""
var value: Variant = null
var level: int = ERROR
var cache: CACHE = CACHE.ALL
var default_err_msg: String = "<no error msg provided>"

static func cache_first_failure() -> Result:
    return Result.new()

static func cache_last_failure() -> Result:
    var res = Result.new()
    res.cache = CACHE.LAST
    return res

static func cache_all_failures() -> Result:
    var res = Result.new()
    res.cache = CACHE.ALL
    return res

static func new_check_and_handle(val: Variant, msg_on_fail: String = "", level_: int = ERROR, min_upgrade_level: int = DO_NOT_UPGRADE, upgrade_new_level: int = FATAL) -> bool:
    var res = Result.new()
    res.check(val, msg_on_fail, level_)
    return res.handle_fail(min_upgrade_level, upgrade_new_level)

func clear() -> void:
    state = PASS
    err = OK
    err_msg = ""
    value = null
    level = ERROR
    default_err_msg = "<no error msg provided>"

func check(something: Variant, msg_on_fail: String = "", level_: int = ERROR) -> void:
    failed(something, msg_on_fail, level_)


## Takes a `something`, where `something` can be: [br]
## - Result: combine result into self [br]
## - int: non-zero is failure [br]
## - bool: false is failure [br]
## - other: converted to bool using standard godot semantics [br]
## Returns `true` if a failure occured. This facilitates the following pattern:
## [codeblock]
## if result.failed(func_that_can_fail(), "the function failed", Result.ERROR): return result
## [/codeblock]
func failed(something: Variant, msg_on_fail: String = "", level_: int = ERROR) -> bool:
    if cache != CACHE.FIRST or state == PASS:
        if something is Result:
            value = something.value
            if something.state == FAIL:
                state = FAIL
                err = something.err
                value = something.value
                if cache == CACHE.ALL:
                    err_msg = err_msg + "\n" + (something.err_msg if !something.err_msg.is_empty() else (msg_on_fail if !msg_on_fail.is_empty() else default_err_msg)) + " : " + err_str.call(err)
                    level = maxi(level, something.level)
                else:
                    err_msg = something.err_msg if !something.err_msg.is_empty() else (msg_on_fail if !msg_on_fail.is_empty() else default_err_msg) + " : " + err_str.call(err)
                    level = something.level
        elif something is int:
            if something != OK:
                state = FAIL
                err = something
                if cache == CACHE.ALL:
                    err_msg = err_msg + "\n" + (msg_on_fail if !msg_on_fail.is_empty() else default_err_msg) + " : " + err_str.call(err)
                    level = maxi(level, level_)
                else:
                    err_msg = (msg_on_fail if !msg_on_fail.is_empty() else default_err_msg) + " : " + err_str.call(err)
                    level = level_
        else:
            something = !!something
            if something == false:
                state = FAIL
                err = FAILED
                if cache == CACHE.ALL:
                    err_msg = err_msg + "\n" + (msg_on_fail if !msg_on_fail.is_empty() else default_err_msg) + " : " + err_str.call(err)
                    level = maxi(level, level_)
                else:
                    err_msg = (msg_on_fail if !msg_on_fail.is_empty() else default_err_msg) + " : " + err_str.call(err)
                    level = level_
    return state

func with_val(val: Variant) -> Result:
    value = val
    return self

func with_err(err_: int = FAILED, msg: String = "", level_: int = ERROR) -> Result:
    state = FAIL
    err = err_
    if cache == CACHE.ALL:
        err_msg = err_msg + "\n" + (msg if !msg.is_empty() else default_err_msg) + " : " + err_str.call(err)
        level = maxi(level, level_)
    else:
        err_msg = (msg if !msg.is_empty() else default_err_msg) + " : " + err_str.call(err)
        level = level_
    return self

func is_passing() -> bool:
    return state == PASS

func is_failing() -> bool:
    return state == FAIL

func handle_fail(upgrade_min_level: int = DO_NOT_UPGRADE, upgrade_new_level: int = FATAL) -> bool:
    if state == FAIL:
        if level >= upgrade_min_level:
            level = maxi(INFO, mini(FATAL, upgrade_new_level))
        match level:
            INFO: Result.handle_info.call(self)
            WARN: Result.handle_warn.call(self)
            ERROR: Result.handle_error.call(self)
            FATAL: Result.handle_fatal.call(self)
            _: Result.handle_error.call(self)
        return true
    return false

func handle_fail_with_level(level_: int) -> bool:
    if state == FAIL:
        self.level = maxi(INFO, mini(FATAL, level_))
        match level:
            INFO: Result.handle_info.call(self)
            WARN: Result.handle_warn.call(self)
            ERROR: Result.handle_error.call(self)
            FATAL: Result.handle_fatal.call(self)
            _: Result.handle_error.call(self)
        return true
    return false

static func _default_handle_info(result: Result) -> void:
    print(result.err_msg)

static func _default_handle_warn(result: Result) -> void:
    push_warning(result.err_msg)

static func _default_handle_error(result: Result) -> void:
    push_error(result.err_msg)

static func _default_handle_fatal(result: Result) -> void:
    push_error(result.err_msg)
    assert(false)

static func _default_error_str(err_: int) -> String:
    return error_string(err_)

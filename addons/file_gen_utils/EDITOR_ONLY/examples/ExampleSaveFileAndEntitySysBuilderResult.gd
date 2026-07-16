extends RefCounted

const ExampleSaveFileAndEntitySysBuilderResult = preload("res://addons/file_gen_utils/EDITOR_ONLY/examples/ExampleSaveFileAndEntitySysBuilderResult.gd")
const DATA_MODE := FileFormatUtil.DATA_MODE.ENCRYPTED
const AUTO_SAVE_SOFT_DELAY_SECS: float = 15.0
const AUTO_SAVE_MAX_DELAY_SECS: float = 60.0
const ENCRYPTION_KEY: PackedByteArray = [1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239]
const FMT_SIG: PackedByteArray = [77, 89, 83, 65, 86, 69]
const BIG_ENDIAN: bool = false
const MAX_VERSION: int = 1


signal file_saved(file: ExampleSaveFileAndEntitySysBuilderResult)
signal file_loaded(file: ExampleSaveFileAndEntitySysBuilderResult)


var file_path: String = ""
var format_version: int = MAX_VERSION
var is_open: bool = true
var auto_save_soft_timeout: float = -1.0
var auto_save_max_timeout: float = -1.0
var disable_auto_save: bool = false
var disable_extra_integrity_check: bool = false

var player_hp: float = 100.0:
    set(val):
        player_hp = val
        queue_save()
var player_max_hp: float = 100.0:
    set(val):
        player_max_hp = val
        queue_save()
var player_level: int = 1:
    set(val):
        player_level = val
        queue_save()
var ent_kind: PackedInt64Array = []
var ent_max_health: PackedFloat32Array = []
var ent_curr_health: PackedFloat32Array = []
var ent_global_position: Array[Vector2i] = []
var ent_tile_sub_position: Array[Vector2i] = []
var ent_faction: PackedInt64Array = []
var next_unused_id: int = 1:
    set(val):
        next_unused_id = val
        queue_save()
var num_free_entities: int = 0:
    set(val):
        num_free_entities = val
        queue_save()
var first_free_entity_id: int = 0:
    set(val):
        first_free_entity_id = val
        queue_save()
var entity_free_tracker: PackedInt32Array = []
var entity_gen_tracker: PackedInt32Array = []

func exists() -> bool:
    return FileAccess.file_exists(file_path)

func load(_is_integrity_check: bool = false, _is_integrity_check_on_auto_save: bool = false) -> Result:
    var result := FileFormatUtil.load_common(file_path, DATA_MODE, FileAccess.CompressionMode.COMPRESSION_FASTLZ, PackedByteArray(), ENCRYPTION_KEY, FMT_SIG, MAX_VERSION, BIG_ENDIAN)
    if result.is_failing(): return result
    var did_upgrade = format_version < MAX_VERSION
    if format_version == MAX_VERSION:
        _load_directly(result, result.value.bin_file)
    else:
        _load_to_dict_then_upgrade(result, result.value.bin_file)
    if result.is_failing(): return result
    if did_upgrade:
        result.check(queue_save())
    #region USER POST LOAD
    # this happens immediately after load
    #endregion END USER POST LOAD
    file_loaded.emit(self)
    is_open = true
    return result

func _load_to_dict_then_upgrade(result: Result, file: BinaryFile) -> void:
    assert(format_version < MAX_VERSION)
    var read_routine: Callable = ExampleSaveFileAndEntitySysBuilderResult.PREV_VERSION_READ_ROUTINES[format_version]
    var vals: Dictionary = {}
    read_routine.call(file, vals)
    if result.failed(file.last_error(), FileFormatUtil.FILE_READ_ERROR % file_path ): return
    while format_version < MAX_VERSION:
        var upgrade_routine: Callable = ExampleSaveFileAndEntitySysBuilderResult.PREV_VERSION_UPGRADE_ROUTINES[format_version]
        upgrade_routine.call(vals)
        format_version += 1
    player_hp = vals["player_hp"]
    player_max_hp = vals["player_max_hp"]
    player_level = vals["player_level"]
    ent_kind = vals["ent_kind"]
    ent_max_health = vals["ent_max_health"]
    ent_curr_health = vals["ent_curr_health"]
    ent_global_position = vals["ent_global_position"]
    ent_tile_sub_position = vals["ent_tile_sub_position"]
    ent_faction = vals["ent_faction"]
    next_unused_id = vals["next_unused_id"]
    num_free_entities = vals["num_free_entities"]
    first_free_entity_id = vals["first_free_entity_id"]
    entity_free_tracker = vals["entity_free_tracker"]
    entity_gen_tracker = vals["entity_gen_tracker"]
    return

func _load_directly(result: Result, file: BinaryFile) -> void:
    assert(format_version == MAX_VERSION)
    player_hp = file.read_f32()
    player_max_hp = file.read_f32()
    player_level = file.read_u16()
    ent_kind = file.read_u32_array_len_prefix()
    ent_max_health = file.read_f32_array_len_prefix()
    ent_curr_health = file.read_f32_array_len_prefix()
    ent_global_position = file.read_vec2_i32_array_len_prefix()
    ent_tile_sub_position = file.read_vec2_u8_array_len_prefix()
    ent_faction = file.read_u32_array_len_prefix()
    next_unused_id = file.read_u32()
    num_free_entities = file.read_u32()
    first_free_entity_id = file.read_u32()
    entity_free_tracker = file.read_i32_array_len_prefix()
    entity_gen_tracker = file.read_i32_array_len_prefix()
    result.check(file.last_error(), FileFormatUtil.FILE_READ_ERROR % file_path)
    return

func check_valid() -> Result:
    var result := FileFormatUtil.load_common(file_path, DATA_MODE, FileAccess.CompressionMode.COMPRESSION_FASTLZ, ENCRYPTION_KEY, PackedByteArray(), FMT_SIG, MAX_VERSION, BIG_ENDIAN)
    return result

func queue_save() -> Result:
    var result := Result.cache_first_failure()
    if !is_open: return result
    if !disable_auto_save:
        if auto_save_max_timeout <= 0.0:
            auto_save_max_timeout = AUTO_SAVE_MAX_DELAY_SECS
        auto_save_soft_timeout = AUTO_SAVE_SOFT_DELAY_SECS
        if auto_save_soft_timeout <= 0.0 or auto_save_max_timeout <= 0.0:
            result.check(save(false, true))
    return result

func save_and_close() -> Result:
    return save(true, false)

func save(close_after_save: bool = false, _is_auto_save: bool = false) -> Result:
    assert(format_version == MAX_VERSION)
    var result := Result.cache_first_failure()
    if !is_open: return result
    # USER PRE SAVE
    # this happens immediately before save
    # END USER PRE SAVE
    result.check(FileFormatUtil.save_common_one(file_path, DATA_MODE, FileAccess.CompressionMode.COMPRESSION_FASTLZ, PackedByteArray(), ENCRYPTION_KEY, FMT_SIG, MAX_VERSION, BIG_ENDIAN))
    if result.is_failing(): return result
    var file = result.value
    file.write_f32(player_hp)
    file.write_f32(player_max_hp)
    file.write_u16(player_level)
    file.write_u32_array_len_prefix(ent_kind)
    file.write_f32_array_len_prefix(ent_max_health)
    file.write_f32_array_len_prefix(ent_curr_health)
    file.write_vec2_i32_array_len_prefix(ent_global_position)
    file.write_vec2_u8_array_len_prefix(ent_tile_sub_position)
    file.write_u32_array_len_prefix(ent_faction)
    file.write_u32(next_unused_id)
    file.write_u32(num_free_entities)
    file.write_u32(first_free_entity_id)
    file.write_i32_array_len_prefix(entity_free_tracker)
    file.write_i32_array_len_prefix(entity_gen_tracker)
    FileFormatUtil.save_common_two(result, file, file_path, DATA_MODE)
    if result.is_passing() and !disable_extra_integrity_check:
        var check_clone = clone_metadata_only(true)
        check_clone.file_path = check_clone.file_path + ".tmp"
        result.check(check_clone.load(true))
        result.check(self.data_equals(check_clone), FileFormatUtil.DATA_INTEGRITY_FAIL % file_path)
    FileFormatUtil.save_common_three(result, file_path)
    # USER POST SAVE
    # this happens immediately after save
    # END USER POST SAVE
    if result.is_passing():
        auto_save_max_timeout = -1.0
        auto_save_soft_timeout = -1.0
        if !close_after_save:
            file_saved.emit(self)
        else:
            is_open = false
    return result

func delete(send_to_trash: bool = false) -> Result:
    var result := Result.cache_first_failure()
    if !FileAccess.file_exists(file_path): return result.with_err(ERR_FILE_NOT_FOUND, FileFormatUtil.FILE_DOESNT_EXIST % file_path)
    if send_to_trash:
        result.check(OS.move_to_trash(file_path), FileFormatUtil.COULDNT_SEND_FILE_TO_TRASH % file_path)
    else:
        result.check(DirAccess.remove_absolute(file_path), FileFormatUtil.COULDNT_DELETE_FILE % file_path)
    return result

func clone_metadata_only(disable_autosave_on_clone: bool = false) -> ExampleSaveFileAndEntitySysBuilderResult:
    var new_self := ExampleSaveFileAndEntitySysBuilderResult.new(self.file_path)
    new_self.format_version = self.format_version
    new_self.disable_auto_save = self.disable_auto_save or disable_autosave_on_clone
    new_self.disable_extra_integrity_check = self.disable_extra_integrity_check
    return new_self

func data_equals(other: ExampleSaveFileAndEntitySysBuilderResult, _is_integrity_check: bool = false) -> bool:
    # USER PRE INTEGRITY CHECK
    # this happens before the save integrity check
    # END USER PRE INTEGRITY CHECK
    if other.player_hp != self.player_hp: return false
    if other.player_max_hp != self.player_max_hp: return false
    if other.player_level != self.player_level: return false
    if other.ent_kind != self.ent_kind: return false
    if other.ent_max_health != self.ent_max_health: return false
    if other.ent_curr_health != self.ent_curr_health: return false
    if other.ent_global_position != self.ent_global_position: return false
    if other.ent_tile_sub_position != self.ent_tile_sub_position: return false
    if other.ent_faction != self.ent_faction: return false
    if other.next_unused_id != self.next_unused_id: return false
    if other.num_free_entities != self.num_free_entities: return false
    if other.first_free_entity_id != self.first_free_entity_id: return false
    if other.entity_free_tracker != self.entity_free_tracker: return false
    if other.entity_gen_tracker != self.entity_gen_tracker: return false
    return true


func _init(path: String) -> void:
    file_path = path
    return 

func _process(delta: float) -> void:
    if !disable_auto_save:
        var need_save := false
        if auto_save_max_timeout >= 0.0:
            auto_save_max_timeout -= delta
            need_save = true
        if auto_save_soft_timeout >= 0.0:
            auto_save_soft_timeout -= delta
            need_save = true
        if need_save and (auto_save_soft_timeout <= 0.0 or auto_save_max_timeout <= 0.0):
            var result = save(false, true)
            result.handle_fail()
    return 

static func read_ver_0(file: BinaryFile, vals: Dictionary) -> void:
    vals["player_max_hp"] = file.read_f32()
    vals["player_hp"] = file.read_f32()
    vals["ent_kind"] = file.read_u32_array_len_prefix()
    vals["ent_max_health"] = file.read_f32_array_len_prefix()
    vals["ent_curr_health"] = file.read_f32_array_len_prefix()
    vals["ent_global_position"] = file.read_vec2_i32_array_len_prefix()
    vals["ent_tile_sub_position"] = file.read_vec2_u8_array_len_prefix()
    vals["ent_faction"] = file.read_u32_array_len_prefix()

static func upgrade_ver_0(vals: Dictionary) -> void:
    pass
    pass


signal player_died

const HP_REGEN := 5.0

func hurt_player(amount: float) -> void:
    player_hp -= amount
    if player_hp <= 0.0:
        player_hp = 0.0
        player_died.emit()


enum ENT_KIND {
    NONE,
    R_CRYSTAL,
    P_PLAYER,
    E_RAT_SMALL,
    E_GOBLIN_SMALL,
}

enum ENT_FACTION {
    NONE,
    PLAYER_PARTY,
    TOWN,
    RATS,
    GOBLINS,
}

func entity_exists(ent_id: Vector2i) -> bool:
    if ent_id.x <= 0 or ent_id.x >= next_unused_id: return false
    if entity_gen_tracker[ent_id.x] != ent_id.y: return false
    var free_sub_idx := ent_id.x & 63
    var free_block_idx := ent_id.x >> 6
    var is_free_block = entity_free_tracker[free_block_idx]
    var is_free = ((is_free_block >> free_sub_idx) & 1) == 1
    if is_free: return false
    return true

func create_entity() -> Vector2i:
    var ent_id: Vector2i
    if num_free_entities > 0:
        var first_free: int = first_free_entity_id
        var next_free: int = ent_kind[first_free]
        first_free_entity_id = next_free
        num_free_entities -= 1
        var free_sub_idx: int = first_free & 63
        var free_block_idx: int= first_free >> 6
        var is_free_block = entity_free_tracker[free_block_idx]
        is_free_block = is_free_block & (~(1 << free_sub_idx))
        entity_free_tracker[free_block_idx] = is_free_block
        var gen = entity_gen_tracker[first_free]
        ent_id = Vector2i(first_free, gen)
    else:
        if next_unused_id >= ent_kind.size():
            _grow_all_props_flat()
        var gen = entity_gen_tracker[next_unused_id]
        var id_ = next_unused_id
        next_unused_id += 1
        ent_id = Vector2i(id_, gen)
    # USER ENTITY POST CREATE
    # post create
    # END USER ENTITY POST CREATE
    return ent_id

func destroy_entity(ent_id: Vector2i) -> bool:
    if !entity_exists(ent_id): return false
    # USER ENTITY PRE DELETE
    # pre delete
    # END USER ENTITY PRE DELETE
    var num_free_ent_bits = entity_free_tracker.size() << 6
    if num_free_entities >= num_free_ent_bits:
        entity_free_tracker.push_back(0)
        var this_free: int = ent_id.x
        var next_free: int = first_free_entity_id
        ent_kind[this_free] = next_free
        first_free_entity_id = this_free
        num_free_entities += 1
        var free_sub_idx: int = this_free & 63
        var free_block_idx: int= this_free >> 6
        var is_free_block = entity_free_tracker[free_block_idx]
        is_free_block = is_free_block | (1 << free_sub_idx)
        entity_free_tracker[free_block_idx] = is_free_block
    return true

func _reinit_prop_lists_to_pow2() -> void:
    var old_count = next_unused_id
    var mask = 32 - 1
    var new_count = (old_count + mask) & ~mask
    _resize_all_props(old_count, new_count)

func _grow_all_props_flat() -> void:
    var old_count = next_unused_id
    var new_count = old_count + 32
    _resize_all_props(old_count, new_count)

func _resize_all_props(old_count: int, new_count: int) -> void:
    if old_count == new_count: return
    assert(new_count == 0 or ((new_count - 1) & new_count == 0), "when growing entity arrays, new_count was expected to be a power of 2 but it wasnt")
    ent_kind.resize(new_count)
    ent_max_health.resize(new_count)
    ent_curr_health.resize(new_count)
    ent_global_position.resize(new_count)
    ent_tile_sub_position.resize(new_count)
    ent_faction.resize(new_count)
    var g := entity_gen_tracker.size()
    if g < new_count:
        entity_gen_tracker.resize(new_count)
        while g < new_count:
            entity_gen_tracker[g] = 0
            g += 1
    else:
        while g > new_count:
            g -= 1
            entity_gen_tracker[g] = (entity_gen_tracker[g] + 1) % INT32_MAX
    if old_count < new_count:
        while old_count < new_count:
            var ent_id = Vector2i(old_count, 0)
            set_kind(ent_id, 0, true)
            set_max_health(ent_id, 100.0, true)
            set_curr_health(ent_id, 0.0, true)
            set_global_position(ent_id, Vector2i(0, 0), true)
            set_tile_sub_position(ent_id, Vector2i(0, 0), true)
            set_faction(ent_id, ENT_FACTION.NONE, true)
            old_count += 1
    else:
        while old_count > new_count:
            old_count -= 1
            var ent_id = Vector2i(old_count, entity_gen_tracker[old_count])
            if entity_exists(ent_id):
                destroy_entity(ent_id)

func get_kind(ent_id: Vector2i, default: int = 0) -> int:
    if !entity_exists(ent_id): return default
    var val = ent_kind[ent_id.x]
    return val

func set_kind(ent_id: Vector2i, val: int, force: bool = false) -> bool:
    if !force and !entity_exists(ent_id): return false
    ent_kind[ent_id.x] = val
    return true

func get_max_health(ent_id: Vector2i, default: float = 100.0) -> float:
    if !entity_exists(ent_id): return default
    var val = ent_max_health[ent_id.x]
    return val

func set_max_health(ent_id: Vector2i, val: float, force: bool = false) -> bool:
    if !force and !entity_exists(ent_id): return false
    ent_max_health[ent_id.x] = val
    return true

func get_curr_health(ent_id: Vector2i, default: float = 0.0) -> float:
    if !entity_exists(ent_id): return default
    var val = ent_curr_health[ent_id.x]
    return val

func set_curr_health(ent_id: Vector2i, val: float, force: bool = false) -> bool:
    if !force and !entity_exists(ent_id): return false
    ent_curr_health[ent_id.x] = val
    return true

func get_global_position(ent_id: Vector2i, default: Vector2i = Vector2i(0, 0)) -> Vector2i:
    if !entity_exists(ent_id): return default
    var val = ent_global_position[ent_id.x]
    return val

func set_global_position(ent_id: Vector2i, val: Vector2i, force: bool = false) -> bool:
    if !force and !entity_exists(ent_id): return false
    ent_global_position[ent_id.x] = val
    return true

func get_tile_sub_position(ent_id: Vector2i, default: Vector2i = Vector2i(0, 0)) -> Vector2i:
    if !entity_exists(ent_id): return default
    var val = ent_tile_sub_position[ent_id.x]
    return val

func set_tile_sub_position(ent_id: Vector2i, val: Vector2i, force: bool = false) -> bool:
    if !force and !entity_exists(ent_id): return false
    ent_tile_sub_position[ent_id.x] = val
    return true

func get_faction(ent_id: Vector2i, default: ENT_FACTION = ENT_FACTION.NONE) -> ENT_FACTION:
    if !entity_exists(ent_id): return default
    var val = ent_faction[ent_id.x]
    return val

func set_faction(ent_id: Vector2i, val: ENT_FACTION, force: bool = false) -> bool:
    if !force and !entity_exists(ent_id): return false
    ent_faction[ent_id.x] = val
    return true
static var PREV_VERSION_READ_ROUTINES: Array[Callable] = [
    read_ver_0,
]:
    set(v): assert(false)

static var PREV_VERSION_UPGRADE_ROUTINES: Array[Callable] = [
    upgrade_ver_0,
]:
    set(v): assert(false)


extends RefCounted

const EntitySystem = preload("res://addons/file_gen_utils/EDITOR_ONLY/examples/ExampleFatEntitySystemBuilderResult.gd")


var ent_kind: PackedInt64Array = []
var ent_max_health: PackedFloat32Array = []
var ent_curr_health: PackedFloat32Array = []
var ent_global_position: Array[Vector2i] = []
var ent_tile_sub_position: Array[Vector2i] = []
var ent_faction: PackedInt64Array = []
var next_unused_id: int = 1
var num_free_entities: int = 0
var first_free_entity_id: int = 0
var entity_free_tracker: PackedInt32Array = []
var entity_gen_tracker: PackedInt32Array = []


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

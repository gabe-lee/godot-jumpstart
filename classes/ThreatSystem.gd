class_name ThreatSystem extends RefCounted



var thr_owner_entity: PackedInt32Array = []
var thr_prev_threat: Array[Vector2i] = []
var thr_next_threat: Array[Vector2i] = []
var thr_amount: PackedFloat32Array = []
var next_unused_id: int = 1
var num_free_entities: int = 0
var first_free_entity_id: int = 0
var threat_free_tracker: PackedInt32Array = []
var threat_gen_tracker: PackedInt32Array = []


func add_new_threat(owner: Vector2i, prev_threat_id: Vector2i, amount: float) -> Vector2i:
    var new_id = create_entity()
    var prev_id_next = get_next_threat(prev_threat_id)
    assert(prev_id_next == Vector2i.ZERO, "prev_theat_id wasnt the last in its list")
    set_next_threat(prev_threat_id, new_id)
    set_prev_threat(new_id, prev_threat_id)
    set_amount(new_id, amount)
    set_owner_entity(new_id, owner.x)
    sort_single_threat(new_id)
    return new_id

func sort_single_threat(id: Vector2i) -> void:
    pass

func entity_exists(ent_id: Vector2i) -> bool:
    if ent_id.x <= 0 or ent_id.x >= next_unused_id: return false
    if threat_gen_tracker[ent_id.x] != ent_id.y: return false
    var free_sub_idx := ent_id.x & 63
    var free_block_idx := ent_id.x >> 6
    var is_free_block = threat_free_tracker[free_block_idx]
    var is_free = ((is_free_block >> free_sub_idx) & 1) == 1
    if is_free: return false
    return true

func create_entity() -> Vector2i:
    var ent_id: Vector2i
    if num_free_entities > 0:
        var first_free: int = first_free_entity_id
        var next_free: int = thr_owner_entity[first_free]
        first_free_entity_id = next_free
        num_free_entities -= 1
        var free_sub_idx: int = first_free & 63
        var free_block_idx: int= first_free >> 6
        var is_free_block = threat_free_tracker[free_block_idx]
        is_free_block = is_free_block & (~(1 << free_sub_idx))
        threat_free_tracker[free_block_idx] = is_free_block
        var gen = threat_gen_tracker[first_free]
        ent_id = Vector2i(first_free, gen)
    else:
        if next_unused_id >= thr_owner_entity.size():
            _grow_all_props_flat()
        var gen = threat_gen_tracker[next_unused_id]
        var id_ = next_unused_id
        next_unused_id += 1
        ent_id = Vector2i(id_, gen)
    # USER ENTITY POST CREATE
    # pre create
    # END USER ENTITY POST CREATE
    return ent_id

func destroy_entity(ent_id: Vector2i) -> bool:
    if !entity_exists(ent_id): return false
    # USER ENTITY PRE DELETE
    # post delete
    # END USER ENTITY PRE DELETE
    var num_free_ent_bits = threat_free_tracker.size() << 6
    if num_free_entities >= num_free_ent_bits:
        threat_free_tracker.push_back(0)
        var this_free: int = ent_id.x
        var next_free: int = first_free_entity_id
        thr_owner_entity[this_free] = next_free
        first_free_entity_id = this_free
        num_free_entities += 1
        var free_sub_idx: int = this_free & 63
        var free_block_idx: int= this_free >> 6
        var is_free_block = threat_free_tracker[free_block_idx]
        is_free_block = is_free_block | (1 << free_sub_idx)
        threat_free_tracker[free_block_idx] = is_free_block
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
    thr_owner_entity.resize(new_count)
    thr_prev_threat.resize(new_count)
    thr_next_threat.resize(new_count)
    thr_amount.resize(new_count)
    var g := threat_gen_tracker.size()
    if g < new_count:
        threat_gen_tracker.resize(new_count)
        while g < new_count:
            threat_gen_tracker[g] = 0
            g += 1
    else:
        while g > new_count:
            g -= 1
            threat_gen_tracker[g] = (threat_gen_tracker[g] + 1) % INT32_MAX
    if old_count < new_count:
        while old_count < new_count:
            var ent_id = Vector2i(old_count, 0)
            set_owner_entity(ent_id, 0, true)
            set_prev_threat(ent_id, Vector2i.ZERO, true)
            set_next_threat(ent_id, Vector2i.ZERO, true)
            set_amount(ent_id, 0.0, true)
            old_count += 1
    else:
        while old_count > new_count:
            old_count -= 1
            var ent_id = Vector2i(old_count, threat_gen_tracker[old_count])
            if entity_exists(ent_id):
                destroy_entity(ent_id)

func get_owner_entity(ent_id: Vector2i, default: int = 0) -> int:
    if !entity_exists(ent_id): return default
    var val = thr_owner_entity[ent_id.x]
    return val

func set_owner_entity(ent_id: Vector2i, val: int, force: bool = false) -> bool:
    if !force and !entity_exists(ent_id): return false
    thr_owner_entity[ent_id.x] = val
    return true

func get_prev_threat(ent_id: Vector2i, default: Vector2i = Vector2i.ZERO) -> Vector2i:
    if !entity_exists(ent_id): return default
    var val = thr_prev_threat[ent_id.x]
    return val

func set_prev_threat(ent_id: Vector2i, val: Vector2i, force: bool = false) -> bool:
    if !force and !entity_exists(ent_id): return false
    thr_prev_threat[ent_id.x] = val
    return true

func get_next_threat(ent_id: Vector2i, default: Vector2i = Vector2i.ZERO) -> Vector2i:
    if !entity_exists(ent_id): return default
    var val = thr_next_threat[ent_id.x]
    return val

func set_next_threat(ent_id: Vector2i, val: Vector2i, force: bool = false) -> bool:
    if !force and !entity_exists(ent_id): return false
    thr_next_threat[ent_id.x] = val
    return true

func get_amount(ent_id: Vector2i, default: float = 0.0) -> float:
    if !entity_exists(ent_id): return default
    var val = thr_amount[ent_id.x]
    return val

func set_amount(ent_id: Vector2i, val: float, force: bool = false) -> bool:
    if !force and !entity_exists(ent_id): return false
    thr_amount[ent_id.x] = val
    return true

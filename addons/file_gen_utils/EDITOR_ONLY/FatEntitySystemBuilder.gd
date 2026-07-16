@tool
class_name FatEntitySystemBuilder extends FileFormatBuilder

enum CHANGE_TRACKER {
    NONE,
    ONE_BIT_WHOLE_ENTITY,
    ONE_BIT_PER_PROPERTY,
}

## If `true`, if any property on an entity is changed, it sets a one-bit flag 
## until `clear_updates()` is called
var include_entity_any_property_changed_tracker: bool = false:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        include_entity_any_property_changed_tracker = v
## Optional code to run inside the `_process(delta: float)` function
## before any individual entity process is run
## [br]
## If the entity manager does not inherit from `Node`, you must call `_process()` manually
var user_process_code_before_entity_process: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_process_code_before_entity_process = v
## Optional code to run inside the `_process(delta: float)` function
## before any individual entity process is run
## [br]
## If the entity manager does not inherit from `Node`, you must call `_process()` manually
var user_process_code_after_entity_process: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_process_code_after_entity_process = v
## Optional code to run inside the `_process(delta: float)` function
## for every given entity.
## [br]
## In addition to `delta`, a variable named `ent_id` (int) will be in scope to
## access the entity properties 
## [br]
## If the entity manager does not inherit from `Node`, you must call `_process()` manually
var user_entity_process_code: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_entity_process_code = v
## Optional code to run immediately before deleting an entity
## [br]
## A variable named `ent_id` (int) will be in scope to
## access the entity properties
var user_entity_pre_delete_code: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_entity_pre_delete_code = v
## Optional code to run immediately after creating an entity
## [br]
## A variable named `ent_id` (int) will be in scope to
## access the entity properties
var user_entity_post_create_code: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_entity_post_create_code = v
## If the entity property lists need to grow, grow them by this amount
## [br]
## A larger value will allow fewer reallocations at the cost of more (potentially wasted) memory
## [br]
## MUST be a power of 2 AND >= 8 for mathmatical reasons
var property_list_flat_grow_amount: int = 32:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        assert(v > 0 and (v & (v - 1)) == 0, "property_list_flat_grow_amount is not a power of 2!")
        assert(v >= 8, "property_list_flat_grow_amount must be >= 8!")
        property_list_flat_grow_amount = v
## Optional code that will be written inside the sub-class defined by `entity_ref_class_name`
## [br]
## An `id` field exists on the sub-class, and each property has a `<property_name>()` getter and
## `set_<property_name>(val)` setter
var user_entity_ref_script_body_code: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        user_entity_ref_script_body_code = v
## If, for some god-forsaken reason you are serializing an FES to a text ConfigFile,
## this is the section all the arrays will be put...
var entity_arrays_config_file_section: String = "ENTITY_DATA":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        entity_arrays_config_file_section = v
## The name for the special property that tracks whether an entity is free or not
var entity_free_tracker_name: String = "entity_free_tracker":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        entity_free_tracker_name = v
## When an entity is freed, the entity manager hijacks/repurposes this EXACT property on the entity
## as a property that points to the 'next free entity id', if any
## [br]
## It MUST be a scalar (single) integer type, and it must be at least a Uint32 or Int32 or larger.
## [br]
## Every entity manager MUST have at least one one property that fulfils this condition, and
## it MUST be present in the 'current' version of the manager/file-format
var entity_next_free_property: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        entity_next_free_property = v
## If `include_entity_generation` is true, this is the name of the generation tracking array
var entity_gen_tracker_name: String = "entity_gen_tracker":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        entity_gen_tracker_name = v
## The name of the special 'number of free entities' property
var num_free_entities_name: String = "num_free_entities":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        num_free_entities_name = v
    ## The name of the special 'first free entity id' property
var first_free_entity_name: String = "first_free_entity_id":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        first_free_entity_name = v
## The name of the special 'next unused entity id' property
var next_unused_id_name: String = "next_unused_id":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        next_unused_id_name = v
## If `true`, an additional array will be created that tracks the 'generation' of an entity.
## [br]
## In this way you can strictly prevent the following logic error:
## [br]
## - An object holds an entity id with value 1 [br]
## - Entity 1 is deleted and id 1 is sent to the free pool [br]
## - The object does not yet use any of the entity's values and is not alerted that it is invalid [br]
## - A new entity is requested and entity id 1 is free to host the new entity [br]
## - The object now holds a VALID reference to a completely unrelated entity (both with id 1, but completely separate) [br]
var include_entity_generation: bool = false:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        include_entity_generation = v
## This string will be prepended to all entity property arrays (useful for preventing colisions with a parent file format)
var entity_property_prefix: String = "":
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        entity_property_prefix = v
## Strip the `entity_property_prefix` from the getter/setter function names
var strip_property_prefix_from_getters_setters: bool = true:
    set(v):
        assert(_in_mode == M_CONFIG, "you can only set the configuration variables inside the `_set_config()` function")
        strip_property_prefix_from_getters_setters = v

func _pre_serialize() -> void:
    _create_entity_system_code()

func _write_queue_save(out: StringBuilder, indent: int) -> void:
    if !completely_omit_serialization_code and automatically_save:
        out.write_indented_line(indent, "queue_save().handle_fail()")

func _create_entity_system_code() -> void:
    assert(_in_mode == M_PRE_SERIALIZE)
    var out = StringBuilder.new(newline_mode as StringBuilder.NEWLINE_MODE, tab_mode as StringBuilder.TAB_MODE)
    var id_type = "Vector2i" if include_entity_generation else "int"
    var idx = "ent_id.x" if include_entity_generation else "ent_id"
    var gen = "ent_id.y" if include_entity_generation else ""
    # USER BODY
    out.write_string(user_script_body)
    out.write_newline()

    var found_free_ptr_prop: bool = false
    for id in _version_val_layouts[_num_versions - 1]:
        var n = _val_names[id]
        if n == entity_next_free_property:
            var t = _val_types[id]
            assert(t == TYPE_UTIL.T.Uint32 or t == TYPE_UTIL.T.Int32 or t == TYPE_UTIL.T.Uint63 or t == TYPE_UTIL.T.Int64, "entity property '%s' is set to be used for the 'next free entity id' property (when entity is free), but it wasnt a Uint32, Int32, Uint63, or Int64... got `%s` instead" % [entity_next_free_property, TYPE_UTIL.T.find_key(t)])
            found_free_ptr_prop = true
    assert(found_free_ptr_prop, "did not find REQUIRED entity property '%s' in the current version (used for 'next free entity id' field when entity is free)")

    _in_mode = M_REGISTER_PROPS
    _version_val_layouts[_num_versions - 1].append(_num_vals)
    register_named_value(Val.single_val(_num_vals, next_unused_id_name, TYPE_UTIL.T.Uint32, 1))
    _version_val_layouts[_num_versions - 1].append(_num_vals)
    register_named_value(Val.single_val(_num_vals, num_free_entities_name, TYPE_UTIL.T.Uint32, 0))
    _version_val_layouts[_num_versions - 1].append(_num_vals)
    register_named_value(Val.single_val(_num_vals, first_free_entity_name, TYPE_UTIL.T.Uint32, 0))
    _version_val_layouts[_num_versions - 1].append(_num_vals)
    register_named_value(Val.array(_num_vals, entity_free_tracker_name, TYPE_UTIL.T.Int32, []).omit_setter())
    if include_entity_generation:
        _version_val_layouts[_num_versions - 1].append(_num_vals)
        register_named_value(Val.array(_num_vals, entity_gen_tracker_name, TYPE_UTIL.T.Int32, []).omit_setter())
    _in_mode = M_PRE_SERIALIZE

    out.write_line("func entity_exists(ent_id: ",id_type,") -> bool:")
    out.write_indented_line(1, "if ",idx," <= 0 or ",idx," >= ", next_unused_id_name, ": return false")
    if include_entity_generation:
        out.write_indented_line(1, "if ", entity_gen_tracker_name, "[",idx,"] != ",gen,": return false")
    out.write_indented_line(1, "var free_sub_idx := ", idx, " & 63")
    out.write_indented_line(1, "var free_block_idx := ", idx, " >> 6")
    out.write_indented_line(1, "var is_free_block = ", entity_free_tracker_name, "[free_block_idx]")
    out.write_indented_line(1, "var is_free = ((is_free_block >> free_sub_idx) & 1) == 1")
    out.write_indented_line(1, "if is_free: return false")
    out.write_indented_line(1, "return true")
    out.write_newline()

    out.write_line("func create_entity() -> ",id_type,":")
    out.write_indented_line(1, "var ent_id: ", id_type)
    out.write_indented_line(1, "if ", num_free_entities_name, " > 0:")
    out.write_indented_line(2, "var first_free: int = ", first_free_entity_name)
    out.write_indented_line(2, "var next_free: int = ", entity_next_free_property, "[first_free]")
    out.write_indented_line(2, first_free_entity_name, " = next_free")
    out.write_indented_line(2, num_free_entities_name, " -= 1")
    out.write_indented_line(2, "var free_sub_idx: int = first_free & 63")
    out.write_indented_line(2, "var free_block_idx: int= first_free >> 6")
    out.write_indented_line(2, "var is_free_block = ", entity_free_tracker_name, "[free_block_idx]")
    out.write_indented_line(2, "is_free_block = is_free_block & (~(1 << free_sub_idx))")
    out.write_indented_line(2, entity_free_tracker_name, "[free_block_idx] = is_free_block")
    if include_entity_generation:
        out.write_indented_line(2, "var gen = ", entity_gen_tracker_name, "[first_free]")
        out.write_indented_line(2, "ent_id = Vector2i(first_free, gen)")
    else:
        out.write_indented_line(2, "ent_id = first_free")
    out.write_indented_line(1, "else:")
    out.write_indented_line(2, "if ", next_unused_id_name, " >= ", entity_next_free_property, ".size():")
    out.write_indented_line(3, "_grow_all_props_flat()")
    if include_entity_generation:
        out.write_indented_line(2, "var gen = ", entity_gen_tracker_name, "[",next_unused_id_name,"]")
        out.write_indented_line(2, "var id_ = ", next_unused_id_name)
        out.write_indented_line(2, next_unused_id_name, " += 1")
        out.write_indented_line(2, "ent_id = Vector2i(id_, gen)")
    else:
        out.write_indented_line(2, "ent_id = ", next_unused_id_name)
        out.write_indented_line(2, next_unused_id_name, " += 1")
    if user_entity_post_create_code.length() > 0:
        out.write_indented_line(1, "# USER ENTITY POST CREATE")
        ScriptFileBuilder.clean_and_write_string(user_entity_post_create_code, out, 1)
        out.write_indented_line(1, "# END USER ENTITY POST CREATE")
    if automatically_save:
        _write_queue_save(out, 1)
    out.write_indented_line(1, "return ent_id")
    out.write_newline()

    out.write_line("func destroy_entity(ent_id: ",id_type,") -> bool:")
    out.write_indented_line(1, "if !entity_exists(ent_id): return false")
    if user_entity_pre_delete_code.length() > 0:
        out.write_indented_line(1, "# USER ENTITY PRE DELETE")
        ScriptFileBuilder.clean_and_write_string(user_entity_pre_delete_code, out, 1)
        out.write_indented_line(1, "# END USER ENTITY PRE DELETE")
    out.write_indented_line(1, "var num_free_ent_bits = ",entity_free_tracker_name,".size() << 6")
    out.write_indented_line(1, "if ", num_free_entities_name, " >= num_free_ent_bits:")
    out.write_indented_line(2, entity_free_tracker_name,".push_back(0)")
    out.write_indented_line(2, "var this_free: int = ", idx)
    out.write_indented_line(2, "var next_free: int = ", first_free_entity_name)
    out.write_indented_line(2, entity_next_free_property, "[this_free] = next_free")
    out.write_indented_line(2, first_free_entity_name, " = this_free")
    out.write_indented_line(2, num_free_entities_name, " += 1")
    out.write_indented_line(2, "var free_sub_idx: int = this_free & 63")
    out.write_indented_line(2, "var free_block_idx: int= this_free >> 6")
    out.write_indented_line(2, "var is_free_block = ", entity_free_tracker_name, "[free_block_idx]")
    out.write_indented_line(2, "is_free_block = is_free_block | (1 << free_sub_idx)")
    out.write_indented_line(2, entity_free_tracker_name, "[free_block_idx] = is_free_block")
    if automatically_save:
        _write_queue_save(out, 1)
    out.write_indented_line(1, "return true")
    out.write_newline()

    out.write_line("func _reinit_prop_lists_to_pow2() -> void:")
    out.write_indented_line(1, "var old_count = ", next_unused_id_name)
    out.write_indented_line(1, "var mask = ", property_list_flat_grow_amount, " - 1")
    out.write_indented_line(1, "var new_count = (old_count + mask) & ~mask")
    out.write_indented_line(1, "_resize_all_props(old_count, new_count)")
    out.write_newline()

    out.write_line("func _grow_all_props_flat() -> void:")
    out.write_indented_line(1, "var old_count = ", next_unused_id_name)
    out.write_indented_line(1, "var new_count = old_count + ",property_list_flat_grow_amount)
    out.write_indented_line(1, "_resize_all_props(old_count, new_count)")
    out.write_newline()

    out.write_line("func _resize_all_props(old_count: int, new_count: int) -> void:")
    out.write_indented_line(1, "if old_count == new_count: return")
    out.write_indented_line(1, "assert(new_count == 0 or ((new_count - 1) & new_count == 0), \"when growing entity arrays, new_count was expected to be a power of 2 but it wasnt\")")
    if _at_least_one_sub_bit_prop:
        out.write_indented_line(1, "var real_count")
    var p := 0
    while p < _num_props_defined:
        var bit_size = _entity_prop_bit_sizes[p]
        var name = _val_names[p]
        if bit_size > 0:
            assert(bit_size == 1 or bit_size == 2 or bit_size == 4)
            match bit_size:
                1:
                    out.write_indented_line(1, "real_count = new_count >> 3")
                2:
                    out.write_indented_line(1, "real_count = new_count >> 2")
                4:
                    out.write_indented_line(1, "real_count = new_count >> 1")
            out.write_indented_line(1, name, ".resize(real_count)")
        else:
            out.write_indented_line(1, name, ".resize(new_count)")
        p += 1
    if include_entity_generation:
        out.write_indented_line(1, "var g := ", entity_gen_tracker_name, ".size()")
        out.write_indented_line(1, "if g < new_count:")
        out.write_indented_line(2, entity_gen_tracker_name, ".resize(new_count)")
        out.write_indented_line(2, "while g < new_count:")
        out.write_indented_line(3, entity_gen_tracker_name, "[g] = 0")
        out.write_indented_line(3, "g += 1")
        out.write_indented_line(1, "else:")
        out.write_indented_line(2, "while g > new_count:")
        out.write_indented_line(3, "g -= 1")
        out.write_indented_line(3, entity_gen_tracker_name, "[g] = (",entity_gen_tracker_name, "[g] + 1) % INT32_MAX")
        
    p = 0

    out.write_indented_line(1, "if old_count < new_count:")
    out.write_indented_line(2, "while old_count < new_count:")
    if include_entity_generation:
        out.write_indented_line(3, "var ent_id = ",id_type,"(old_count, 0)")
    else:
        out.write_indented_line(3, "var ent_id = count")
    while p < _num_props_defined:
        var name = _val_names[p]
        var is_id = _entity_prop_is_prop[p]
        if strip_property_prefix_from_getters_setters:
            name = name.trim_prefix(entity_property_prefix)
        var default_str: String = id_zero() if is_id else default_entity_val_string(p)
        out.write_indented_line(3, "set_",name, "(ent_id, ", default_str, ", true)")
        p += 1
    out.write_indented_line(3, "old_count += 1")
    out.write_indented_line(1, "else:")
    out.write_indented_line(2, "while old_count > new_count:")
    out.write_indented_line(3, "old_count -= 1")
    if include_entity_generation:
        out.write_indented_line(3, "var ent_id = ",id_type,"(old_count, ",entity_gen_tracker_name,"[old_count])")
    else:
        out.write_indented_line(3, "var ent_id = count")
    out.write_indented_line(3, "if entity_exists(ent_id):")
    out.write_indented_line(4, "destroy_entity(ent_id)")
    if automatically_save:
        _write_queue_save(out, 1)
    out.write_newline()
    
    p = 0
    while p < _num_props_defined:
        var getter = _entity_prop_getters[p]
        var pre_set = _entity_prop_pre_setters[p]
        var post_set = _entity_prop_post_setters[p]
        var bit_size = _entity_prop_bit_sizes[p]
        var is_id = _entity_prop_is_prop[p]
        var name = _val_names[p]
        var f_name = name
        if strip_property_prefix_from_getters_setters:
            f_name = f_name.trim_prefix(entity_property_prefix)
        var type = _val_types[p]
        var arrayness = _val_arrayness[p]
        var custom_type = _entity_prop_custom_types[p]
        var type_name: String
        arrayness -= 1
        if custom_type.is_empty():
            if arrayness == 0:
                type_name = TYPE_UTIL.T_GD_NAME[type]
            elif arrayness == 1:
                type_name = TYPE_UTIL.T_GD_NAME_ARRAY[type]
            else:
                type_name = TYPE_UTIL.T_GD_NAME_ARRAY_NESTED
        else:
            if arrayness > 0:
                type_name = TYPE_UTIL.T_GD_NAME_ARRAY_NESTED
            else:
                type_name = custom_type
        var default_str: String = id_zero() if is_id else default_entity_val_string(p)
        out.write_line("func get_", f_name, "(ent_id: ",id_type,", default: ", type_name, " = ", default_str, ") -> ", type_name, ":")
        out.write_indented_line(1, "if !entity_exists(ent_id): return default")
        if bit_size > 0:
            assert(bit_size == 1 or bit_size == 2 or bit_size == 4)
            match bit_size:
                1:
                    out.write_indented_line(1, "var sub_idx := ", idx, " & 7")
                    out.write_indented_line(1, "var block_idx := ", idx, " >> 3")
                    out.write_indented_line(1, "var val = ", name, "[block_idx]")
                    out.write_indented_line(1, "val = (val >> sub_idx) & 1")
                2:
                    out.write_indented_line(1, "var sub_idx := ", idx, " & 3")
                    out.write_indented_line(1, "var block_idx := ", idx, " >> 2")
                    out.write_indented_line(1, "var val = ", name, "[block_idx]")
                    out.write_indented_line(1, "val = (val >> (sub_idx * 2)) & 3")
                4:
                    out.write_indented_line(1, "var sub_idx := ", idx, " & 1")
                    out.write_indented_line(1, "var block_idx := ", idx, " >> 1")
                    out.write_indented_line(1, "var val = ", name, "[block_idx]")
                    out.write_indented_line(1, "val = (val >> (sub_idx * 4)) & 15")
        else:
            out.write_indented_line(1, "var val = ", name, "[",idx,"]")
        if getter.length() > 0:
            ScriptFileBuilder.clean_and_write_string(getter, out, 1)
        out.write_indented_line(1, "return val")
        out.write_newline()

        out.write_line("func set_", f_name, "(ent_id: ",id_type,", val: ", type_name, ", force: bool = false) -> bool:")
        out.write_indented_line(1, "if !force and !entity_exists(ent_id): return false")
        if pre_set.length() > 0:
            ScriptFileBuilder.clean_and_write_string(pre_set, out, 1)
        if bit_size > 0:
            assert(bit_size == 1 or bit_size == 2 or bit_size == 4)
            match bit_size:
                1:
                    out.write_indented_line(1, "var sub_idx := ", idx, " & 7")
                    out.write_indented_line(1, "var block_idx := ", idx, " >> 3")
                    out.write_indented_line(1, "var prev_val = ", name, "[block_idx]")
                    out.write_indented_line(1, "prev_val = prev_val & (~(1 << sub_idx))")
                    out.write_indented_line(1, "assert(0 <= val and val <= 1, \"value does not fit within 1 bit\")")
                    out.write_indented_line(1, "val = (val & 1) << sub_idx")
                2:
                    out.write_indented_line(1, "var sub_idx := ", idx, " & 3")
                    out.write_indented_line(1, "var block_idx := ", idx, " >> 2")
                    out.write_indented_line(1, "var prev_val = ", name, "[block_idx]")
                    out.write_indented_line(1, "assert(0 <= val and val <= 3, \"value does not fit within 2 bits\")")
                    out.write_indented_line(1, "var shift = sub_idx * 2")
                    out.write_indented_line(1, "prev_val = prev_val & (~(3 << shift))")
                    out.write_indented_line(1, "val = (val & 3) << shift")
                4:
                    out.write_indented_line(1, "var sub_idx := ", idx, " & 1")
                    out.write_indented_line(1, "var block_idx := ", idx, " >> 1")
                    out.write_indented_line(1, "var prev_val = ", name, "[block_idx]")
                    out.write_indented_line(1, "assert(0 <= val and val <= 15, \"value does not fit within 4 bits\")")
                    out.write_indented_line(1, "var shift = sub_idx * 4")
                    out.write_indented_line(1, "prev_val = prev_val & (~(15 << shift))")
                    out.write_indented_line(1, "val = (val & 15) << shift")
            out.write_indented_line(1, "val = val | prev_val")
            out.write_indented_line(1, name, "[block_idx] = val")
        else:
            out.write_indented_line(1, name, "[",idx,"] = val")
        if post_set.length() > 0:
            ScriptFileBuilder.clean_and_write_string(post_set, out, 1)
        if automatically_save:
            _write_queue_save(out, 1)
        out.write_indented_line(1, "return true")
        out.write_newline()
        p += 1
    # END USER BODY
    _in_mode = M_CONFIG
    self.user_script_body = out.finish_and_reset()
    _in_mode = M_PRE_SERIALIZE
    # PROCCESS
    out.write(self.user_process_body)
    out.write_newline()
    if user_process_code_before_entity_process.length() > 0:
        out.write_line("# USER PROCESS BEFORE ENTITY PROCESS")
        ScriptFileBuilder.clean_and_write_string(user_process_code_before_entity_process, out, 0)
        out.write_line("# END USER PROCESS BEFORE ENTITY PROCESS")
    if user_entity_process_code.length() > 0:
        out.write_line("var e: int = 1")
        out.write_line("while e < ", next_unused_id_name, ":")
        if include_entity_generation:
            out.write_indented_line(1, "var g = ", entity_gen_tracker_name, "[e]")
            out.write_indented_line(1, "var ent_id = ", id_type, "(e, g)")
        else:
            out.write_indented_line(1, "var ent_id = e")
        out.write_indented_line(1, "if !entity_exists(ent_id):")
        out.write_indented_line(2, "e += 1")
        out.write_indented_line(2, "continue")
        out.write_indented_line(1, "# USER ENTITY PROCESS")
        ScriptFileBuilder.clean_and_write_string(user_entity_process_code, out, 1)
        out.write_indented_line(1, "# END USER ENTITY PROCESS")
        out.write_indented_line(1, "e += 1")
    if user_process_code_after_entity_process.length() > 0:
        out.write_line("# USER PROCESS AFTER ENTITY PROCESS")
        ScriptFileBuilder.clean_and_write_string(user_process_code_after_entity_process, out, 0)
        out.write_line("# END USER PROCESS AFTER ENTITY PROCESS")
    _in_mode = M_CONFIG
    self.user_process_body = out.finish_and_clear()
    _in_mode = M_PRE_SERIALIZE

var _entity_prop_getters: PackedStringArray = []
var _entity_prop_pre_setters: PackedStringArray = []
var _entity_prop_post_setters: PackedStringArray = []
var _entity_prop_bit_sizes: PackedByteArray = []
var _entity_prop_defaults: Array = []
var _entity_prop_custom_defaults: PackedStringArray = []
var _entity_prop_custom_types: PackedStringArray = []
var _entity_prop_is_prop: PackedByteArray = []
var _num_props_defined: int = 0
var _at_least_one_sub_bit_prop: bool = false

class Prop:
    var _id: int = 0
    var _name: String = ""
    var _bit_size: int = 0
    var _type: TYPE_UTIL.T = TYPE_UTIL.T.Bool
    var _arrayness: int = 0
    var _default: Variant = null
    var _getter: String = ""
    var _pre_setter: String = ""
    var _post_setter: String = ""
    var _custom_type: String = ""
    var _custom_default: String = ""
    var _no_serialize: int = 0
    var _custom_sub_layout: Array[Val] = []
    var _type_is_entity_id: bool = false

    func _init(id: int, name: String, type: TYPE_UTIL.T, default: Variant) -> void:
        _id = id
        _name = name
        _type = type
        _default = default

    static func single_val(id: int, name: String, type: TYPE_UTIL.T, default: Variant) -> Prop:
        var vset = Prop.new(id, name, type, default)
        vset._arrayness = 0
        return vset
    
    static func array(id: int, name: String, type: TYPE_UTIL.T, default: Variant) -> Prop:
        var vset = Prop.new(id, name, type, default)
        vset._arrayness = 1
        return vset
    
    static func nested_arrays(id: int, name: String, type: TYPE_UTIL.T, default: Variant, depth: int) -> Prop:
        var vset = Prop.new(id, name, type, default)
        vset._arrayness = depth
        return vset
    
    func run_code_before_val_set(code: String) -> Prop:
        var new_set = self
        new_set._pre_setter = code
        return new_set
    
    func run_code_after_val_set(code: String) -> Prop:
        var new_set = self
        new_set._post_setter = code
        return new_set
    
    func run_code_before_val_get(code: String) -> Prop:
        var new_set = self
        new_set._getter = code
        return new_set
    
    func sub_byte_bits(bit_size: int) -> Prop:
        var new_set = self
        assert(bit_size == 1 or bit_size == 2 or bit_size == 4, "Only bit-sizes 1, 2, or 4 are supported, otherwise use whole integers (Uint8, Uint16, Uint32, etc.")
        new_set._bit_size = bit_size
        return new_set
    
    func property_is_entity_id_type() -> Prop:
        var new_set = self
        new_set._type_is_entity_id = true
        return new_set
    
    func custom_default(default: String) -> Prop:
        var new_set = self
        new_set._custom_default = default
        return new_set
    
    func custom_type(type: String) -> Prop:
        var new_set = self
        new_set._custom_type = type
        return new_set
    
    func do_not_serialize() -> Prop:
        var new_set = self
        new_set._no_serialize = 1
        return new_set
    
    func to_normal_val(prefix: String, entity_arrays_config_file_section_: String) -> FileFormatBuilder.Val:
        var val = FileFormatBuilder.Val.new(self._id, prefix + self._name, self._type, [])
        val._arrayness = self._arrayness + 1
        val._config_section = entity_arrays_config_file_section_
        val._custom_type = ""
        val._custom_sub_layout = self._custom_sub_layout
        val._omit_setter = true
        val._custom_default = ""
        val._no_serialize = self._no_serialize
        return val

func register_entity_property(prop: Prop) -> void:
    _entity_prop_getters.push_back(prop._getter)
    _entity_prop_pre_setters.push_back(prop._pre_setter)
    _entity_prop_post_setters.push_back(prop._post_setter)
    _entity_prop_bit_sizes.push_back(prop._bit_size)
    _entity_prop_defaults.push_back(prop._default)
    _entity_prop_custom_types.push_back(prop._custom_type)
    _entity_prop_custom_defaults.push_back(prop._custom_default)
    _entity_prop_is_prop.push_back(int(prop._type_is_entity_id))
    _num_props_defined += 1
    _at_least_one_sub_bit_prop = _at_least_one_sub_bit_prop or prop._bit_size > 0
    if prop._type_is_entity_id:
        if include_entity_generation:
            prop._type = TYPE_UTIL.T.Vec2_Uint32
            prop._default = Vector2i.ZERO
        else:
            prop._type = TYPE_UTIL.T.Uint32
            prop._default = 0
    TYPE_UTIL.check_default_value(prop._type, prop._arrayness, prop._default, prop._custom_default,true)
    var as_val = prop.to_normal_val(entity_property_prefix, entity_arrays_config_file_section)
    register_named_value(as_val)

func default_entity_val_string(val_id: int) -> String:
    var default_cust = _entity_prop_custom_defaults[val_id]
    if default_cust.length() > 0: return default_cust
    var type = _val_types[val_id]
    var default = _entity_prop_defaults[val_id]
    if type == TYPE_UTIL.T.String_Ascii or type == TYPE_UTIL.T.String_Utf8:
        return "\"" + str(default) + "\""
    return var_to_str(default)


func id_t_name() -> String:
    if include_entity_generation: return "Vector2i"
    return "int"

func id_p_idx(id: String) -> String:
    if include_entity_generation: return id + ".x"
    return id

func id_zero() -> String:
    if include_entity_generation: return "Vector2i.ZERO"
    return "0"

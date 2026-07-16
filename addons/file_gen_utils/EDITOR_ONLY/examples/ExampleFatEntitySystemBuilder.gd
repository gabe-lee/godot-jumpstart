@tool
extends FatEntitySystemBuilder

func _set_config() -> void:
    self.script_class = "EntitySystem"
    self.write_class_name = false # to prevent the examples from polluting the project namespace
    self.script_path = "res://addons/file_gen_utils/EDITOR_ONLY/examples/ExampleFatEntitySystemBuilderResult.gd"
    self.entity_next_free_property = "ent_kind"
    self.entity_free_tracker_name = "entity_free_tracker"
    self.entity_gen_tracker_name = "entity_gen_tracker"
    self.include_entity_generation = true
    self.strip_property_prefix_from_getters_setters = true
    self.entity_property_prefix = "ent_"
    self.data_mode = DATA_MODE.COMPRESSED
    self.compression_kind = FileAccess.COMPRESSION_ZSTD
    self.automatically_save = true
    self.user_entity_post_create_code = "# post create"
    self.user_entity_pre_delete_code = "# pre delete"
    self.user_entity_process_code = "# entity process"
    self.user_process_code_after_entity_process = "# process after entity process"
    self.user_process_code_before_entity_process = "# process before entity process"
    self.completely_omit_serialization_code = true # example for if you JUST need the logic, no file serialization
    self.user_script_body = """
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
"""

enum VAL {
    KIND,
    MAX_HEALTH,
    CURR_HEALTH,
    GLOBAL_POSITION,
    TILE_POSITION,
    FACTION,
}

func _register_properties() -> void:
    register_entity_property(Prop.single_val(VAL.KIND, "kind", TYPE_UTIL.T.Uint32, 0))
    register_entity_property(Prop.single_val(VAL.MAX_HEALTH, "max_health", TYPE_UTIL.T.Float32, 100.0))
    register_entity_property(Prop.single_val(VAL.CURR_HEALTH, "curr_health", TYPE_UTIL.T.Float32, 0.0))
    register_entity_property(Prop.single_val(VAL.GLOBAL_POSITION, "global_position", TYPE_UTIL.T.Vec2_Int32, Vector2i.ZERO))
    register_entity_property(Prop.single_val(VAL.TILE_POSITION, "tile_sub_position", TYPE_UTIL.T.Vec2_Uint8, Vector2i.ZERO))
    register_entity_property(Prop.single_val(VAL.FACTION, "faction", TYPE_UTIL.T.Uint32, Vector2i.ZERO).custom_type("ENT_FACTION").custom_default("ENT_FACTION.NONE"))

func _register_versions() -> void:
    register_version_layout(0, [
        VAL.KIND,
        VAL.MAX_HEALTH,
        VAL.CURR_HEALTH,
        VAL.GLOBAL_POSITION,
        VAL.TILE_POSITION,
        VAL.FACTION,
    ])
    # For the combined example with `ExampleSaveFileBuilder`,
    # both formats MUST have the exact same number of versions
    # (essentially thay are the SAME format split into two files)
    # And also must have no conflicting property names (in any given version)
    register_version_with_no_changes_from_prev(1) 

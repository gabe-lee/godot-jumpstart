@tool
extends ScriptFragmentBuilder

func _define_config() -> void:
    self.fragment_name = "TestFragment"

func _define_code(out: ScriptFileBuilder) -> void:
    out._line("my_val = 'it worked!'")

func _define_targets() -> void:
    add_target("res://addons/file_gen_utils/EDITOR_ONLY/examples/ExampleFragmentResult.gd", "# BEGIN MY BODY", "# END MY BODY", MODE.OVERWRITE_BLOCK)

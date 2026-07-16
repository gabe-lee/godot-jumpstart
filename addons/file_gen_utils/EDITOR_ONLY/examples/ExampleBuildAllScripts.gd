@tool
extends EditorScript

# Normally you would NAME your builder files so they can be referenced directly,
# for the examples we omit the `class_name` in the builder scripts
# so they dont show up in your project, and use preload() instead
var ExampleFragBuilder = preload("res://addons/file_gen_utils/EDITOR_ONLY/examples/ExampleFragmentBuilder.gd")
var ExampleScriptBuilder = preload("res://addons/file_gen_utils/EDITOR_ONLY/examples/ExampleScriptBuilder.gd")
var ExampleSettingsBuilder = preload("res://addons/file_gen_utils/EDITOR_ONLY/examples/ExampleSettingsBuilder.gd")
var ExampleSaveFileBuilder = preload("res://addons/file_gen_utils/EDITOR_ONLY/examples/ExampleSaveFileBuilder.gd")
var ExampleFatEntityBuilder = preload("res://addons/file_gen_utils/EDITOR_ONLY/examples/ExampleFatEntitySystemBuilder.gd")
var ExampleSaveFileAndEntitySysBuilder = preload("res://addons/file_gen_utils/EDITOR_ONLY/examples/ExampleSaveAndEntitySysFileBuilder.gd")

# You can automatically run ALL file gen scripts defined from a single file
func _run() -> void:
    ExampleFragBuilder.new()._run()
    ExampleScriptBuilder.new()._run()
    ExampleSettingsBuilder.new()._run()
    ExampleSaveFileBuilder.new()._run()
    ExampleFatEntityBuilder.new()._run()
    ExampleSaveFileAndEntitySysBuilder.new([ExampleFatEntityBuilder.new()])._run()

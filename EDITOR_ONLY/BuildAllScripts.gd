@tool
extends EditorScript

func _run() -> void:
    GameStateBuilder.new([EntitySystemBuilder.new()])._run()
    SaveManifestBuilder.new()._run()
    SettingsBuilder.new()._run()
    FragmentClearer.new()._run()
    TranslationTableBuilder.new()._run()
    EntityConstantBuilder.new()._run()

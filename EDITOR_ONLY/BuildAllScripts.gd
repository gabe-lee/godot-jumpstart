@tool
extends EditorScript

func _run() -> void:
    GameStateBuilder.new()._run()
    SaveManifestBuilder.new()._run()
    SettingsBuilder.new()._run()
    FragmentClearer.new()._run()
    TranslationTableBuilder.new()._run()

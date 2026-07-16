class_name ModalBlock extends ColorRect

@export var visible_when_enabled: bool = true

func _ready() -> void:
    disable()
    self.color = THEME.MODAL_BLOCK_COLOR
    self.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED

func enable() -> void:
    self.mouse_filter = Control.MOUSE_FILTER_STOP
    self.visible = visible_when_enabled

func disable() -> void:
    self.mouse_filter = Control.MOUSE_FILTER_IGNORE
    self.visible = false

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouse:
        accept_event()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouse:
        accept_event()

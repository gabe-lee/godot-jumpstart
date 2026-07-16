class_name NotificationPanel extends LogicContainer

@onready var title_panel: PanelContainer = $main_panel/margins/sections/title_panel
@onready var title_label: Label = $main_panel/margins/sections/title_panel/title
@onready var details: Label = $main_panel/margins/sections/details
@onready var button: Button = $main_panel/margins/sections/button_container/confirm_button

var vals_set: bool = false
var msg: String = ""
var kind: Game.NOTIFICATION_KIND = Game.NOTIFICATION_KIND.INFO
var prev_focus: Control = null

func _ready() -> void:
    _write_msg()
    button.pressed.connect(_handle_accept)
    button.grab_focus.call_deferred()

func _handle_accept() -> void:
    Game.main.close_notification(self, kind)

func set_message(full_msg: String, mode_: Game.NOTIFICATION_KIND, prev_focus_: Control = null) -> void:
    msg = full_msg
    kind = mode_
    prev_focus = prev_focus_
    if self.is_node_ready():
        _write_msg()

func _write_msg() -> void:
    if prev_focus == null:
        prev_focus = get_viewport().gui_get_focus_owner()
    if vals_set: return
    vals_set = true
    details.text = msg
    match kind:
        Game.NOTIFICATION_KIND.INFO:
            title_panel.theme_type_variation = THEME.VARIANT.PANEL_CONT_INFO
            details.theme_type_variation = THEME.VARIANT.LABEL_INFO
            title_label.text = "Info"
            button.theme_type_variation = THEME.VARIANT.BUTTON_INFO
        Game.NOTIFICATION_KIND.WARNING:
            title_panel.theme_type_variation = THEME.VARIANT.PANEL_CONT_USER_ERROR
            details.theme_type_variation = THEME.VARIANT.LABEL_USER_ERR
            title_label.text = "User Error"
            button.theme_type_variation = THEME.VARIANT.BUTTON_USER_ERR
        Game.NOTIFICATION_KIND.ERROR:
            title_panel.theme_type_variation = THEME.VARIANT.PANEL_CONT_GAME_ERROR
            details.theme_type_variation = THEME.VARIANT.LABEL_GAME_ERR
            title_label.text = "Game Error"
            button.theme_type_variation = THEME.VARIANT.BUTTON_GAME_ERR
        Game.NOTIFICATION_KIND.FATAL:
            title_panel.theme_type_variation = THEME.VARIANT.PANEL_CONT_FATAL_ERROR
            details.theme_type_variation = THEME.VARIANT.LABEL_FATAL_ERR
            title_label.text = "FATAL ERROR"
            button.theme_type_variation = THEME.VARIANT.BUTTON_FATAL_ERR
        _: pass

    

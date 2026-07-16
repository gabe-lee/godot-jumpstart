@tool
class_name ThemeBuilder extends ProgrammaticTheme

const UPDATE_ON_SAVE = true
const VERBOSITY = Verbosity.SILENT

@warning_ignore_start("integer_division")

func _run():
    super._run()
    print("Theme generation Time: ", Time.get_datetime_string_from_system())


#region Named Theme Variables
var primary_bg_color := Color("#141020")
var primary_accent_color := Color("#FFD700")
var normal_font_color := Color("#F8F8FF")
var disabled_font_color := normal_font_color.darkened(0.6)
var accent_font_color := primary_accent_color.lightened(0.3)
var focused_control_color := primary_accent_color

var info_color := Color.CORNFLOWER_BLUE
var warn_color := Color.GOLD
var error_color := Color.ORANGE
var fatal_err_color := Color.CRIMSON

var standard_margins := 4
var button_margins := 6
var large_margins := 12
var screen_edge_margins := 8

var normal_font_size := 10
var small_font_size := 8
var micro_font_size := 6
var large_font_size := 12
var massive_font_size := 16

var line_spacing_divisor := 4
var focused_control_border_extend := 3.0
var focused_control_border_width := 1

var menu_button_color_normal := primary_bg_color.lightened(0.1)
var menu_button_color_disabled := menu_button_color_normal.darkened(0.1)
var menu_button_color_hover := menu_button_color_normal.lightened(0.1)
var menu_button_color_pressed := menu_button_color_normal.lightened(0.2)

var menu_button_text_normal := normal_font_color
var menu_button_text_disabled := disabled_font_color
var menu_button_text_hover := normal_font_color
var menu_button_text_pressed := normal_font_color
var menu_button_text_focus := normal_font_color

var menu_button_icon_normal := Color.WHITE
var menu_button_icon_disabled := Color.GRAY
var menu_button_icon_hover := Color.WHITE
var menu_button_icon_pressed := Color.WHITE
var menu_button_icon_focus := Color.WHITE

var menu_button_text_icon_sep := standard_margins
var menu_button_icon_max_width := 0
var menu_button_corner_anti_alias := true
var menu_button_corner_anti_alias_size := 1.0
var menu_button_border_blend := false
var menu_button_shadow_color := Color(0, 0, 0, 0)
var menu_button_shadow_size := 0
var menu_button_shadow_offset := Vector2.ZERO
var menu_button_skew := Vector2.ZERO
var menu_button_content_margin := button_margins
var menu_button_corner_radius := 8
var menu_button_corner_detail := 4
var menu_button_border_width := 0
var menu_button_border_color := Color(0,0,0,0)

var panel_corner_anti_alias := false
var panel_corner_anti_alias_size := 0
var panel_border_blend := false
var panel_shadow_color := Color(0, 0, 0, 0)
var panel_shadow_size := 0
var panel_shadow_offset := Vector2.ZERO
var panel_skew := Vector2.ZERO
var panel_content_margin = standard_margins
var panel_corner_radius := 0
var panel_corner_detail := 0
var panel_border_width := 1
var panel_border_color := primary_bg_color.lightened(0.2)

static var modal_blocker_color := Color(0, 0, 0, 0.5)
#endregion

func setup():
    set_save_path(Game.THEME_PATH)

func define_theme():
    define_default_font_size(normal_font_size)

    var panel_proto = stylebox_flat({
        corner_radius_ = corner_radius(panel_corner_radius),
        corner_detail = panel_corner_detail,
        border_ = border_width(panel_border_width),
        border_color = panel_border_color,
        shadow_color = panel_shadow_color,
        shadow_offset = panel_shadow_offset,
        shadow_size = panel_shadow_size,
        skew = panel_skew,
        content_margin_ = content_margins(panel_content_margin),
    })
    var panel_normal = inherit(panel_proto, {
        bg_color = primary_bg_color,
    })
    var panel_info = inherit(panel_proto, {
        bg_color = info_color,
    })
    var panel_user_err = inherit(panel_proto, {
        bg_color = warn_color,
    })
    var panel_game_err = inherit(panel_proto, {
        bg_color = error_color,
    })
    var panel_fatal_err = inherit(panel_proto, {
        bg_color = fatal_err_color,
    })

    define_style(THEME.VARIANT.PANEL, {
        panel = panel_normal
    })
    define_variant_style(THEME.VARIANT.PANEL_INFO, THEME.VARIANT.PANEL, {
        panel = panel_info
    })
    define_variant_style(THEME.VARIANT.PANEL_USER_ERROR, THEME.VARIANT.PANEL, {
        panel = panel_user_err
    })
    define_variant_style(THEME.VARIANT.PANEL_GAME_ERROR, THEME.VARIANT.PANEL, {
        panel = panel_game_err
    })
    define_variant_style(THEME.VARIANT.PANEL_FATAL_ERROR, THEME.VARIANT.PANEL, {
        panel = panel_fatal_err
    })

    define_style(THEME.VARIANT.PANEL_CONT, {
        panel = panel_normal
    })
    define_variant_style(THEME.VARIANT.PANEL_CONT_INFO, THEME.VARIANT.PANEL_CONT, {
        panel = panel_info
    })
    define_variant_style(THEME.VARIANT.PANEL_CONT_USER_ERROR, THEME.VARIANT.PANEL_CONT, {
        panel = panel_user_err
    })
    define_variant_style(THEME.VARIANT.PANEL_CONT_GAME_ERROR, THEME.VARIANT.PANEL_CONT, {
        panel = panel_game_err
    })
    define_variant_style(THEME.VARIANT.PANEL_CONT_FATAL_ERROR, THEME.VARIANT.PANEL_CONT, {
        panel = panel_fatal_err
    })

    define_style(THEME.VARIANT.LABEL, {
        font_color = normal_font_color,
        font_size = normal_font_size,
        line_spacing = normal_font_size / line_spacing_divisor,
    })
    define_variant_style(THEME.VARIANT.LABEL_SMALL, THEME.VARIANT.LABEL, {
        font_size = small_font_size,
        line_spacing = small_font_size / line_spacing_divisor,
    })
    define_variant_style(THEME.VARIANT.LABEL_MICRO, THEME.VARIANT.LABEL, {
        font_size = micro_font_size,
        line_spacing = micro_font_size / line_spacing_divisor,
    })
    define_variant_style(THEME.VARIANT.LABEL_LARGE, THEME.VARIANT.LABEL, {
        font_size = large_font_size,
        line_spacing = large_font_size / line_spacing_divisor,
    })
    define_variant_style(THEME.VARIANT.LABEL_MASSIVE, THEME.VARIANT.LABEL, {
        font_size = massive_font_size,
        line_spacing = massive_font_size / line_spacing_divisor,
    })

    define_variant_style(THEME.VARIANT.LABEL_DISABLED, THEME.VARIANT.LABEL, {
        font_color = disabled_font_color,
    })
    define_variant_style(THEME.VARIANT.LABEL_DISABLED_SMALL, THEME.VARIANT.LABEL, {
        font_color = disabled_font_color,
        font_size = small_font_size,
        line_spacing = small_font_size / line_spacing_divisor,
    })
    define_variant_style(THEME.VARIANT.LABEL_DISABLED_MICRO, THEME.VARIANT.LABEL, {
        font_color = disabled_font_color,
        font_size = micro_font_size,
        line_spacing = micro_font_size / line_spacing_divisor,
    })
    define_variant_style(THEME.VARIANT.LABEL_DISABLED_LARGE, THEME.VARIANT.LABEL, {
        font_color = disabled_font_color,
        font_size = large_font_size,
        line_spacing = large_font_size / line_spacing_divisor,
    })
    define_variant_style(THEME.VARIANT.LABEL_DISABLED_MASSIVE, THEME.VARIANT.LABEL, {
        font_color = disabled_font_color,
        font_size = massive_font_size,
        line_spacing = massive_font_size / line_spacing_divisor,
    })
    
    define_variant_style(THEME.VARIANT.LABEL_ACCENT, THEME.VARIANT.LABEL, {
        font_color = accent_font_color,
    })
    define_variant_style(THEME.VARIANT.LABEL_ACCENT_SMALL, THEME.VARIANT.LABEL, {
        font_color = accent_font_color,
        font_size = small_font_size,
        line_spacing = small_font_size / line_spacing_divisor,
    })
    define_variant_style(THEME.VARIANT.LABEL_ACCENT_MICRO, THEME.VARIANT.LABEL, {
        font_color = accent_font_color,
        font_size = micro_font_size,
        line_spacing = micro_font_size / line_spacing_divisor,
    })
    define_variant_style(THEME.VARIANT.LABEL_ACCENT_LARGE, THEME.VARIANT.LABEL, {
        font_color = accent_font_color,
        font_size = large_font_size,
        line_spacing = large_font_size / line_spacing_divisor,
    })
    define_variant_style(THEME.VARIANT.LABEL_ACCENT_MASSIVE, THEME.VARIANT.LABEL, {
        font_color = accent_font_color,
        font_size = massive_font_size,
        line_spacing = massive_font_size / line_spacing_divisor,
    })

    define_variant_style(THEME.VARIANT.LABEL_INVERSE, THEME.VARIANT.LABEL, {
        font_color = primary_bg_color,
    })
    define_variant_style(THEME.VARIANT.LABEL_INVERSE_SMALL, THEME.VARIANT.LABEL, {
        font_color = primary_bg_color,
        font_size = small_font_size,
        line_spacing = small_font_size / line_spacing_divisor,
    })
    define_variant_style(THEME.VARIANT.LABEL_INVERSE_MICRO, THEME.VARIANT.LABEL, {
        font_color = primary_bg_color,
        font_size = micro_font_size,
        line_spacing = micro_font_size / line_spacing_divisor,
    })
    define_variant_style(THEME.VARIANT.LABEL_INVERSE_LARGE, THEME.VARIANT.LABEL, {
        font_color = primary_bg_color,
        font_size = large_font_size,
        line_spacing = large_font_size / line_spacing_divisor,
    })
    define_variant_style(THEME.VARIANT.LABEL_INVERSE_MASSIVE, THEME.VARIANT.LABEL, {
        font_color = primary_bg_color,
        font_size = massive_font_size,
        line_spacing = massive_font_size / line_spacing_divisor,
    })

    define_variant_style(THEME.VARIANT.LABEL_INFO, THEME.VARIANT.LABEL, {
        font_color = info_color,
    })
    define_variant_style(THEME.VARIANT.LABEL_USER_ERR, THEME.VARIANT.LABEL, {
        font_color = warn_color,
    })
    define_variant_style(THEME.VARIANT.LABEL_GAME_ERR, THEME.VARIANT.LABEL, {
        font_color = error_color,
    })
    define_variant_style(THEME.VARIANT.LABEL_FATAL_ERR, THEME.VARIANT.LABEL, {
        font_color = fatal_err_color,
    })


    define_style(THEME.VARIANT.MARGIN_CONTAINER, {
        margin_ = margins(standard_margins)
    })
    define_variant_style(THEME.VARIANT.MARGIN_CONTAINER_ZERO, THEME.VARIANT.MARGIN_CONTAINER, {
        margin_ = margins(0)
    })
    define_variant_style(THEME.VARIANT.MARGIN_CONTAINER_SCREEN_EDGE, THEME.VARIANT.MARGIN_CONTAINER, {
        margin_ = margins(screen_edge_margins)
    })
    define_variant_style(THEME.VARIANT.MARGIN_CONTAINER_LARGE, THEME.VARIANT.MARGIN_CONTAINER, {
        margin_ = margins(large_margins)
    })
    define_variant_style(THEME.VARIANT.MARGIN_CONTAINER_BUTTON, THEME.VARIANT.MARGIN_CONTAINER, {
        margin_ = margins(button_margins)
    })

    var button_box_proto = stylebox_flat({
        corner_radius_ = corner_radius(menu_button_corner_radius),
        corner_detail = menu_button_corner_detail,
        border_ = border_width(menu_button_border_width),
        border_color = menu_button_border_color,
        shadow_color = menu_button_shadow_color,
        shadow_offset = menu_button_shadow_offset,
        shadow_size = menu_button_shadow_size,
        skew = menu_button_skew,
        content_margin_ = content_margins(menu_button_content_margin),
    })
    var button_box_disabled = inherit(button_box_proto, {
        bg_color = menu_button_color_disabled,
        font_color = disabled_font_color,
    })
    var button_box_normal = inherit(button_box_proto, {
        bg_color = menu_button_color_normal,
    })
    var button_box_hover = inherit(button_box_proto, {
        bg_color = menu_button_color_hover,
    })
    var button_box_pressed = inherit(button_box_proto, {
        bg_color = menu_button_color_pressed,
    })
    var focus_outline = inherit(button_box_proto, {
        bg_color = Color(0,0,0,0),
        draw_center = false,
        # expand_margin_top = focused_control_border_extend,
        # expand_margin_bottom = focused_control_border_extend,
        # expand_margin_left = focused_control_border_extend,
        # expand_margin_right = focused_control_border_extend,
        expand_margin_ = expand_margins(int(focused_control_border_extend)),
        border_color = focused_control_color,
        border_ = border_width(focused_control_border_width),
        corner_radius_ = corner_radius(menu_button_corner_radius + int(focused_control_border_extend)),
    })

    var button_box_disabled_info = inherit(button_box_proto, {
        bg_color = info_color.darkened(0.1),
    })
    var button_box_normal_info = inherit(button_box_proto, {
        bg_color = info_color,
    })
    var button_box_hover_info = inherit(button_box_proto, {
        bg_color = info_color.lightened(0.05),
    })
    var button_box_pressed_info = inherit(button_box_proto, {
        bg_color = info_color.lightened(0.1),
    })
    var button_box_focus_info = inherit(focus_outline, {
        border_color = info_color,
    })

    var button_box_disabled_user_err = inherit(button_box_proto, {
        bg_color = warn_color.darkened(0.1),
    })
    var button_box_normal_user_err = inherit(button_box_proto, {
        bg_color = warn_color,
    })
    var button_box_hover_user_err = inherit(button_box_proto, {
        bg_color = warn_color.lightened(0.05),
    })
    var button_box_pressed_user_err = inherit(button_box_proto, {
        bg_color = warn_color.lightened(0.1),
    })
    var button_box_focus_user_err = inherit(focus_outline, {
        border_color = warn_color,
    })

    var button_box_disabled_game_err = inherit(button_box_proto, {
        bg_color = error_color.darkened(0.1),
    })
    var button_box_normal_game_err = inherit(button_box_proto, {
        bg_color = error_color,
    })
    var button_box_hover_game_err = inherit(button_box_proto, {
        bg_color = error_color.lightened(0.05),
    })
    var button_box_pressed_game_err = inherit(button_box_proto, {
        bg_color = error_color.lightened(0.1),
    })
    var button_box_focus_game_err = inherit(focus_outline, {
        border_color = error_color,
    })

    var button_box_disabled_fatal_err = inherit(button_box_proto, {
        bg_color = fatal_err_color.darkened(0.1),
    })
    var button_box_normal_fatal_err = inherit(button_box_proto, {
        bg_color = fatal_err_color,
    })
    var button_box_hover_fatal_err = inherit(button_box_proto, {
        bg_color = fatal_err_color.lightened(0.05),
    })
    var button_box_pressed_fatal_err = inherit(button_box_proto, {
        bg_color = fatal_err_color.lightened(0.1),
    })
    var button_box_focus_fatal_err = inherit(focus_outline, {
        border_color = fatal_err_color,
    })


    define_style(THEME.VARIANT.BUTTON, {
        font_size = normal_font_size,
        font_color = normal_font_color,
        font_disabled_color = menu_button_text_disabled,
        font_focus_color = menu_button_text_focus,
        font_hover_color = menu_button_text_normal,
        font_hover_pressed_color = menu_button_text_pressed,
        font_pressed_color = menu_button_text_pressed,
        disabled = button_box_disabled,
        normal = button_box_normal,
        hover = button_box_hover,
        hover_pressed = button_box_pressed,
        pressed = button_box_pressed,
        focus = focus_outline,
    })
    define_variant_style(THEME.VARIANT.BUTTON_INFO, THEME.VARIANT.BUTTON, {
        font_size = normal_font_size,
        font_color = primary_bg_color,
        font_disabled_color = primary_bg_color,
        font_focus_color = primary_bg_color,
        font_hover_color = primary_bg_color,
        font_hover_pressed_color = primary_bg_color,
        font_pressed_color = primary_bg_color,
        disabled = button_box_disabled_info,
        normal = button_box_normal_info,
        hover = button_box_hover_info,
        hover_pressed = button_box_pressed_info,
        pressed = button_box_pressed_info,
        focus = button_box_focus_info,
    })
    define_variant_style(THEME.VARIANT.BUTTON_USER_ERR, THEME.VARIANT.BUTTON, {
        font_size = normal_font_size,
        font_color = primary_bg_color,
        font_disabled_color = primary_bg_color,
        font_focus_color = primary_bg_color,
        font_hover_color = primary_bg_color,
        font_hover_pressed_color = primary_bg_color,
        font_pressed_color = primary_bg_color,
        disabled = button_box_disabled_user_err,
        normal = button_box_normal_user_err,
        hover = button_box_hover_user_err,
        hover_pressed = button_box_pressed_user_err,
        pressed = button_box_pressed_user_err,
        focus = button_box_focus_user_err,
    })
    define_variant_style(THEME.VARIANT.BUTTON_GAME_ERR, THEME.VARIANT.BUTTON, {
        font_size = normal_font_size,
        font_color = primary_bg_color,
        font_disabled_color = primary_bg_color,
        font_focus_color = primary_bg_color,
        font_hover_color = primary_bg_color,
        font_hover_pressed_color = primary_bg_color,
        font_pressed_color = primary_bg_color,
        disabled = button_box_disabled_game_err,
        normal = button_box_normal_game_err,
        hover = button_box_hover_game_err,
        hover_pressed = button_box_pressed_game_err,
        pressed = button_box_pressed_game_err,
        focus = button_box_focus_game_err,
    })
    define_variant_style(THEME.VARIANT.BUTTON_FATAL_ERR, THEME.VARIANT.BUTTON, {
        font_size = normal_font_size,
        font_color = primary_bg_color,
        font_disabled_color = primary_bg_color,
        font_focus_color = primary_bg_color,
        font_hover_color = primary_bg_color,
        font_hover_pressed_color = primary_bg_color,
        font_pressed_color = primary_bg_color,
        disabled = button_box_disabled_fatal_err,
        normal = button_box_normal_fatal_err,
        hover = button_box_hover_fatal_err,
        hover_pressed = button_box_pressed_fatal_err,
        pressed = button_box_pressed_fatal_err,
        focus = button_box_focus_fatal_err,
    })

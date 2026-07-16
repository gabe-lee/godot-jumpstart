## A container that allows its children to fill its area, has no margins, and is designed to
## hold the script logic that all its children need so that they dont deviate from their cannonical types
class_name LogicContainer extends MarginContainer

func _enter_tree() -> void:
    self.add_theme_constant_override("margin_top", 0)
    self.add_theme_constant_override("margin_bottom", 0)
    self.add_theme_constant_override("margin_left", 0)
    self.add_theme_constant_override("margin_right", 0)
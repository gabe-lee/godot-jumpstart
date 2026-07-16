class_name Utils extends Object


class DayHourMinSec:
    var days: int = 0
    var hours: int = 0
    var mins: int = 0
    var secs: int = 0

static func seconds_to_dhms(seconds: float) -> DayHourMinSec:
    var dmhs = DayHourMinSec.new()
    dmhs.days = floori(seconds / 86400.0)
    dmhs.hours = floori(fmod(seconds / 3600.0, 3600.0))
    dmhs.mins = floori(fmod(seconds / 60.0, 60.0))
    dmhs.secs = floori(fmod(seconds, 60.0))
    return dmhs

static func seconds_to_hms(seconds: float) -> DayHourMinSec:
    var dmhs = DayHourMinSec.new()
    dmhs.hours = floori(seconds / 3600.0)
    dmhs.mins = floori(fmod(seconds / 60.0, 60.0))
    dmhs.secs = floori(fmod(seconds, 60.0))
    return dmhs

static func gcf(a: int, b: int) -> int:
    var divisor: int = a if (a < b) else b
    var numerator: int = b if (a < b) else a
    var remainder = numerator % divisor
    while remainder > 0:
        numerator = divisor
        divisor = remainder
        remainder = numerator % divisor
    return divisor

static func get_pixel_zoom(target_px: Vector2i, target_inches: Vector2) -> PackedInt32Array:
    var arr: PackedInt32Array
    arr.resize(3)
    var dpi: int = DisplayServer.screen_get_dpi()
    # var size: Vector2i = DisplayServer.screen_get_size()
    var scale: float = DisplayServer.screen_get_scale()
    var eff_dpi = float(dpi) / scale
    var possible_zoom_factor: int = 1
    var possible_inches: Vector2 = Vector2.ZERO
    var possible_render_error: Vector2 = Vector2.INF
    var best_render_error: float = INF
    var keep_checking = true
    while keep_checking:
        possible_inches = Vector2(target_px * possible_zoom_factor) / eff_dpi
        possible_render_error = abs(target_inches - possible_inches) / target_inches
        possible_render_error.x = (possible_render_error.x + possible_render_error.y) / 2.0
        keep_checking = possible_render_error.x < best_render_error
        if keep_checking:
            
            best_render_error = possible_render_error.x
            possible_zoom_factor += 1
        else:
            possible_zoom_factor -= 1
    arr[0] = maxi(possible_zoom_factor - 1, 1)
    arr[1] = possible_zoom_factor
    arr[2] = possible_zoom_factor + 1
    return arr

static func remove_all_children(node: Node) -> void:
    for child in node.get_children():
        node.remove_child(child)
        child.queue_free()

class_name BinaryFile extends RefCounted

var file: FileAccess = null

static func create_temp(flags: FileAccess.ModeFlags, prefix: String = "", extension: String = "", keep: bool = false) -> BinaryFile:
    var bf = BinaryFile.new()
    bf.file = FileAccess.create_temp(flags, prefix, extension, keep)
    return bf

static func open(path: String, flags: FileAccess.ModeFlags) -> TextFile:
    var bf = BinaryFile.new()
    bf.file = FileAccess.open(path, flags)
    return bf

static func open_compressed(path: String, flags: FileAccess.ModeFlags, compression_mode: FileAccess.CompressionMode) -> BinaryFile:
    var bf = BinaryFile.new()
    bf.file = FileAccess.open_compressed(path, flags, compression_mode)
    return bf

static func open_encrypted(path: String, flags: FileAccess.ModeFlags, key: PackedByteArray, iv: PackedByteArray = PackedByteArray()) -> BinaryFile:
    var bf = BinaryFile.new()
    bf.file = FileAccess.open_encrypted(path, flags, key, iv)
    return bf

static func open_encrypted_with_pass(path: String, flags: FileAccess.ModeFlags, pass_: String) -> BinaryFile:
    var bf = BinaryFile.new()
    bf.file = FileAccess.open_encrypted_with_pass(path, flags, pass_)
    return bf

static func open_encrypted_hmac(path: String, flags: FileAccess.ModeFlags, mac_key: PackedByteArray, enc_key: PackedByteArray, iv: PackedByteArray = PackedByteArray()) -> BinaryFile:
    var bf = BinaryFile.new()
    assert(ClassDB.class_has_method(&"FileAccess", "open_encrypted_hmac"), "FileAccess.open_encrypted_hmac() is not defined in the engine (it requires custom source code or modules")
    bf.file = ClassDB.class_call_static("FileAccess", "open_encrypted_hmac", path, flags, mac_key, enc_key, iv)
    return bf

static func open_encrypted_hmac_pass(path: String, flags: FileAccess.ModeFlags, mac_pass: String, enc_pass: String) -> BinaryFile:
    var bf = BinaryFile.new()
    assert(ClassDB.class_has_method(&"FileAccess", "open_encrypted_hmac_pass"), "FileAccess.open_encrypted_hmac_pass() is not defined in the engine (it requires custom source code or modules")
    bf.file = ClassDB.class_call_static("FileAccess", "open_encrypted_hmac_pass", path, flags, mac_pass, enc_pass)
    return bf

static func _col_to_vec4_int(color: Color, intmax: int) -> Vector4i:
    var x = color.r * float(intmax)
    var y = color.g * float(intmax)
    var z = color.b * float(intmax)
    var w = color.a * float(intmax)
    return Vector4i(floori(x), floori(y), floori(z), floori(w))

static func _vec4_int_to_col(vec: Vector4i, intmax: int) -> Color:
    var r = float(vec.x) / float(intmax)
    var g = float(vec.y) / float(intmax)
    var b = float(vec.z) / float(intmax)
    var a = float(vec.w) / float(intmax)
    return Color(r, g, b, a)

static func open_error() -> Error:
    return FileAccess.get_open_error()

func is_null() -> bool:
    return file == null

func not_null() -> bool:
    return file != null

func size() -> int:
    return file.get_length()

func pos() -> int:
    return file.get_position()

func close() -> void:
    file.close()

func flush() -> void:
    file.flush()

func resize(new_size: int) -> Error:
    return file.resize(new_size)

func set_big_endian(state: bool) -> void:
    file.big_endian = state

func bytes_after_cursor() -> int:
    return size() - pos()

func bytes_before_cursor() -> int:
    return pos()

func has_at_least_n_bytes_to_read(n: int) -> bool:
    return size() - pos() >= n

func seek(new_pos: int) -> void:
    file.seek(new_pos)

func seek_from_end(delta: int) -> void:
    file.seek_end(delta)

func last_error() -> Error:
    return file.get_error()

#region Scalars

func read_byte() -> int:
    return file.get_8()

func write_byte(val: int) -> bool:
    assert(val >= 0 and val <= UINT8_MAX)
    return file.store_8(val)

func read_bool() -> bool:
    return bool(file.get_8())

func write_bool(val: bool) -> bool:
    return file.store_8(int(val))

func read_u8() -> int:
    return file.get_8()

func write_u8(val: int) -> bool:
    assert(val >= 0 and val <= UINT8_MAX)
    return file.store_8(val)

func read_i8() -> int:
    var raw = file.get_8()
    return (raw << 56) >> 56

func write_i8(val: int) -> bool:
    assert(val >= INT8_MIN and val <= INT8_MAX)
    return file.store_8(val)

func read_u16() -> int:
    return file.get_16()

func write_u16(val: int) -> bool:
    assert(val >= 0 and val <= UINT16_MAX)
    return file.store_16(val)

func read_i16() -> int:
    var raw = file.get_16()
    return (raw << 48) >> 48

func write_i16(val: int) -> bool:
    assert(val >= INT16_MIN and val <= INT16_MAX)
    return file.store_16(val)

func read_u32() -> int:
    return file.get_32()

func write_u32(val: int) -> bool:
    assert(val >= 0 and val <= UINT32_MAX)
    return file.store_32(val)

func read_i32() -> int:
    var raw = file.get_32()
    return (raw << 32) >> 32

func write_i32(val: int) -> bool:
    assert(val >= INT32_MIN and val <= INT32_MAX)
    return file.store_32(val)

func read_u63() -> int:
    return file.get_64()

func write_u63(val: int) -> bool:
    assert(val >= 0)
    return file.store_64(val)

func read_i64() -> int:
    return file.get_64()

func write_i64(val: int) -> bool:
    return file.store_64(val)

func read_f16() -> float:
    return file.get_half()

func write_f16(val: float) -> bool:
    return file.store_half(val)

func read_f32() -> float:
    return file.get_float()

func write_f32(val: float) -> bool:
    return file.store_float(val)

func read_f64() -> float:
    return file.get_double()

func write_f64(val: float) -> bool:
    return file.store_double(val)

func read_no_prefix_string_utf8(bytes: int) -> String:
    return file.get_buffer(bytes).get_string_from_utf8()

func write_no_prefix_string_utf8(string: String) -> bool:
    return file.store_buffer(string.to_utf8_buffer())

func read_len_prefix_string_utf8() -> String:
    return file.get_pascal_string()

func write_len_prefix_string_utf8(string: String) -> bool:
    return file.store_pascal_string(string)

func read_no_prefix_string_ascii(bytes: int) -> String:
    return file.get_buffer(bytes).get_string_from_ascii()

func write_no_prefix_string_ascii(string: String) -> bool:
    return file.store_buffer(string.to_ascii_buffer())

func read_len_prefix_string_ascii() -> String:
    var count = file.get_32()
    var ascii: PackedByteArray = file.get_buffer(count)
    return ascii.get_string_from_ascii()

func write_len_prefix_string_ascii(string: String) -> bool:
    var ascii = string.to_ascii_buffer()
    file.store_32(ascii.size())
    return file.store_buffer(ascii)

func read_variant_no_objects() -> Variant:
    return file.get_var(false)

func write_variant_no_objects(variant: Variant) -> bool:
    return file.store_var(variant, false)

func read_variant_allow_objects() -> Variant:
    return file.get_var(true)

func write_variant_allow_objects(variant: Variant) -> bool:
    return file.store_var(variant, true)

func read_custom(routine: Callable) -> Variant:
    return routine.call(file)

func write_custom(routine: Callable, val: Variant) -> bool:
    return routine.call(file, val)

#endregion

#region Vectors

func read_vec2_u8() -> Vector2i:
    var x = file.get_8()
    var y = file.get_8()
    return Vector2i(x, y)

func write_vec2_u8(val: Vector2i) -> bool:
    assert(val.x >= 0 and val.x <= UINT8_MAX)
    assert(val.y >= 0 and val.y <= UINT8_MAX)
    var ok = file.store_8(val.x)
    return ok and file.store_8(val.y)

func read_vec3_u8() -> Vector3i:
    var x = file.get_8()
    var y = file.get_8()
    var z = file.get_8()
    return Vector3i(x, y, z)

func write_vec3_u8(val: Vector3i) -> bool:
    assert(val.x >= 0 and val.x <= UINT8_MAX)
    assert(val.y >= 0 and val.y <= UINT8_MAX)
    assert(val.z >= 0 and val.z <= UINT8_MAX)
    var ok = file.store_8(val.x)
    ok = ok and file.store_8(val.y)
    return ok and file.store_8(val.z)

func read_vec4_u8() -> Vector4i:
    var x = file.get_8()
    var y = file.get_8()
    var z = file.get_8()
    var w = file.get_8()
    return Vector4i(x, y, z, w)

func write_vec4_u8(val: Vector4i) -> bool:
    assert(val.x >= 0 and val.x <= UINT8_MAX)
    assert(val.y >= 0 and val.y <= UINT8_MAX)
    assert(val.z >= 0 and val.z <= UINT8_MAX)
    assert(val.w >= 0 and val.w <= UINT8_MAX)
    var ok = file.store_8(val.x)
    ok = ok and file.store_8(val.y)
    ok = ok and file.store_8(val.z)
    return ok and file.store_8(val.w)

func read_vec2_i8() -> Vector2i:
    var x = (file.get_8() << 56) >> 56
    var y = (file.get_8() << 56) >> 56
    return Vector2i(x, y)

func write_vec2_i8(val: Vector2i) -> bool:
    assert(val.x >= INT8_MIN and val.x <= INT8_MAX)
    assert(val.y >= INT8_MIN and val.y <= INT8_MAX)
    var ok = file.store_8(val.x)
    return ok and file.store_8(val.y)

func read_vec3_i8() -> Vector3i:
    var x = (file.get_8() << 56) >> 56
    var y = (file.get_8() << 56) >> 56
    var z = (file.get_8() << 56) >> 56
    return Vector3i(x, y, z)

func write_vec3_i8(val: Vector3i) -> bool:
    assert(val.x >= INT8_MIN and val.x <= INT8_MAX)
    assert(val.y >= INT8_MIN and val.y <= INT8_MAX)
    assert(val.z >= INT8_MIN and val.z <= INT8_MAX)
    var ok = file.store_8(val.x)
    ok = ok and file.store_8(val.y)
    return ok and file.store_8(val.z)

func read_vec4_i8() -> Vector4i:
    var x = (file.get_8() << 56) >> 56
    var y = (file.get_8() << 56) >> 56
    var z = (file.get_8() << 56) >> 56
    var w = (file.get_8() << 56) >> 56
    return Vector4i(x, y, z, w)

func write_vec4_i8(val: Vector4i) -> bool:
    assert(val.x >= INT8_MIN and val.x <= INT8_MAX)
    assert(val.y >= INT8_MIN and val.y <= INT8_MAX)
    assert(val.z >= INT8_MIN and val.z <= INT8_MAX)
    assert(val.w >= INT8_MIN and val.w <= INT8_MAX)
    var ok = file.store_8(val.x)
    ok = ok and file.store_8(val.y)
    ok = ok and file.store_8(val.z)
    return ok and file.store_8(val.w)

func read_vec2_u16() -> Vector2i:
    var x = file.get_16()
    var y = file.get_16()
    return Vector2i(x, y)

func write_vec2_u16(val: Vector2i) -> bool:
    assert(val.x >= 0 and val.x <= UINT16_MAX)
    assert(val.y >= 0 and val.y <= UINT16_MAX)
    var ok = file.store_16(val.x)
    return ok and file.store_16(val.y)

func read_vec3_u16() -> Vector3i:
    var x = file.get_16()
    var y = file.get_16()
    var z = file.get_16()
    return Vector3i(x, y, z)

func write_vec3_u16(val: Vector3i) -> bool:
    assert(val.x >= 0 and val.x <= UINT16_MAX)
    assert(val.y >= 0 and val.y <= UINT16_MAX)
    assert(val.z >= 0 and val.z <= UINT16_MAX)
    var ok = file.store_16(val.x)
    ok = ok and file.store_16(val.y)
    return ok and file.store_16(val.z)

func read_vec4_u16() -> Vector4i:
    var x = file.get_16()
    var y = file.get_16()
    var z = file.get_16()
    var w = file.get_16()
    return Vector4i(x, y, z, w)

func write_vec4_u16(val: Vector4i) -> bool:
    assert(val.x >= 0 and val.x <= UINT16_MAX)
    assert(val.y >= 0 and val.y <= UINT16_MAX)
    assert(val.z >= 0 and val.z <= UINT16_MAX)
    assert(val.w >= 0 and val.w <= UINT16_MAX)
    var ok = file.store_16(val.x)
    ok = ok and file.store_16(val.y)
    ok = ok and file.store_16(val.z)
    return ok and file.store_16(val.w)

func read_vec2_i16() -> Vector2i:
    var x = (file.get_16() << 48) >> 48
    var y = (file.get_16() << 48) >> 48
    return Vector2i(x, y)

func write_vec2_i16(val: Vector2i) -> bool:
    assert(val.x >= INT16_MIN and val.x <= INT16_MAX)
    assert(val.y >= INT16_MIN and val.y <= INT16_MAX)
    var ok = file.store_16(val.x)
    return ok and file.store_16(val.y)

func read_vec3_i16() -> Vector3i:
    var x = (file.get_16() << 48) >> 48
    var y = (file.get_16() << 48) >> 48
    var z = (file.get_16() << 48) >> 48
    return Vector3i(x, y, z)

func write_vec3_i16(val: Vector3i) -> bool:
    assert(val.x >= INT16_MIN and val.x <= INT16_MAX)
    assert(val.y >= INT16_MIN and val.y <= INT16_MAX)
    assert(val.z >= INT16_MIN and val.z <= INT16_MAX)
    var ok = file.store_16(val.x)
    ok = ok and file.store_16(val.y)
    return ok and file.store_16(val.z)

func read_vec4_i16() -> Vector4i:
    var x = (file.get_16() << 48) >> 48
    var y = (file.get_16() << 48) >> 48
    var z = (file.get_16() << 48) >> 48
    var w = (file.get_16() << 48) >> 48
    return Vector4i(x, y, z, w)

func write_vec4_i16(val: Vector4i) -> bool:
    assert(val.x >= INT16_MIN and val.x <= INT16_MAX)
    assert(val.y >= INT16_MIN and val.y <= INT16_MAX)
    assert(val.z >= INT16_MIN and val.z <= INT16_MAX)
    assert(val.w >= INT16_MIN and val.w <= INT16_MAX)
    var ok = file.store_16(val.x)
    ok = ok and file.store_16(val.y)
    ok = ok and file.store_16(val.z)
    return ok and file.store_16(val.w)

func read_vec2_u32() -> Vector2i:
    var x = file.get_32()
    var y = file.get_32()
    return Vector2i(x, y)

func write_vec2_u32(val: Vector2i) -> bool:
    assert(val.x >= 0 and val.x <= UINT32_MAX)
    assert(val.y >= 0 and val.y <= UINT32_MAX)
    var ok = file.store_32(val.x)
    return ok and file.store_32(val.y)

func read_vec3_u32() -> Vector3i:
    var x = file.get_32()
    var y = file.get_32()
    var z = file.get_32()
    return Vector3i(x, y, z)

func write_vec3_u32(val: Vector3i) -> bool:
    assert(val.x >= 0 and val.x <= UINT32_MAX)
    assert(val.y >= 0 and val.y <= UINT32_MAX)
    assert(val.z >= 0 and val.z <= UINT32_MAX)
    var ok = file.store_32(val.x)
    ok = ok and file.store_32(val.y)
    return ok and file.store_32(val.z)

func read_vec4_u32() -> Vector4i:
    var x = file.get_32()
    var y = file.get_32()
    var z = file.get_32()
    var w = file.get_32()
    return Vector4i(x, y, z, w)

func write_vec4_u32(val: Vector4i) -> bool:
    assert(val.x >= 0 and val.x <= UINT32_MAX)
    assert(val.y >= 0 and val.y <= UINT32_MAX)
    assert(val.z >= 0 and val.z <= UINT32_MAX)
    assert(val.w >= 0 and val.w <= UINT32_MAX)
    var ok = file.store_32(val.x)
    ok = ok and file.store_32(val.y)
    ok = ok and file.store_32(val.z)
    return ok and file.store_32(val.w)

func read_vec2_i32() -> Vector2i:
    var x = (file.get_32() << 32) >> 32
    var y = (file.get_32() << 32) >> 32
    return Vector2i(x, y)

func write_vec2_i32(val: Vector2i) -> bool:
    assert(val.x >= INT32_MIN and val.x <= INT32_MAX)
    assert(val.y >= INT32_MIN and val.y <= INT32_MAX)
    var ok = file.store_32(val.x)
    return ok and file.store_32(val.y)

func read_vec3_i32() -> Vector3i:
    var x = (file.get_32() << 32) >> 32
    var y = (file.get_32() << 32) >> 32
    var z = (file.get_32() << 32) >> 32
    return Vector3i(x, y, z)

func write_vec3_i32(val: Vector3i) -> bool:
    assert(val.x >= INT32_MIN and val.x <= INT32_MAX)
    assert(val.y >= INT32_MIN and val.y <= INT32_MAX)
    assert(val.z >= INT32_MIN and val.z <= INT32_MAX)
    var ok = file.store_32(val.x)
    ok = ok and file.store_32(val.y)
    return ok and file.store_32(val.z)

func read_vec4_i32() -> Vector4i:
    var x = (file.get_32() << 32) >> 32
    var y = (file.get_32() << 32) >> 32
    var z = (file.get_32() << 32) >> 32
    var w = (file.get_32() << 32) >> 32
    return Vector4i(x, y, z, w)

func write_vec4_i32(val: Vector4i) -> bool:
    assert(val.x >= INT32_MIN and val.x <= INT32_MAX)
    assert(val.y >= INT32_MIN and val.y <= INT32_MAX)
    assert(val.z >= INT32_MIN and val.z <= INT32_MAX)
    assert(val.w >= INT32_MIN and val.w <= INT32_MAX)
    var ok = file.store_32(val.x)
    ok = ok and file.store_32(val.y)
    ok = ok and file.store_32(val.z)
    return ok and file.store_32(val.w)

func read_vec2_u63() -> Vector2i:
    var x = file.get_64()
    var y = file.get_64()
    return Vector2i(x, y)

func write_vec2_u63(val: Vector2i) -> bool:
    assert(val.x >= 0)
    assert(val.y >= 0)
    var ok = file.store_64(val.x)
    return ok and file.store_64(val.y)

func read_vec3_u63() -> Vector3i:
    var x = file.get_64()
    var y = file.get_64()
    var z = file.get_64()
    return Vector3i(x, y, z)

func write_vec3_u63(val: Vector3i) -> bool:
    assert(val.x >= 0)
    assert(val.y >= 0)
    assert(val.z >= 0)
    var ok = file.store_64(val.x)
    ok = ok and file.store_64(val.y)
    return ok and file.store_64(val.z)

func read_vec4_u63() -> Vector4i:
    var x = file.get_64()
    var y = file.get_64()
    var z = file.get_64()
    var w = file.get_64()
    return Vector4i(x, y, z, w)

func write_vec4_u63(val: Vector4i) -> bool:
    assert(val.x >= 0)
    assert(val.y >= 0)
    assert(val.z >= 0)
    assert(val.w >= 0)
    var ok = file.store_64(val.x)
    ok = ok and file.store_64(val.y)
    ok = ok and file.store_64(val.z)
    return ok and file.store_64(val.w)

func read_vec2_i64() -> Vector2i:
    var x = file.get_64()
    var y = file.get_64()
    return Vector2i(x, y)

func write_vec2_i64(val: Vector2i) -> bool:
    var ok = file.store_64(val.x)
    return ok and file.store_64(val.y)

func read_vec3_i64() -> Vector3i:
    var x = file.get_64()
    var y = file.get_64()
    var z = file.get_64()
    return Vector3i(x, y, z)

func write_vec3_i64(val: Vector3i) -> bool:
    var ok = file.store_64(val.x)
    ok = ok and file.store_64(val.y)
    return ok and file.store_64(val.z)

func read_vec4_i64() -> Vector4i:
    var x = file.get_64()
    var y = file.get_64()
    var z = file.get_64()
    var w = file.get_64()
    return Vector4i(x, y, z, w)

func write_vec4_i64(val: Vector4i) -> bool:
    var ok = file.store_64(val.x)
    ok = ok and file.store_64(val.y)
    ok = ok and file.store_64(val.z)
    return ok and file.store_64(val.w)

func read_vec2_f16() -> Vector2:
    var x = file.get_half()
    var y = file.get_half()
    return Vector2(x, y)

func write_vec2_f16(val: Vector2) -> bool:
    var ok = file.store_half(val.x)
    return ok and file.store_half(val.y)

func read_vec3_f16() -> Vector3:
    var x = file.get_half()
    var y = file.get_half()
    var z = file.get_half()
    return Vector3(x, y, z)

func write_vec3_f16(val: Vector3) -> bool:
    var ok = file.store_half(val.x)
    ok = ok and file.store_half(val.y)
    return ok and file.store_half(val.z)

func read_vec4_f16() -> Vector4:
    var x = file.get_half()
    var y = file.get_half()
    var z = file.get_half()
    var w = file.get_half()
    return Vector4(x, y, z, w)

func write_vec4_f16(val: Vector4) -> bool:
    var ok = file.store_half(val.x)
    ok = ok and file.store_half(val.y)
    ok = ok and file.store_half(val.z)
    return ok and file.store_half(val.w)

func read_vec2_f32() -> Vector2:
    var x = file.get_float()
    var y = file.get_float()
    return Vector2(x, y)

func write_vec2_f32(val: Vector2) -> bool:
    var ok = file.store_float(val.x)
    return ok and file.store_float(val.y)

func read_vec3_f32() -> Vector3:
    var x = file.get_float()
    var y = file.get_float()
    var z = file.get_float()
    return Vector3(x, y, z)

func write_vec3_f32(val: Vector3) -> bool:
    var ok = file.store_float(val.x)
    ok = ok and file.store_float(val.y)
    return ok and file.store_float(val.z)

func read_vec4_f32() -> Vector4:
    var x = file.get_float()
    var y = file.get_float()
    var z = file.get_float()
    var w = file.get_float()
    return Vector4(x, y, z, w)

func write_vec4_f32(val: Vector4) -> bool:
    var ok = file.store_float(val.x)
    ok = ok and file.store_float(val.y)
    ok = ok and file.store_float(val.z)
    return ok and file.store_float(val.w)

func read_vec2_f64() -> Vector2:
    var x = file.get_double()
    var y = file.get_double()
    return Vector2(x, y)

func write_vec2_f64(val: Vector2) -> bool:
    var ok = file.store_double(val.x)
    return ok and file.store_double(val.y)

func read_vec3_f64() -> Vector3:
    var x = file.get_double()
    var y = file.get_double()
    var z = file.get_double()
    return Vector3(x, y, z)

func write_vec3_f64(val: Vector3) -> bool:
    var ok = file.store_double(val.x)
    ok = ok and file.store_double(val.y)
    return ok and file.store_double(val.z)

func read_vec4_f64() -> Vector4:
    var x = file.get_double()
    var y = file.get_double()
    var z = file.get_double()
    var w = file.get_double()
    return Vector4(x, y, z, w)

func write_vec4_f64(val: Vector4) -> bool:
    var ok = file.store_double(val.x)
    ok = ok and file.store_double(val.y)
    ok = ok and file.store_double(val.z)
    return ok and file.store_double(val.w)

func write_color_u8(val: Color) -> bool:
    var vec = _col_to_vec4_int(val, UINT8_MAX)
    return write_vec4_u8(vec)

func read_color_u8() -> Color:
    var vec = read_vec4_u8()
    return _vec4_int_to_col(vec, UINT8_MAX)

func write_color_u16(val: Color) -> bool:
    var vec = _col_to_vec4_int(val, UINT16_MAX)
    return write_vec4_u16(vec)

func read_color_u16() -> Color:
    var vec = read_vec4_u16()
    return _vec4_int_to_col(vec, UINT16_MAX)

func write_color_u32(val: Color) -> bool:
    var vec = _col_to_vec4_int(val, UINT32_MAX)
    return write_vec4_u32(vec)

func read_color_u32() -> Color:
    var vec = read_vec4_u32()
    return _vec4_int_to_col(vec, UINT32_MAX)

func read_color_f16() -> Color:
    var r = file.get_half()
    var g = file.get_half()
    var b = file.get_half()
    var a = file.get_half()
    return Color(r, g, b, a)

func write_color_f16(val: Color) -> bool:
    var ok = file.store_half(val.r)
    ok = ok and file.store_half(val.g)
    ok = ok and file.store_half(val.b)
    return ok and file.store_half(val.a)

func read_color_f32() -> Color:
    var r = file.get_float()
    var g = file.get_float()
    var b = file.get_float()
    var a = file.get_float()
    return Color(r, g, b, a)

func write_color_f32(val: Color) -> bool:
    var ok = file.store_float(val.r)
    ok = ok and file.store_float(val.g)
    ok = ok and file.store_float(val.b)
    return ok and file.store_float(val.a)

func read_color_f64() -> Color:
    var r = file.get_double()
    var g = file.get_double()
    var b = file.get_double()
    var a = file.get_double()
    return Color(r, g, b, a)

func write_color_f64(val: Color) -> bool:
    var ok = file.store_double(val.r)
    ok = ok and file.store_double(val.g)
    ok = ok and file.store_double(val.b)
    return ok and file.store_double(val.a)

#endregion

#region Arrays (no length prefix)

func read_byte_array(count: int) -> PackedByteArray:
    return file.get_buffer(count)

func write_byte_array(val: PackedByteArray) -> bool:
    return file.store_buffer(val)

func read_bool_array(count: int) -> PackedByteArray:
    return file.get_buffer(count)

func write_bool_array(val: PackedByteArray) -> bool:
    return file.store_buffer(val)

func read_u8_array(count: int) -> PackedInt32Array:
    var arr: PackedInt32Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = file.get_8()
        i += 1
    return arr

func write_u8_array(val: PackedInt32Array) -> bool:
    var success := true
    for v in val:
        success = success and write_u8(v)
    return success

func read_i8_array(count: int) -> PackedInt32Array:
    var arr: PackedInt32Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = (file.get_8() << 56) >> 56
        i += 1
    return arr

func write_i8_array(val: PackedInt32Array) -> bool:
    var success := true
    for v in val:
        success = success and write_i8(v)
    return success

func read_u16_array(count: int) -> PackedInt32Array:
    var arr: PackedInt32Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = file.get_16()
        i += 1
    return arr

func write_u16_array(val: PackedInt32Array) -> bool:
    var success := true
    for v in val:
        success = success and write_u16(v)
    return success

func read_i16_array(count: int) -> PackedInt32Array:
    var arr: PackedInt32Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = (file.get_16() << 48) >> 48
        i += 1
    return arr

func write_i16_array(val: PackedInt32Array) -> bool:
    var success := true
    for v in val:
        success = success and write_i16(v)
    return success

func read_u32_array(count: int) -> PackedInt64Array:
    var arr: PackedInt64Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = file.get_32()
        i += 1
    return arr

func write_u32_array(val: PackedInt64Array) -> bool:
    var success := true
    for v in val:
        success = success and write_u32(v)
    return success

func read_i32_array(count: int) -> PackedInt32Array:
    var arr: PackedInt32Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = (file.get_32() << 32) >> 32
        i += 1
    return arr

func write_i32_array(val: PackedInt32Array) -> bool:
    var success := true
    for v in val:
        success = success and write_i32(v)
    return success

func read_u63_array(count: int) -> PackedInt64Array:
    var arr: PackedInt64Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = file.get_64()
        i += 1
    return arr

func write_u63_array(val: PackedInt64Array) -> bool:
    var success := true
    for v in val:
        success = success and write_u63(v)
    return success

func read_i64_array(count: int) -> PackedInt64Array:
    var arr: PackedInt64Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = file.get_64()
        i += 1
    return arr

func write_i64_array(val: PackedInt64Array) -> bool:
    var success := true
    for v in val:
        success = success and file.store_64(v)
    return success

func read_f16_array(count: int) -> PackedFloat32Array:
    var arr: PackedFloat32Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = file.get_half()
        i += 1
    return arr

func write_f16_array(val: PackedFloat32Array) -> bool:
    var success := true
    for v in val:
        success = success and file.store_half(v)
    return success

func read_f32_array(count: int) -> PackedFloat32Array:
    var arr: PackedFloat32Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = file.get_float()
        i += 1
    return arr

func write_f32_array(val: PackedFloat32Array) -> bool:
    var success := true
    for v in val:
        success = success and file.store_float(v)
    return success

func read_f64_array(count: int) -> PackedFloat64Array:
    var arr: PackedFloat64Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = file.get_double()
        i += 1
    return arr

func write_f64_array(val: PackedFloat64Array) -> bool:
    var success := true
    for v in val:
        success = success and file.store_double(v)
    return success

func read_no_prefix_string_utf8_array(byte_counts: PackedInt32Array) -> PackedStringArray:
    var arr: PackedStringArray
    var count = byte_counts.size()
    arr.resize(count)
    var i := 0
    while i < count:
        var bytes = byte_counts[i]
        arr[i] = file.get_buffer(bytes).get_string_from_utf8()
        i += 1
    return arr

func write_no_prefix_string_utf8_array(strings: PackedStringArray) -> bool:
    var success := true
    for s in strings:
        success = success and file.store_buffer(s.to_utf8_buffer())
    return success

func read_len_prefix_string_utf8_array(count: int) -> PackedStringArray:
    var arr: PackedStringArray
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = file.get_pascal_string()
        i += 1
    return arr

func write_len_prefix_string_utf8_array(strings: PackedStringArray) -> bool:
    var success := true
    for s in strings:
        success = success and file.store_pascal_string(s)
    return success

func read_no_prefix_string_ascii_array(byte_counts: PackedInt32Array) -> PackedStringArray:
    var arr: PackedStringArray
    var count = byte_counts.size()
    arr.resize(count)
    var i := 0
    while i < count:
        var bytes = byte_counts[i]
        arr[i] = file.get_buffer(bytes).get_string_from_ascii()
        i += 1
    return arr

func write_no_prefix_string_ascii_array(strings: PackedStringArray) -> bool:
    var success := true
    for s in strings:
        success = success and file.store_buffer(s.to_ascii_buffer())
    return success

func read_len_prefix_string_ascii_array(count: int) -> PackedStringArray:
    var arr: PackedStringArray
    arr.resize(count)
    var i := 0
    while i < count:
        var bytes = file.get_32()
        var ascii: PackedByteArray = file.get_buffer(bytes)
        arr[i] = ascii.get_string_from_ascii()
        i += 1
    return arr

func write_len_prefix_string_ascii_array(strings: PackedStringArray) -> bool:
    var success := true
    for s in strings:
        var ascii = s.to_ascii_buffer()
        success = success and file.store_32(ascii.size())
        success = success and file.store_buffer(ascii)
    return success

func read_variant_no_objects_array(count:int) -> Array:
    var arr: Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = file.get_var(false)
        i += 1
    return arr

func write_variant_no_objects_array(variants: Array) -> bool:
    var success := true
    for v in variants:
        success = success and file.store_var(v, false)
    return success

func read_variant_allow_objects_array(count: int) -> Array:
    var arr: Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = file.get_var(true)
        i += 1
    return arr

func write_variant_allow_objects_array(variants: Array) -> bool:
    var success := true
    for v in variants:
        success = success and file.store_var(v, true)
    return success

func read_custom_array(routine: Callable, count: int) -> Array:
    var arr: Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = routine.call(self)
        i += 1
    return arr

func write_custom_array(routine: Callable, vals: Array) -> bool:
    var success := true
    for v in vals:
        success = success and routine.call(self, v)
    return success

#endregion

#region Arrays (Vector, no len prefix)

func read_vec2_u8_array(count: int) -> Array[Vector2i]:
    var arr: Array[Vector2i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec2_u8()
        i += 1
    return arr

func write_vec2_u8_array(vals: Array[Vector2i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec2_u8(v)
    return success

func read_vec3_u8_array(count: int) -> Array[Vector3i]:
    var arr: Array[Vector3i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec3_u8()
        i += 1
    return arr

func write_vec3_u8_array(vals: Array[Vector3i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec3_u8(v)
    return success

func read_vec4_u8_array(count: int) -> Array[Vector4i]:
    var arr: Array[Vector4i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec4_u8()
        i += 1
    return arr

func write_vec4_u8_array(vals: Array[Vector4i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec4_u8(v)
    return success

func read_vec2_i8_array(count: int) -> Array[Vector2i]:
    var arr: Array[Vector2i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec2_i8()
        i += 1
    return arr

func write_vec2_i8_array(vals: Array[Vector2i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec2_i8(v)
    return success

func read_vec3_i8_array(count: int) -> Array[Vector3i]:
    var arr: Array[Vector3i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec3_i8()
        i += 1
    return arr

func write_vec3_i8_array(vals: Array[Vector3i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec3_i8(v)
    return success

func read_vec4_i8_array(count: int) -> Array[Vector4i]:
    var arr: Array[Vector4i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec4_i8()
        i += 1
    return arr

func write_vec4_i8_array(vals: Array[Vector4i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec4_i8(v)
    return success

func read_vec2_u16_array(count: int) -> Array[Vector2i]:
    var arr: Array[Vector2i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec2_u16()
        i += 1
    return arr

func write_vec2_u16_array(vals: Array[Vector2i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec2_u16(v)
    return success

func read_vec3_u16_array(count: int) -> Array[Vector3i]:
    var arr: Array[Vector3i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec3_u16()
        i += 1
    return arr

func write_vec3_u16_array(vals: Array[Vector3i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec3_u16(v)
    return success

func read_vec4_u16_array(count: int) -> Array[Vector4i]:
    var arr: Array[Vector4i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec4_u16()
        i += 1
    return arr

func write_vec4_u16_array(vals: Array[Vector4i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec4_u16(v)
    return success

func read_vec2_i16_array(count: int) -> Array[Vector2i]:
    var arr: Array[Vector2i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec2_i16()
        i += 1
    return arr

func write_vec2_i16_array(vals: Array[Vector2i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec2_i16(v)
    return success

func read_vec3_i16_array(count: int) -> Array[Vector3i]:
    var arr: Array[Vector3i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec3_i16()
        i += 1
    return arr

func write_vec3_i16_array(vals: Array[Vector3i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec3_i16(v)
    return success

func read_vec4_i16_array(count: int) -> Array[Vector4i]:
    var arr: Array[Vector4i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec4_i16()
        i += 1
    return arr

func write_vec4_i16_array(vals: Array[Vector4i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec4_i16(v)
    return success

func read_vec2_u32_array(count: int) -> Array[Vector2i]:
    var arr: Array[Vector2i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec2_u32()
        i += 1
    return arr

func write_vec2_u32_array(vals: Array[Vector2i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec2_u32(v)
    return success

func read_vec3_u32_array(count: int) -> Array[Vector3i]:
    var arr: Array[Vector3i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec3_u32()
        i += 1
    return arr

func write_vec3_u32_array(vals: Array[Vector3i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec3_u32(v)
    return success

func read_vec4_u32_array(count: int) -> Array[Vector4i]:
    var arr: Array[Vector4i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec4_u32()
        i += 1
    return arr

func write_vec4_u32_array(vals: Array[Vector4i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec4_u32(v)
    return success

func read_vec2_i32_array(count: int) -> Array[Vector2i]:
    var arr: Array[Vector2i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec2_i32()
        i += 1
    return arr

func write_vec2_i32_array(vals: Array[Vector2i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec2_i32(v)
    return success

func read_vec3_i32_array(count: int) -> Array[Vector3i]:
    var arr: Array[Vector3i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec3_i32()
        i += 1
    return arr

func write_vec3_i32_array(vals: Array[Vector3i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec3_i32(v)
    return success

func read_vec4_i32_array(count: int) -> Array[Vector4i]:
    var arr: Array[Vector4i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec4_i32()
        i += 1
    return arr

func write_vec4_i32_array(vals: Array[Vector4i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec4_i32(v)
    return success

func read_vec2_u63_array(count: int) -> Array[Vector2i]:
    var arr: Array[Vector2i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec2_u63()
        i += 1
    return arr

func write_vec2_u63_array(vals: Array[Vector2i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec2_u63(v)
    return success

func read_vec3_u63_array(count: int) -> Array[Vector3i]:
    var arr: Array[Vector3i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec3_u63()
        i += 1
    return arr

func write_vec3_u63_array(vals: Array[Vector3i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec3_u63(v)
    return success

func read_vec4_u63_array(count: int) -> Array[Vector4i]:
    var arr: Array[Vector4i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec4_u63()
        i += 1
    return arr

func write_vec4_u63_array(vals: Array[Vector4i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec4_u63(v)
    return success

func read_vec2_i64_array(count: int) -> Array[Vector2i]:
    var arr: Array[Vector2i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec2_i64()
        i += 1
    return arr

func write_vec2_i64_array(vals: Array[Vector2i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec2_i64(v)
    return success

func read_vec3_i64_array(count: int) -> Array[Vector3i]:
    var arr: Array[Vector3i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec3_i64()
        i += 1
    return arr

func write_vec3_i64_array(vals: Array[Vector3i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec3_i64(v)
    return success

func read_vec4_i64_array(count: int) -> Array[Vector4i]:
    var arr: Array[Vector4i]
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec4_i64()
        i += 1
    return arr

func write_vec4_i64_array(vals: Array[Vector4i]) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec4_i64(v)
    return success

func read_vec2_f16_array(count: int) -> PackedVector2Array:
    var arr: PackedVector2Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec2_f16()
        i += 1
    return arr

func write_vec2_f16_array(vals: PackedVector2Array) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec2_f16(v)
    return success

func read_vec3_f16_array(count: int) -> PackedVector3Array:
    var arr: PackedVector3Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec3_f16()
        i += 1
    return arr

func write_vec3_f16_array(vals: PackedVector3Array) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec3_f16(v)
    return success

func read_vec4_f16_array(count: int) -> PackedVector4Array:
    var arr: PackedVector4Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec4_f16()
        i += 1
    return arr

func write_vec4_f16_array(vals: PackedVector4Array) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec4_f16(v)
    return success

func read_vec2_f32_array(count: int) -> PackedVector2Array:
    var arr: PackedVector2Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec2_f32()
        i += 1
    return arr

func write_vec2_f32_array(vals: PackedVector2Array) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec2_f32(v)
    return success

func read_vec3_f32_array(count: int) -> PackedVector3Array:
    var arr: PackedVector3Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec3_f32()
        i += 1
    return arr

func write_vec3_f32_array(vals: PackedVector3Array) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec3_f32(v)
    return success

func read_vec4_f32_array(count: int) -> PackedVector4Array:
    var arr: PackedVector4Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec4_f32()
        i += 1
    return arr

func write_vec4_f32_array(vals: PackedVector4Array) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec4_f32(v)
    return success

func read_vec2_f64_array(count: int) -> PackedVector2Array:
    var arr: PackedVector2Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec2_f64()
        i += 1
    return arr

func write_vec2_f64_array(vals: PackedVector2Array) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec2_f64(v)
    return success

func read_vec3_f64_array(count: int) -> PackedVector3Array:
    var arr: PackedVector3Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec3_f64()
        i += 1
    return arr

func write_vec3_f64_array(vals: PackedVector3Array) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec3_f64(v)
    return success

func read_vec4_f64_array(count: int) -> PackedVector4Array:
    var arr: PackedVector4Array
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_vec4_f64()
        i += 1
    return arr

func write_vec4_f64_array(vals: PackedVector4Array) -> bool:
    var success := true
    for v in vals:
        success = success and write_vec4_f64(v)
    return success

func read_color_u8_array(count: int) -> PackedColorArray:
    var arr: PackedColorArray
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_color_u8()
        i += 1
    return arr

func write_color_u8_array(vals: PackedColorArray) -> bool:
    var success := true
    for v in vals:
        success = success and write_color_u8(v)
    return success

func read_color_u16_array(count: int) -> PackedColorArray:
    var arr: PackedColorArray
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_color_u16()
        i += 1
    return arr

func write_color_u16_array(vals: PackedColorArray) -> bool:
    var success := true
    for v in vals:
        success = success and write_color_u16(v)
    return success

func read_color_u32_array(count: int) -> PackedColorArray:
    var arr: PackedColorArray
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_color_u32()
        i += 1
    return arr

func write_color_u32_array(vals: PackedColorArray) -> bool:
    var success := true
    for v in vals:
        success = success and write_color_u32(v)
    return success

func read_color_f16_array(count: int) -> PackedColorArray:
    var arr: PackedColorArray
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_color_f16()
        i += 1
    return arr

func write_color_f16_array(vals: PackedColorArray) -> bool:
    var success := true
    for v in vals:
        success = success and write_color_f16(v)
    return success

func read_color_f32_array(count: int) -> PackedColorArray:
    var arr: PackedColorArray
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_color_f32()
        i += 1
    return arr

func write_color_f32_array(vals: PackedColorArray) -> bool:
    var success := true
    for v in vals:
        success = success and write_color_f32(v)
    return success

func read_color_f64_array(count: int) -> PackedColorArray:
    var arr: PackedColorArray
    arr.resize(count)
    var i := 0
    while i < count:
        arr[i] = read_color_f64()
        i += 1
    return arr

func write_color_f64_array(vals: PackedColorArray) -> bool:
    var success := true
    for v in vals:
        success = success and write_color_f64(v)
    return success

#endregion

#region Len-Prefixed Arrays

func read_byte_array_len_prefix() -> PackedByteArray:
    var count = file.get_32()
    return read_byte_array(count)

func write_byte_array_len_prefix(val: PackedByteArray) -> bool:
    var count = val.size()
    var success = file.store_32(count)
    return success and write_byte_array(val)

func read_bool_array_len_prefix() -> PackedByteArray:
    var count = file.get_32()
    return read_bool_array(count)

func write_bool_array_len_prefix(val: PackedByteArray) -> bool:
    var count = val.size()
    var success = file.store_32(count)
    return success and write_bool_array(val)

func read_u8_array_len_prefix() -> PackedInt32Array:
    var count = file.get_32()
    return read_u8_array(count)

func write_u8_array_len_prefix(val: PackedInt32Array) -> bool:
    var count = val.size()
    var success = file.store_32(count)
    return success and write_u8_array(val)

func read_i8_array_len_prefix() -> PackedInt32Array:
    var count = file.get_32()
    return read_i8_array(count)

func write_i8_array_len_prefix(val: PackedInt32Array) -> bool:
    var count = val.size()
    var success = file.store_32(count)
    return success and write_i8_array(val)

func read_u16_array_len_prefix() -> PackedInt32Array:
    var count = file.get_32()
    return read_u16_array(count)

func write_u16_array_len_prefix(val: PackedInt32Array) -> bool:
    var count = val.size()
    var success = file.store_32(count)
    return success and write_u16_array(val)

func read_i16_array_len_prefix() -> PackedInt32Array:
    var count = file.get_32()
    return read_i16_array(count)

func write_i16_array_len_prefix(val: PackedInt32Array) -> bool:
    var count = val.size()
    var success = file.store_32(count)
    return success and write_i16_array(val)

func read_u32_array_len_prefix() -> PackedInt64Array:
    var count = file.get_32()
    return read_u32_array(count)

func write_u32_array_len_prefix(val: PackedInt64Array) -> bool:
    var count = val.size()
    var success = file.store_32(count)
    return success and write_u32_array(val)

func read_i32_array_len_prefix() -> PackedInt32Array:
    var count = file.get_32()
    return read_i32_array(count)

func write_i32_array_len_prefix(val: PackedInt32Array) -> bool:
    var count = val.size()
    var success = file.store_32(count)
    return success and write_i32_array(val)

func read_u63_array_len_prefix() -> PackedInt64Array:
    var count = file.get_32()
    return read_u63_array(count)

func write_u63_array_len_prefix(val: PackedInt64Array) -> bool:
    var count = val.size()
    var success = file.store_32(count)
    return success and write_u63_array(val)

func read_i64_array_len_prefix() -> PackedInt64Array:
    var count = file.get_32()
    return read_i64_array(count)

func write_i64_array_len_prefix(val: PackedInt64Array) -> bool:
    var count = val.size()
    var success = file.store_32(count)
    return success and write_i64_array(val)

func read_f16_array_len_prefix() -> PackedFloat32Array:
    var count = file.get_32()
    return read_f16_array(count)

func write_f16_array_len_prefix(val: PackedFloat32Array) -> bool:
    var count = val.size()
    var success = file.store_32(count)
    return success and write_f16_array(val)

func read_f32_array_len_prefix() -> PackedFloat32Array:
    var count = file.get_32()
    return read_f32_array(count)

func write_f32_array_len_prefix(val: PackedFloat32Array) -> bool:
    var count = val.size()
    var success = file.store_32(count)
    return success and write_f32_array(val)

func read_f64_array_len_prefix() -> PackedFloat64Array:
    var count = file.get_32()
    return read_f64_array(count)

func write_f64_array_len_prefix(val: PackedFloat64Array) -> bool:
    var count = val.size()
    var success = file.store_32(count)
    return success and write_f64_array(val)

func read_len_prefix_string_utf8_array_len_prefix() -> PackedStringArray:
    var count = file.get_32()
    return read_len_prefix_string_utf8_array(count)

func write_len_prefix_string_utf8_array_len_prefix(strings: PackedStringArray) -> bool:
    var count = strings.size()
    var success = file.store_32(count)
    return success and write_len_prefix_string_utf8_array(strings)

func read_len_prefix_string_ascii_array_len_prefix() -> PackedStringArray:
    var count = file.get_32()
    return read_len_prefix_string_ascii_array(count)

func write_len_prefix_string_ascii_array_len_prefix(strings: PackedStringArray) -> bool:
    var count = strings.size()
    var success = file.store_32(count)
    return success and write_len_prefix_string_ascii_array(strings)

func read_variant_no_objects_array_len_prefix() -> Array:
    var count = file.get_32()
    return read_variant_no_objects_array(count)

func write_variant_no_objects_array_len_prefix(variants: Array) -> bool:
    var count = variants.size()
    var success = file.store_32(count)
    return success and write_variant_no_objects_array(variants)

func read_variant_allow_objects_array_len_prefix() -> Array:
    var count = file.get_32()
    return read_variant_allow_objects_array(count)

func write_variant_allow_objects_array_len_prefix(variants: Array) -> bool:
    var count = variants.size()
    var success = file.store_32(count)
    return success and write_variant_allow_objects_array(variants)

func read_custom_array_len_prefix(routine: Callable) -> Array:
    var count = file.get_32()
    return read_custom_array(routine, count)

func write_custom_array_len_prefix(routine: Callable, vals: Array) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_custom_array(routine, vals)

#endregion

#region Len-prefixed arrays (Vector)

func read_vec2_u8_array_len_prefix() -> Array[Vector2i]:
    var count = file.get_32()
    return read_vec2_u8_array(count)

func write_vec2_u8_array_len_prefix(vals: Array[Vector2i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec2_u8_array(vals)

func read_vec3_u8_array_len_prefix() -> Array[Vector3i]:
    var count = file.get_32()
    return read_vec3_u8_array(count)

func write_vec3_u8_array_len_prefix(vals: Array[Vector3i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec3_u8_array(vals)

func read_vec4_u8_array_len_prefix() -> Array[Vector4i]:
    var count = file.get_32()
    return read_vec4_u8_array(count)

func write_vec4_u8_array_len_prefix(vals: Array[Vector4i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec4_u8_array(vals)

func read_vec2_i8_array_len_prefix() -> Array[Vector2i]:
    var count = file.get_32()
    return read_vec2_i8_array(count)

func write_vec2_i8_array_len_prefix(vals: Array[Vector2i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec2_i8_array(vals)

func read_vec3_i8_array_len_prefix() -> Array[Vector3i]:
    var count = file.get_32()
    return read_vec3_i8_array(count)

func write_vec3_i8_array_len_prefix(vals: Array[Vector3i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec3_i8_array(vals)

func read_vec4_i8_array_len_prefix() -> Array[Vector4i]:
    var count = file.get_32()
    return read_vec4_i8_array(count)

func write_vec4_i8_array_len_prefix(vals: Array[Vector4i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec4_i8_array(vals)

func read_vec2_u16_array_len_prefix() -> Array[Vector2i]:
    var count = file.get_32()
    return read_vec2_u16_array(count)

func write_vec2_u16_array_len_prefix(vals: Array[Vector2i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec2_u16_array(vals)

func read_vec3_u16_array_len_prefix() -> Array[Vector3i]:
    var count = file.get_32()
    return read_vec3_u16_array(count)

func write_vec3_u16_array_len_prefix(vals: Array[Vector3i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec3_u16_array(vals)

func read_vec4_u16_array_len_prefix() -> Array[Vector4i]:
    var count = file.get_32()
    return read_vec4_u16_array(count)

func write_vec4_u16_array_len_prefix(vals: Array[Vector4i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec4_u16_array(vals)

func read_vec2_i16_array_len_prefix() -> Array[Vector2i]:
    var count = file.get_32()
    return read_vec2_i16_array(count)

func write_vec2_i16_array_len_prefix(vals: Array[Vector2i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec2_i16_array(vals)

func read_vec3_i16_array_len_prefix() -> Array[Vector3i]:
    var count = file.get_32()
    return read_vec3_i16_array(count)

func write_vec3_i16_array_len_prefix(vals: Array[Vector3i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec3_i16_array(vals)

func read_vec4_i16_array_len_prefix() -> Array[Vector4i]:
    var count = file.get_32()
    return read_vec4_i16_array(count)

func write_vec4_i16_array_len_prefix(vals: Array[Vector4i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec4_i16_array(vals)

func read_vec2_u32_array_len_prefix() -> Array[Vector2i]:
    var count = file.get_32()
    return read_vec2_u32_array(count)

func write_vec2_u32_array_len_prefix(vals: Array[Vector2i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec2_u32_array(vals)

func read_vec3_u32_array_len_prefix() -> Array[Vector3i]:
    var count = file.get_32()
    return read_vec3_u32_array(count)

func write_vec3_u32_array_len_prefix(vals: Array[Vector3i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec3_u32_array(vals)

func read_vec4_u32_array_len_prefix() -> Array[Vector4i]:
    var count = file.get_32()
    return read_vec4_u32_array(count)

func write_vec4_u32_array_len_prefix(vals: Array[Vector4i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec4_u32_array(vals)

func read_vec2_i32_array_len_prefix() -> Array[Vector2i]:
    var count = file.get_32()
    return read_vec2_i32_array(count)

func write_vec2_i32_array_len_prefix(vals: Array[Vector2i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec2_i32_array(vals)

func read_vec3_i32_array_len_prefix() -> Array[Vector3i]:
    var count = file.get_32()
    return read_vec3_i32_array(count)

func write_vec3_i32_array_len_prefix(vals: Array[Vector3i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec3_i32_array(vals)

func read_vec4_i32_array_len_prefix() -> Array[Vector4i]:
    var count = file.get_32()
    return read_vec4_i32_array(count)

func write_vec4_i32_array_len_prefix(vals: Array[Vector4i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec4_i32_array(vals)

func read_vec2_u63_array_len_prefix() -> Array[Vector2i]:
    var count = file.get_32()
    return read_vec2_u63_array(count)

func write_vec2_u63_array_len_prefix(vals: Array[Vector2i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec2_u63_array(vals)

func read_vec3_u63_array_len_prefix() -> Array[Vector3i]:
    var count = file.get_32()
    return read_vec3_u63_array(count)

func write_vec3_u63_array_len_prefix(vals: Array[Vector3i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec3_u63_array(vals)

func read_vec4_u63_array_len_prefix() -> Array[Vector4i]:
    var count = file.get_32()
    return read_vec4_u63_array(count)

func write_vec4_u63_array_len_prefix(vals: Array[Vector4i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec4_u63_array(vals)

func read_vec2_i64_array_len_prefix() -> Array[Vector2i]:
    var count = file.get_32()
    return read_vec2_i64_array(count)

func write_vec2_i64_array_len_prefix(vals: Array[Vector2i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec2_i64_array(vals)

func read_vec3_i64_array_len_prefix() -> Array[Vector3i]:
    var count = file.get_32()
    return read_vec3_i64_array(count)

func write_vec3_i64_array_len_prefix(vals: Array[Vector3i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec3_i64_array(vals)

func read_vec4_i64_array_len_prefix() -> Array[Vector4i]:
    var count = file.get_32()
    return read_vec4_i64_array(count)

func write_vec4_i64_array_len_prefix(vals: Array[Vector4i]) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec4_i64_array(vals)

func read_vec2_f16_array_len_prefix() -> PackedVector2Array:
    var count = file.get_32()
    return read_vec2_f16_array(count)

func write_vec2_f16_array_len_prefix(vals: PackedVector2Array) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec2_f16_array(vals)

func read_vec3_f16_array_len_prefix() -> PackedVector3Array:
    var count = file.get_32()
    return read_vec3_f16_array(count)

func write_vec3_f16_array_len_prefix(vals: PackedVector3Array) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec3_f16_array(vals)

func read_vec4_f16_array_len_prefix() -> PackedVector4Array:
    var count = file.get_32()
    return read_vec4_f16_array(count)

func write_vec4_f16_array_len_prefix(vals: PackedVector4Array) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec4_f16_array(vals)

func read_vec2_f32_array_len_prefix() -> PackedVector2Array:
    var count = file.get_32()
    return read_vec2_f32_array(count)

func write_vec2_f32_array_len_prefix(vals: PackedVector2Array) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec2_f32_array(vals)

func read_vec3_f32_array_len_prefix() -> PackedVector3Array:
    var count = file.get_32()
    return read_vec3_f32_array(count)

func write_vec3_f32_array_len_prefix(vals: PackedVector3Array) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec3_f32_array(vals)

func read_vec4_f32_array_len_prefix() -> PackedVector4Array:
    var count = file.get_32()
    return read_vec4_f32_array(count)

func write_vec4_f32_array_len_prefix(vals: PackedVector4Array) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec4_f32_array(vals)

func read_vec2_f64_array_len_prefix() -> PackedVector2Array:
    var count = file.get_32()
    return read_vec2_f64_array(count)

func write_vec2_f64_array_len_prefix(vals: PackedVector2Array) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec2_f64_array(vals)

func read_vec3_f64_array_len_prefix() -> PackedVector3Array:
    var count = file.get_32()
    return read_vec3_f64_array(count)

func write_vec3_f64_array_len_prefix(vals: PackedVector3Array) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec3_f64_array(vals)

func read_vec4_f64_array_len_prefix() -> PackedVector4Array:
    var count = file.get_32()
    return read_vec4_f64_array(count)

func write_vec4_f64_array_len_prefix(vals: PackedVector4Array) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_vec4_f64_array(vals)

func read_color_u8_array_len_prefix() -> PackedColorArray:
    var count = file.get_32()
    return read_color_u8_array(count)

func write_color_u8_array_len_prefix(vals: PackedColorArray) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_color_u8_array(vals)

func read_color_u16_array_len_prefix() -> PackedColorArray:
    var count = file.get_32()
    return read_color_u16_array(count)

func write_color_u16_array_len_prefix(vals: PackedColorArray) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_color_u16_array(vals)

func read_color_u32_array_len_prefix() -> PackedColorArray:
    var count = file.get_32()
    return read_color_u32_array(count)

func write_color_u32_array_len_prefix(vals: PackedColorArray) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_color_u32_array(vals)

func read_color_f16_array_len_prefix() -> PackedColorArray:
    var count = file.get_32()
    return read_color_f16_array(count)

func write_color_f16_array_len_prefix(vals: PackedColorArray) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_color_f16_array(vals)

func read_color_f32_array_len_prefix() -> PackedColorArray:
    var count = file.get_32()
    return read_color_f32_array(count)

func write_color_f32_array_len_prefix(vals: PackedColorArray) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_color_f32_array(vals)

func read_color_f64_array_len_prefix() -> PackedColorArray:
    var count = file.get_32()
    return read_color_f64_array(count)

func write_color_f64_array_len_prefix(vals: PackedColorArray) -> bool:
    var count = vals.size()
    var success = file.store_32(count)
    return success and write_color_f64_array(vals)

#endregion

#region Nested Length-prefixed arrays

func read_byte_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_byte_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_nest = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_byte_array_len_prefix_nested(new_nest)
        i += 1
    return arr

func write_byte_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_byte_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_byte_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_bool_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_byte_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_byte_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_bool_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_byte_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_bool_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_u8_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_u8_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_u8_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_u8_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_u8_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_u8_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_i8_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_i8_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_i8_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_i8_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_i8_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_i8_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_u16_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_u16_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_u16_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_u16_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_u16_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_u16_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_i16_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_i16_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_i16_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_i16_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_i16_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_i16_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_u32_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_u32_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_u32_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_u32_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_u32_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_u32_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_i32_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_i32_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_i32_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_i32_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_i32_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_i32_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_u63_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_u63_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_u63_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_u63_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_u63_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_u63_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_i64_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_i64_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_i64_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_i64_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_i64_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_i64_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_f16_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_f16_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_f16_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_f16_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_f16_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_f16_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_f32_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_f32_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_f32_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_f32_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_f32_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_f32_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_f64_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_f64_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_f64_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_f64_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_f64_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_f64_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_len_prefix_string_utf8_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_len_prefix_string_utf8_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_len_prefix_string_utf8_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_len_prefix_string_utf8_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_len_prefix_string_utf8_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_len_prefix_string_utf8_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_len_prefix_string_ascii_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_len_prefix_string_ascii_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_len_prefix_string_ascii_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_len_prefix_string_ascii_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_len_prefix_string_ascii_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_len_prefix_string_ascii_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_variant_no_objects_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_variant_no_objects_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_variant_no_objects_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_variant_no_objects_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_variant_no_objects_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_variant_no_objects_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_variant_allow_objects_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_variant_allow_objects_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_variant_allow_objects_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_variant_allow_objects_array_len_prefix_nested(vals: Variant, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_variant_allow_objects_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_variant_allow_objects_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_custom_array_len_prefix_nested(routine: Callable, depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_custom_array_len_prefix(routine)
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_custom_array_len_prefix_nested(routine, new_depth)
        i += 1
    return arr

func write_custom_array_len_prefix_nested(routine: Callable, vals: Array, depth: int) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_custom_array_len_prefix(routine, vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_custom_array_len_prefix_nested(routine, vals[i], new_depth)
        i += 1
    return success

#endregion

#region Nested Length-prefixed arrays (Vectors)

func read_vec2_u8_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec2_u8_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec2_u8_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec2_u8_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec2_u8_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec2_u8_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec3_u8_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec3_u8_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec3_u8_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec3_u8_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec3_u8_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec3_u8_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec4_u8_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec4_u8_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec4_u8_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec4_u8_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec4_u8_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec4_u8_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec2_i8_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec2_i8_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec2_i8_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec2_i8_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec2_i8_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec2_i8_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec3_i8_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec3_i8_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec3_i8_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec3_i8_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec3_i8_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec3_i8_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec4_i8_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec4_i8_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec4_i8_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec4_i8_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec4_i8_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec4_i8_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec2_u16_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec2_u16_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec2_u16_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec2_u16_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec2_u16_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec2_u16_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec3_u16_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec3_u16_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec3_u16_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec3_u16_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec3_u16_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec3_u16_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec4_u16_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec4_u16_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec4_u16_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec4_u16_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec4_u16_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec4_u16_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec2_i16_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec2_i16_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec2_i16_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec2_i16_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec2_i16_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec2_i16_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec3_i16_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec3_i16_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec3_i16_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec3_i16_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec3_i16_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec3_i16_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec4_i16_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec4_i16_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec4_i16_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec4_i16_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec4_i16_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec4_i16_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec2_u32_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec2_u32_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec2_u32_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec2_u32_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec2_u32_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec2_u32_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec3_u32_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec3_u32_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec3_u32_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec3_u32_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec3_u32_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec3_u32_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec4_u32_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec4_u32_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec4_u32_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec4_u32_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec4_u32_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec4_u32_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec2_i32_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec2_i32_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec2_i32_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec2_i32_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec2_i32_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec2_i32_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec3_i32_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec3_i32_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec3_i32_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec3_i32_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec3_i32_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec3_i32_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec4_i32_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec4_i32_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec4_i32_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec4_i32_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec4_i32_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec4_i32_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec2_u63_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec2_u63_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec2_u63_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec2_u63_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec2_u63_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec2_u63_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec3_u63_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec3_u63_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec3_u63_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec3_u63_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec3_u63_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec3_u63_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec4_u63_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec4_u63_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec4_u63_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec4_u63_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec4_u63_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec4_u63_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec2_i64_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec2_i64_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec2_i64_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec2_i64_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec2_i64_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec2_i64_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec3_i64_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec3_i64_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec3_i64_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec3_i64_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec3_i64_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec3_i64_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec4_i64_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec4_i64_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec4_i64_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec4_i64_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec4_i64_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec4_i64_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec2_f16_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec2_f16_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec2_f16_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec2_f16_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec2_f16_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec2_f16_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec3_f16_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec3_f16_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec3_f16_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec3_f16_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec3_f16_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec3_f16_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec4_f16_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec4_f16_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec4_f16_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec4_f16_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec4_f16_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec4_f16_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec2_f32_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec2_f32_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec2_f32_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec2_f32_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec2_f32_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec2_f32_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec3_f32_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec3_f32_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec3_f32_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec3_f32_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec3_f32_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec3_f32_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec4_f32_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec4_f32_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec4_f32_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec4_f32_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec4_f32_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec4_f32_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec2_f64_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec2_f64_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec2_f64_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec2_f64_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec2_f64_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec2_f64_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec3_f64_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec3_f64_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec3_f64_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec3_f64_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec3_f64_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec3_f64_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_vec4_f64_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_vec4_f64_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_vec4_f64_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_vec4_f64_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_vec4_f64_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_vec4_f64_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_color_u8_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_color_u8_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_color_u8_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_color_u8_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_color_u8_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_color_u8_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_color_u16_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_color_u16_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_color_u16_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_color_u16_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_color_u16_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_color_u16_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_color_u32_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_color_u32_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_color_u32_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_color_u32_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_color_u32_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_color_u32_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_color_f16_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_color_f16_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_color_f16_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_color_f16_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_color_f16_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_color_f16_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_color_f32_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_color_f32_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_color_f32_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_color_f32_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_color_f32_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_color_f32_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success

func read_color_f64_array_len_prefix_nested(depth: int) -> Variant:
    assert(depth >= 0)
    if depth == 0:
        return read_color_f64_array_len_prefix()
    var arr: Array
    var count = file.get_32()
    arr.resize(count)
    var new_depth = depth - 1
    var i: int = 0
    while i < count:
        arr[i] = read_color_f64_array_len_prefix_nested(new_depth)
        i += 1
    return arr

func write_color_f64_array_len_prefix_nested(depth: int, vals: Variant) -> bool:
    assert(depth >= 0)
    if depth == 0:
        return write_color_f64_array_len_prefix(vals)
    var count = vals.size()
    var new_depth = depth - 1
    var i: int = 0
    var success := true
    while i < count:
        success = success and write_color_f64_array_len_prefix_nested(vals[i], new_depth)
        i += 1
    return success
#endregion

class_name TYPE_UTIL extends Object

enum T {
    Byte,
    Bool,
    Int8,
    Int16,
    Int32,
    Int64,
    Uint8,
    Uint16,
    Uint32,
    Uint63,
    Float16,
    Float32,
    Float64,
    Vec2_Int8,
    Vec2_Int16,
    Vec2_Int32,
    Vec2_Int64,
    Vec2_Uint8,
    Vec2_Uint16,
    Vec2_Uint32,
    Vec2_Uint63,
    Vec2_Float16,
    Vec2_Float32,
    Vec2_Float64,
    Vec3_Int8,
    Vec3_Int16,
    Vec3_Int32,
    Vec3_Int64,
    Vec3_Uint8,
    Vec3_Uint16,
    Vec3_Uint32,
    Vec3_Uint63,
    Vec3_Float16,
    Vec3_Float32,
    Vec3_Float64,
    Vec4_Int8,
    Vec4_Int16,
    Vec4_Int32,
    Vec4_Int64,
    Vec4_Uint8,
    Vec4_Uint16,
    Vec4_Uint32,
    Vec4_Uint63,
    Vec4_Float16,
    Vec4_Float32,
    Vec4_Float64,
    Color_Uint8,
    Color_Uint16,
    Color_Uint32,
    Color_Float16,
    Color_Float32,
    String_Utf8,
    String_Ascii,
    Variant_NoObject,
    Variant_AllowObject,
    CustomType,
}
const NUM_T = (T.CustomType as int) + 1

const T_NAME_GEN: PackedStringArray = [
    "byte",
    "bool",
    "i8",
    "i16",
    "i32",
    "i64",
    "u8",
    "u16",
    "u32",
    "u63",
    "f16",
    "f32",
    "f64",
    "vec2_i8",
    "vec2_i16",
    "vec2_i32",
    "vec2_i64",
    "vec2_u8",
    "vec2_u16",
    "vec2_u32",
    "vec2_u63",
    "vec2_f16",
    "vec2_f32",
    "vec2_f64",
    "vec3_i8",
    "vec3_i16",
    "vec3_i32",
    "vec3_i64",
    "vec3_u8",
    "vec3_u16",
    "vec3_u32",
    "vec3_u63",
    "vec3_f16",
    "vec3_f32",
    "vec3_f64",
    "vec4_i8",
    "vec4_i16",
    "vec4_i32",
    "vec4_i64",
    "vec4_u8",
    "vec4_u16",
    "vec4_u32",
    "vec4_u63",
    "vec4_f16",
    "vec4_f32",
    "vec4_f64",
    "color_u8",
    "color_u16",
    "color_u32",
    "color_f16",
    "color_f32",
    "len_prefix_string_utf8",
    "len_prefix_string_ascii",
    "variant_no_objects",
    "variant_allow_objects",
    "custom",
]
const T_VECNESS: PackedInt32Array = [
    1,# Byte,
    1,# Bool,
    1,# Int8,
    1,# Int16,
    1,# Int32,
    1,# Int64,
    1,# Uint8,
    1,# Uint16,
    1,# Uint32,
    1,# Uint63,
    1,# Float16,
    1,# Float32,
    1,# Float64,
    2,# Vec2_Int8,
    2,# Vec2_Int16,
    2,# Vec2_Int32,
    2,# Vec2_Int64,
    2,# Vec2_Uint8,
    2,# Vec2_Uint16,
    2,# Vec2_Uint32,
    2,# Vec2_Uint63,
    2,# Vec2_Float16,
    2,# Vec2_Float32,
    2,# Vec2_Float64,
    3,# Vec3_Int8,
    3,# Vec3_Int16,
    3,# Vec3_Int32,
    3,# Vec3_Int64,
    3,# Vec3_Uint8,
    3,# Vec3_Uint16,
    3,# Vec3_Uint32,
    3,# Vec3_Uint63,
    3,# Vec3_Float16,
    3,# Vec3_Float32,
    3,# Vec3_Float64,
    4,# Vec4_Int8,
    4,# Vec4_Int16,
    4,# Vec4_Int32,
    4,# Vec4_Int64,
    4,# Vec4_Uint8,
    4,# Vec4_Uint16,
    4,# Vec4_Uint32,
    4,# Vec4_Uint63,
    4,# Vec4_Float16,
    4,# Vec4_Float32,
    4,# Vec4_Float64,
    4,# Color_Uint8,
    4,# Color_Uint16,
    4,# Color_Uint32,
    4,# Color_Float16,
    4,# Color_Float32,
    1,# String_Utf8,
    1,# String_Ascii,
    1,# Variant_NoObject,
    1,# Variant_AllowObject,
    1,# CustomType,
]
const T_ELEM_TYPE: PackedByteArray = [
    Variant.Type.TYPE_INT,# Byte,
    Variant.Type.TYPE_BOOL,# Bool,
    Variant.Type.TYPE_INT,# Int8,
    Variant.Type.TYPE_INT,# Int16,
    Variant.Type.TYPE_INT,# Int32,
    Variant.Type.TYPE_INT,# Int64,
    Variant.Type.TYPE_INT,# Uint8,
    Variant.Type.TYPE_INT,# Uint16,
    Variant.Type.TYPE_INT,# Uint32,
    Variant.Type.TYPE_INT,# Uint63,
    Variant.Type.TYPE_FLOAT,# Float16,
    Variant.Type.TYPE_FLOAT,# Float32,
    Variant.Type.TYPE_FLOAT,# Float64,
    Variant.Type.TYPE_INT,# Vec2_Int8,
    Variant.Type.TYPE_INT,# Vec2_Int16,
    Variant.Type.TYPE_INT,# Vec2_Int32,
    Variant.Type.TYPE_INT,# Vec2_Int64,
    Variant.Type.TYPE_INT,# Vec2_Uint8,
    Variant.Type.TYPE_INT,# Vec2_Uint16,
    Variant.Type.TYPE_INT,# Vec2_Uint32,
    Variant.Type.TYPE_INT,# Vec2_Uint63,
    Variant.Type.TYPE_FLOAT,# Vec2_Float16,
    Variant.Type.TYPE_FLOAT,# Vec2_Float32,
    Variant.Type.TYPE_FLOAT,# Vec2_Float64,
    Variant.Type.TYPE_INT,# Vec3_Int8,
    Variant.Type.TYPE_INT,# Vec3_Int16,
    Variant.Type.TYPE_INT,# Vec3_Int32,
    Variant.Type.TYPE_INT,# Vec3_Int64,
    Variant.Type.TYPE_INT,# Vec3_Uint8,
    Variant.Type.TYPE_INT,# Vec3_Uint16,
    Variant.Type.TYPE_INT,# Vec3_Uint32,
    Variant.Type.TYPE_INT,# Vec3_Uint63,
    Variant.Type.TYPE_FLOAT,# Vec3_Float16,
    Variant.Type.TYPE_FLOAT,# Vec3_Float32,
    Variant.Type.TYPE_FLOAT,# Vec3_Float64,
    Variant.Type.TYPE_INT,# Vec4_Int8,
    Variant.Type.TYPE_INT,# Vec4_Int16,
    Variant.Type.TYPE_INT,# Vec4_Int32,
    Variant.Type.TYPE_INT,# Vec4_Int64,
    Variant.Type.TYPE_INT,# Vec4_Uint8,
    Variant.Type.TYPE_INT,# Vec4_Uint16,
    Variant.Type.TYPE_INT,# Vec4_Uint32,
    Variant.Type.TYPE_INT,# Vec4_Uint63,
    Variant.Type.TYPE_FLOAT,# Vec4_Float16,
    Variant.Type.TYPE_FLOAT,# Vec4_Float32,
    Variant.Type.TYPE_FLOAT,# Vec4_Float64,
    Variant.Type.TYPE_INT,# Color_Uint8,
    Variant.Type.TYPE_INT,# Color_Uint16,
    Variant.Type.TYPE_INT,# Color_Uint32,
    Variant.Type.TYPE_FLOAT,# Color_Float16,
    Variant.Type.TYPE_FLOAT,# Color_Float32,
    Variant.Type.TYPE_STRING,# String_Utf8,
    Variant.Type.TYPE_STRING,# String_Ascii,
    Variant.Type.TYPE_NIL,# Variant_NoObject,
    Variant.Type.TYPE_NIL,# Variant_AllowObject,
    Variant.Type.TYPE_NIL,# CustomType,
]
const T_ELEM_MIN: Array = [
    0,# Byte,
    null,# Bool,
    INT8_MIN,# Int8,
    INT16_MIN,# Int16,
    INT32_MIN,# Int32,
    INT64_MIN,# Int64,
    0,# Uint8,
    0,# Uint16,
    0,# Uint32,
    0,# Uint63,
    null,# Float16,
    null,# Float32,
    null,# Float64,
    INT8_MIN,# Vec2_Int8,
    INT16_MIN,# Vec2_Int16,
    INT32_MIN,# Vec2_Int32,
    INT64_MIN,# Vec2_Int64,
    0,# Vec2_Uint8,
    0,# Vec2_Uint16,
    0,# Vec2_Uint32,
    0,# Vec2_Uint63,
    null,# Vec2_Float16,
    null,# Vec2_Float32,
    null,# Vec2_Float64,
    INT8_MIN,# Vec3_Int8,
    INT16_MIN,# Vec3_Int16,
    INT32_MIN,# Vec3_Int32,
    INT64_MIN,# Vec3_Int64,
    0,# Vec3_Uint8,
    0,# Vec3_Uint16,
    0,# Vec3_Uint32,
    0,# Vec3_Uint63,
    null,# Vec3_Float16,
    null,# Vec3_Float32,
    null,# Vec3_Float64,
    INT8_MIN,# Vec4_Int8,
    INT16_MIN,# Vec4_Int16,
    INT32_MIN,# Vec4_Int32,
    INT64_MIN,# Vec4_Int64,
    0,# Vec4_Uint8,
    0,# Vec4_Uint16,
    0,# Vec4_Uint32,
    0,# Vec4_Uint63,
    null,# Vec4_Float16,
    null,# Vec4_Float32,
    null,# Vec4_Float64,
    0.0,# Color_Uint8,
    0.0,# Color_Uint16,
    0.0,# Color_Uint32,
    0.0,# Color_Float16,
    0.0,# Color_Float32,
    null,# String_Utf8,
    null,# String_Ascii,
    null,# Variant_NoObject,
    null,# Variant_AllowObject,
    null,# CustomType,
]
const T_ELEM_MAX: Array = [
    UINT8_MAX,# Byte,
    null,# Bool,
    INT8_MAX,# Int8,
    INT16_MAX,# Int16,
    INT32_MAX,# Int32,
    INT64_MAX,# Int64,
    UINT8_MAX, # Uint8,
    UINT16_MAX,# Uint16,
    UINT32_MAX,# Uint32,
    INT64_MAX,# Uint63,
    null,# Float16,
    null,# Float32,
    null,# Float64,
    INT8_MAX,# Vec2_Int8,
    INT16_MAX,# Vec2_Int16,
    INT32_MAX,# Vec2_Int32,
    INT64_MAX,# Vec2_Int64,
    UINT8_MAX, # Vec2_Uint8,
    UINT16_MAX,# Vec2_Uint16,
    UINT32_MAX,# Vec2_Uint32,
    INT64_MAX,# Vec2_Uint63,
    null,# Vec2_Float16,
    null,# Vec2_Float32,
    null,# Vec2_Float64,
    INT8_MAX,# Vec3_Int8,
    INT16_MAX,# Vec3_Int16,
    INT32_MAX,# Vec3_Int32,
    INT64_MAX,# Vec3_Int64,
    UINT8_MAX, # Vec3_Uint8,
    UINT16_MAX,# Vec3_Uint16,
    UINT32_MAX,# Vec3_Uint32,
    INT64_MAX,# Vec3_Uint63,
    null,# Vec3_Float16,
    null,# Vec3_Float32,
    null,# Vec3_Float64,
    INT8_MAX,# Vec4_Int8,
    INT16_MAX,# Vec4_Int16,
    INT32_MAX,# Vec4_Int32,
    INT64_MAX,# Vec4_Int64,
    UINT8_MAX, # Vec4_Uint8,
    UINT16_MAX,# Vec4_Uint16,
    UINT32_MAX,# Vec4_Uint32,
    INT64_MAX,# Vec4_Uint63,
    null,# Vec4_Float16,
    null,# Vec4_Float32,
    null,# Vec4_Float64,
    1.0,# Color_Uint8,
    1.0,# Color_Uint16,
    1.0,# Color_Uint32,
    1.0,# Color_Float16,
    1.0,# Color_Float32,
    null,# String_Utf8,
    null,# String_Ascii,
    null,# Variant_NoObject,
    null,# Variant_AllowObject,
    null,# CustomType,
]
const T_GD_TYPE: PackedByteArray = [
    Variant.Type.TYPE_INT,# Byte,
    Variant.Type.TYPE_BOOL,# Bool,
    Variant.Type.TYPE_INT,# Int8,
    Variant.Type.TYPE_INT,# Int16,
    Variant.Type.TYPE_INT,# Int32,
    Variant.Type.TYPE_INT,# Int64,
    Variant.Type.TYPE_INT,# Uint8,
    Variant.Type.TYPE_INT,# Uint16,
    Variant.Type.TYPE_INT,# Uint32,
    Variant.Type.TYPE_INT,# Uint63,
    Variant.Type.TYPE_FLOAT,# Float16,
    Variant.Type.TYPE_FLOAT,# Float32,
    Variant.Type.TYPE_FLOAT,# Float64,
    Variant.Type.TYPE_VECTOR2I,# Vec2_Int8,
    Variant.Type.TYPE_VECTOR2I,# Vec2_Int16,
    Variant.Type.TYPE_VECTOR2I,# Vec2_Int32,
    Variant.Type.TYPE_VECTOR2I,# Vec2_Int64,
    Variant.Type.TYPE_VECTOR2I,# Vec2_Uint8,
    Variant.Type.TYPE_VECTOR2I,# Vec2_Uint16,
    Variant.Type.TYPE_VECTOR2I,# Vec2_Uint32,
    Variant.Type.TYPE_VECTOR2I,# Vec2_Uint63,
    Variant.Type.TYPE_VECTOR2,# Vec2_Float16,
    Variant.Type.TYPE_VECTOR2,# Vec2_Float32,
    Variant.Type.TYPE_VECTOR2,# Vec2_Float64,
    Variant.Type.TYPE_VECTOR3I,# Vec3_Int8,
    Variant.Type.TYPE_VECTOR3I,# Vec3_Int16,
    Variant.Type.TYPE_VECTOR3I,# Vec3_Int32,
    Variant.Type.TYPE_VECTOR3I,# Vec3_Int64,
    Variant.Type.TYPE_VECTOR3I,# Vec3_Uint8,
    Variant.Type.TYPE_VECTOR3I,# Vec3_Uint16,
    Variant.Type.TYPE_VECTOR3I,# Vec3_Uint32,
    Variant.Type.TYPE_VECTOR3I,# Vec3_Uint63,
    Variant.Type.TYPE_VECTOR3,# Vec3_Float16,
    Variant.Type.TYPE_VECTOR3,# Vec3_Float32,
    Variant.Type.TYPE_VECTOR3,# Vec3_Float64,
    Variant.Type.TYPE_VECTOR4I,# Vec4_Int8,
    Variant.Type.TYPE_VECTOR4I,# Vec4_Int16,
    Variant.Type.TYPE_VECTOR4I,# Vec4_Int32,
    Variant.Type.TYPE_VECTOR4I,# Vec4_Int64,
    Variant.Type.TYPE_VECTOR4I,# Vec4_Uint8,
    Variant.Type.TYPE_VECTOR4I,# Vec4_Uint16,
    Variant.Type.TYPE_VECTOR4I,# Vec4_Uint32,
    Variant.Type.TYPE_VECTOR4I,# Vec4_Uint63,
    Variant.Type.TYPE_VECTOR4,# Vec4_Float16,
    Variant.Type.TYPE_VECTOR4,# Vec4_Float32,
    Variant.Type.TYPE_VECTOR4,# Vec4_Float64,
    Variant.Type.TYPE_COLOR,# Color_Uint8,
    Variant.Type.TYPE_COLOR,# Color_Uint16,
    Variant.Type.TYPE_COLOR,# Color_Uint32,
    Variant.Type.TYPE_COLOR,# Color_Float16,
    Variant.Type.TYPE_COLOR,# Color_Float32,
    Variant.Type.TYPE_STRING,# String_Utf8,
    Variant.Type.TYPE_STRING,# String_Ascii,
    Variant.Type.TYPE_NIL,# Variant_NoObject,
    Variant.Type.TYPE_NIL,# Variant_AllowObject,
    Variant.Type.TYPE_NIL,# CustomType,
]
const T_GD_NAME: PackedStringArray = [
    "int",# Byte,
    "bool",# Bool,
    "int",# Int8,
    "int",# Int16,
    "int",# Int32,
    "int",# Int64,
    "int",# Uint8,
    "int",# Uint16,
    "int",# Uint32,
    "int",# Uint63,
    "float",# Float16,
    "float",# Float32,
    "float",# Float64,
    "Vector2i",# Vec2_Int8,
    "Vector2i",# Vec2_Int16,
    "Vector2i",# Vec2_Int32,
    "Vector2i",# Vec2_Int64,
    "Vector2i",# Vec2_Uint8,
    "Vector2i",# Vec2_Uint16,
    "Vector2i",# Vec2_Uint32,
    "Vector2i",# Vec2_Uint63,
    "Vector2",# Vec2_Float16,
    "Vector2",# Vec2_Float32,
    "Vector2",# Vec2_Float64,
    "Vector3i",# Vec3_Int8,
    "Vector3i",# Vec3_Int16,
    "Vector3i",# Vec3_Int32,
    "Vector3i",# Vec3_Int64,
    "Vector3i",# Vec3_Uint8,
    "Vector3i",# Vec3_Uint16,
    "Vector3i",# Vec3_Uint32,
    "Vector3i",# Vec3_Uint63,
    "Vector3",# Vec3_Float16,
    "Vector3",# Vec3_Float32,
    "Vector3",# Vec3_Float64,
    "Vector4i",# Vec4_Int8,
    "Vector4i",# Vec4_Int16,
    "Vector4i",# Vec4_Int32,
    "Vector4i",# Vec4_Int64,
    "Vector4i",# Vec4_Uint8,
    "Vector4i",# Vec4_Uint16,
    "Vector4i",# Vec4_Uint32,
    "Vector4i",# Vec4_Uint63,
    "Vector4",# Vec4_Float16,
    "Vector4",# Vec4_Float32,
    "Vector4",# Vec4_Float64,
    "Color",# Color_Uint8,
    "Color",# Color_Uint16,
    "Color",# Color_Uint32,
    "Color",# Color_Float16,
    "Color",# Color_Float32,
    "String",# String_Utf8,
    "String",# String_Ascii,
    "Variant",# Variant_NoObject,
    "Variant",# Variant_AllowObject,
    "Variant",# CustomType,
]
const T_GD_NAME_ARRAY: PackedStringArray = [
    "PackedByteArray",# Byte,
    "PackedByteArray",# Bool,
    "PackedInt32Array",# Int8,
    "PackedInt32Array",# Int16,
    "PackedInt32Array",# Int32,
    "PackedInt64Array",# Int64,
    "PackedInt32Array",# Uint8,
    "PackedInt32Array",# Uint16,
    "PackedInt64Array",# Uint32,
    "PackedInt64Array",# Uint63,
    "PackedFloat32Array",# Float16,
    "PackedFloat32Array",# Float32,
    "PackedFloat64Array",# Float64,
    "Array[Vector2i]",# Vec2_Int8,
    "Array[Vector2i]",# Vec2_Int16,
    "Array[Vector2i]",# Vec2_Int32,
    "Array[Vector2i]",# Vec2_Int64,
    "Array[Vector2i]",# Vec2_Uint8,
    "Array[Vector2i]",# Vec2_Uint16,
    "Array[Vector2i]",# Vec2_Uint32,
    "Array[Vector2i]",# Vec2_Uint63,
    "PackedVector2Array",# Vec2_Float16,
    "PackedVector2Array",# Vec2_Float32,
    "PackedVector2Array",# Vec2_Float64,
    "Array[Vector3i]",# Vec3_Int8,
    "Array[Vector3i]",# Vec3_Int16,
    "Array[Vector3i]",# Vec3_Int32,
    "Array[Vector3i]",# Vec3_Int64,
    "Array[Vector3i]",# Vec3_Uint8,
    "Array[Vector3i]",# Vec3_Uint16,
    "Array[Vector3i]",# Vec3_Uint32,
    "Array[Vector3i]",# Vec3_Uint63,
    "PackedVector3Array",# Vec3_Float16,
    "PackedVector3Array",# Vec3_Float32,
    "PackedVector3Array",# Vec3_Float64,
    "Array[Vector4i]",# Vec4_Int8,
    "Array[Vector4i]",# Vec4_Int16,
    "Array[Vector4i]",# Vec4_Int32,
    "Array[Vector4i]",# Vec4_Int64,
    "Array[Vector4i]",# Vec4_Uint8,
    "Array[Vector4i]",# Vec4_Uint16,
    "Array[Vector4i]",# Vec4_Uint32,
    "Array[Vector4i]",# Vec4_Uint63,
    "PackedVector4Array",# Vec4_Float16,
    "PackedVector4Array",# Vec4_Float32,
    "PackedVector4Array",# Vec4_Float64,
    "PackedColorArray",# Color_Uint8,
    "PackedColorArray",# Color_Uint16,
    "PackedColorArray",# Color_Uint32,
    "PackedColorArray",# Color_Float16,
    "PackedColorArray",# Color_Float32,
    "PackedStringArray",# String_Utf8,
    "PackedStringArray",# String_Ascii,
    "Array",# Variant_NoObject,
    "Array",# Variant_AllowObject,
    "Array",# CustomType,
]
const T_GD_NAME_ARRAY_NESTED = "Array"

static func check_default_value(type: T, arrayness: int, default: Variant, custom_default: String, root: bool = false, custom_min: Variant = null, custom_max: Variant = null) -> void:
    if custom_default.length() > 0: return
    var vecness = T_VECNESS[type as int]
    var elem_min = custom_min if custom_min != null else T_ELEM_MIN[type as int]
    var elem_max = custom_max if custom_max != null else T_ELEM_MAX[type as int]
    var exp_gd_type = T_GD_TYPE[type as int]
    if root:
        var got_gd_type = typeof(default)
        if arrayness == 0:
            assert(got_gd_type == exp_gd_type, "default value did not match expected type `%s`, got `%s`" % [type_string(exp_gd_type), type_string(got_gd_type)])
        elif arrayness == 1:
            pass
        else:
            assert(got_gd_type == Variant.Type.TYPE_ARRAY, "default value did not match expected type `Array`, got `%s`" % [type_string(got_gd_type)])
    if arrayness > 0 and elem_min != null and elem_max != null:
        for d in default:
            check_default_value(type, arrayness - 1, d, "")
    elif arrayness == 0 and elem_min != null and elem_max != null:
        if vecness <= 1:
            assert(elem_min <= default and default <= elem_max)
        else:
            if exp_gd_type == Variant.Type.TYPE_COLOR:
                assert(elem_min <= default.r and default.r <= elem_max)
                assert(elem_min <= default.g and default.g <= elem_max)
                assert(elem_min <= default.b and default.b <= elem_max)
                assert(elem_min <= default.a and default.a <= elem_max)
            else:
                assert(elem_min <= default.x and default.x <= elem_max)
                assert(elem_min <= default.y and default.y <= elem_max)
                if vecness >= 3:
                    assert(elem_min <= default.z and default.z <= elem_max)
                if vecness >= 4:
                    assert(elem_min <= default.w and default.w <= elem_max)

class Val:
    var type: int
    var type_name: String
    var value: Variant
    var array: bool
    var raw_: String

    func as_str() -> String:
        if raw_: return raw_
        if type == T.CustomType:
            if array:
                var out := StringBuilder.new()
                out.write("[")
                var i := 0
                for v in value:
                    out.write(v)
                    if i < value.size() - 1:
                        out.write(", ")
                out.write("]")
                return out.finish_and_clear()
            else:
                return value as String
        elif type == T.String_Ascii or type == T.String_Ascii:
            if array:
                return var_to_str(value)
            else:
                return "\"" + value + "\""
        else:
            return var_to_str(value)

    func _init(t: int, n: String, v: Variant, a: bool = false, r: String = "") -> void:
        type = t
        type_name = n
        value = v
        array = a
        raw_ = r
    
    static func raw(s: String, a: bool = false) -> Val:
        return Val.new(T.CustomType, "", "", a, s)
    
    func with_name(name: String) -> PropWithVal:
        var p = Prop.new(name, type, type_name)
        return PropWithVal.new(p, self)


static func u8(val: int) -> Val:
    return Val.new(T.Uint8, T_GD_NAME[T.Uint8], val)
static func i8(val: int) -> Val:
    return Val.new(T.Int8, T_GD_NAME[T.Int8], val)
static func u16(val: int) -> Val:
    return Val.new(T.Uint16, T_GD_NAME[T.Uint16], val)
static func i16(val: int) -> Val:
    return Val.new(T.Int16, T_GD_NAME[T.Int16], val)
static func u32(val: int) -> Val:
    return Val.new(T.Uint32, T_GD_NAME[T.Uint32], val)
static func i32(val: int) -> Val:
    return Val.new(T.Int32, T_GD_NAME[T.Int32], val)
static func u63(val: int) -> Val:
    return Val.new(T.Uint63, T_GD_NAME[T.Uint63], val)
static func i64(val: int) -> Val:
    return Val.new(T.Int64, T_GD_NAME[T.Int64], val)
static func f16(val: float) -> Val:
    return Val.new(T.Float16, T_GD_NAME[T.Float16], val)
static func f32(val: int) -> Val:
    return Val.new(T.Float32, T_GD_NAME[T.Float32], val)
static func f64(val: float) -> Val:
    return Val.new(T.Float64, T_GD_NAME[T.Float64], val)
static func string(val: String) -> Val:
    return Val.new(T.String_Utf8, T_GD_NAME[T.String_Utf8], val)
static func variant(val: Variant) -> Val:
    return Val.new(T.Variant_AllowObject, T_GD_NAME[T.Variant_AllowObject], val)
static func custom(val: String) -> Val:
    return Val.new(T.CustomType, T_GD_NAME[T.CustomType], val)
static func raw_val(val: String) -> Val:
    return Val.raw(val)

static func u8_arr(val: int) -> Val:
    return Val.new(T.Uint8, T_GD_NAME_ARRAY[T.Uint8], val, true)
static func i8_arr(val: int) -> Val:
    return Val.new(T.Int8, T_GD_NAME_ARRAY[T.Int8], val, true)
static func u16_arr(val: int) -> Val:
    return Val.new(T.Uint16, T_GD_NAME_ARRAY[T.Uint16], val, true)
static func i16_arr(val: int) -> Val:
    return Val.new(T.Int16, T_GD_NAME_ARRAY[T.Int16], val, true)
static func u32_arr(val: int) -> Val:
    return Val.new(T.Uint32, T_GD_NAME_ARRAY[T.Uint32], val, true)
static func i32_arr(val: int) -> Val:
    return Val.new(T.Int32, T_GD_NAME_ARRAY[T.Int32], val, true)
static func u63_arr(val: int) -> Val:
    return Val.new(T.Uint63, T_GD_NAME_ARRAY[T.Uint63], val, true)
static func i64_arr(val: int) -> Val:
    return Val.new(T.Int64, T_GD_NAME_ARRAY[T.Int64], val, true)
static func f16_arr(val: float) -> Val:
    return Val.new(T.Float16, T_GD_NAME_ARRAY[T.Float16], val, true)
static func f32_arr(val: int) -> Val:
    return Val.new(T.Float32, T_GD_NAME_ARRAY[T.Float32], val, true)
static func f64_arr(val: float) -> Val:
    return Val.new(T.Float64, T_GD_NAME_ARRAY[T.Float64], val, true)
static func string_arr(val: PackedStringArray) -> Val:
    return Val.new(T.String_Utf8, T_GD_NAME_ARRAY[T.String_Utf8], val, true)
static func variant_arr(val: Array[Variant]) -> Val:
    return Val.new(T.Variant_AllowObject, T_GD_NAME_ARRAY[T.Variant_AllowObject], val, true)
static func custom_arr(val: PackedStringArray) -> Val:
    return Val.new(T.CustomType, T_GD_NAME_ARRAY[T.CustomType], val, true)
static func raw_val_arr(val: String) -> Val:
    return Val.raw(val, true)

class Prop:
    var prop_name: String
    var type: int
    var type_name: String
    var array: bool
    var raw_: String

    func with_val(val: Variant) -> PropWithVal:
        var v
        if raw_:
            v = Val.raw(val, array)
        else:
            v = Val.new(type, type_name, val, array)
        return PropWithVal.new(self, v)

    func as_str() -> String:
        if raw_: return raw_
        return prop_name + ": " + T_GD_NAME[type]

    func _init(p: String, t: int, n: String, a: bool = false, r: String = "") -> void:
        prop_name = p
        type = t
        type_name = n
        array = a
        raw_ = ""
    
    static func raw(s: String, a: bool = false) -> Prop:
        return Prop.new("", T.CustomType, "", a, s)

class PropWithVal:
    var prop: Prop
    var val: Val

    func as_str() -> String:
        return prop.as_str() + " = " + val.as_str()

    func _init(p: Prop, v: Val) -> void:
        prop = p
        val = v

class_name FileFormatUtil

enum DATA_MODE {
    PLAIN_BINARY = 0,
    COMPRESSED = 1,
    ENCRYPTED = 2,
    HMAC_ENCRYPTED = 3,
    TEXT_CONFIG = 4,
}

const _KEY_CFG_META_SECTION = "METADATA_DO_NOT_EDIT"
const _KEY_CFG_SIG = "__FMT_SIG__DO_NOT_EDIT__"
const _KEY_CFG_VER = "__VERSION__DO_NOT_EDIT__"

const FAILED_TO_SAVE := "failed to save file `%s` to filesystem"
const FAILED_TO_LOAD := "failed to load file `%s` from filesystem"
const ALREADY_EXISTS := "file `%s` already exists on filesystem"
const FILE_DOESNT_EXIST := "file `%s` does not exist on filesystem"
const FILE_SIG_MISMATCH := "file `%s` had a mismatch of its signature string... file encryption key/iv was incorrect, or the file was not in the expected format"
const FILE_TOO_SHORT := "file `%s` had a read error while reading values: file too short for expected data"
const FILE_READ_ERROR := "file `%s` had a read error while reading values"
const FILE_WRITE_ERROR := "file `%s` had a read error while writing values"
const VERSION_TOO_SMALL := "file `%s` had a version less than the minimum supported version"
const VERSION_TOO_LARGE := "file `%s` had a version larger than the maximum supported version... the file may have been created with a newer software version and you may need to upgrade to read it"
const COULDNT_MAKE_DIR := "could not create directory for file `%s`"
const COULDNT_OPEN_DIR := "could not open directory for file `%s`"
const COULDNT_DELETE_TEMP := "could not delete temp file after saving `%s`"
const COULDNT_DELETE_FILE := "could not delete file `%s`"
const COULDNT_SEND_FILE_TO_TRASH := "could not send file `%s` to trash"
const DATA_INTEGRITY_FAIL := "when file `%s` was saved to temp file then re-loaded, its re-loaded values did not match the expected current state"

class LoadedFile:
    var bin_file: BinaryFile
    var cfg_file: ConfigFile
    var version: int

static func load_common(file_path: String, data_mode: DATA_MODE, compress_mode: FileAccess.CompressionMode, mac_key: PackedByteArray, enc_key: PackedByteArray, fmt_sig: PackedByteArray, max_version: int, big_endian: bool) -> Result:
    var result := Result.cache_first_failure()
    if result.failed(FileAccess.file_exists(file_path), FILE_DOESNT_EXIST % file_path): return result
    var file
    match data_mode:
        DATA_MODE.PLAIN_BINARY:
            file = BinaryFile.open(file_path, FileAccess.READ)
        DATA_MODE.COMPRESSED:
            file = BinaryFile.open_compressed(file_path, FileAccess.READ, compress_mode)
        DATA_MODE.ENCRYPTED:
            file = BinaryFile.open_encrypted(file_path, FileAccess.READ, enc_key)
        DATA_MODE.HMAC_ENCRYPTED:
            file = BinaryFile.open_encrypted_hmac(file_path, FileAccess.READ, mac_key, enc_key)
        DATA_MODE.TEXT_CONFIG:
            file = ConfigFile.new()
    var sig: PackedByteArray
    var format_version: int
    if data_mode != DATA_MODE.TEXT_CONFIG:
        if file.is_null():
            return result.with_err(FileAccess.get_open_error(), FAILED_TO_LOAD % file_path)
        file.set_big_endian(big_endian)
        if result.failed(file.size() >= fmt_sig.size() + 4, FILE_TOO_SHORT % file_path): return result
        sig = file.read_byte_array(fmt_sig.size())
        if result.failed(file.last_error(), FILE_READ_ERROR % file_path): return result
        format_version = file.read_u32()
        if result.failed(file.last_error(), FILE_READ_ERROR % file_path): return result
    else:
        sig = file.get_value(_KEY_CFG_META_SECTION, _KEY_CFG_SIG, fmt_sig)
        format_version = file.get_value(_KEY_CFG_META_SECTION, _KEY_CFG_VER, max_version)
    if result.failed(sig.size() == fmt_sig.size(), FILE_READ_ERROR % file_path): return result
    if result.failed(sig == fmt_sig, FILE_SIG_MISMATCH % file_path): return result
    if result.failed(format_version >= 0, VERSION_TOO_SMALL % file_path): return result
    if result.failed(format_version <= max_version, VERSION_TOO_LARGE % file_path): return result
    var loaded_file := LoadedFile.new()
    if data_mode != DATA_MODE.TEXT_CONFIG:
        loaded_file.bin_file = file
    else:
        loaded_file.cfg_file = file
    loaded_file.version = format_version
    result.value = loaded_file
    return result

static func save_common_one(file_path: String, data_mode: DATA_MODE, compress_mode: FileAccess.CompressionMode, mac_key: PackedByteArray, enc_key: PackedByteArray, fmt_sig: PackedByteArray, max_version: int, big_endian: bool) -> Result:
    var result := Result.cache_first_failure()
    var temp_path = file_path + ".tmp"
    var file
    match data_mode:
        DATA_MODE.PLAIN_BINARY:
            file = BinaryFile.open(temp_path, FileAccess.WRITE)
        DATA_MODE.COMPRESSED:
            file = BinaryFile.open_compressed(temp_path, FileAccess.WRITE, compress_mode)
        DATA_MODE.ENCRYPTED:
            file = BinaryFile.open_encrypted(temp_path, FileAccess.WRITE, enc_key)
        DATA_MODE.HMAC_ENCRYPTED:
            file = BinaryFile.open_encrypted_hmac(temp_path, FileAccess.WRITE, mac_key, enc_key)
        DATA_MODE.TEXT_CONFIG:
            file = ConfigFile.new()
    if data_mode != DATA_MODE.TEXT_CONFIG:
        if file.is_null():
            return result.with_err(FileAccess.get_open_error(), FAILED_TO_SAVE % file_path)
        file.set_big_endian(big_endian)
        file.write_byte_array(fmt_sig)
        file.write_u32(max_version)
        if result.failed(file.last_error(), FILE_WRITE_ERROR % file_path): return result
    else:
        file.set_value(_KEY_CFG_META_SECTION, _KEY_CFG_SIG, fmt_sig)
        file.set_value(_KEY_CFG_META_SECTION, _KEY_CFG_VER, max_version)
    result.value = file
    return result

static func save_common_two(result: Result, file: Variant, file_path: String, data_mode: DATA_MODE) -> void:
    var temp_path = file_path + ".tmp"
    if data_mode != DATA_MODE.TEXT_CONFIG:
        file.flush()
        result.check(file.last_error(), FILE_WRITE_ERROR % file_path)
        file.close()
    else:
        result.check(file.save(temp_path), FAILED_TO_SAVE % file_path)
    return

static func save_common_three(result: Result, file_path: String) -> void:
    var temp_path = file_path + ".tmp"
    var dir = DirAccess.open(file_path.get_base_dir())
    result.check(dir, COULDNT_OPEN_DIR % file_path)
    if result.is_failing():
        DirAccess.remove_absolute(temp_path)
        return
    result.check(dir.rename(temp_path, file_path), FAILED_TO_SAVE % file_path)
    return

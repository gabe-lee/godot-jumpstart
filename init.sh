#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

confirm() {
    while true; do
        read -r -p "$1 [y/n]: " response
        case "${response,,}" in
            y|yes|Y|YES|true|TRUE|t|T) return 0 ;; # true
            n|no|N|NO|false|FALSE|f|F) return 1 ;; # false
            *)     echo "Please answer y or n." ;;
        esac
    done
}

echo "Initializing directory structure in 'build/local'..."

# 1. Create the templates directories
mkdir -p "build/local/templates/windows"
mkdir -p "build/local/templates/linux"
mkdir -p "build/local/templates/android"
mkdir -p "build/local/templates/web"
mkdir -p "build/local/templates/macos"
mkdir -p "build/local/templates/ios"

mkdir -p "build/local/bin/windows"
mkdir -p "build/local/bin/linux"
mkdir -p "build/local/bin/android"
mkdir -p "build/local/bin/web"
mkdir -p "build/local/bin/macos"
mkdir -p "build/local/bin/ios"

# Ensure the local directory is ignored by Git by adding a local .gitignore
if [ ! -f "build/local/.gitignore" ]; then
    echo "*" > "build/local/.gitignore"
    echo "Created 'build/local/.gitignore' to keep these local files out of version control."
fi

# 2. Initialize env.sh with the requested paths
ENV_FILE="build/local/env.sh"
echo ""
echo "--- Local Environment Configuration ---"

# Prompt for Godot source path
read -r -p "Enter the filepath to the Godot source repository: " godot_path
godot_path=$(echo "$godot_path" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# Prompt for Java Directory
read -r -p "Enter the path for JAVA_DIR: " java_dir
java_dir=$(echo "$java_dir" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# Prompt for Android SDK Directory
read -r -p "Enter the path for ANDROID_SDK_DIR: " android_sdk_dir
android_sdk_dir=$(echo "$android_sdk_dir" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# Prompt for Android NDK Directory
read -r -p "Enter the path for ANDROID_NDK_DIR: " android_ndk_dir
android_ndk_dir=$(echo "$android_ndk_dir" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# Prompt for OSXCross Directory
read -r -p "Enter the path for OSXCROSS_DIR: " osxcross
osxcross=$(echo "$osxcross" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# Prompt for LocalSend Android
read -r -p "Enter the named device for for LOCALSEND_ANDROID: " localsend_android
localsend_android=$(echo "$localsend_android" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# Prompt for Editor platform
read -r -p "Enter the platform your are working from (linuxbsd|windows|macos): " machine_plat
machine_plat=$(echo "$machine_plat" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# Prompt for Editor arch
read -r -p "Enter the arch your are working from (auto|x86_32|x86_64|arm32|arm64|ppc64|rv64|wasm32): " machine_arch
machine_arch=$(echo "$machine_arch" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# Prompt for Editor arch
read -r -p "Enter the path to the godot editor: " editor_path
editor_path=$(echo "$editor_path" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# Prompt for exports
if confirm "Include export to Windows? "; then
    export_windows="true"
else
    export_windows="false"
fi
if confirm "Include export to Linux? "; then
    export_linux="true"
else
    export_linux="false"
fi
if confirm "Include export to MacOS? "; then
    export_macos="true"
else
    export_macos="false"
fi
if confirm "Include export to Android? "; then
    export_android="true"
else
    export_android="false"
fi
if confirm "Include export to iOS? "; then
    export_ios="true"
else
    export_ios="false"
fi
if confirm "Include export to Web? "; then
    export_web="true"
else
    export_web="false"
fi
if confirm "Use PCK encryption? "; then
    use_encrypt="true"
else
    use_encrypt="false"
fi
# Prompt for Project Name
read -r -p "Enter the name of the project: " proj_name
proj_name=$(echo "$proj_name" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# Generate the random encryption key
encrypt_key=""
if [[ "$use_encrypt" == "true" ]]; then
    if command -v openssl >/dev/null 2>&1; then
        encrypt_key=$(openssl rand -hex 32)
        echo "Successfully generated a 32-byte hex key using OpenSSL."
    else
        echo "Warning: 'openssl' command was not found. Storing a placeholder key." >&2
        encrypt_key="aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbccccccccccccccccdddddddddddddddd"
    fi
fi

sed -i "s/JumpstartTemplate/$proj_name/g" project.godot

cp -v "export_presets.cfg.template" "export_presets.cfg"

sed -i "s/JumpstartTemplate/$proj_name/g" export_presets.cfg

echo "Running editor to initialize project files"
godot --headless --editor --quit

cp -v "export_credentials.cfg.template" ".godot/export_credentials.cfg"

sed -i "s/script_encryption_key=\"\"/script_encryption_key=\"$encrypt_key\"/g" .godot/export_credentials.cfg

# Write the variables to the environment shell script
{
    echo "#!/usr/bin/env bash"
    echo "# Local environment paths for compile pipeline"
    echo ""
    echo "export GODOT_SOURCE_PATH=\"$godot_path\""
    echo "export JAVA_DIR=\"$java_dir\""
    echo "export ANDROID_SDK_DIR=\"$android_sdk_dir\""
    echo "export ANDROID_NDK_DIR=\"$android_ndk_dir\""
    echo "export OSXCROSS_DIR=\"$osxcross\""
    if [[ "$use_encrypt" == "true" ]]; then
        echo "export SCRIPT_AES256_ENCRYPTION_KEY=\"$encrypt_key\""
    else
        echo "# UNCOMMENT TO ENABLE PCK ENCRYPTION ON EXPORT TEMPLATES"
        echo "# export SCRIPT_AES256_ENCRYPTION_KEY=\"$encrypt_key\""
    fi
    echo "export GODOT_EDITOR_PLAT=\"$machine_plat\""
    echo "export GODOT_EDITOR_ARCH=\"$machine_arch\""
    echo "export GODOT_EDITOR_PATH=\"$editor_path\""
    echo "export GODOT_EXPORT_WINDOWS=\"$export_windows\""
    echo "export GODOT_EXPORT_LINUX=\"$export_linux\""
    echo "export GODOT_EXPORT_MACOS=\"$export_macos\""
    echo "export GODOT_EXPORT_ANDROID=\"$export_android\""
    echo "export GODOT_EXPORT_IOS=\"$export_ios\""
    echo "export GODOT_EXPORT_WEB=\"$export_web\""
    echo "export GODOT_PROJECT_NAME=\"$proj_name\""
    echo "export LOCALSEND_ANDROID=\"$localsend_android\""
} > "$ENV_FILE"

# Make the generated script executable as well
chmod +x "$ENV_FILE"
echo "Environment vars saved to '$ENV_FILE'."

echo ""
echo "Initialization process finished."
#!/usr/bin/env bash

PLATFORM=""
MODE="DEBUG" # Default build mode

# Print usage instructions
usage() {
    echo "Usage: $0 <PLATFORM|all> [--debug | --release]"
    echo "Options:"
    echo "  --debug, -d    Export in debug mode (default)"
    echo "  --release, -r  Export in release mode"
    exit 1
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --debug|-d)
            MODE="DEBUG"
            shift
            ;;
        --release|-r)
            MODE="RELEASE"
            shift
            ;;
        -*)
            echo "Error: Unknown option $1" >&2
            usage
            exit 1
            ;;
        *)
            if [ -z "$PLATFORM" ]; then
                PLATFORM="$1"
            else
                echo "Error: Multiple platforms specified ($PLATFORM and $1)" >&2
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Ensure the PLATFORM argument was provided
if [ -z "$PLATFORM" ]; then
    echo "Error: PLATFORM argument is required." >&2
    usage
    exit 1
fi

if [[ ! -f "build/local/env.sh" ]]; then
  echo "Error: no 'build/local/env.sh' file"
  exit 1
fi

# Function to run the Godot command
export_project() {
    local p_key="$1"
    local p_val="$2"
    local export_flag="--export-debug"

    if [ "$MODE" = "RELEASE" ]; then
        export_flag="--export-release"
    fi

    echo "Exporting '$p_key' to '$p_val' in $MODE mode..."
    godot --headless "$export_flag" "$p_key" "$p_val"
}

source ./build/local/env.sh

if [[ "$PLATFORM" == "all" ]]; then
    if [["$GODOT_EXPORT_WINDOWS" == "true"]]; then
        export_project "windows" "build/local/bin/windows/$GODOT_PROJECT_NAME.exe"
    fi
    if [["$GODOT_EXPORT_LINUX" == "true"]]; then
        export_project "linux" "build/local/bin/linux/$GODOT_PROJECT_NAME.x86_64"
    fi
    if [["$GODOT_EXPORT_MACOS" == "true"]]; then
        export_project "macos" "build/local/bin/macos/$GODOT_PROJECT_NAME.app"
    fi
    if [["$GODOT_EXPORT_ANDROID" == "true"]]; then
        export_project "android" "build/local/bin/android/$GODOT_PROJECT_NAME.apk"
    fi
    bash ./build_localsend_to_android.sh
    if [["$GODOT_EXPORT_IOS" == "true"]]; then
        export_project "ios" "build/local/bin/ios/$GODOT_PROJECT_NAME.ipa"
    fi
    if [["$GODOT_EXPORT_WEB" == "true"]]; then
        export_project "web" "build/local/bin/web/index.html"
    fi
elif [[ "$PLATFORM" == "windows" ]]; then
    if [["$GODOT_EXPORT_WINDOWS" != "true"]]; then
        echo "Windows export not enabled in ./build/local/env.sh (also requires defined export preset and compiled templates)"
        exit 1
    fi
    export_project "windows" "build/local/bin/windows/$GODOT_PROJECT_NAME.exe"
elif [[ "$PLATFORM" == "linux" ]]; then
    if [["$GODOT_EXPORT_LINUX" != "true"]]; then
        echo "Linux export not enabled in ./build/local/env.sh (also requires defined export preset and compiled templates)"
        exit 1
    fi
    export_project "linux" "build/local/bin/linux/$GODOT_PROJECT_NAME.x86_64"
elif [[ "$PLATFORM" == "macos" ]]; then
    if [["$GODOT_EXPORT_MACOS" != "true"]]; then
        echo "MacOS export not enabled in ./build/local/env.sh (also requires defined export preset and compiled templates)"
        exit 1
    fi
    export_project "macos" "build/local/bin/macos/$GODOT_PROJECT_NAME.app"
elif [[ "$PLATFORM" == "android" ]]; then
    if [["$GODOT_EXPORT_MACOS" != "true"]]; then
        echo "Android export not enabled in ./build/local/env.sh (also requires defined export preset and compiled templates)"
        exit 1
    fi
    export_project "android" "build/local/bin/android/$GODOT_PROJECT_NAME.apk"
    bash ./build_localsend_to_android.sh
elif [[ "$PLATFORM" == "ios" ]]; then
    if [["$GODOT_EXPORT_IOS" != "true"]]; then
        echo "iOS export not enabled in ./build/local/env.sh (also requires defined export preset and compiled templates)"
        exit 1
    fi
    export_project "ios" "build/local/bin/ios/$GODOT_PROJECT_NAME.ipa"
elif [[ "$PLATFORM" == "web" ]]; then
    if [["$GODOT_EXPORT_WEB" != "true"]]; then
        echo "Web export not enabled in ./build/local/env.sh (also requires defined export preset and compiled templates)"
        exit 1
    fi
    export_project "web" "build/local/bin/web/index.html"
fi

echo "Done building project"
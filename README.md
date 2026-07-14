## COMMANDS (REQUIRES UNIX-LIKE SHELL ENVIRONMENT and `bash`):
- `./init.sh`: Run this command first to initialize the godot project
- `./compile.sh <all|windows|linux|macos|android|ios|web|editor>`: Compile the godot export templates (or optionally the editor) with the exncryption key
- `./build.sh <all|windows|linux|macos|android|ios|web> [--debug | -d | --release | -r]`: build the project for one or all targets, with optional release flag (defaults to debug)

#### Note
Non-native export targets will require additional setup by the user. This template tries its best to set the relevant initialization settings everywhere they are needed but it's not guaranteed to be perfect or work out of the box.
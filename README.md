## SETUP (REQUIRES UNIX-LIKE SHELL ENVIRONMENT and `bash`):
1. run `./init.sh` first to initialize the folder structure and envoronment variables
2. open the project in godot and navigate to `Project > Export...`, then create all the export presets for your desired targets with the default settings AND set `Encryption > Encrypt Exported PCK` on each if you want encryption
3. run `./config_exports.sh` to auto config all the export templates
4. `./compile.sh <all|windows|linux|macos|android|ios|web|editor>`: Compile the godot export templates (or optionally the editor) with the exncryption key
5. `./build.sh <all|windows|linux|macos|android|ios|web> [--debug | -d | --release | -r]`: build the project for one or all targets, with optional release flag (defaults to debug)

#### Note
Non-native export targets will require additional setup by the user. This template tries its best to set the relevant initialization settings everywhere they are needed but it's not guaranteed to be perfect or work out of the box.
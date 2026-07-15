## COMMANDS (REQUIRES UNIX-LIKE SHELL ENVIRONMENT and `bash`):
- `./init.sh`: Initialize the folder structure and envoronment variables on a fresh Godot Project
- `./compile.sh <all|windows|linux|macos|android|ios|web|editor>`: Compile the godot export templates with the exncryption key (or optionally the editor) from the godot source repo (must exist on system) `all` mode only considers the export targets set in `./init.sh`
- `./build.sh <all|windows|linux|macos|android|ios|web> [--debug | -d | --release | -r]`: Build the project for one or all targets, with optional release flag (defaults to debug) `all` mode only considers the export targets set in `./init.sh`
- `./delete_uids.sh`: Deletes all `.uid` files in the project, usefull when dragging and dropping files/folders from another project, but may break scripts that reference resources by their UID
- `./delete_init_files.sh`: Deletes all files intended only for project initialization:
  - `export_credentials.cfg.template`
  - `export_presets.cfg.template`
  - `README.md` (this file)
  - `LICENSE` (the license for the jumpstart repo, not your own code)
  - `init.sh`
  - `delete_init_files.sh`
#### Note
Non-native export targets will require additional setup by the user. This template tries its best to set the relevant initialization settings everywhere they are needed but it's not guaranteed to be perfect or work out of the box.
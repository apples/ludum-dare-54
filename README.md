# LD54

## Project Requirements

- Godot 4.1

## Naming conventions

File and folder names must be `snake_case`, and can only contain the following characters:

```
qwertyuiopasdfghjklzxcvbnm_1234567890
```

## Project Organization

Art and audio assets go in the `assets/` folder, organized by category/object.

e.g. `assets/textures/player/player.png`

Object scenes go in `objects/` e.g. `objects/player/player.tscn`, with associated scripts.

Main scenes go in `scenes/` e.g. `scenes/main_menu/main_menu.tscn`, with associated scripts.

Scripts not associated with anything go in `scripts/`.

Autoload scripts *and* scenes go in `autoload/`.

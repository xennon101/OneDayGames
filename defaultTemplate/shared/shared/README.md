# Shared Systems

This folder hosts reusable systems for OneDayGames projects. Autoload the scripts in `shared/autoload/` in your Godot 4 project to satisfy `shared_systems_spec.md`.

## Autoload singletons
- `SceneConfig.gd` - scene ID registry.
- `EventBus.gd` - lightweight publish/subscribe.
- `ConfigManager.gd` - config persistence, applies display/audio/input.
- `InputManager.gd` - default bindings and runtime rebinding.
- `AudioManager.gd` - SFX one-shots and music playback with crossfade.
- `SaveManager.gd` - user save handling and gating.
- `LegalManager.gd` - company/legal text provider.
- `SceneManager.gd` - async scene changes by ID, loading screen, fade.

## Scene IDs
Defaults map to template scenes:
- `boot`, `main_menu`, `loading`, `settings`, `credits`, `gameplay`

Extend with `SceneConfig.register_scene("id", "res://path.tscn")` for game-specific scenes.

## Testing
Run shared tests headlessly from the repo root:
```
godot --headless -s res://shared/tests/test_runner.gd
```
Tests cover config merge, event bus, input rebinding, save/load guards, legal defaults, and scene manager guard paths. Add new cases alongside new functionality.

## Audio/asset registries
`AudioManager` registries are asset-agnostic; register audio streams at runtime. SceneManager expects the loading scene ID `loading` if you want loading UI; otherwise it skips gracefully.

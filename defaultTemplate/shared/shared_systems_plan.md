# Shared Systems Implementation Plan

## Goal
Implement the shared autoload singletons and supporting config/scene registry to satisfy `shared_systems_spec.md`, using Godot 4.x and reusable patterns, without yet writing runtime code.

## Existing engines/libraries to leverage
- Godot built-ins: `ConfigFile`/`FileAccess` for config + saves, `InputMap` for bindings, `AudioServer` + `AudioStreamPlayer` for SFX/music, `ResourceLoader` for async loads, `Tween`/`SceneTreeTimer` for transitions, `DirAccess` for user data paths.
- Testing: plan to adopt the existing Godot Unit Test (GUT) addon (well-supported for Godot 4) for 100% coverage; will vendor under `shared/addons/gut` and wire into CI/test runner. No network fetch in codegen; will add files directly when implementing.

## Planned structure
- `shared/autoload/SceneConfig.gd`: registry of scene IDs -> paths; shared helper to resolve paths and validate IDs.
- `shared/autoload/EventBus.gd`: simple publish/subscribe with `subscribe`, `unsubscribe`, `emit` covering required events.
- `shared/autoload/ConfigManager.gd`: load/save JSON-ish config via `ConfigFile`, merge defaults, apply settings to Audio/Input/Display immediately.
- `shared/autoload/InputManager.gd`: default bindings, rebind flow, persistence via ConfigManager, listening state helpers.
- `shared/autoload/AudioManager.gd`: SFX/Music registries, bus volume application from config, crossfade and one-shots.
- `shared/autoload/SaveManager.gd`: user:// storage, `game_supports_saves` flag, guards corrupt/missing files, enable/disable load button logic support.
- `shared/autoload/LegalManager.gd`: holds company/legal text, provides getters for credits/epilepsy warning.
- `shared/autoload/SceneManager.gd`: async scene changes by ID via SceneConfig, optional loading screen + fades, maintains `current_scene_id`, prevents concurrent loads, quit wrapper.
- `shared/ui/default_theme.tres`: shared UI theme placeholder (to be fleshed out later).

## Implementation steps (no code yet)
1) Set up autoload entries in `project.godot` for all singletons above; ensure paths align with SceneConfig.
2) Author `SceneConfig.gd` with PATHS map from spec and helpers: `get_path(id)`, `has(id)`, `all_ids()`.
3) Build `EventBus.gd` publish/subscribe with weak references to avoid leaks; cover required events.
4) Implement `ConfigManager.gd`: defaults per spec, `load_config`, `save_config`, `get_setting`, `set_setting`, `get_full_config`, merging missing keys, and immediate application hooks.
5) Implement `InputManager.gd`: define required actions, apply defaults to `InputMap`, rebind flow capturing next event (esc cancels), persist via ConfigManager, emit config-changed.
6) Implement `AudioManager.gd`: manage SFX one-shots, music player with crossfade/tween, update volumes from ConfigManager, id-to-resource registry.
7) Implement `SaveManager.gd`: json data storage in user://, safe load with try/catch, `has_save`, respect `game_supports_saves` flag; expose enablement helper for UI.
8) Implement `LegalManager.gd`: store company/credit strings, epilepsy warning toggle/text, provide getters for UI scenes.
9) Implement `SceneManager.gd`: async `change_scene(id, show_loading)`, `reload_current_scene`, `return_to_main_menu`, `get_current_scene_id`, `quit`; integrate loading screen, fade, and EventBus hooks; guard concurrent loads.
10) Wire startup order: ConfigManager.load_config -> AudioManager.update_volumes -> InputManager.apply_bindings_from_config -> SceneManager loads boot/main menu per spec.
11) Tests: add GUT addon, create unit tests for each manager (config merge, input rebind, audio volume mapping, save corrupt file handling, event bus subscriptions, scene routing) plus integration tests simulating startup and scene transitions; ensure 100% coverage target.
12) Documentation: update README/usage notes for shared systems, scene IDs, config schema, and how games should register additional scenes/audio ids.

## Open questions/assumptions
- Music/SFX registries initially empty; will define minimal placeholder IDs in a follow-up task when assets are available. ANSWER: System must be agnostic of assets so that assets can be wired later when a game is made.
- Fade/transition styling: will start with simple fade unless a template provides assets.
- Theme details: placeholder theme only; real styling may come from UI task.

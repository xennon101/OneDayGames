# Shared Systems Specification  
Location: `shared/`  
Applies to: `defaultTemplate` and all games under `games/...`

This document defines all global systems, singletons, behaviours, structures, and requirements that every OneDayGames project must follow. All systems described here must be implemented once and reused across all games.

---

## 1. Autoloaded Singletons

- SceneManager.gd  
- ConfigManager.gd  
- AudioManager.gd  
- InputManager.gd  
- SaveManager.gd  
- EventBus.gd  
- LegalManager.gd  

---

## 2. Scene Management – SceneManager.gd

### Purpose

- Provide centralised scene loading, unloading, transitions, and flow control.
- Maintain a consistent, ID-based routing system for all games.
- Handle loading screens, fade transitions, and main menu routing.

### Dependencies

- Must use a scene registry defined in `shared/autoload/SceneConfig.gd`.

### Scene Registry

```gdscript
const PATHS = {
    "boot": "res://defaultTemplate/boot.tscn",
    "main_menu": "res://defaultTemplate/main_menu.tscn",
    "loading": "res://defaultTemplate/loading_screen.tscn",
    "settings": "res://defaultTemplate/settings_menu.tscn",
    "credits": "res://defaultTemplate/credits.tscn",
    "gameplay": "res://defaultTemplate/placeholder_game.tscn"
}
```

### Public API

- change_scene(id: String, show_loading := true)  
- reload_current_scene(show_loading := true)  
- return_to_main_menu(show_loading := true)  
- get_current_scene_id() -> String  

### Behaviour

- Must update an internal current_scene_id whenever a scene loads.
- Must support asynchronous scene loading.
- Must optionally show loading_screen.tscn when loading.
- Must prevent concurrent scene loads.
- Must support fade transitions if enabled.
- quit() must call get_tree().quit()

---

## 3. Configuration Management – ConfigManager.gd

### Purpose

- Handle persistent configuration: display, audio, input bindings, and game-specific settings.
- Provide runtime access to configuration values.
- Apply settings instantly without restart.

### JSON Structure

```json
{
  "version": 1,
  "display": {
    "fullscreen": false,
    "borderless": false,
    "resolution": "1920x1080",
    "vsync": true
  },
  "audio": {
    "master_volume": 1.0,
    "music_volume": 0.8,
    "sfx_volume": 0.8
  },
  "input": {
    "actions": {}
  },
  "game": {}
}
```

### Public API

- load_config()  
- save_config()  
- get_setting(category, key, default)  
- set_setting(category, key, value, autosave := true)  
- get_full_config()  

### Behaviour

- Must merge missing keys into config.
- Must save config automatically if autosave is enabled.
- Must apply display, audio, and input changes immediately through shared managers.

---

## 4. Audio Management – AudioManager.gd

### Purpose

- Centralised audio playback and volume control.

### Requirements

- Must use buses:
  - Master  
  - Music  
  - SFX  

- Must maintain a registry mapping string IDs to AudioStream resources.

### Public API

- play_sfx(id: String)  
- play_music(id: String, crossfade_time := 0.5)  
- stop_music(fade_out_time := 0.5)  
- update_volumes()  

### Behaviour

- update_volumes() must read from ConfigManager.
- SFX must be played as one-shots.
- Music must support fade and crossfade.

---

## 5. Input and Keybinding – InputManager.gd

### Purpose

- Provide runtime key rebinding and default input mapping.

### Required Actions

- move_left  
- move_right  
- move_up  
- move_down  
- action_primary  
- pause  
- ui_accept  
- ui_cancel  

### Public API

- apply_bindings_from_config()  
- start_rebind(action_name)  
- cancel_rebind()  
- is_listening_for_rebind()  

### Behaviour

- Rebinding must capture the next key.
- ESC must cancel listening mode.
- Must save changes to ConfigManager and apply to InputMap immediately.

---

## 6. Save System – SaveManager.gd

### Purpose

- Provide save/load functionality across all games.

### Required Fields

- game_supports_saves: bool (default false)

### Public API

- has_save()  
- save_game(data)  
- load_game()  

### Behaviour

- Must store save file in user data directory.
- Must handle corrupt/missing files gracefully.
- Load Game button must be disabled unless:
  - game_supports_saves == true  
  - has_save() == true  

---

## 7. Event Bus – EventBus.gd

### Purpose

- Provide cross-system communication using simple event names.

### Public API

- subscribe(event_name, target, method)  
- unsubscribe(event_name, target, method)  
- emit(event_name, payload := null)  

### Required Events

- request_quit_game  
- request_return_to_main_menu  
- config_changed  
- play_sfx  

---

## 8. Legal and Company Info – LegalManager.gd

### Purpose

- Provide company branding and legal text to UI scenes.

### Required Fields

- company_name  
- copyright_line  
- website_url  
- credits_text  
- epilepsy_warning_enabled  
- epilepsy_warning_text  

### Usage

- Credits screen must use LegalManager content.
- Boot scene must show warning if enabled.

---

## 9. Startup Sequence

### Required Order

- ConfigManager.load_config()  
- AudioManager.update_volumes()  
- InputManager.apply_bindings_from_config()  
- SceneManager loads boot or main_menu  

### Boot Behaviour

- Boot scene may show logo or legal text.
- Must transition to main_menu via SceneManager.change_scene("main_menu").

---

## 10. Default Common Items Required Across All Games

- Shared UI theme at shared/ui/default_theme.tres  
- Standard audio buses  
- Shared input map  
- Shared scene flow  
- Shared SceneConfig IDs  
- Shared exit behaviour via SceneManager.quit() or EventBus.emit("request_quit_game")  

Games must follow this sequence:

- Boot → Main Menu → Settings / Credits / Gameplay → Exit

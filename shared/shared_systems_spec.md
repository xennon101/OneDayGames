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
- PlayerIdentityManager.gd  
- LeaderboardManager.gd  
- MatchmakingManager.gd  
- NetSessionManager.gd  

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


---

## 11. Player Identity – PlayerIdentityManager.gd

### Purpose

- Provide a global, persistent, anonymous player identifier that can be used across all games.
- Avoid requiring user authentication while still giving each player a stable identity for services such as leaderboards and matchmaking.

### Requirements

- Must generate a unique player identifier on first use.
- The identifier must:
  - Be a UUID v4 or equivalent high-entropy random string.
  - Be stable across runs for the same user on the same device.
  - Be stored in a persistent location (for example `user://` or inside ConfigManager).
- The identifier must not be derived from personally identifiable information.

### Public API

- get_player_id() -> String  
  - Returns the existing player_id, generating and persisting one if it does not exist.
- reset_player_id() -> void  
  - Optional. Regenerates the player_id and persists it. Must not be called accidentally.

### Behaviour

- On first call to get_player_id(), the manager must:
  - Check persistent storage for an existing id.
  - If not present, generate a UUID.
  - Persist the UUID.
- All subsequent calls must return the same ID until reset_player_id() is explicitly used.
- PlayerIdentityManager must be treated as read-mostly; games should not reset the ID during normal operation.
- PlayerIdentityManager must not perform any network calls by itself.


---

## 12. Leaderboard Client – LeaderboardManager.gd

### Purpose

- Provide a shared client-side API for submitting and retrieving leaderboard scores from an external backend service (for example an AWS-hosted leaderboard service).
- Hide HTTP and authentication details from individual games so they only call a small, stable API.

### Dependencies

- PlayerIdentityManager.gd for `player_id`.
- ConfigManager.gd for configuration of:
  - Leaderboard service base URL.
  - Environment (dev/stage/prod) if required.

### Configuration

ConfigManager must provide keys under a `leaderboard` category, for example:

- `leaderboard.base_url` (String)  
  - The HTTPS base URL for the leaderboard backend, such as `https://api.example.com`.
- `leaderboard.enabled` (bool, default true)  
  - If false, LeaderboardManager must behave as a no-op (submissions do nothing, fetches return empty lists or appropriate defaults).

The manager may provide sensible defaults if no config is present, but all network endpoints must be configurable.

### Public API

- submit_score(game_id: String, score: int, player_name: String = "") -> void  
  - Asynchronously submits a score for the current player.
- fetch_top(game_id: String, limit: int = 10, callback: Callable) -> void  
  - Asynchronously fetches the top scores, calling the provided callback with the results or an error.

Results passed to callbacks should use a normalised structure, for example:

- An Array of Dictionaries with fields:
  - `player_name` (String)
  - `score` (int)
  - `rank` (int)

### Network Behaviour

- All requests must be performed over HTTPS.
- The manager must use Godot's HTTP client facilities (for example HTTPRequest node).
- Requests must include:
  - `game_id` (string) to distinguish different games.
  - `player_id` from PlayerIdentityManager.
  - `player_name` if provided by the game.
  - `score` (for submissions).
- The manager must be resilient to network errors:
  - If submission fails, it must not crash the game.
  - If fetching fails, it must return an empty list or propagate an error via the callback in a controlled way.
- The manager must not block the main thread; all operations are asynchronous.

### Security Model

- The manager may include an HMAC-based signature if required by the backend (for example to deter trivial tampering), but:
  - Any secrets used for signing must not be hardcoded directly into scripts.
  - Secrets should be provided via ConfigManager, and populated at build time or from external configuration.

### Integration With Games

- Games should not call HTTP directly for leaderboard operations.
- Games must:
  - Use PlayerIdentityManager for player identity.
  - Use LeaderboardManager for submit and fetch operations.
- The shared default template may include placeholder UI elements for:
  - Showing the top N scores.
  - Submitting the final score on game over.


---

## 13. Matchmaking Client – MatchmakingManager.gd

### Purpose

- Provide a shared client-side API for queueing players into matchmaking, checking match status, and exchanging signalling data required to set up peer-to-peer sessions.
- Hide HTTP details and backend-specific mechanics behind a simple Godot-facing interface.

### Dependencies

- PlayerIdentityManager.gd for `player_id`.
- ConfigManager.gd for configuration of:
  - Matchmaking service base URL.
  - Environment (dev/stage/prod) if required.

### Configuration

ConfigManager must provide keys under a `matchmaking` category, for example:

- `matchmaking.base_url` (String)  
  - The HTTPS base URL for the matchmaking backend.
- `matchmaking.enabled` (bool, default false)  
  - If false, matchmaking functions must behave as no-ops or return immediate failure states.

### Public API

- queue_for_match(game_id: String, mode: String, metrics: Dictionary = {}) -> void  
  - Enqueues the current player into a matchmaking queue.
- cancel_queue(game_id: String, mode: String) -> void  
  - Cancels an outstanding matchmaking request.
- poll_match_status(game_id: String, mode: String, callback: Callable) -> void  
  - Polls the backend for match status and invokes the callback with results.
- send_signal(match_id: String, payload: Dictionary) -> void  
  - Sends signalling data (for example WebRTC offer/answer/ICE) to the backend.
- poll_signals(match_id: String, callback: Callable) -> void  
  - Retrieves signalling messages destined for this player and passes them to the callback.

The exact structure of `metrics` and signalling payloads must follow the AWS multiplayer service spec.

### Behaviour

- All operations must be asynchronous and must not block the main thread.
- Network failures must be surfaced via callbacks in a controlled, non-crashing way.
- MatchmakingManager does not start or own the peer-to-peer session itself; it only interacts with the backend service and forwards signalling data to NetSessionManager (or equivalent).

### Security Model

- If the backend requires request signing (for example HMAC), MatchmakingManager must:
  - Obtain any signing keys or tokens from ConfigManager.
  - Never hardcode secrets directly in scripts.



---

## 14. P2P Session Management – NetSessionManager.gd

### Purpose

- Manage the lifecycle of peer-to-peer multiplayer sessions in Godot.
- Abstract the underlying transport (for example WebRTC or ENet) behind a consistent API.
- Coordinate with MatchmakingManager for signalling data.

### Transport

- The preferred transport for internet-based peer-to-peer is WebRTC via Godot's WebRTC classes.
- Local or LAN-based games may additionally support ENet via ENetMultiplayerPeer.

### Public API

- start_host_session(match_id: String, config: Dictionary = {}) -> void  
  - Prepares the local player to act as the host/authority for a P2P session.
- start_client_session(match_id: String, config: Dictionary = {}) -> void  
  - Prepares the local player to join as a client in a P2P session.
- handle_signalling_message(match_id: String, payload: Dictionary) -> void  
  - Accepts signalling messages received via MatchmakingManager and routes them into the underlying WebRTC/ENet implementation.
- is_connected() -> bool  
  - Returns true when the P2P session is established.
- disconnect() -> void  
  - Gracefully tears down the session.

### Behaviour

- For WebRTC:
  - As host:
    - Create WebRTC peer.
    - Generate offers and ICE candidates and pass them to MatchmakingManager.send_signal().
  - As client:
    - Receive offers and ICE candidates via MatchmakingManager.poll_signals().
    - Generate answers and ICE candidates and send them back via MatchmakingManager.
- For ENet (if used):
  - Coordinate with a rendezvous or relay backend as described in the multiplayer backend spec.
- NetSessionManager must:
  - Integrate with Godot's high-level MultiplayerAPI (for example SceneMultiplayer).
  - Ensure authority and peer IDs are configured correctly.
  - Expose a clear way for game code to register RPC-based game logic.

### Integration With Games

- Games must not directly instantiate WebRTC or ENet peers for standard P2P flows; they must use NetSessionManager instead.
- Game scenes can query NetSessionManager for connection status and peer information.
- Game-specific networked logic should rely on Godot's multiplayer RPC model, configured by NetSessionManager.


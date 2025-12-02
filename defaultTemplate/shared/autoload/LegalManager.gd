extends Node

var company_name: String = "OneDayGames"
var copyright_line: String = "(c) OneDayGames. All rights reserved."
var website_url: String = "https://example.com"
var credits_text: String = "Game by OneDayGames."
var epilepsy_warning_enabled: bool = false
var epilepsy_warning_text: String = "This game may contain flashing lights. Player discretion advised."
var mission_text: String = "OneDayGames builds games in around one man-day by leaning on AI for code, art, sound, and design."


func _ready() -> void:
	_load_from_config()


func get_company_name() -> String:
	return company_name


func get_copyright() -> String:
	return copyright_line


func get_website_url() -> String:
	return website_url


func get_credits_text() -> String:
	return credits_text


func is_epilepsy_warning_enabled() -> bool:
	return epilepsy_warning_enabled


func get_epilepsy_warning_text() -> String:
	return epilepsy_warning_text


func get_mission_text() -> String:
	return mission_text


func _load_from_config() -> void:
	if Engine.has_singleton("ConfigManager"):
		var cfg = Engine.get_singleton("ConfigManager")
		var assets: Dictionary = cfg.get_template_assets_config()
		company_name = assets.get("company", {}).get("name", company_name)
		copyright_line = assets.get("legal", {}).get("footer", copyright_line)
		credits_text = assets.get("legal", {}).get("credits_text", credits_text)
		epilepsy_warning_text = assets.get("legal", {}).get("epilepsy_warning", epilepsy_warning_text)
		mission_text = assets.get("legal", {}).get("mission", mission_text)

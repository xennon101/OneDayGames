extends Node

var company_name: String = "OneDayGames"
var copyright_line: String = "(c) OneDayGames. All rights reserved."
var website_url: String = "https://example.com"
var credits_text: String = "Game by OneDayGames."
var epilepsy_warning_enabled: bool = false
var epilepsy_warning_text: String = "This game may contain flashing lights. Player discretion advised."


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

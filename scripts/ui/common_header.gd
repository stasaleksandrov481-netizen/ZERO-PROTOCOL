extends HBoxContainer

@export var title_key := ""
@export var subtitle_key := ""

func _ready() -> void:
	$Titles/Title.text = tr(title_key)
	$Titles/Subtitle.text = tr(subtitle_key)
	$Back.pressed.connect(NavigationManager.back)

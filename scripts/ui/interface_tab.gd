extends SettingsTab

func _ready() -> void:
	super._ready()
	intro(tr("INTERFACE_TITLE"),tr("INTERFACE_HINT"))
	add_choice("ui/scale",tr("UI_SCALE"),["90%","100%","110%","125%"],[0.9,1.0,1.1,1.25],tr("SCALE_HINT"))
	add_toggle("ui/high_contrast",tr("HIGH_CONTRAST"),tr("CONTRAST_HINT"))
	var language := RiftUI.column(8)
	language.add_child(RiftUI.section_title(tr("LANGUAGE")))
	language.add_child(RiftUI.label("Русский",20))
	language.add_child(RiftUI.paragraph(tr("LANGUAGE_HINT"),15))
	add_child(RiftUI.panel(language,18))

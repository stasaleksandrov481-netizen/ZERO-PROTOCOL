extends SettingsTab

func _ready() -> void:
	super._ready()
	intro(tr("VIDEO_TITLE"),tr("VIDEO_HINT"))
	add_choice("video/quality",tr("QUALITY"),[tr("LOW"),tr("MEDIUM"),tr("HIGH")],[0,1,2],tr("QUALITY_HINT"))
	add_choice("video/fps",tr("FPS_CAP"),["30 FPS","60 FPS",tr("UNCAPPED")],[30,60,0],tr("FPS_HINT"))
	add_toggle("video/reduced_motion",tr("REDUCED"),tr("REDUCED_HINT"))
	var note := RiftUI.column(8)
	note.add_child(RiftUI.section_title(tr("RENDERER")))
	note.add_child(RiftUI.paragraph(tr("RENDERER_HINT"),15))
	add_child(RiftUI.panel(note,18))

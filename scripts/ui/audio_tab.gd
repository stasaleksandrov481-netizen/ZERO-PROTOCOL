extends SettingsTab

func _ready() -> void:
	super._ready()
	intro(tr("AUDIO_TITLE"),tr("AUDIO_HINT"))
	add_slider("audio/master",tr("MASTER"),"",0.0,1.0,0.01,percent)
	add_slider("audio/music",tr("MUSIC"),tr("MUSIC_HINT"),0.0,1.0,0.01,percent)
	add_slider("audio/sfx",tr("SFX"),tr("SFX_HINT"),0.0,1.0,0.01,percent)
	add_slider("audio/ui",tr("UI_AUDIO"),tr("UI_AUDIO_HINT"),0.0,1.0,0.01,percent)
	var actions := RiftUI.row()
	actions.add_child(RiftUI.button(tr("TEST_SOUND"),func() -> void: AudioManager.play_ui("confirm")))
	add_child(actions)

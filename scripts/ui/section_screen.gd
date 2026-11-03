extends Control
## Honest, separately addressable future sections. No fake launch buttons.

@export var title_key := ""
@export var summary_key := ""
@export var empty_key := ""
@export var card_keys := PackedStringArray()
@export var section_icon: Texture2D

func _ready() -> void:
	$Margin/Column/Header/Titles/Title.text = tr(title_key)
	$Margin/Column/Scroll/Content/Hero/Inset/Column/Summary.text = tr(summary_key)
	$Margin/Column/Scroll/Content/Hero/Inset/Column/EmptyRow/Titles/Title.text = tr(empty_key)
	$Margin/Column/Scroll/Content/Hero/Inset/Column/EmptyRow/Icon.texture = section_icon
	var cards := $Margin/Column/Scroll/Content/Cards
	for key: String in card_keys:
		var column := RiftUI.column(14)
		column.add_child(RiftUI.section_title(tr(key)))
		var unavailable := RiftUI.button(tr("PLANNED"))
		unavailable.disabled = true
		column.add_child(unavailable)
		var card := RiftUI.panel(column,20)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cards.add_child(card)
	$Margin/Column/BackMenu.pressed.connect(NavigationManager.back)

func focus_initial() -> void:
	$Margin/Column/Header/Back.grab_focus()

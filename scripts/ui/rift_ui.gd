class_name RiftUI
extends RefCounted
## Shared palette and constructors. Runtime controls stay normal editable Godot Controls.

const INK := Color("090f14")
const PANEL := Color("111c23")
const TEXT := Color("e0e4dc")
const MUTED := Color("90a1a6")
const RED := Color("d6ad62")
const LINE := Color("36494f")
const CYAN := Color("a1cedd")
const FONT = preload("res://assets/fonts/DejaVuSans.ttf")
const BOLD = preload("res://assets/fonts/DejaVuSans-Bold.ttf")
const MONO = preload("res://assets/fonts/DejaVuSansMono.ttf")
const ButtonSkin = preload("res://scripts/ui/ui_button.gd")
const Surface = preload("res://scripts/ui/ui_surface.gd")
const Glyph = preload("res://scripts/ui/ui_glyph.gd")
const HEADING = BOLD
const THEME = preload("res://resources/theme/rift_theme.tres")

static func label(value: String, font_size: int = 18, color: Color = TEXT) -> Label:
 var node := Label.new()
 node.text = value
 node.add_theme_font_size_override("font_size", font_size)
 node.add_theme_color_override("font_color", color)
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return node

static func paragraph(value: String, font_size: int = 17, color: Color = MUTED) -> Label:
 var node := label(value, font_size, color)
 node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 return node

static func micro(value: String) -> Label:
 var node := label(value, 12, MUTED)
 node.add_theme_font_override("font", MONO)
 return node

static func button(value: String, action: Callable = Callable()) -> Button:
 var node := ButtonSkin.new()
 node.text = value
 node.custom_minimum_size.y = 48
 node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 if action.is_valid(): node.pressed.connect(action)
 node.pressed.connect(func() -> void: AudioManager.play_ui())
 return node

static func spacer(height: float = 16.0) -> Control:
 var node := Control.new()
 node.custom_minimum_size.y = height
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return node

static func column(gap: int = 12) -> VBoxContainer:
 var node := VBoxContainer.new()
 node.add_theme_constant_override("separation", gap)
 node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 return node

static func row(gap: int = 12) -> HBoxContainer:
 var node := HBoxContainer.new()
 node.add_theme_constant_override("separation", gap)
 node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 return node

static func rule() -> HSeparator:
 var node := HSeparator.new()
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return node

static func inset(child: Control, amount: int = 24) -> MarginContainer:
 var margin := MarginContainer.new()
 for edge in ["left", "right", "top", "bottom"]:
  margin.add_theme_constant_override("margin_" + edge, amount)
 margin.add_child(child)
 return margin

static func panel(child: Control, amount: int = 24) -> PanelContainer:
 var node := Surface.new()
 node.add_child(inset(child, amount))
 return node

static func section_title(text: String) -> Label:
 var node := label(text, 13, CYAN)
 node.add_theme_font_override("font", BOLD)
 return node

static func heading(value: String,font_size: int = 32) -> Label:
 var node := label(value,font_size,TEXT);node.add_theme_font_override("font",HEADING);return node
static func primary(value: String,action: Callable = Callable()) -> Button:
 var node := button(value,action);node.primary = true;return node
static func icon(kind: String,extent: float = 24,color: Color = CYAN) -> Control:
 var node := Glyph.new();node.kind = kind;node.color = color;node.custom_minimum_size = Vector2.ONE*extent;node.size = Vector2.ONE*extent;return node
static func icon_button(kind: String,action: Callable = Callable(),tip: String = "") -> Button:
 var node := button("",action);node.quiet = true;node.tooltip_text = tip;node.custom_minimum_size = Vector2(48,46)
 var glyph := icon(kind);node.add_child(glyph);glyph.set_anchors_preset(Control.PRESET_TOP_LEFT);glyph.position = Vector2(12,11)
 node.resized.connect(func() -> void: glyph.position = (node.size-glyph.size)*.5)
 return node
static func design_theme() -> Theme:
 var result := THEME.duplicate(true) as Theme
 for type: String in ["Button","OptionButton","LineEdit"]:
  for state: String in ["normal","hover","pressed","disabled","focus"]:
   var style := StyleBoxFlat.new();style.corner_detail = 1;style.set_corner_radius_all(6);style.set_border_width_all(1)
   style.bg_color = Color("131e25");style.border_color = LINE
   style.content_margin_left = 16;style.content_margin_right = 16;style.content_margin_top = 10;style.content_margin_bottom = 10
   if state == "hover": style.bg_color = Color("23343b");style.border_color = CYAN
   if state == "pressed": style.bg_color = Color("49272e");style.border_color = RED
   if state == "disabled": style.bg_color.a = .45;style.border_color.a = .35
   if state == "focus": style.bg_color = Color.TRANSPARENT;style.border_color = CYAN
   result.set_stylebox(state,type,style)
  result.set_color("font_color",type,TEXT);result.set_color("font_hover_color",type,Color.WHITE)
 var panel_style := StyleBoxFlat.new();panel_style.bg_color = Color("101a20");panel_style.border_color = LINE;panel_style.set_border_width_all(1);panel_style.corner_detail = 1;panel_style.set_corner_radius_all(8)
 result.set_stylebox("panel","PanelContainer",panel_style);result.set_stylebox("panel","PopupMenu",panel_style)
 result.set_color("font_color","Label",TEXT)
 var bar := StyleBoxFlat.new();bar.bg_color = Color("27353c");bar.content_margin_top = 2
 result.set_stylebox("background","ProgressBar",bar)
 var fill := StyleBoxFlat.new();fill.bg_color = RED;result.set_stylebox("fill","ProgressBar",fill)
 return result

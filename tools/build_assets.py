"""Regenerate original vector UI, theme and procedural audio. Python 3, numpy, fonttools.
Generated raster art is independent and kept in assets/background; never overwritten here.
"""
from pathlib import Path
import math
import wave
import numpy as np
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

ROOT = Path(__file__).resolve().parents[1]

def put(path, content):
    (ROOT/path).write_text(content, encoding='utf-8')

def svg(body, w=32, h=32):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>'

icons = {
 'campaign': '<path d="M9 5L27 16 9 27Z"/>',
 'operations': '<path d="M7 5l20 22M25 5L5 27M4 5l5 1-3 5M28 5l-5 1 3 5M5 26l5-2M27 26l-5-2"/>',
 'hangar': '<path d="M4 27V12L16 5l12 7v15M7 27V15h18v12M8 19h16M8 23h16"/>',
 'archive': '<rect x="6" y="4" width="21" height="24" rx="1"/><path d="M11 10h11M11 15h11M11 20h11M11 25h7"/>',
 'settings': '<path d="M13 3h6l1 5 4 2 4-1 3 5-4 3-1 4 2 4-5 3-3-3-5-1-3 3-5-3 2-4-1-4-4-3 3-5 5 1 2-2Z"/><circle cx="17" cy="16" r="5"/>',
 'quit': '<path d="M16 3v13M9 7a11 11 0 1 0 14 0"/>',
 'back': '<path d="M19 7l-9 9 9 9M10 16h18"/>',
 'arrow': '<path d="M6 11l10 10 10-10"/>',
 'check': '<rect x="3" y="3" width="26" height="26" rx="2"/><path d="M9 16l5 5 10-11"/>',
 'unchecked': '<rect x="3" y="3" width="26" height="26" rx="2"/>',
 'info': '<circle cx="16" cy="16" r="12"/><path d="M16 15v10M16 8v3"/>',
 'lock': '<path d="M9 14V9a7 7 0 0 1 14 0v5"/><rect x="5" y="14" width="22" height="15" rx="2"/><path d="M16 19v5"/>',
}
for name, body in icons.items():
    put(f'assets/icons/{name}.svg', svg(f'<g fill="none" stroke="#aebbc8" stroke-width="2" stroke-linejoin="round" stroke-linecap="round">{body}</g>'))
put('assets/icons/grabber.svg', svg('<path d="M10 5h12v22H10Z" fill="#e45866"/><path d="M14 9v14" stroke="#ffe1e4"/>'))
put('assets/icons/app_icon.svg',svg('<rect width="128" height="128" rx="24" fill="#0d1725"/><path d="M24 34h80L64 104Z" fill="none" stroke="#e94f60" stroke-width="7"/><path d="M46 44h40L65 78Z" fill="#adbdcc"/><path d="M12 87l104-26" stroke="#0d1725" stroke-width="8"/>',128,128).replace('width="128" height="128"','width="512" height="512"'))

# Logo remains editable SVG paths. Letterforms are derived from the bundled licensed font.
font = TTFont(ROOT/'assets/fonts/DejaVuSans-Bold.ttf')
glyphs, cmap = font.getGlyphSet(), font.getBestCmap()
def outlines(text, tracking=0):
    x, paths = 0, []
    for ch in text:
        name=cmap[ord(ch)]
        pen=SVGPathPen(glyphs); glyphs[name].draw(pen)
        paths.append(f'<path transform="translate({x} 0)" d="{pen.getCommands()}"/>')
        x+=font['hmtx'][name][0]+tracking
    return ''.join(paths), x
big, width=outlines('RIFT',-55)
small, subwidth=outlines('ZERO PROTOCOL',420)
logo=f'''<defs><mask id="cut" maskUnits="userSpaceOnUse" x="0" y="0" width="380" height="145"><rect width="400" height="142" fill="white"/>
<path d="M18 35h340M5 70h320M90 47h42M217 22h33" stroke="black" stroke-width="3"/></mask></defs>
<g mask="url(#cut)"><g fill="#e1e5e7" transform="translate(22 92) skewX(-12) scale({318/width} -0.055)">{big}</g></g>
<g fill="#bdc7d1" transform="translate(5 125) scale({342/subwidth} -0.016)">{small}</g>
<path d="M4 139h340" stroke="#b02e41" stroke-width="2"/><path d="M354 29h11v10h-11ZM350 59h11v10h-11Z" fill="#ef4f61"/>'''
put('assets/ui/rift_logo.svg',svg(logo,380,145))
put('assets/background/pilot.svg',svg('''<ellipse cx="48" cy="213" rx="38" ry="5" fill="#050b13" opacity=".7"/>
<path d="M31 49l4-18 9-9 15 2 9 9 1 18-10 9H42Z" fill="#101822" stroke="#344252" stroke-width="2"/>
<path d="M55 39l13 1-2 5-12-1Z" fill="#b77532"/>
<path d="M29 61l15-7 18 3 13 13 4 47-15 13-36-8-7-29Z" fill="#121e2a" stroke="#3a4959" stroke-width="2"/>
<path d="M34 65h27v40H34Z" fill="#1e2c3a"/><path d="M39 71h17l-8 15Z" fill="none" stroke="#788492" stroke-width="2"/>
<path d="M23 72l-9 8-5 47 10 16 11-8-3-38M73 75l11 12 6 43-8 13-10-8-2-35" fill="#101b27" stroke="#374858" stroke-width="2"/>
<path d="M30 120l33 2 5 42-8 42-16 1-2-43-7 44-17 1 3-47Z" fill="#0c141e" stroke="#334351" stroke-width="2"/>
<path d="M16 202l21 1 1 12H11ZM44 202l19-2 9 13-26 2Z" fill="#080e17"/>
<path d="M29 60l4 45M65 62l3 42M20 154h14M47 156h16" stroke="#5c6971" opacity=".6" stroke-width="2"/>''',100,225))

def rgba(h,a=1):
    return 'Color('+','.join(str(round(int(h[i:i+2],16)/255,4)) for i in (0,2,4))+f',{a})'
parts=['[gd_resource type="Theme" load_steps=18 format=3]',
       '[ext_resource type="FontFile" path="res://assets/fonts/DejaVuSans.ttf" id="1"]']
for i,name in enumerate(['arrow','check','unchecked','grabber'],2):
    parts.append(f'[ext_resource type="Texture2D" path="res://assets/icons/{name}.svg" id="{i}"]')
styles={
 'normal':('132031',.72,'354355',1), 'hover':('30202c',.95,'b14c5c',1),
 'pressed':('52212c',.95,'ed5869',1), 'focus':('301823',.25,'f87b87',2),
 'disabled':('121923',.6,'27313e',1), 'panel':('0c1624',.97,'344356',1),
 'slider':('243548',1,'405265',0), 'grabber':('cf5163',1,'f8818d',0),
 'scroll':('0a1320',.8,'0a1320',0), 'scroll_grab':('53677f',1,'53677f',0),
 'separator':('304052',1,'304052',0), 'empty':('000000',0,'000000',0)
}
for name,(bg,alpha,border,line) in styles.items():
    parts += [f'[sub_resource type="StyleBoxFlat" id="{name}"]',
              f'bg_color = {rgba(bg,alpha)}',f'border_color = {rgba(border)}']
    for edge in ('left','top','right','bottom'):
        parts.append(f'border_width_{edge} = {line}')
    if name in ['normal','hover','pressed','disabled']:
        parts += ['content_margin_left = 16.0','content_margin_right = 16.0','content_margin_top = 10.0','content_margin_bottom = 10.0']
    if name in ['slider','separator','scroll']:
        parts.append('content_margin_top = 2.0')
    if name == 'scroll_grab':
        parts += ['content_margin_left = 6.0','content_margin_top = 24.0']
parts += ['[resource]','default_font = ExtResource("1")','default_font_size = 18']
for cls in ['Button','OptionButton','CheckBox']:
    parts += [f'{cls}/colors/font_color = {rgba("e2e7ec")}',f'{cls}/colors/font_hover_color = {rgba("ffffff")}',
              f'{cls}/colors/font_pressed_color = {rgba("ffffff")}',f'{cls}/colors/font_disabled_color = {rgba("6f7b8a")}',
              f'{cls}/colors/font_focus_color = {rgba("ffffff")}']
    for state in ['normal','hover','pressed','disabled','focus']:
        parts.append(f'{cls}/styles/{state} = SubResource("{state if cls != "CheckBox" else ("focus" if state == "focus" else "empty")}")')
parts += ['OptionButton/icons/arrow = ExtResource("2")', 'OptionButton/constants/arrow_margin = 14',
          'OptionButton/constants/h_separation = 18','CheckBox/icons/checked = ExtResource("3")',
          'CheckBox/icons/unchecked = ExtResource("4")','CheckBox/constants/h_separation = 14',
          'Label/colors/font_color = '+rgba('e2e7ec'), 'PanelContainer/styles/panel = SubResource("panel")',
          'HSlider/styles/slider = SubResource("slider")','HSlider/styles/grabber_area = SubResource("grabber")',
          'HSlider/styles/grabber_area_highlight = SubResource("grabber")',
          'HSlider/icons/grabber = ExtResource("5")','HSlider/icons/grabber_highlight = ExtResource("5")',
          'VScrollBar/styles/scroll = SubResource("scroll")','VScrollBar/styles/grabber = SubResource("scroll_grab")',
          'VScrollBar/styles/grabber_highlight = SubResource("grabber")','VScrollBar/styles/grabber_pressed = SubResource("grabber")',
          'HSeparator/styles/separator = SubResource("separator")', 'PopupMenu/styles/panel = SubResource("panel")',
          'PopupMenu/styles/hover = SubResource("hover")','PopupMenu/colors/font_color = '+rgba('e2e7ec'),
          'PopupMenu/constants/v_separation = 18','PopupMenu/font_sizes/font_size = 18']
put('resources/theme/rift_theme.tres','\n\n'.join(parts)+'\n')

RATE=22050
def wav(name, data):
    data=np.asarray(data)
    assert np.max(np.abs(data))<1.0
    with wave.open(str(ROOT/f'assets/audio/{name}.wav'),'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed'))
        f.writeframes((data*32767).astype('<i2').tobytes())
for name,duration,start,end in [('ui_click',.11,750,420),('ui_back',.17,520,260),('ui_confirm',.24,650,1050)]:
    t=np.arange(int(RATE*duration))/RATE
    env=np.minimum(t/.008,1)*np.exp(-t*23)
    phase=2*np.pi*(start*t+(end-start)*t*t/(2*duration))
    wav(name,.16*np.sin(phase)*env+.035*np.sin(phase*2)*env)
t=np.arange(16*RATE)/RATE
drone=np.zeros_like(t)
for freq,amp in [(41,.045),(61.5,.028),(82,.02),(123,.012),(164,.008),(246,.004)]:
    drone+=amp*np.sin(2*np.pi*freq*t)*(0.85+0.15*np.cos(2*np.pi*t/8))
wav('hangar_drone',drone)
rng=np.random.default_rng(2089)
freq=np.fft.rfftfreq(len(t),1/RATE)
noise=rng.normal(size=len(freq))+1j*rng.normal(size=len(freq))
noise*=np.minimum(freq/110,1)/np.maximum(freq,100)**.55
rain=np.fft.irfft(noise,n=len(t)); rain=rain/np.max(np.abs(rain))*.12
wav('rain_air',rain)
print('Original SVG, Theme and audio assets generated.')

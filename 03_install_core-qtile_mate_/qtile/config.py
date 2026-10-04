# Copyright (c) 2025 JustAGuyLinux

from libqtile import bar, layout, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen, ScratchPad, DropDown
from libqtile.lazy import lazy
import os
import subprocess
from libqtile.widget import Image # Ensure this is present

from libqtile import hook
from colors import *

# ─── HELPER FUNCTIONS & HOOKS ─────────────────────────────────────────
def notify_layout():
    """Show current layout in notification"""
    def _notify_layout(qtile):
        layout_name = qtile.current_group.layout.name
        layout_map = {
            "monadtall": "Monad Tall",
            "treetab": "Tree Tab"
        }
        display_name = layout_map.get(layout_name, layout_name.title())
        subprocess.run(["notify-send", "Layout", display_name, "-t", "1500", "-u", "low"])
    return _notify_layout

def notify_restart():
    """Show restart notification"""
    def _notify_restart(qtile):
        subprocess.run(["notify-send", "Qtile", "Restarting...", "-t", "2000", "-u", "normal"])
    return _notify_restart

def toggle_float_center():
    """Toggle floating and center at 75% size"""
    def _toggle_float_center(qtile):
        window = qtile.current_window
        if window:
            was_floating = window.floating
            window.toggle_floating()
            if not was_floating and window.floating:
                screen = qtile.current_screen
                width = int(screen.width * 0.70)
                height = int(screen.height * 0.60)
                window.set_size_floating(width, height)
                window.center()
    return _toggle_float_center

def resize_left():
    """Resize window left - intuitive based on focus"""
    def _resize_left(qtile):
        if not qtile.current_window:
            return
        layout = qtile.current_layout.name
        group = qtile.current_group

        if layout in ["bsp", "columns"]:
            qtile.current_layout.grow_left()
        elif layout in ["monadtall", "monadwide", "tile", "ratiotile"]:
            current_idx = group.windows.index(qtile.current_window)
            if current_idx == 0:
                qtile.current_layout.shrink()
            else:
                qtile.current_layout.grow()
        else:
            qtile.current_layout.shrink()
    return _resize_left

def resize_right():
    """Resize window right - intuitive based on focus"""
    def _resize_right(qtile):
        if not qtile.current_window:
            return
        layout = qtile.current_layout.name
        group = qtile.current_group

        if layout in ["bsp", "columns"]:
            qtile.current_layout.grow_right()
        elif layout in ["monadtall", "monadwide", "tile", "ratiotile"]:
            current_idx = group.windows.index(qtile.current_window)
            if current_idx == 0:
                qtile.current_layout.grow()
            else:
                qtile.current_layout.shrink()
        else:
            qtile.current_layout.grow()
    return _resize_right

def focus_left():
    """Focus window to the left, or cycle if floating"""
    def _focus_left(qtile):
        if not qtile.current_window:
            return
        if qtile.current_layout.name == "floating" or qtile.current_window.floating:
            qtile.current_group.prev_window()
        else:
            qtile.current_layout.left()
    return _focus_left

def focus_right():
    """Focus window to the right, or cycle if floating"""
    def _focus_right(qtile):
        if not qtile.current_window:
            return
        if qtile.current_layout.name == "floating" or qtile.current_window.floating:
            qtile.current_group.next_window()
        else:
            qtile.current_layout.right()
    return _focus_right

@hook.subscribe.startup_once
def autostart():
    home = os.path.expanduser('~/.config/qtile/scripts/autostart.sh')
    subprocess.run([home])

@hook.subscribe.startup
def set_wallpaper():
    autostart = os.path.expanduser('~/.config/qtile/scripts/autostart.sh')
    with open(autostart) as f:
        for line in f:
            if 'feh' in line:
                cmd = line.strip().rstrip('&').strip()
                subprocess.Popen(cmd, shell=True)

@hook.subscribe.client_new
def fit_floating_media_players(window):
    """Automatically fit tall floating video windows to screen height with margins."""
    media_classes = ["mpv", "vlc", "totem", "celluloid", "qimgv"]
    
    wm_class = window.get_wm_class()
    if wm_class and any(c in wm_class for c in media_classes):
        window.floating = True
        screen = window.qtile.current_screen
        
        max_h = int(screen.height * 0.85)
        max_w = int(screen.width * 0.95)
        
        w, h = window.get_size() if hasattr(window, "get_size") else (800, 600)
        
        if h > max_h or w > max_w:
            aspect_ratio = w / float(h) if h > 0 else 1.0
            if h > max_h:
                h = max_h
                w = int(h * aspect_ratio)
            if w > max_w:
                w = max_w
                h = int(w / aspect_ratio)
            
            window.set_size_floating(w, h)
        
        window.center()


# ─── USER CONSTANTS ───────────────────────────────────────────────────
mod = "mod4"
terminal = "mate-terminal"
browser = "google-chrome"
whatsapp = "google-chrome --app=https://web.whatsapp.com"
virtmanager = "virt-manager"

colors, backgroundColor, foregroundColor, workspaceColor, foregroundColorTwo = monokai()


# ─── KEYBINDINGS ──────────────────────────────────────────────────────
keys = [

# === WM CONTROL ===
    Key([mod], "q", lazy.window.kill(), desc="Close focused window"),
    Key([mod, "shift"], "r", lazy.function(notify_restart()), lazy.restart(), desc="Restart Qtile"),
    Key([mod, "shift"], "q", lazy.shutdown(), desc="Exit Qtile"),
    Key([mod], "x", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/power")), desc="Power menu"),

# === LAUNCH ===
    Key([mod], "space", lazy.spawn("rofi -show drun -modi drun -line-padding 4 -hide-scrollbar -show-icons -theme ~/.config/qtile/rofi/config.rasi"), desc="Launch Rofi"),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "w", lazy.spawn(whatsapp), desc="Launch whatsapp"),
    Key([mod], "b", lazy.spawn(browser), desc="Launch browser"),
    Key([mod], "v", lazy.spawn(virtmanager), desc="Launch Virt Manager"),
    Key([mod, "shift"], "b", lazy.spawn(browser + " -private-window"), desc="Launch browser (private)"),
    Key([mod], "c", lazy.spawn("helium"), desc="Launch Helium"),
    Key([mod, "shift"], "c", lazy.spawn("helium --incognito"), desc="Launch Helium (incognito)"),
    Key([mod], "f", lazy.spawn("caja"), desc="Launch file manager"),
    Key([mod], "e", lazy.spawn("subl"), desc="Launch text editor"),
    Key([mod], "g", lazy.spawn("gimp"), desc="Launch GIMP"),
    Key([mod], "d", lazy.spawn("Discord"), desc="Launch Discord"),
    Key([mod], "o", lazy.spawn("obs"), desc="Launch OBS"),
    Key([mod], "slash", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/help")), desc="Show keybindings"),
    Key([mod, "shift"], "t", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/thememenu")), desc="Theme switcher"),

# === WINDOW NAVIGATION ===
    Key([mod], "Left", lazy.function(focus_left()), desc="Focus left"),
    Key([mod], "h", lazy.function(focus_left()), desc="Focus left"),
    Key([mod], "Right", lazy.function(focus_right()), desc="Focus right"),
    Key([mod], "l", lazy.function(focus_right()), desc="Focus right"),
    Key([mod], "Up", lazy.layout.up(), desc="Focus up"),
    Key([mod], "k", lazy.layout.up(), desc="Focus up"),
    Key([mod], "Down", lazy.layout.down(), desc="Focus down"),
    Key([mod], "j", lazy.layout.down(), desc="Focus down"),
    Key(["mod1"], "Tab", lazy.group.next_window(), desc="Alt-Tab cycle windows"),

# === WINDOW MOVE/SWAP ===
    Key([mod, "shift"], "Left",  lazy.layout.shuffle_left(),  lazy.layout.swap_left(),  desc="Swap window left"),
    Key([mod, "shift"], "h",     lazy.layout.shuffle_left(),  lazy.layout.swap_left(),  desc="Swap window left"),
    Key([mod, "shift"], "Right", lazy.layout.shuffle_right(), lazy.layout.swap_right(), desc="Swap window right"),
    Key([mod, "shift"], "l",     lazy.layout.shuffle_right(), lazy.layout.swap_right(), desc="Swap window right"),
    Key([mod, "shift"], "Up",    lazy.layout.shuffle_up(),    desc="Swap window up"),
    Key([mod, "shift"], "k",     lazy.layout.shuffle_up(),    desc="Swap window up"),
    Key([mod, "shift"], "Down",  lazy.layout.shuffle_down(),  desc="Swap window down"),
    Key([mod, "shift"], "j",     lazy.layout.shuffle_down(),  desc="Swap window down"),

# === WINDOW RESIZE ===
    Key([mod, "control"], "Left",  lazy.function(resize_left()),  desc="Resize window left"),
    Key([mod, "control"], "h",     lazy.function(resize_left()),  desc="Resize window left"),
    Key([mod, "control"], "Right", lazy.function(resize_right()), desc="Resize window right"),
    Key([mod, "control"], "l",     lazy.function(resize_right()), desc="Resize window right"),
    Key([mod, "control"], "Up",    lazy.layout.grow_up(),   lazy.layout.grow(),   lazy.layout.decrease_nmaster(), desc="Grow window up"),
    Key([mod, "control"], "k",     lazy.layout.grow_up(),   lazy.layout.grow(),   lazy.layout.decrease_nmaster(), desc="Grow window up"),
    Key([mod, "control"], "Down",  lazy.layout.grow_down(), lazy.layout.shrink(), lazy.layout.increase_nmaster(), desc="Grow window down"),
    Key([mod, "control"], "j",     lazy.layout.grow_down(), lazy.layout.shrink(), lazy.layout.increase_nmaster(), desc="Grow window down"),
    Key([mod, "control"], "equal", lazy.layout.normalize(), desc="Reset all window sizes"),

# === LAYOUTS ===
    Key([mod], "Tab", lazy.next_layout(), lazy.function(notify_layout()), desc="Cycle layouts"),
    Key([mod], "t", lazy.layout.toggle_split(), desc="Toggle split direction (BSP)"),
    Key([mod], "y", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/layoutmenu")), desc="Layout menu"),

# === WINDOW STATE ===
    Key([mod, "shift"], "space", lazy.function(toggle_float_center()), desc="Toggle floating, center"),
    Key([mod, "shift"], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen"),

# === SCRATCHPADS ===
    Key([mod, "shift"], "Return", lazy.group['scratchpad'].dropdown_toggle('terminal'), desc="Toggle terminal scratchpad"),
    Key([mod, "mod1"], "a", lazy.group['scratchpad'].dropdown_toggle('audio'), desc="Toggle audio scratchpad"),

# === MEDIA & BRIGHTNESS ===
    Key([mod], "F12", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/changevolume up")), desc="Volume up"),
    Key([mod], "F11", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/changevolume down")), desc="Volume down"),
    Key([mod], "F10", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/changevolume mute")), desc="Mute/Unmute"),
    Key([], "XF86AudioRaiseVolume", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/changevolume up")), desc="Volume up"),
    Key([], "XF86AudioLowerVolume", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/changevolume down")), desc="Volume down"),
    Key([], "XF86AudioMute", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/changevolume mute")), desc="Mute/Unmute"),
    Key([], "XF86MonBrightnessUp", lazy.spawn("xbacklight +10"), desc="Brightness up"),
    Key([], "XF86MonBrightnessDown", lazy.spawn("xbacklight -10"), desc="Brightness down"),

# === SCREENSHOTS ===
    Key([mod], "s", lazy.spawn("flameshot full --path " + os.path.expanduser("~/Screenshots/")), desc="Screenshot (full)"),
    Key([mod, "shift"], "s", lazy.spawn("flameshot gui --path " + os.path.expanduser("~/Screenshots/")), desc="Screenshot (region)"),
    Key([], "Print", lazy.spawn("flameshot full --path " + os.path.expanduser("~/Screenshots/")), desc="Screenshot (full)"),
    Key([mod], "Print", lazy.spawn("flameshot gui --path " + os.path.expanduser("~/Screenshots/")), desc="Screenshot (region)"),
]


# ─── GROUPS & SCRATCHPADS ─────────────────────────────────────────────
groups = [
    Group('1', label="|  [R]"),
    Group('2', label="|  [T]"),
    Group('3', label="|  [X]"),
    Group('4', label="|  PC-STATS  |"),
]

groups.append(ScratchPad("scratchpad", [
    DropDown("terminal", "mate-terminal", width=0.6, height=0.6, x=0.2, y=0.02, opacity=0.95),
    DropDown("audio", "mate-terminal --class=audio -e pulsemixer", width=0.5, height=0.5, x=0.25, y=0.02, opacity=0.95),
]))

for i in groups:
    if i.name != "scratchpad":
        keys.extend(
            [
                Key(
                    [mod],
                    i.name,
                    lazy.group[i.name].toscreen(),
                    desc="Switch to group {}".format(i.name),
                ),
                Key(
                    [mod, "shift"],
                    i.name,
                    lazy.window.togroup(i.name, switch_group=True),
                    desc="Switch to & move focused window to group {}".format(i.name),
                ),
            ]
        )


# ─── LAYOUTS ──────────────────────────────────────────────────────────
layout_theme = {
    "margin": 5,
    "border_width": 4,
    "border_focus": colors[3],
    "border_normal": colors[1]
}

layouts = [
    layout.TreeTab(
        active_bg=colors[3][0],
        active_fg=backgroundColor,
        inactive_bg=colors[1][0],
        inactive_fg=foregroundColor,
        bg_color=backgroundColor,
        border_width=2,
        font='FreeMono',
        fontsize=14,
        panel_width=200,
        sections=['Main'],
        section_fontsize=14,
        section_fg=foregroundColorTwo,
    ),
    layout.MonadTall(**layout_theme),
]


# ─── BAR & WIDGETS ────────────────────────────────────────────────────
widget_defaults = dict(
    font='FreeMono',
    background=backgroundColor,
    foreground=foregroundColor,
    fontsize=14,
    padding=4,
)
extension_defaults = widget_defaults.copy()

def create_separator():
    return widget.TextBox(
        text="|",
        foreground=foregroundColorTwo,
        padding=8,
        fontsize=14
    )

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.Spacer(length=8),
                (widget.CurrentLayoutIcon(
                    custom_icon_paths=[os.path.expanduser("~/.config/qtile/icons/layouts")],
                    foreground=colors[6][0],
                    scale=0.65,
                    padding=4
                ) if hasattr(widget, "CurrentLayoutIcon") else widget.CurrentLayout(
                    foreground=colors[6][0],
                    padding=4
                )),

                widget.TextBox(
                    text="|    WORK-SPACE  ",
                    foreground=foregroundColorTwo,
                    padding=8,
                    fontsize=14
                ),
                
                widget.GroupBox(
                    toggle=False,
                    disable_drag=True,
                    use_mouse_wheel=False,

                    block_highlight_text_color=foregroundColor,  
                    active=foregroundColorTwo,                    
                    inactive=foregroundColorTwo,                        

                    highlight_method='line',
                    highlight_color=[backgroundColor, backgroundColor],

                    this_current_screen_border=backgroundColor,

                    this_screen_border=colors[1][0],
                    other_current_screen_border=colors[1][0],
                    other_screen_border=backgroundColor,

                    urgent_alert_method='text',
                    urgent_text=colors[10][0],

                    rounded=False,
                    margin_x=0,
                    margin_y=3,
                    padding_x=10,
                    padding_y=6,
                    borderwidth=3,
                    hide_unused=False,
                ),
                
                widget.WindowName(
                    format='',
                    max_chars=60,
                    foreground=foregroundColor,
                    padding=6
                ),
                                widget.GenPollText(
                    func=lambda: " CAPS " if "Caps Lock:   on" in subprocess.run(['xset', 'q'], capture_output=True, text=True).stdout else "",
                    update_interval=1,
                    padding=4,
                    foreground=backgroundColor,
                    background=colors[10][0],
                ),

                # === STORAGE & RAM AT TOP ===
                create_separator(),
                widget.DF(
                    partition="/",  # Target mount point (e.g., '/' or '/home')
                    format="SSD: {uf}{m} / {s}{m}",  # Output format: Remaining / Total
                    measure="G",  # Measure in Gigabytes ('G'), Megabytes ('M'), or Bytes ('B')
                    visible_on_warn=False,  # Keep visible at all times
                    warn_space=10,  # Highlight if remaining space drops below 10 GB
                    warn_color="ff0000",  # Color applied when below warn_space
                    update_interval=60,  # Refresh every 60 seconds
                ),

                create_separator(),
                widget.Memory(
                    format='RAM: {MemUsed: .0f}{mm}/{MemTotal: .0f}{mm}',
                    foreground=colors[4][0],
                    padding=4
                ),
                create_separator(),
                widget.Battery(
                    format='{char} {percent:2.0%}',
                    charge_char='Charging',
                    discharge_char='Power',
                    full_char='Full',
                    empty_char='Low',
                    unknown_char='Unknown',
                    update_interval=5,
                    show_short_text=False
                ),

                create_separator(),
                widget.Clock(
                    format='%A %-d %B',
                    foreground=foregroundColor,
                    padding=6,
                    mouse_callbacks={'Button1': lazy.spawn('gsimplecal')}
                ),
                create_separator(),
                widget.Clock(
                    format='%T',
                    foreground=colors[6][0],
                    padding=6,
                ),
                create_separator(),
                widget.Image(
                    filename="/usr/share/icons/rami/panel/16/system-shutdown-panel.svg",
                    scale=True,
                    mouse_callbacks={'Button1': lazy.spawn(os.path.expanduser('~/.config/qtile/scripts/power'))},
                    margin_x=4,
                    margin_y=4
                ),
                widget.Spacer(length=8),
            ],
            34,
            background=backgroundColor,
            margin=[0, 0, 0, 0],
        ),
        
        left=bar.Bar(
            [

                widget.Spacer(length=10),
                widget.ThermalSensor(
                    format='TEMP {temp:.0f}{unit}',
                    foreground=colors[3][0],
                    threshold=80,
                    foreground_alert='ff0000',
                    update_interval=1.0,
                ),
                widget.Spacer(length=10),
                widget.CPU(
                    format='CPU {load_percent}%',
                    foreground=colors[3][0],
                    update_interval=1.0,
                ),

                # Push the brand label to the bottom
                widget.Spacer(),

                # === LAPTOP BRAND AT BOTTOM ===
                widget.TextBox(
                    text="LENOVO THINKPAD",  # Replace with your laptop brand (e.g. DELL, HP, ASUS)
                    foreground=colors[6][0],
                    fontsize=11,
                ),
                widget.Spacer(length=10),
            ],
            40,
            background=backgroundColor,
            margin=[0, 0, 0, 0],
        ),
    ),
]


# ─── MOUSE & FLOATING RULES ───────────────────────────────────────────
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False

floating_layout = layout.Floating(
    border_width=4,
    border_focus=colors[3],
    border_normal=colors[1],
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(wm_class="qimgv"),
        Match(wm_class="mpv"),
        Match(wm_class="vlc"),
        Match(wm_class="totem"),
        Match(wm_class="celluloid"),
        Match(wm_class="nwg-look"),
        Match(wm_class="pavucontrol"),
        Match(wm_class="Galculator"),
        Match(wm_class="confirmreset"),
        Match(wm_class="makebranch"),
        Match(wm_class="maketag"),
        Match(wm_class="ssh-askpass"),
        Match(title="branchdialog"),
        Match(title="pinentry"),
    ]
)

auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
auto_minimize = True
wl_input_rules = None

wmname = "qtile"
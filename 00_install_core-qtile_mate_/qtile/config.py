# Copyright (c) 2025 JustAGuyLinux

from libqtile import bar, layout, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen, ScratchPad, DropDown
from libqtile.lazy import lazy
import os
import subprocess
from libqtile import bar, layout, widget
from libqtile.widget import Image # Ensure this is present

from libqtile import hook
from colors import *

# ─── HiDPI / 4K displays ──────────────────────────────────────────────
# Qtile doesn't scale, and apps are launched by qtile itself (lazy.spawn),
# not by autostart.sh — so scaling has to be set here, in qtile's own
# environment, for those apps to inherit it. If type is tiny on a 4K
# screen, uncomment this block and restart qtile.
#
# Values give ~200%. For ~150% use Xft.dpi 144, drop GDK_SCALE, and set the
# cursor sizes to 36.
# subprocess.run(["xrdb", "-merge"], text=True,
#                input="Xft.dpi: 192\nXcursor.size: 48\n")  # X apps, fonts + cursor
# os.environ["GDK_SCALE"] = "2"          # GTK app widgets (caja, subl)
# os.environ["GDK_DPI_SCALE"] = "0.5"    # cancel GTK's double font scaling
# os.environ["QT_AUTO_SCREEN_SCALE_FACTOR"] = "1"   # Qt apps follow Xft.dpi
# os.environ["XCURSOR_SIZE"] = "48"
# ──────────────────────────────────────────────────────────────────────

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
                # Only resize/center when going from tiled to floating
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

def toggle_treetab():
    """Toggle between TreeTab (qtile's closest thing to bspwm-tabs) and MonadTall"""
    def _toggle_treetab(qtile):
        group = qtile.current_group
        target = "monadtall" if group.layout.name == "treetab" else "treetab"
        group.setlayout(target)
        subprocess.run(["notify-send", "Layout",
                        "Tree Tab" if target == "treetab" else "Monad Tall",
                        "-t", "1500", "-u", "low"])
    return _toggle_treetab

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



mod = "mod4"
terminal = "mate-terminal"
browser = "google-chrome"
whatsapp = "google-chrome --app=https://web.whatsapp.com"

colors, backgroundColor, foregroundColor, workspaceColor, foregroundColorTwo = monokai()

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
    #Key([mod], "w", lazy.function(toggle_treetab()), desc="Toggle tab group (TreeTab)"),
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

groups = [
    Group('1', label="|  WORK-SPACE  ", layout="treetab"),
    Group('2', label="|  PC-STATS  |", layout="treetab"),
]

# Define scratchpads
# Define scratchpads
groups.append(ScratchPad("scratchpad", [
    # Plain terminal scratchpad using mate-terminal
    DropDown("terminal", "mate-terminal", width=0.6, height=0.6, x=0.2, y=0.02, opacity=0.95),
    DropDown("audio", "mate-terminal --class=audio -e pulsemixer", width=0.5, height=0.5, x=0.25, y=0.02, opacity=0.95),
]))



for i in groups:
    if i.name != "scratchpad":  # Skip scratchpad groups
        keys.extend(
            [
                # mod1 + letter of group = switch to group
                Key(
                    [mod],
                    i.name,
                    lazy.group[i.name].toscreen(),
                    desc="Switch to group {}".format(i.name),
                ),
                # mod1 + shift + letter of group = switch to & move focused window to group
                Key(
                    [mod, "shift"],
                    i.name,
                    lazy.window.togroup(i.name, switch_group=True),
                    desc="Switch to & move focused window to group {}".format(i.name),
                ),
                # Or, use below if you prefer not to switch to that group.
                # # mod1 + shift + letter of group = move focused window to group
                # Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
                #     desc="move focused window to group {}".format(i.name)),
            ]
        )

# Define layouts and layout themes
layout_theme = {
        "margin":5,
        "border_width": 4,
        "border_focus": colors[3],
        "border_normal": colors[1]
    }

# Layout preference by monitor type:
# MonadTall - Default layout (master-stack tiling)
# BSP - Traditional monitors (16:9, 4:3)
# Columns - Ultrawide monitors (21:9, 32:9)
# Layout preference by monitor type:
# TreeTab    - Default layout (Vertical tabbed side panel)
# MonadTall  - Master-stack tiling
# BSP        - Traditional monitors (16:9, 4:3)
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

# Updated widget defaults to match Polybar styling
widget_defaults = dict(
    font='FreeMono',  # Match Polybar font
    background=backgroundColor,
    foreground=foregroundColor,
    fontsize=14,  # Increased font size
    padding=4,
)
extension_defaults = widget_defaults.copy()

# Custom separator to match Polybar
def create_separator():
    return widget.TextBox(
        text="|",
        foreground=foregroundColorTwo,  # disabled color
        padding=8,
        fontsize=14
    )


screens = [
    Screen(
        top=bar.Bar(
            [
                # Left modules - Layout icon, workspaces, window title
                widget.Spacer(length=8),
                # CurrentLayoutIcon was removed in qtile 0.33+ (forky ships 0.35).
                # Fall back to CurrentLayout (text) on newer qtile; keep icons
                # everywhere they're still available (trixie ships 0.31).
                (widget.CurrentLayoutIcon(
                    custom_icon_paths=[os.path.expanduser("~/.config/qtile/icons/layouts")],
                    foreground=colors[6][0],
                    scale=0.65,
                    padding=4
                ) if hasattr(widget, "CurrentLayoutIcon") else widget.CurrentLayout(
                    foreground=colors[6][0],
                    padding=4
                )),

                
                widget.GroupBox(
                    toggle=False,
                    disable_drag=True,
                    use_mouse_wheel=False,

                    # --- Tab Text Muting & Unmuting ---
                    block_highlight_text_color=foregroundColor,  
                    active=foregroundColorTwo,                    
                    inactive=foregroundColorTwo,                       

                    # --- Visual Indicators (Borders) ---
                    highlight_method='line',
                    highlight_color=[backgroundColor, backgroundColor],

                    # --- Active border indicator ---
                    this_current_screen_border=backgroundColor,#colors[3][0],

                    # --- Inactive border indicators ---
                    this_screen_border=colors[1][0],
                    other_current_screen_border=colors[1][0],
                    other_screen_border=backgroundColor,

                    # --- Alert Formatting ---
                    urgent_alert_method='text',
                    urgent_text=colors[10][0],

                    # --- Spacing & Padding ---
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

                # Right modules
                widget.GenPollText(
                    func=lambda: " CAPS " if "Caps Lock:   on" in subprocess.run(['xset', 'q'], capture_output=True, text=True).stdout else "",
                    update_interval=1,
                    padding=4,
                    foreground=backgroundColor,
                    background=colors[10][0],
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
    ),
]

# Drag floating layouts.
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
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="qimgv"),  # q image viewer
        Match(wm_class="nwg-look"),  # nwg-look (GTK theme manager)
        Match(wm_class="pavucontrol"),  # pavucontrol
        Match(wm_class="Galculator"),  # calculator
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

wmname = "qtile"

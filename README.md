# Debian-Qtile-Mate Starter Kit for Debian 12/13
<img align="left"  src="https://user-images.githubusercontent.com/32820131/79635263-47d9d580-8170-11ea-87b1-943144be83d7.png" width="90"> 
This is Qtile-Mate setup script for Debian-based systems.
Features dynamic tiling layouts, powerful keybindings, a unified theme switcher, and a polished desktop experience — ready to roll out of the box.


## 📦 System Requirements

- **Debian 12 (Bookworm)** - Uses pipx installation method
- **Debian 13 (Trixie)** - Uses native qtile package from repository
- **Ubuntu** and other Debian-based systems - Uses pipx installation method

The installer automatically detects your system version and chooses the appropriate installation method.

## Installation Method

The installer automatically chooses the best method based on your system:

### Debian 13 (Trixie) and newer ✅ Recommended
- Uses the native `qtile` package from Debian repositories (v0.31.0)
- Simple and clean: `sudo apt install qtile python3-psutil`
- **Stable and tested** - Debian's rigorous testing ensures reliability
- All dependencies handled automatically by the package manager
- Integrates seamlessly with the system
- Better system integration than pipx installation
- **Note:** `python3-psutil` is required for CPU and memory monitoring widgets in the qtile bar


The main script `install` can exec all scripts or only a select list:
  * `install`: exec all scripts interactively.
  * `install -l`: list all scripts.
  * `install -d`: install all scripts with default option Y.
  * `install -a 5,8-12`: exec selected scripts.
  * `install -a grub`: exec all actions with `grub` in description.

&nbsp; 
## 🚀 Quick Start

```bash
git clone https://github.com/karoney-kn/Debian-Qtile-Mate.git
cd Debian-Qtile-Mate
chmod +x install.sh
./install.sh
```

### <img align="center" width="450" src="https://user-images.githubusercontent.com/32820131/79147593-764c5f00-7dc4-11ea-9ca2-f2569260928f.png">
#### <img align="center" width="450" src="https://user-images.githubusercontent.com/32820131/79147594-76e4f580-7dc4-11ea-9f2c-56376bd9e6fa.png">

### <img align="center" width="450" src="https://user-images.githubusercontent.com/32820131/79147600-777d8c00-7dc4-11ea-9e01-f3d072fa8961.png">
<img align="center" width="450" src="https://user-images.githubusercontent.com/32820131/81058996-de77f780-8ecf-11ea-9ec0-aa089c637c8a.png">

&nbsp; 
## Install
  * Install Debian using netinstall image. Its recommended don't install `Debian desktop environment`, install only `standard system utilities`.
<img align="center" width="700" src="https://user-images.githubusercontent.com/32820131/101158317-d467d400-362b-11eb-8759-9d3beb40a20c.png">
  
  * Connect to Internet. If you need to connect to WIFI network in CLI you can do:
  ```
  ip a                                            # To get your wlan interface name, mine is wlp5s0
  iwlist wlp5s0 scan | egrep "Address|ESSID"      # To get available wifi networks
  wpa_supplicant -B -i wlp5s0 -c <(wpa_passphrase YOUR-SSID YOUR-PASS)  # To authenticate in your wifi network
  dhclient -v wlp5s0                              # To get DHCP IP
  ```
  * Install git: `apt install git`
  * Clone or download this project: `git clone https://github.com/leomarcov/debian-openbox`
  * Exec `install` script and select scripts you want to install.
  
```
$ ./install -h
Exec a set of scripts
Usage: install [-l] [-a <actions>] [-y] [-d] [-h]
   -l     Only list actions 
   -a <actions> Filter selected actions by number range or text pattern (comma separated)
   -y     Auto-answer yes to all actions
   -d     Auto-answer default to all actions
   -h     Show this help


# Exec all actions interactively:
$ ./install

# Exec all actions and answer yes to all (no ask):
$ ./install -y

# Exec all actions and answer default to all (no ask and only exec actions with default Y):
$ ./install -d

# Exec only actions 5,7,10,11,12,13,14 and 15:
$ ./install -a 5,7,10-15

# Exec only actions with grub text in description:
$ ./install -a grub

# List all actions:
$ ./install -l
 NUM  TYPE  DESCRIPTION
=======================================================================================================================
 [1]   CONFIG   Add Debian repositories contrib, non-free and non-free-firmware (Y)
 [2]   INSTALL  Install some basic CLI packages (Y)
 [3]   INSTALL  Install and configure Qtile-Mate window manager and Desktop (Y)
 [4]   INSTALL  Install some basic GUI packages (Y)
 [5]   CONFIG   Config modified .profile file with new path (sbin for all users) and color definitions (Y)
 [6]   CONFIG   Config new bash prompt (Y)
 [7]   CONFIG   Config system for show text messages during boot time (Y)
 [8]   CONFIG   Config GRUB for disable recovery and UEFI entreis (N)
 [9]   CONFIG   Config GRUB with password protection to prevent users editing entries (N)
 [10]  CONFIG   Config GRUB for skip menu (timeout=0) (N)
 [11]  CONFIG   Config users home directories permissions to 750 (for current and future users) (Y)
 [12]  CONFIG   Enable CTRL+ALT+BACKSPACE shortcut for kill X server (Y)
 [13]  CONFIG   Install sudo and add user 1000 to sudo group (Y)
 [14]  SCRIPT   Install script to control screen brightness (N)
 [15]  SCRIPT   Config Linux login in text mode (tty) using ufetch style and install a tty locker (physlock) (Y)
 [16]  INSTALL  Install CUPS printer system and add user 1000 to lpadmin group (N)
 [17]  INSTALL  Install Google Chrome, add to repositories and set has default browser (Y)
 [18]  INSTALL  Install OnlyOffice package and add to repositories (N)
 [19]  INSTALL  Install Sublime Text, add repositories and set as default editor (Y)
 [20]  INSTALL  Install vim editor, and apply some configs and plugins (Y)
 [21]  INSTALL  Install VirtualBox Guest Additions from Oracle (N)
 [22]  INSTALL  Install VirtualBox and Extension Pack from Oracle and add to repositories (N)
 [23]  INSTALL  Install Visual Studio Code and add repositories (N)
 [24]  CLEAN    Remove unnecesary packages and saved .deb files (N)

```
  
&nbsp; 
## Customize
The script can be easily customized. Each `install.sh` script placed in a subdirectory are automatillacy recognized by `install`.
  * For **remove action** simply delete the action directory.
  * For **add action** simply add new folder and place inside `install.sh` script and dependences. `install.sh` script must have this header:
  ```
  #!/bin/bash
  # ACTION: Description of the action
  # INFO: Optional additional info
  # DEFAULT: y
  
  script commands to do action
  
  ```

## 🔑 Keybindings

Press `Super + /` to open the keybinding cheat sheet in rofi, grouped by category.

### Launch
| Shortcut             | Action                          |
|----------------------|---------------------------------|
| `Super + Enter`      | Launch terminal (kitty)         |
| `Super + Space`      | Launch Rofi                     |
| `Super + /`          | Show keybindings                |
| `Super + B`          | Launch browser                  |
| `Super + Shift + B`  | Launch Firefox (Private)        |
| `Super + F`          | Launch file manager             |
| `Super + E`          | Launch text editor              |
| `Super + D`          | Launch Discord                  |
| `Super + G`          | Launch GIMP                     |
| `Super + O`          | Launch OBS                      |
| `Print` / `Super + S`  | Screenshot (full screen)      |
| `Super + Print` / `Super + Shift + S` | Screenshot (region select) |

### Navigation
| Shortcut             | Action                          |
|----------------------|---------------------------------|
| `Super + Arrow Keys` | Move focus directionally        |
| `Super + J/K`        | Focus next/previous window      |
| `Alt + Tab`          | Cycle windows                   |
| `Super + Shift + Arrow Keys` | Move window directionally |
| `Super + Shift + J/K`| Move window up-left/down-right  |
| `Super + Ctrl + Arrow Keys`  | Resize window directionally |
| `Super + 1–9,0,-,=`  | Switch to workspace (1-12)     |
| `Super + Shift + 1–9,0,-,=` | Move window to workspace  |

### Layout & Theming
| Shortcut             | Action                          |
|----------------------|---------------------------------|
| `Super + Tab`        | Cycle through layouts           |
| `Super + Shift + L`  | Layout menu                     |
| `Super + Shift + T`  | Theme switcher                  |
| `Super + T`          | Toggle split direction in BSP   |
| `Super + Shift + Space` | Toggle floating (centered 75%) |
| `Super + Shift + Z`  | Reset all window sizes          |

### Window Management
| Shortcut             | Action                          |
|----------------------|---------------------------------|
| `Super + Q`          | Close focused window            |
| `Super + Shift + R`  | Restart Qtile                   |
| `Super + Shift + Q`  | Exit Qtile                      |
| `Super + X`          | Power menu                      |


---

## 🖥️ Layouts

Cycle layouts with `Super + Tab` or pick one from the layout menu with `Super + Shift + L`.

- **`MonadTall`** — Classic master-stack
- **`BSP`** — Binary space partitioning
- **`Columns`** — Dynamic column layout (3 columns)
- **`Max`** — Fullscreen stacked windows
- **`Floating`** — Free window placement
- **`Zoomy`** — Zoom-focused layout

---

## 📂 Configuration Files

```
~/.config/qtile/
├── config.py                    # Main Qtile configuration
├── colors.py                    # Color scheme definitions (12 themes)
├── themes/                      # Pre-generated theme templates
│   ├── github_dark/
│   │   ├── dunstrc              # Dunst notification config
│   │   ├── config.rasi          # Rofi app launcher theme
│   │   ├── power.rasi           # Rofi power menu theme
│   │   └── keybinds.rasi        # Rofi keybinds display theme
│   ├── dracula/
│   │   └── ...
│   └── .../                     # (12 theme directories total)
├── dunst/dunstrc                # Active dunst config (swapped on theme switch)
├── rofi/
│   ├── config.rasi              # Active rofi config (swapped on theme switch)
│   ├── power.rasi               # Active power menu config
│   └── keybinds.rasi            # Active keybinds display config
├── picom/picom.conf             # Compositor configuration
├── wallpaper/                   # Wallpaper collection (one per theme)
└── scripts/
    ├── autostart.sh             # Startup: polkit, feh, picom, dunst, xsettingsd
    ├── thememenu                # Theme switcher script
    ├── help                     # Keybind cheat sheet (auto-parsed from config.py)
    ├── power                    # Rofi power menu
    ├── layoutmenu               # Rofi layout switcher
    └── changevolume             # Volume control with notifications
```

&nbsp;  
## Lincense
Debian-Qtile-Mate license is [GPLv3](LICENSE)


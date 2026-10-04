#!/bin/sh

# polkit
lxpolkit &

# background
feh --bg-fill /usr/share/backgrounds/mate/desktop/TzoneNSO.jpg &

# GTK live theme updates
xsettingsd &

# compositor
picom --config ~/.config/qtile/picom/picom.conf -b &

# Notifications
dunst -config ~/.config/qtile/dunst/dunstrc &

# First-login welcome (shown once, dismissable)
if [ ! -f "$HOME/.cache/qtile/welcomed" ]; then
	mkdir -p "$HOME/.cache/qtile"
	touch "$HOME/.cache/qtile/welcomed"
	(sleep 3; notify-send -u normal -t 15000 \
		"Welcome to Qtile" \
		"Press Super + / anytime to see all keybindings.&#10;See ~/QUICKSTART-qtile.md for a cheat sheet.") &
fi

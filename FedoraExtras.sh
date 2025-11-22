#!/usr/bin/env bash

# Require root
if [ "$EUID" -ne 0 ]; then
    echo "This script must run as root."
    echo "Please start again using:"
    echo "  sudo $0"
    exit 1
fi

echo
echo "=== Fedora Setup Extras ==="
echo
echo "1) Update DNF first"
echo "2) Enable minimize & maximize window buttons"
echo "3) Enable full Flatpak support"
echo "4) Enable RPM Fusion (incl. Appstream)"
echo "5) Install multimedia codecs"
echo "6) Reboot when done"
echo "0) Cancel"
echo
echo "Enter the desired options separated by spaces."
echo "Example: 1 2 4 5 6"
echo

read -p "Selection: " choices

do_update=0
do_buttons=0
do_flatpak=0
do_rpmfusion=0
do_codecs=0
do_reboot=0

for c in $choices; do
    case "$c" in
        1) do_update=1 ;;
        2) do_buttons=1 ;;
        3) do_flatpak=1 ;;
        4) do_rpmfusion=1 ;;
        5) do_codecs=1 ;;
        6) do_reboot=1 ;;
        0) echo "Cancelled."; exit 0 ;;
        *) echo "Unknown option: $c" ;;
    esac
done

echo
echo "Starting tasks..."
echo

[ $do_update -eq 1 ] && {
    echo "--- Updating DNF packages ---"
    dnf upgrade -y
}

[ $do_buttons -eq 1 ] && {
    echo "--- Enabling window buttons ---"
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
}

[ $do_flatpak -eq 1 ] && {
    echo "--- Enabling full Flatpak support ---"
    dnf install -y flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

[ $do_rpmfusion -eq 1 ] && {
    echo "--- Enabling RPM Fusion ---"
    dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    echo "--- Installing RPM Fusion Appstream metadata ---"
    dnf install -y rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data
}

[ $do_codecs -eq 1 ] && {
    if [ $do_rpmfusion -ne 1 ]; then
        echo "Error: Multimedia codecs require RPM Fusion. Enable option 4."
        exit 1
    fi

    echo "--- Installing multimedia codecs ---"
    dnf groupupdate -y multimedia
    dnf groupupdate -y sound-and-video
    dnf install -y libavcodec-freeworld
}

[ $do_reboot -eq 1 ] && {
    echo
    echo "Rebooting in 10 seconds..."
    sleep 10
    systemctl reboot
}

echo
echo "Done."
echo "You can run this script again anytime to enable more features."
echo


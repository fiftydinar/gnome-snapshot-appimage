#!/bin/sh

set -eux

ARCH="$(uname -m)"
PACKAGE=snapshot
URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

VERSION=$(pacman -Q "$PACKAGE" | awk 'NR==1 {print $2; exit}')
[ -n "$VERSION" ] && echo "$VERSION" > ~/version

# Variables used by quick-sharun
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export OUTNAME="$PACKAGE"-"$VERSION"-anylinux-"$ARCH".AppImage
export DESKTOP=/usr/share/applications/org.gnome.Snapshot.desktop
export ICON=/usr/share/icons/hicolor/scalable/apps/org.gnome.Snapshot.svg
export DEPLOY_PIPEWIRE=1
export DEPLOY_OPENGL=1
export DEPLOY_VULKAN=1
export DEPLOY_GSTREAMER=1
export STARTUPWMCLASS=snapshot # For Wayland, this is 'org.gnome.Snapshot', so this needs to be changed in desktop file manually by the user in that case until some potential automatic fix exists for this

# DEPLOY ALL LIBS
wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
./quick-sharun /usr/bin/snapshot /usr/lib/libglycin*

## Manually copy glycin loaders, for camera to work, gallery doesn't work yet
cp -rv /usr/lib/glycin-loaders ./AppDir/shared/lib
cp -rv /usr/share/glycin-loaders/ ./AppDir/share
## Patch glycin config to look into right libraries
sed -i 's|/usr/lib/glycin-loaders/1+/||g' ./AppDir/share/glycin-loaders/*/*/*

## Further debloat locale
find ./AppDir/share/locale -type f ! -name '*glib*' ! -name '*snapshot*' -delete

## Set gsettings to save to keyfile, instead to dconf
echo "GSETTINGS_BACKEND=keyfile" >> ./AppDir/.env

# MAKE APPIMAGE WITH URUNTIME
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage
./uruntime2appimage

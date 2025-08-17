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
export PATH_MAPPING_RELATIVE=1 # GTK applications are usually hardcoded to look into /usr/share, especially noticeable in non-working locale, looking for better solution which doesn't change working directory
export DEPLOY_PIPEWIRE=1
export DEPLOY_LOCALE=1

# Prepare AppDir
mkdir -p ./AppDir/shared/lib

# DEPLOY ALL LIBS
wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
GSK_RENDERER=cairo ./quick-sharun /usr/bin/snapshot /usr/lib/libgst* /usr/lib/gstreamer-*/*.so /usr/lib/libglycin*

## Manually copy glycin loaders, for camera to work, gallery doesn't work yet
cp -rv /usr/lib/glycin-loaders ./AppDir/shared/lib
cp -rv /usr/share/glycin-loaders/ ./AppDir/share
## Patch glycin config to look into right libraries
sed -i 's|/usr/lib|././/lib|g' ./AppDir/share/glycin-loaders/*/*/*

## Patch StartupWMClass to work on X11
## Doesn't work when ran in Wayland, as it's 'org.gnome.Snapshot' instead.
## It needs to be manually changed by the user in this case.
sed -i '/^\[Desktop Entry\]/a\
StartupWMClass=snapshot
' ./AppDir/*.desktop

## Further debloat locale
find ./AppDir/share/locale -type f ! -name '*glib*' ! -name '*snapshot*' -delete

## Set gsettings to save to keyfile, instead to dconf
echo "GSETTINGS_BACKEND=keyfile" >> ./AppDir/.env

## Force use of cairo backend
echo "GSK_RENDERER=cairo" >> ./AppDir/.env

## Regenerate lib dir list for sharun, as we copy new libs
./quick-sharun l -g

# MAKE APPIMAGE WITH URUNTIME
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage
./uruntime2appimage

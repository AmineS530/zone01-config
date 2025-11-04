#!/usr/bin/env bash
# download_discord_portable.sh
# Download latest official Discord tar.gz (no sudo), extract into a folder in $HOME,
# create a .desktop launcher in ~/.local/share/applications, and optionally pin to GNOME dock.
#
# Usage:
#   ./download_discord_portable.sh            # uses defaults
#   ./download_discord_portable.sh -d ~/apps/discord-copy -n "discord-copy" -p
#
# Flags:
#   -d DIR    Destination directory (default: $HOME/discord-portable)
#   -n NAME   Name/slug used for desktop file (default: discord-portable)
#   -p        Pin to GNOME favorites (adds the desktop file to your favorites)
#   -f        Force overwrite if destination exists
#   -h        Show help

set -euo pipefail

# Configurable defaults
DEST_DIR_DEFAULT="$HOME/discord-portable"
NAME_DEFAULT="discord-portable"
PIN=false
FORCE=false

# Official (stable) tarball endpoint (redirects to the actual file)
DISCORD_TAR_URL="https://discord.com/api/download/stable?platform=linux&format=tar.gz"

usage() {
  cat <<EOF
Usage: $0 [-d DEST_DIR] [-n NAME] [-p] [-f] [-h]
  -d DEST_DIR   where to extract (default: $DEST_DIR_DEFAULT)
  -n NAME       slug/name for desktop file (default: $NAME_DEFAULT)
  -p            pin to GNOME favorites (requires gsettings)
  -f            force overwrite existing DEST_DIR
  -h            show this help
EOF
}

# parse args
DEST_DIR="$DEST_DIR_DEFAULT"
NAME="$NAME_DEFAULT"

while getopts "d:n:pfh" opt; do
  case "$opt" in
    d) DEST_DIR="$OPTARG" ;;
    n) NAME="$OPTARG" ;;
    p) PIN=true ;;
    f) FORCE=true ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

echo "Destination: $DEST_DIR"
echo "Name: $NAME"
echo "Pin to favorites: $PIN"
echo "Force: $FORCE"
echo

# Prepare
TMPDIR="$(mktemp -d)"
TARPATH="$TMPDIR/discord.tar.gz"

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

# Download latest stable tar.gz (follows redirects)
echo "Downloading latest Discord tarball..."
if command -v curl >/dev/null 2>&1; then
  curl -L --fail --progress-bar -o "$TARPATH" "$DISCORD_TAR_URL"
elif command -v wget >/dev/null 2>&1; then
  wget -q --show-progress -O "$TARPATH" "$DISCORD_TAR_URL"
else
  echo "Error: neither curl nor wget found." >&2
  exit 1
fi

if [[ ! -s "$TARPATH" ]]; then
  echo "Download failed or file empty." >&2
  exit 1
fi
echo "Downloaded to $TARPATH"

# Handle destination
if [[ -e "$DEST_DIR" && "$FORCE" != "true" ]]; then
  echo "Error: destination '$DEST_DIR' exists. Use -f to overwrite." >&2
  exit 1
fi

# Remove existing if force
if [[ -e "$DEST_DIR" && "$FORCE" == "true" ]]; then
  echo "Removing existing $DEST_DIR"
  rm -rf "$DEST_DIR"
fi

mkdir -p "$DEST_DIR"

echo "Extracting tarball into $DEST_DIR..."
tar -xzf "$TARPATH" -C "$DEST_DIR" --strip-components=0

# The tarball generally contains a directory named "Discord" or similar.
# Find the main Electron binary (commonly named "Discord")
# Try to find executable file within extracted folder.
EXEC_PATH=""
# search for an executable named "Discord" or "discord"
while IFS= read -r -d '' file; do
  # Use -x to check executable bit
  if [[ "$(basename "$file")" =~ ^([Dd]iscord)$ ]] && [[ -x "$file" ]]; then
    EXEC_PATH="$file"
    break
  fi
done < <(find "$DEST_DIR" -type f -print0)

if [[ -z "$EXEC_PATH" ]]; then
  # try to find any file with "Discord" in name and make it executable
  cand="$(find "$DEST_DIR" -type f -iname '*discord*' | head -n1 || true)"
  if [[ -n "$cand" ]]; then
    chmod +x "$cand"
    EXEC_PATH="$cand"
  fi
fi

if [[ -z "$EXEC_PATH" ]]; then
  echo "Warning: couldn't locate the Discord executable automatically."
  echo "You can run the app by inspecting $DEST_DIR and running the appropriate binary (usually named 'Discord')."
else
  echo "Detected executable: $EXEC_PATH"
fi

# find icon (png/svg) inside extracted folder
ICON_PATH=""
ICON_CAND="$(find "$DEST_DIR" -type f \( -iname '*.png' -o -iname '*.svg' -o -iname '*.xpm' \) | grep -i discord | head -n1 || true)"
if [[ -n "$ICON_CAND" ]]; then
  ICON_PATH="$ICON_CAND"
fi

# create desktop file in user data
XDG_APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p "$XDG_APPS_DIR"

DESKTOP_FILENAME="${NAME}.desktop"
DESKTOP_PATH="$XDG_APPS_DIR/$DESKTOP_FILENAME"

echo "Creating desktop file at $DESKTOP_PATH"

# Build Exec and Icon absolute paths (Exec uses quoted path)
if [[ -n "$EXEC_PATH" ]]; then
  EXEC_CMD="$EXEC_PATH"
else
  # fallback: run the "Discord" binary in the extracted folder if present
  # Try common locations: $DEST_DIR/Discord/Discord
  if [[ -x "$DEST_DIR/Discord/Discord" ]]; then
    EXEC_CMD="$DEST_DIR/Discord/Discord"
  else
    EXEC_CMD="$DEST_DIR/Discord/Discord"  # best-effort; user may edit later
  fi
fi

cat > "$DESKTOP_PATH" <<EOF
[Desktop Entry]
Name=Discord ($NAME)
Comment=Discord (portable) - $NAME
Exec="$EXEC_CMD" %U
Terminal=false
Type=Application
Categories=Network;Chat;
StartupWMClass=discord
EOF

if [[ -n "$ICON_PATH" ]]; then
  echo "Icon=$ICON_PATH" >> "$DESKTOP_PATH"
fi

chmod 644 "$DESKTOP_PATH"

echo "Desktop file created."

# Optionally pin to GNOME favorites (Ubuntu dock)
if [[ "$PIN" == "true" ]]; then
  if command -v gsettings >/dev/null 2>&1; then
    KEY="org.gnome.shell favorite-apps"
    # read current favorites
    current=$(gsettings get org.gnome.shell favorite-apps || echo "[]")
    # gsettings returns a Python-like array; we will append if not present
    # convert to newline list and check
    if echo "$current" | grep -Fq "'$DESKTOP_FILENAME'"; then
      echo "Already in favorites."
    else
      # create new list: insert at end
      # Use python for safe list editing if available
      if command -v python3 >/dev/null 2>&1; then
        new=$(python3 - <<PY
import gi,sys
s = $current
# ensure it's a list
l = list(s)
if "$DESKTOP_FILENAME" not in l:
    l.append("$DESKTOP_FILENAME")
print(l)
PY
)
        # gsettings expects the list in gsettings string form: "['a','b']"
        gsettings set org.gnome.shell favorite-apps "$new" || {
          echo "Failed to set favorites with gsettings."
        }
        echo "Added $DESKTOP_FILENAME to GNOME favorites."
      else
        # fallback: simple sed (best-effort)
        stripped=$(echo "$current" | sed "s/]$//; s/^\[//")
        if [[ -z "$stripped" ]]; then
          gsettings set org.gnome.shell favorite-apps "['$DESKTOP_FILENAME']" || echo "Failed to set favorites."
        else
          gsettings set org.gnome.shell favorite-apps "[$stripped,'$DESKTOP_FILENAME']" || echo "Failed to update favorites."
        fi
        echo "Attempted to add $DESKTOP_FILENAME to GNOME favorites."
      fi
    fi
  else
    echo "gsettings not found; cannot pin to GNOME favorites automatically."
  fi
fi

echo
echo "Done!"
echo "You can start Discord using the desktop entry (look in your app menu) or run:"
if [[ -n "$EXEC_PATH" ]]; then
  echo "  \"$EXEC_PATH\""
else
  echo "  $DEST_DIR/Discord/Discord   (or inspect $DEST_DIR for the binary)"
fi

# Final notes
echo
echo "Notes:"
echo "- This script does NOT require sudo."
echo "- The tarball from Discord is a portable Electron app; extracting and running the binary works for a single-user installation."
echo "- If the desktop icon does not appear right away, run: update-desktop-database ~/.local/share/applications  (optional) or log out/in."

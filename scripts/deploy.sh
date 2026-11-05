#!/usr/bin/env bash
# Installs ReShade into the ReSkate folder and copies the shader and companion plugin there.
# Safe to run again after every change. Your tuned values in ReShadePreset.ini are never overwritten.
#
#   scripts/deploy.sh               install or update
#   scripts/deploy.sh --uninstall   remove what this script installed, keep ReShade.ini and the preset
#
# SKATE_DIR is the ReSkate folder, as a WSL path. HVX_PROXY is optional, and is tried if the ReShade site
# won't load directly. Set them in the environment, or in a .deploy.env file at the repo root (not committed).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$ROOT/.deploy.env" ]]; then source "$ROOT/.deploy.env"; fi

GAME_DIR="${SKATE_DIR:-}"
PROXY="${HVX_PROXY:-}"
PLUGIN_NAME="Local-Skate_HVX_Sim"

# Pinned, so an update to ReShade is a deliberate change here. ReShade is signed with its own
# self-issued certificate, which Windows doesn't trust, so these hashes are what gets checked.
RESHADE_VERSION="6.8.0"
RESHADE_SETUP_SHA256="207aea16205fbf952bc8fe1879966672454cf04002e7ad34237c7990a5b3c0b4"
RESHADE_DLL_SHA256="b2945c29e7095491a901746b400e58db9b1592ab092bacf2a888ce37f02d08da"

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/skate-hvx-sim"
SHADER_DIR="$GAME_DIR/reshade-shaders/Shaders"
PLUGIN_DIR="$GAME_DIR/Mods/$PLUGIN_NAME"
DXGI="$GAME_DIR/dxgi.dll"

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
sha() { sha256sum "$1" | cut -d' ' -f1; }

game_running() { tasklist.exe /FI "IMAGENAME eq Skate.exe" /NH 2>/dev/null | grep -qi 'skate\.exe'; }

fetch_reshade() {
    local setup="$CACHE/ReShade_Setup_$RESHADE_VERSION.exe"
    local url="https://reshade.me/downloads/ReShade_Setup_$RESHADE_VERSION.exe"
    mkdir -p "$CACHE"
    if [[ ! -f "$setup" ]] || [[ "$(sha "$setup")" != "$RESHADE_SETUP_SHA256" ]]; then
        say "Downloading ReShade $RESHADE_VERSION"
        curl -fsSL --max-time 120 -o "$setup" "$url" ||
            { [[ -n "$PROXY" ]] && curl -fsSL --max-time 120 -x "$PROXY" -o "$setup" "$url"; } ||
            die "couldn't download $url"
    fi
    [[ "$(sha "$setup")" == "$RESHADE_SETUP_SHA256" ]] || die "ReShade installer hash doesn't match the pinned one"
    7z e -y -o"$CACHE" "$setup" ReShade64.dll >/dev/null
    [[ "$(sha "$CACHE/ReShade64.dll")" == "$RESHADE_DLL_SHA256" ]] || die "ReShade64.dll hash doesn't match the pinned one"
}

install_reshade() {
    if [[ -f "$DXGI" ]]; then
        [[ "$(sha "$DXGI")" == "$RESHADE_DLL_SHA256" ]] ||
            die "$DXGI already exists and isn't the pinned ReShade. Remove it yourself if it's safe to replace."
        say "ReShade $RESHADE_VERSION already installed"
        return
    fi
    game_running && die "close the game first, ReShade can't be installed while it runs"
    fetch_reshade
    cp "$CACHE/ReShade64.dll" "$DXGI"
    say "Installed ReShade $RESHADE_VERSION as dxgi.dll"
}

# Written once. After that the files belong to ReShade and to whoever is tuning.
write_configs() {
    if [[ ! -f "$GAME_DIR/ReShade.ini" ]]; then
        printf '%s\r\n' '[GENERAL]' \
            'EffectSearchPaths=.\reshade-shaders\Shaders\**' \
            'TextureSearchPaths=.\reshade-shaders\Textures\**' \
            'PresetPath=.\ReShadePreset.ini' \
            '' \
            '[OVERLAY]' \
            'TutorialProgress=4' > "$GAME_DIR/ReShade.ini"
        say "Wrote ReShade.ini"
    fi
    if [[ ! -f "$GAME_DIR/ReShadePreset.ini" ]]; then
        printf '%s\r\n' 'Techniques=SkateHvxSim@SkateHvxSim.fx' \
            'TechniqueSorting=SkateHvxSim@SkateHvxSim.fx' > "$GAME_DIR/ReShadePreset.ini"
        say "Wrote ReShadePreset.ini with the effect switched on"
    fi
}

install_shader() {
    mkdir -p "$SHADER_DIR"
    rm -rf "$SHADER_DIR/SkateHvxSim"
    cp -r "$ROOT/shader/Shaders/." "$SHADER_DIR/"
    say "Copied the shader to reshade-shaders/Shaders"
}

install_plugin() {
    rm -rf "$PLUGIN_DIR"
    mkdir -p "$PLUGIN_DIR"
    cp -r "$ROOT/package/." "$PLUGIN_DIR/"
    say "Copied the plugin to Mods/$PLUGIN_NAME"
}

uninstall() {
    game_running && die "close the game first"
    if [[ -f "$DXGI" ]]; then
        [[ "$(sha "$DXGI")" == "$RESHADE_DLL_SHA256" ]] || die "$DXGI isn't the pinned ReShade, leaving it alone"
        rm "$DXGI"
    fi
    rm -rf "$SHADER_DIR/SkateHvxSim" "$SHADER_DIR/SkateHvxSim.fx" "$PLUGIN_DIR"
    say "Removed. ReShade.ini and ReShadePreset.ini were kept."
}

[[ -n "$GAME_DIR" ]] || die "set SKATE_DIR to the ReSkate folder, for example /mnt/c/Games/ReSkate"
[[ -f "$GAME_DIR/Skate.exe" ]] || die "no Skate.exe in $GAME_DIR, check SKATE_DIR"

case "${1:-}" in
    --uninstall) uninstall ;;
    "")
        install_reshade
        write_configs
        install_shader
        install_plugin
        game_running && say "The game is running: press Reload in the ReShade overlay to pick up the shader."
        say "Done. Start it with ReSkateLauncher.exe, and open ReShade with Home."
        ;;
    *) die "unknown option $1" ;;
esac

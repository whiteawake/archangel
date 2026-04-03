#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────
# yayfix.sh — Post-SteamOS-update yay rebuilder
# ─────────────────────────────────────────────

AUR_PACKAGES_FILE="$HOME/aur-packages.txt"
ARCH_MIRROR="https://mirror.aarnet.edu.au/pub/archlinux"

# ── Helpers ───────────────────────────────────

info()    { echo "[INFO]  $*"; }
success() { echo "[OK]    $*"; }
warn()    { echo "[WARN]  $*"; }
die()     { echo "[ERROR] $*"; exit 1; }

# ── Save AUR packages (run before update) ─────

if [[ "${1:-}" == "--save" ]]; then
    if command -v yay &>/dev/null; then
        yay -Qm | awk '{print $1}' > "$AUR_PACKAGES_FILE"
        success "Saved $(wc -l < "$AUR_PACKAGES_FILE") AUR packages to $AUR_PACKAGES_FILE"
    else
        die "yay is not installed, nothing to save."
    fi
    exit 0
fi

# ── Step 1: Disable read-only filesystem ──────

info "Disabling read-only filesystem..."
sudo steamos-readonly disable

# ── Step 2: Replace mirrorlist ────────────────

info "Writing standard Arch mirrorlist..."
sudo tee /etc/pacman.d/mirrorlist > /dev/null <<EOF
Server = ${ARCH_MIRROR}/\$repo/os/\$arch
EOF
success "Mirrorlist written."

# ── Step 3: Replace pacman.conf entirely ──────
# Valve's versioned repos (jupiter-3.7, holo-3.7 etc.) don't exist on
# standard Arch mirrors and cause sync failures. We replace the whole
# config with a clean standard Arch one for the duration of this script.

info "Writing standard Arch pacman.conf..."
sudo tee /etc/pacman.conf > /dev/null <<'EOF'
#
# /etc/pacman.conf — replaced by yayfix.sh for build purposes
#

[options]
DBPath      = /var/lib/pacman/
CacheDir    = /var/cache/pacman/pkg/
LogFile     = /var/log/pacman.log
GPGDir      = /etc/pacman.d/gnupg/
HookDir     = /etc/pacman.d/hooks/
HoldPkg     = pacman glibc
Architecture = auto
Color
CheckSpace
ParallelDownloads = 10
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
success "pacman.conf written."

# ── Step 4: Initialise keyring and sync ───────

info "Initialising pacman keyring..."
sudo pacman-key --init
sudo pacman-key --populate archlinux

info "Syncing package databases..."
sudo pacman -Syy

# ── Step 5: Install build dependencies ────────

info "Installing build dependencies..."
sudo pacman -S --needed --noconfirm base-devel gcc go glibc git

# ── Step 6: Remove any broken yay install ─────

for pkg in yay yay-bin; do
    if pacman -Q "$pkg" &>/dev/null; then
        info "Removing existing $pkg installation..."
        sudo pacman -Rns --noconfirm "$pkg" 2>/dev/null || true
    fi
done

# ── Step 7: Build yay from source ────────────

info "Building yay from source..."
rm -rf /tmp/yay
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si --noconfirm
cd ~
rm -rf /tmp/yay

# Verify correct libalpm linkage
info "Verifying libalpm linkage..."
ldd "$(which yay)" | grep alpm
success "yay installed: $(yay --version)"

# ── Step 8: Reinstall saved AUR packages ──────

if [ -f "$AUR_PACKAGES_FILE" ]; then
    PACKAGE_COUNT=$(wc -l < "$AUR_PACKAGES_FILE")
    PACKAGES=$(cat "$AUR_PACKAGES_FILE" | tr '\n' ' ')
    info "Reinstalling $PACKAGE_COUNT saved AUR packages..."
    # shellcheck disable=SC2086
    yay -S --needed --noconfirm $PACKAGES
    success "AUR packages reinstalled."
else
    warn "No saved AUR package list found at $AUR_PACKAGES_FILE"
    warn "Run '$0 --save' before your next SteamOS update to save your package list."
fi

# ── Step 9: Re-enable read-only filesystem ────

info "Re-enabling read-only filesystem..."
sudo steamos-readonly enable

success "All done!"

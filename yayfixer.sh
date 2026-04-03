#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────
# yayfix.sh — Post-SteamOS-update yay rebuilder
# ─────────────────────────────────────────────

AUR_PACKAGES_FILE="$HOME/aur-packages.txt"
ARCH_MIRROR="https://mirror.aarnet.edu.au/pub/archlinux/\$repo/os/\$arch"

# ── Helpers ───────────────────────────────────

info()    { echo "[INFO]  $*"; }
success() { echo "[OK]    $*"; }
warn()    { echo "[WARN]  $*"; }
die()     { echo "[ERROR] $*"; exit 1; }

# ── Step 1: Save AUR packages (run before update) ─

if [[ "${1:-}" == "--save" ]]; then
    if command -v yay &>/dev/null; then
        yay -Qm | awk '{print $1}' > "$AUR_PACKAGES_FILE"
        success "Saved $(wc -l < "$AUR_PACKAGES_FILE") AUR packages to $AUR_PACKAGES_FILE"
    else
        die "yay is not installed, nothing to save."
    fi
    exit 0
fi

# ── Step 2: Disable read-only filesystem ──────

info "Disabling read-only filesystem..."
sudo steamos-readonly disable

# ── Step 3: Configure pacman with Arch repos ──

info "Configuring Arch Linux mirror..."

# Write mirrorlist if it doesn't already have our mirror
if ! grep -q "aarnet" /etc/pacman.d/mirrorlist 2>/dev/null; then
    echo "Server = $ARCH_MIRROR" | sudo tee /etc/pacman.d/mirrorlist > /dev/null
    success "Mirrorlist updated."
else
    info "AARNet mirror already present, skipping."
fi

# Add [core] and [extra] repos to pacman.conf if not already present
if ! grep -q "^\[core\]" /etc/pacman.conf; then
    info "Adding core and extra repos to pacman.conf..."
    sudo tee -a /etc/pacman.conf > /dev/null <<EOF

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist
EOF
    success "Repos added to pacman.conf."
else
    info "Arch repos already present in pacman.conf, skipping."
fi

# ── Step 4: Sync and install build dependencies ─

info "Syncing package databases..."
sudo pacman -Syy

info "Installing build dependencies..."
sudo pacman -S --needed --noconfirm base-devel gcc go glibc git

# ── Step 5: Remove any broken yay install ─────

if pacman -Q yay &>/dev/null; then
    info "Removing existing yay installation..."
    sudo pacman -Rns --noconfirm yay 2>/dev/null || true
fi
if pacman -Q yay-bin &>/dev/null; then
    info "Removing existing yay-bin installation..."
    sudo pacman -Rns --noconfirm yay-bin 2>/dev/null || true
fi

# ── Step 6: Build yay from source ────────────

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

# ── Step 7: Reinstall saved AUR packages ──────

if [ -f "$AUR_PACKAGES_FILE" ]; then
    PACKAGES=$(cat "$AUR_PACKAGES_FILE" | tr '\n' ' ')
    PACKAGE_COUNT=$(wc -l < "$AUR_PACKAGES_FILE")
    info "Reinstalling $PACKAGE_COUNT saved AUR packages..."
    # shellcheck disable=SC2086
    yay -S --needed --noconfirm $PACKAGES
    success "AUR packages reinstalled."
else
    warn "No saved AUR package list found at $AUR_PACKAGES_FILE."
    warn "Run '$0 --save' before your next SteamOS update to save your package list."
fi

# ── Step 8: Re-enable read-only filesystem ────

info "Re-enabling read-only filesystem..."
sudo steamos-readonly enable

success "All done!"

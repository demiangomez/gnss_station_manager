#!/usr/bin/env bash
#
# Enable passwordless sudo for the current user. The unattended jobs need it:
# internet_check.sh reboots the station from cron, where sudo has no terminal to
# ask for a password on, and update.sh writes /etc/global.config the same way.
# Run by install.sh; safe to run by hand on existing stations and to re-run, it
# exits without changing anything if sudo already works without a password.
#
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this as your normal user, not as root or with sudo." >&2
  exit 1
fi

USER_NAME="$(id -un)"

# Drop any cached sudo credentials so the check below is accurate
sudo -k

# Already passwordless? Nothing to do.
if sudo -n true 2>/dev/null; then
  echo "sudo already works without a password for ${USER_NAME}. Nothing to do."
  exit 0
fi

# sudo skips files in sudoers.d whose names contain a '.', so sanitize
SAFE_NAME="${USER_NAME//./_}"
TARGET="/etc/sudoers.d/010_${SAFE_NAME}-nopasswd"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" > "$TMP"

# Validate syntax before installing so a typo can't break sudo
sudo visudo -cf "$TMP"
sudo install -m 0440 -o root -g root "$TMP" "$TARGET"

# Confirm it took effect
sudo -k
if sudo -n true 2>/dev/null; then
  echo "Done. Passwordless sudo enabled for ${USER_NAME} via ${TARGET}."
else
  echo "Installed ${TARGET}, but sudo still prompts for a password." >&2
  echo "A later rule in /etc/sudoers or /etc/sudoers.d probably overrides it. Check 'sudo -l'." >&2
  exit 1
fi

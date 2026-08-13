#!/usr/bin/env bash
# Setup script for Maven Central and AUR publishing

set -euo pipefail

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  cumulus-dotfiles Publishing Setup                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${BLUE}[1/4] Checking prerequisites...${NC}"
echo

missing_tools=()
for tool in git gpg ssh; do
  if command -v $tool &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} $tool"
  else
    echo -e "  ${RED}✗${NC} $tool (required)"
    missing_tools+=("$tool")
  fi
done

if [ ${#missing_tools[@]} -gt 0 ]; then
  echo
  echo -e "${RED}Error: Missing required tools: ${missing_tools[@]}${NC}"
  exit 1
fi

echo
echo -e "${BLUE}[2/4] Maven Central Setup${NC}"
echo

read -p "Do you want to setup Maven Central publishing? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Follow these steps:"
  echo "  1. Create Sonatype account: https://issues.sonatype.org/"
  echo "  2. Create ticket requesting rights for 'com.github.petrolal'"
  echo "  3. Generate GPG key:"
  echo "     gpg --full-generate-key"
  echo "  4. Upload public key:"
  echo "     gpg --keyserver hkp://keyserver.ubuntu.com --send-keys YOUR_KEY_ID"
  echo "  5. Export private key:"
  echo "     gpg --export-secret-keys --armor YOUR_KEY_ID"
  echo
  read -p "Press Enter after completing these steps..."
  echo
  read -p "Enter your GPG Key ID: " GPG_KEY_ID
  read -p "Enter your Sonatype username: " SONATYPE_USER
  read -sp "Enter your Sonatype password: " SONATYPE_PASS
  echo
  echo
  echo "To add secrets to GitHub:"
  echo "  1. Go to: https://github.com/petrolal/cumulus-dotfiles/settings/secrets/actions"
  echo "  2. Add these secrets:"
  echo "     - SONATYPE_USERNAME: $SONATYPE_USER"
  echo "     - SONATYPE_PASSWORD: (paste your password)"
  echo "     - PGP_SECRET: (output of: gpg --export-secret-keys --armor $GPG_KEY_ID | base64 -w0)"
  echo "     - PGP_PASSPHRASE: (your GPG passphrase)"
fi

echo
echo -e "${BLUE}[3/4] AUR Setup${NC}"
echo

read -p "Do you want to setup AUR publishing? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Follow these steps:"
  echo "  1. Create AUR account: https://aur.archlinux.org/"
  echo "  2. Add SSH public key to your account"
  echo "  3. Generate SSH key (if you don't have one):"
  echo "     ssh-keygen -t ed25519 -C 'aur@archlinux.org'"
  echo
  read -p "Press Enter after setting up AUR account..."
  echo
  read -sp "Enter your email for PKGBUILD: " MAINTAINER_EMAIL
  echo
  echo
  echo "To add secrets to GitHub:"
  echo "  1. Go to: https://github.com/petrolal/cumulus-dotfiles/settings/secrets/actions"
  echo "  2. Add these secrets:"
  echo "     - AUR_SSH_PRIVATE_KEY: (paste your AUR SSH private key)"
  echo "     - MAINTAINER_EMAIL: $MAINTAINER_EMAIL"
  echo
  echo "To view your SSH key:"
  echo "  cat ~/.ssh/id_ed25519"
fi

echo
echo -e "${BLUE}[4/4] Verifying Configuration${NC}"
echo

echo "Checking git configuration..."
if git config user.name &> /dev/null; then
  echo -e "  ${GREEN}✓${NC} Git user.name: $(git config user.name)"
else
  echo -e "  ${RED}✗${NC} Git user.name not set"
  read -p "Enter your git name: " GIT_NAME
  git config --global user.name "$GIT_NAME"
fi

if git config user.email &> /dev/null; then
  echo -e "  ${GREEN}✓${NC} Git user.email: $(git config user.email)"
else
  echo -e "  ${RED}✗${NC} Git user.email not set"
  read -p "Enter your git email: " GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
fi

echo
echo -e "${GREEN}✓ Setup complete!${NC}"
echo
echo "Next steps:"
echo "  1. Add GitHub secrets via the Actions settings page"
echo "  2. Update version in build.sbt"
echo "  3. Create and push a version tag:"
echo "     git tag -a v0.1.0 -m 'Release version 0.1.0'"
echo "     git push origin --tags"
echo "  4. Watch the CI/CD pipeline: https://github.com/petrolal/cumulus-dotfiles/actions"
echo
echo "For detailed instructions, see: PUBLISHING.md"

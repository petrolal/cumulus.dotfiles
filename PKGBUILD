# Maintainer: petrolal <petrolalucas@gmail.com>
pkgname=cumulus-dotfiles
pkgver=0.1.0
pkgrel=1
pkgdesc="Sway dotfiles installer with Scala 3 + GraalVM native image"
arch=('x86_64')
url="https://github.com/petrolal/cumulus.dotfiles"
license=('MIT')
depends=(
  'sway'
  'waybar'
  'kitty'
  'wofi'
  'swaylock'
  'swayidle'
  'grim'
  'slurp'
  'brightnessctl'
  'libpulse'
  'chromium'
  'docker'
  'terraform'
  'kubectl'
  'helm'
  'neovim'
  'ttf-jetbrains-mono-nerd'
  'sway-notification-center'
  'mako'
  'zsh'
)
makedepends=(
  'jdk-openjdk'
  'sbt'
  'gcc'
  'git'
)
optdepends=(
  'alacritty: for terminal screenshot region selection'
  'termite: alternative terminal for screenshot'
)
source=("git+https://github.com/petrolal/${pkgname}.git")
sha256sums=('SKIP')

build() {
  cd "${pkgname}"
  sbt nativeImage
}

package() {
  cd "${pkgname}"

  # Install main binary
  install -Dm755 "target/native-image/cumulus" "${pkgdir}/usr/local/bin/cumulus"

  # Create subcommand symlinks
  local subcommands=(
    theme runtime-refresh os-colorscheme lock idle screenshot autotiling
    healthcheck backup restore update sdd install deploy install-deps
    install-brew install-homebrew install-gh install-github-cli install-coursier install-cs
    install-fonts install-apps install-browser install-devops install-zsh
    install-sdkman install-nvim install-nvim-deps install-neovim install-tools install-all
    theme-picker whichkey
  )

  for cmd in "${subcommands[@]}"; do
    ln -s "/usr/local/bin/cumulus" "${pkgdir}/usr/local/bin/cumulus-${cmd}"
  done

  # Install dotfiles config directory
  install -dm755 "${pkgdir}/opt/cumulus"
  cp -r config zsh bootstrap.sh "${pkgdir}/opt/cumulus/"

  # Install systemd user service for idle daemon (optional)
  install -dm755 "${pkgdir}/usr/lib/systemd/user"
  # You can add a systemd service file here if needed

  # Install license
  install -Dm644 LICENSE "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}

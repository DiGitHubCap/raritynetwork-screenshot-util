# Maintainer: <xris_pop@yahoo.ca>
pkgname=raritynetwork-screenshot-util
pkgver=3.0
pkgrel=1
pkgdesc="This is a command-line tool that takes a screenshot using either PNG, APNG or JPEG and uploads it to Utils.Rarity.Network"
arch=('any')
url="https://gitgud.io/rarity/RarityNetwork-Screenshot-Util"
license=('custom:The Unlicense')
depends=('maim' 'slop' 'curl' 'xsel' 'ffmpeg' 'mozjpeg-opt' 'zopflipng-git')
optdepends=('torsocks: upload images through Tor')
options=('!strip')
source=("screenshot"
        "LICENSE")
sha256sums=('6ee9340931e43104d1d773f8c458ab398310e74a647890a5e525f30fe90876c5'
            '88d9b4eb60579c191ec391ca04c16130572d7eedc4a86daa58bf28c6e14c9bcd')

package() {
  install -Dm755 screenshot "$pkgdir"/usr/bin/screenshot
  install -Dm644 LICENSE "$pkgdir"/usr/share/licenses/$pkgname/LICENSE
}

# vim:set ts=2 sw=2 et:

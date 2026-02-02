# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic git-r3 autotools

DESCRIPTION="Library for cross-platform C split string functions"
HOMEPAGE="https://github.com/libyal/libcsplit"
EGIT_REPO_URI="https://github.com/libyal/${PN}.git"

# For dated releases (e.g., 20240101), use the date as git tag
# Hard link libcsplit-9999.ebuild to libcsplit-YYYYMMDD.ebuild for releases
if [[ ${PV} == 9999 ]]; then
	KEYWORDS=""
else
	EGIT_COMMIT="${PV}"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi

LICENSE="LGPL-3+"
SLOT="0"
IUSE="debug nls static-libs"

DEPEND="
	dev-libs/libcerror[static-libs?]
"
RDEPEND="
	!static-libs? ( ${DEPEND} )
"
BDEPEND="
	dev-build/autoconf
	dev-build/automake
	dev-build/libtool
	sys-devel/gettext
"

PATCHES=(
	"${FILESDIR}/0001-Remove-embedded-dependencies-for-system-library-buil.patch"
)

src_prepare() {
	default
	./autogen.sh || die "autogen.sh failed"
	eautoreconf
}

src_configure() {
	# Enable debug/verbose output if requested
	if use debug; then
		append-cppflags -DHAVE_DEBUG_OUTPUT -DHAVE_VERBOSE_OUTPUT
	fi

	local myeconfargs=(
		$(use_enable nls)
		$(use_enable static-libs static)
		--enable-shared
	)
	econf "${myeconfargs[@]}"
}

src_install() {
	default
	if ! use static-libs; then
		find "${ED}" -name '*.la' -delete || die
	fi
}

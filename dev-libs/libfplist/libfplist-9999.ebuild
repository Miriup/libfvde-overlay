# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic git-r3 autotools

DESCRIPTION="Library for plist data types"
HOMEPAGE="https://github.com/libyal/libfplist"
EGIT_REPO_URI="https://github.com/libyal/${PN}.git"

LICENSE="LGPL-3+"
SLOT="0"
KEYWORDS=""
IUSE="debug nls static-libs"

DEPEND="
	dev-libs/libcerror[static-libs?]
	dev-libs/libcthreads[static-libs?]
	dev-libs/libcdata[static-libs?]
	dev-libs/libcnotify[static-libs?]
	dev-libs/libuna[static-libs?]
	dev-libs/libfguid[static-libs?]
	dev-libs/libfvalue[static-libs?]
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

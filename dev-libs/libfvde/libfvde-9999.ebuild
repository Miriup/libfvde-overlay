# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )

inherit git-r3 autotools python-single-r1

DESCRIPTION="Library and tools to access FileVault Drive Encryption (FVDE) encrypted volumes"
HOMEPAGE="https://github.com/libyal/libfvde"
EGIT_REPO_URI="https://github.com/libyal/${PN}.git"

# For dated releases (e.g., 20240101), use the date as git tag
# Hard link libfvde-9999.ebuild to libfvde-YYYYMMDD.ebuild for releases
if [[ ${PV} == 9999 ]]; then
	KEYWORDS=""
else
	EGIT_COMMIT="${PV}"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi

LICENSE="LGPL-3+"
SLOT="0"
IUSE="debug fuse nls python static-libs tools +keyring"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

DEPEND="
	dev-libs/libcerror[static-libs?]
	dev-libs/libcthreads[static-libs?]
	dev-libs/libcdata[static-libs?]
	dev-libs/libclocale[static-libs?]
	dev-libs/libcnotify[static-libs?]
	dev-libs/libcsplit[static-libs?]
	dev-libs/libuna[static-libs?]
	dev-libs/libcfile[static-libs?]
	dev-libs/libcpath[static-libs?]
	dev-libs/libbfio[static-libs?]
	dev-libs/libfcache[static-libs?]
	dev-libs/libfdata[static-libs?]
	dev-libs/libfguid[static-libs?]
	dev-libs/libfplist[static-libs?]
	dev-libs/libfvalue[static-libs?]
	dev-libs/libhmac[static-libs?]
	dev-libs/libcaes[static-libs?]
	sys-libs/zlib
	fuse? ( sys-fs/fuse:0 )
	keyring? ( sys-apps/keyutils )
	python? ( ${PYTHON_DEPS} )
"
RDEPEND="
	!static-libs? ( ${DEPEND} )
	static-libs? (
		dev-libs/libcerror[static-libs]
		dev-libs/libcthreads[static-libs]
		dev-libs/libcdata[static-libs]
		dev-libs/libclocale[static-libs]
		dev-libs/libcnotify[static-libs]
		dev-libs/libcsplit[static-libs]
		dev-libs/libuna[static-libs]
		dev-libs/libcfile[static-libs]
		dev-libs/libcpath[static-libs]
		dev-libs/libbfio[static-libs]
		dev-libs/libfcache[static-libs]
		dev-libs/libfdata[static-libs]
		dev-libs/libfguid[static-libs]
		dev-libs/libfplist[static-libs]
		dev-libs/libfvalue[static-libs]
		dev-libs/libhmac[static-libs]
		dev-libs/libcaes[static-libs]
	)
"
BDEPEND="
	dev-build/autoconf
	dev-build/automake
	dev-build/libtool
	sys-devel/gettext
	python? ( dev-lang/swig )
"

PATCHES=(
	"${FILESDIR}/0001-Remove-embedded-dependencies-for-system-library-buil.patch"
)

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	default
	./autogen.sh || die "autogen.sh failed"
	eautoreconf
}

src_configure() {
	local myeconfargs=(
		$(use_enable debug debug-output)
		$(use_enable debug verbose-output)
		$(use_enable nls)
		$(use_enable static-libs static)
		$(use_enable python)
		$(use_with fuse libfuse)
		$(use_with keyring)
		--enable-shared
	)

	use python && myeconfargs+=(
		--enable-python
		--with-pyprefix
	)

	econf "${myeconfargs[@]}"
}

src_install() {
	default

	if ! use static-libs; then
		find "${ED}" -name '*.la' -delete || die
	fi

	if ! use tools; then
		rm -rf "${ED}"/usr/bin/fvde* || die
		rm -rf "${ED}"/usr/share/man/man1/fvde* || die
	fi
}

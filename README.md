# LibFVDE Overlay for Gentoo

A Gentoo portage overlay providing ebuilds for libfvde and all its supporting libraries from the libyal project.

## Documentation

- **[Design Decisions](documentation/DESIGN_DECISIONS.md)** - Major architectural and implementation decisions
- **[Python Bindings](documentation/PYTHON_BINDINGS.md)** - Details on Python support and rationale
- **[Build Order](BUILD_ORDER.md)** - Dependency order and build instructions

## Overview

This overlay provides 18 packages:
- **17 supporting libraries** from https://github.com/libyal (error handling, data structures, I/O, crypto, etc.)
- **1 main library**: libfvde for accessing FileVault Drive Encryption (FVDE/FileVault2) encrypted volumes

All packages are live (-9999) ebuilds that fetch from GitHub using git-r3.eclass.

## Installation

1. The overlay is already configured in `/etc/portage/repos.conf/libfvde-overlay.conf`

2. Install packages in dependency order (see BUILD_ORDER.md) or let portage handle it:

```bash
# Install everything
sudo emerge -av dev-libs/libfvde::libfvde-overlay

# Or install specific libraries
sudo emerge -av dev-libs/libcerror::libfvde-overlay
```

## Features

### Shared vs Static Libraries

By default, all libraries build as shared libraries (`.so` files).

To build as static libraries instead:
```bash
echo "dev-libs/libcerror static-libs" >> /etc/portage/package.use/libfvde
# Repeat for other libraries as needed
```

When `static-libs` is enabled:
- Libraries become build-time only dependencies (not runtime)
- Static archives (`.a`) are installed
- Libtool archives (`.la`) are preserved

### Main Library (libfvde) USE Flags

- `fuse` - Build FUSE filesystem support for mounting FVDE volumes
- `python` - Build Python bindings (pyfvde)
- `tools` - Install fvdetools command-line utilities (default: enabled)
- `keyring` - Linux kernel keyring support for key management (default: enabled)
- `nls` - Native language support
- `static-libs` - Build static library

## Technical Details

### Build System

Each library:
1. Fetches source from GitHub using git-r3.eclass
2. Applies a patch to remove embedded library directories
3. Runs autogen.sh and eautoreconf
4. Configures with system library dependencies
5. Builds and installs shared libraries (or static with USE flag)

### Patches

All libraries (except libcerror which has no dependencies) include a patch in `files/`:
- `0001-Remove-embedded-dependencies-for-system-library-buil.patch`

These patches modify `Makefile.am` and `configure.ac` to:
- Remove embedded library subdirectories from SUBDIRS
- Remove AC_CONFIG_FILES for embedded libraries
- Update build targets to not recurse into embedded library directories

This allows each library to be built standalone using system-installed dependencies instead of the embedded copies that libyal projects typically use.

## Package List

### Tier 1: Base Libraries
- libcerror - Error handling
- libclocale - Locale functions
- libcnotify - Notification functions
- libcsplit - String splitting
- libfguid - GUID/UUID handling
- libhmac - HMAC functions
- libcaes - AES encryption

### Tier 2-5: Dependent Libraries
- libcthreads - Threading (→ libcerror)
- libuna - Unicode/ASCII conversions (→ libcerror)
- libcdata - Generic data structures (→ libcerror, libcthreads)
- libcfile - File I/O (→ libcerror, libclocale, libcnotify, libuna)
- libcpath - Path handling (→ libcerror, libclocale, libcsplit, libcnotify, libuna)
- libfcache - File cache (→ libcerror, libcdata, libcthreads)
- libbfio - Basic file I/O abstraction (→ libcerror, libcdata, libcfile, libcpath, libcthreads, libuna)
- libfvalue - File value types (→ libcerror, libcdata, libcnotify, libuna)
- libfplist - Property list handling (→ libcerror, libfguid, libcdata, libcnotify)
- libfdata - File data types (→ libcerror, libcdata, libcnotify, libcthreads, libfcache)

### Main Library
- libfvde - FileVault Drive Encryption library (→ all 17 libraries above + zlib)

## Development

### Regenerating Patches

If you need to regenerate patches for a library:

```bash
cd /tmp
git clone https://github.com/libyal/LIBNAME.git LIBNAME-patch
cd LIBNAME-patch
# Edit Makefile.am and configure.ac to remove embedded dependencies
git add Makefile.am configure.ac
git commit -m "Remove embedded dependencies for system library build"
git format-patch -1 -o /var/db/repos/libfvde-overlay/dev-libs/LIBNAME/files/
```

### Updating Manifests

After modifying an ebuild or patch:

```bash
cd /var/db/repos/libfvde-overlay/dev-libs/LIBNAME
ebuild LIBNAME-9999.ebuild manifest
```

## References

- libfvde: https://github.com/libyal/libfvde
- libyal project: https://github.com/libyal
- Gentoo git-r3.eclass: https://devmanual.gentoo.org/eclass-reference/git-r3.eclass/

## License

Ebuilds and patches: GPL-2 (per Gentoo policy)
Upstream libraries: LGPL-3+ (see individual project repositories)

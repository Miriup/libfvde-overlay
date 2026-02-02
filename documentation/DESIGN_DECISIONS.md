# Design Decisions

This document records major design decisions made during the creation of this overlay.

## 1. Python Bindings

**Decision:** Only the main library (libfvde) includes Python binding support. The 17 supporting libraries do NOT include Python bindings.

**Rationale:** See [PYTHON_BINDINGS.md](PYTHON_BINDINGS.md) for detailed rationale.

**Impact:**
- Simpler ebuilds and maintenance
- Reduced build complexity
- Python access to main library functionality still available

**Future:** Can be revisited if specific use cases require Python access to individual supporting libraries.

## 2. Tools/Utilities Removed from Some Libraries

**Decision:** Tools/utilities that have complex dependencies were removed from some library builds (libuna, libhmac).

**Rationale:**
- Some tools require additional dependencies not available in the overlay (e.g., libcdatetime)
- Tools are primarily for testing/debugging, not production use
- Library functionality is preserved
- Reduces dependency complexity

**Affected Libraries:**
- `libuna` - unatools removed (requires libcdatetime, libclocale, libcnotify, libcfile)
- `libhmac` - hmactools removed (requires multiple additional libraries)

**Impact:**
- Cannot use command-line tools from these libraries
- Library APIs fully functional
- Reduced build dependencies

**Workaround:** If tools are needed, they can be built from the upstream repositories directly (not as system libraries).

## 3. Live Ebuilds Only

**Decision:** All ebuilds are live (-9999) ebuilds that fetch from git HEAD.

**Rationale:**
- libyal libraries are actively developed
- No stable releases/tarballs published regularly
- Easier to track upstream changes
- Matches upstream development model

**Impact:**
- Builds always use latest git HEAD
- No version pinning
- Requires network access during build
- May occasionally break if upstream introduces incompatibilities

**Future:** Could add tagged version ebuilds (e.g., libcerror-20240101.ebuild) if stable versions are needed.

## 4. Patch-Based Build System Modifications

**Decision:** All build system modifications are done via git-format-patch generated patches, not inline sed commands.

**Rationale:**
- Requested by overlay maintainer
- Patches are version-controlled and reviewable
- Clear documentation of changes
- Can be upstreamed if desired
- Easier to debug when patches fail

**Process:**
1. Clone library from GitHub
2. Make modifications to Makefile.am and configure.ac
3. Commit changes
4. Generate patch with `git format-patch -1`
5. Place in ebuild's files/ directory

**Impact:**
- Patches must be regenerated if upstream Makefile.am structure changes significantly
- Clear audit trail of modifications

## 5. Static Library Support via USE Flag

**Decision:** All libraries support both shared (default) and static builds via the `static-libs` USE flag.

**Rationale:**
- Gentoo convention (standard USE flag name)
- Flexibility for users who need static linking
- When static-libs is enabled, dependencies become DEPEND only (not RDEPEND)

**Implementation:**
```bash
DEPEND="
    dev-libs/libcerror[static-libs?]
"
RDEPEND="
    !static-libs? ( ${DEPEND} )
"
```

**Impact:**
- Users can choose build type
- Static builds don't install runtime dependencies
- Default shared library behavior matches upstream

## 6. System Libraries Over Embedded

**Decision:** Use system-installed libraries instead of embedded copies in each package.

**Rationale:**
- Reduces disk space (single copy of each library)
- Easier security updates (update once, affects all)
- Standard Gentoo practice
- Better dependency tracking

**Implementation:**
- Patches remove embedded library directories from SUBDIRS
- Ebuilds declare explicit dependencies
- Configure detects system libraries via pkg-config

**Impact:**
- Must build in dependency order
- All libraries must be installed to build libfvde
- Cannot use library-specific embedded versions

## 7. No Keywords (Live Ebuilds)

**Decision:** All ebuilds have `KEYWORDS=""` (empty).

**Rationale:**
- Live ebuilds by convention don't have keywords
- Forces explicit acceptance via package.accept_keywords
- Makes it clear these are unstable/live versions

**User Action Required:**
```bash
# Accept all overlay packages
echo "dev-libs/*::libfvde-overlay **" >> /etc/portage/package.accept_keywords/libfvde
```

## 8. Unified Overlay Structure

**Decision:** All packages in a single overlay under dev-libs/.

**Rationale:**
- All packages are libraries
- Related functionality (libfvde ecosystem)
- Easier to manage as a unit
- Clear namespace (::libfvde-overlay)

**Structure:**
```
/var/db/repos/libfvde-overlay/
├── metadata/
│   └── layout.conf
├── profiles/
│   └── repo_name
├── dev-libs/
│   ├── libcerror/
│   ├── libcthreads/
│   ├── ... (17 supporting libraries)
│   └── libfvde/
├── documentation/
└── README.md
```

## 9. Autotools Regeneration Required

**Decision:** All ebuilds run autogen.sh and eautoreconf in src_prepare.

**Rationale:**
- Patches modify Makefile.am and configure.ac
- Must regenerate configure script and Makefile.in
- Ensures clean build with modified build system

**Impact:**
- Requires autotools in BDEPEND (autoconf, automake, libtool)
- Build time slightly increased
- More robust than patching generated files

## 10. Minimal USE Flags

**Decision:** Keep USE flags minimal - only `nls` and `static-libs` for most libraries.

**Rationale:**
- Supporting libraries are internal dependencies
- Don't need extensive configurability
- Main library (libfvde) has more USE flags: fuse, python, tools, keyring
- Reduces complexity

**Exception:** libfvde has additional USE flags for optional features:
- `fuse` - FUSE filesystem support
- `python` - Python bindings
- `tools` - Command-line utilities (enabled by default)
- `keyring` - Linux kernel keyring support (enabled by default)

## Future Considerations

These decisions can be revisited if:
1. Upstream changes significantly
2. User needs change
3. Gentoo policies change
4. Maintainer priorities change

When revisiting, update this document and relevant specific documentation (e.g., PYTHON_BINDINGS.md).

## Last Updated

2026-02-02 - Initial documentation of design decisions

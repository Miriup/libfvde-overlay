# Python Bindings

## Current Status

### Main Library (libfvde)
✅ **Python bindings ARE supported** via the `python` USE flag.

To enable:
```bash
echo "dev-libs/libfvde python" >> /etc/portage/package.use/libfvde
emerge dev-libs/libfvde::libfvde-overlay
```

This will build and install the `pyfvde` Python module, allowing:
```python
import pyfvde
# Use libfvde functionality from Python
```

### Supporting Libraries
❌ **Python bindings are NOT currently supported** for the 17 supporting libraries:
- libcerror, libcthreads, libcdata, libclocale, libcnotify, libcsplit
- libuna, libcfile, libcpath, libbfio, libfcache, libfdata
- libfguid, libfplist, libfvalue, libhmac, libcaes

## Rationale

The decision to exclude Python bindings from supporting libraries was made for the following reasons:

### 1. Practical Usage
- Most users only need Python access to the main library (libfvde)
- The supporting libraries are internal dependencies
- Direct Python access to supporting libraries is rarely needed
- The main library's Python bindings provide all necessary functionality

### 2. Complexity Management
Each Python binding would require:
- SWIG as a build dependency
- Python eclass integration (`inherit python-single-r1`)
- `PYTHON_COMPAT` declarations
- Proper Python module installation paths
- Testing across multiple Python versions
- Additional BDEPEND on `dev-lang/swig`

Multiplied by 17 libraries, this significantly increases overlay complexity.

### 3. Build System Modifications
The patches that remove embedded dependencies also remove Python binding directories:
- `pyhmac/` removed from libhmac
- `pycaes/` removed from libcaes
- Similar for other libraries

This was necessary because the Python bindings often have additional dependencies that would complicate the standalone library builds.

### 4. Dependency Chain Issues
Some Python bindings have cross-dependencies that don't exist in the C libraries:
- Would require coordinating Python module dependencies
- Could create circular dependency issues
- Adds complexity to the dependency resolution

### 5. Resource Efficiency
- Installing 17+ separate Python modules for internal libraries wastes disk space
- Each module would need separate import namespace
- Maintenance burden for rarely-used functionality

## Future Work

If Python bindings for supporting libraries are needed, the following would be required:

### Per-Library Changes

For each library (example: libhmac):

1. **Regenerate patch** to keep Python binding directory:
   ```bash
   # Don't remove pyhmac from SUBDIRS
   # Don't remove AC_CONFIG_FILES([pyhmac/Makefile])
   ```

2. **Update ebuild** to add Python support:
   ```bash
   inherit git-r3 autotools python-single-r1

   PYTHON_COMPAT=( python3_{10..13} )

   IUSE="nls python static-libs"
   REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

   BDEPEND="
       ...
       python? ( dev-lang/swig )
   "

   pkg_setup() {
       use python && python-single-r1_pkg_setup
   }

   src_configure() {
       local myeconfargs=(
           $(use_enable python)
           ...
       )
       econf "${myeconfargs[@]}"
   }
   ```

3. **Regenerate manifest** for the updated ebuild

### Testing Requirements

For each library with Python bindings:
- Test import in Python
- Verify module functionality
- Test across Python 3.10, 3.11, 3.12, 3.13
- Document Python API

### Libraries Most Likely to Need Python Bindings

Priority order if implementing:
1. **libhmac** - Cryptographic functions useful standalone
2. **libcaes** - AES encryption useful standalone
3. **libuna** - Unicode conversion useful standalone
4. **Others** - Less likely to be used directly from Python

## Examples

### Using the Main Library (Currently Supported)

```python
import pyfvde

# Open a FileVault encrypted volume
volume = pyfvde.volume()
volume.open("encrypted.dmg")

# Work with the volume
# ... (libfvde functionality)
```

### Hypothetical Individual Library Use (Not Currently Supported)

```python
# This does NOT currently work:
import pyhmac  # ModuleNotFoundError

# If implemented, would allow:
import pyhmac
digest = pyhmac.sha256("data")
```

## Decision Process

This design decision prioritizes:
1. ✅ Simplicity and maintainability
2. ✅ Common use cases (Python access to main library)
3. ✅ Minimal dependency chains
4. ✅ Easier troubleshooting

Over:
1. ❌ Comprehensive Python coverage of all libraries
2. ❌ Standalone use of internal libraries from Python
3. ❌ Maximum flexibility

## Changing This Decision

To enable Python bindings for supporting libraries:

1. Review this document and understand the tradeoffs
2. Determine which specific libraries need Python support
3. Follow the "Future Work" section above
4. Update this document with the new status
5. Consider maintaining a separate branch for Python-enabled variants

## References

- libyal project: https://github.com/libyal
- SWIG documentation: http://www.swig.org/
- Gentoo Python Guide: https://devmanual.gentoo.org/eclass-reference/python-single-r1.eclass/

## Last Updated

2026-02-02 - Initial documentation of Python bindings decision

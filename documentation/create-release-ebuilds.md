# create-release-ebuilds.sh

Script to create release ebuilds from GitHub tags using symlinks.

## Features

- Uses GitHub CLI (`gh`) to query available tags from libyal repositories
- Creates symlinks from `libfoo-9999.ebuild` to `libfoo-YYYYMMDD.ebuild`
- Automatically regenerates manifests after creating symlinks
- Supports processing all libraries or specific ones

## Requirements

- GitHub CLI (`gh`) must be installed and authenticated
- `ebuild` command must be available (Gentoo system)

## Options

```
-l, --latest       Only create ebuild for the latest tag (default: all tags)
-n, --dry-run      Show what would be done without making changes
-c, --clean        Remove existing release symlinks before creating new ones
-t, --tag TAG      Only create ebuild for specific tag
-h, --help         Show this help message
```

## Examples

```bash
# See what latest tags would be created (dry run)
./create-release-ebuilds.sh --dry-run --latest

# Create ebuilds for latest tags of all libraries
./create-release-ebuilds.sh --latest

# Create ebuilds for all available tags
./create-release-ebuilds.sh

# Create ebuilds only for libfvde and libcerror
./create-release-ebuilds.sh --latest libfvde libcerror

# Clean old symlinks and recreate with latest
./create-release-ebuilds.sh --clean --latest
```

## How It Works

The libyal project uses date-based tags (e.g., `20240502`) for releases. This script:

1. Queries GitHub for available tags using `gh api`
2. Creates symlinks pointing to the `-9999.ebuild` file
3. The ebuild contains logic to detect when `${PV} != 9999` and sets `EGIT_COMMIT="${PV}"` to check out the specific tag
4. Non-9999 versions automatically get `KEYWORDS="~amd64 ~arm ~arm64 ~x86"` for testing status

This approach means:
- Only one ebuild file needs to be maintained per library
- Release ebuilds are just symlinks, no code duplication
- Patches in `files/` are shared between live and release versions

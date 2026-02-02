#!/bin/bash
# create-release-ebuilds.sh - Create release ebuilds from GitHub tags
#
# This script uses GitHub CLI (gh) to find available tags for libyal
# libraries and creates symlinks to the 9999 ebuilds for each tag.
#
# Usage:
#   ./create-release-ebuilds.sh [options] [library...]
#
# Options:
#   -l, --latest       Only create ebuild for the latest tag (default: all tags)
#   -n, --dry-run      Show what would be done without making changes
#   -c, --clean        Remove existing release symlinks before creating new ones
#   -t, --tag TAG      Only create ebuild for specific tag
#   -h, --help         Show this help message
#
# Examples:
#   ./create-release-ebuilds.sh                    # All libraries, all tags
#   ./create-release-ebuilds.sh --latest           # All libraries, latest tag only
#   ./create-release-ebuilds.sh libcerror libfvde  # Specific libraries only
#   ./create-release-ebuilds.sh -t 20240415        # Specific tag for all libraries
#
# Requirements:
#   - GitHub CLI (gh) must be installed and authenticated
#   - ebuild command must be available (for manifest generation)

set -euo pipefail

OVERLAY_DIR="/var/db/repos/libfvde-overlay"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# All libraries in the overlay
ALL_LIBRARIES=(
    libcerror
    libcthreads
    libcdata
    libclocale
    libcnotify
    libcsplit
    libuna
    libcfile
    libcpath
    libbfio
    libfcache
    libfdata
    libfguid
    libfplist
    libfvalue
    libhmac
    libcaes
    libfdatetime
    libfwnt
    libfvde
)

# Options
LATEST_ONLY=false
DRY_RUN=false
CLEAN=false
SPECIFIC_TAG=""
LIBRARIES=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

show_help() {
    sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--latest)
            LATEST_ONLY=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -t|--tag)
            SPECIFIC_TAG="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        -*)
            log_error "Unknown option: $1"
            exit 1
            ;;
        *)
            LIBRARIES+=("$1")
            shift
            ;;
    esac
done

# Use all libraries if none specified
if [[ ${#LIBRARIES[@]} -eq 0 ]]; then
    LIBRARIES=("${ALL_LIBRARIES[@]}")
fi

# Check prerequisites
check_prerequisites() {
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed. Please install it first."
        log_error "  Gentoo: emerge dev-util/github-cli"
        exit 1
    fi

    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated. Please run: gh auth login"
        exit 1
    fi

    if ! command -v ebuild &> /dev/null; then
        log_error "ebuild command not found. Are you running on a Gentoo system?"
        exit 1
    fi
}

# Get tags for a library from GitHub
get_tags() {
    local lib="$1"
    local tags

    tags=$(gh api "repos/libyal/${lib}/tags" --jq '.[].name' 2>/dev/null | sort -V)

    if [[ -z "$tags" ]]; then
        log_warn "No tags found for ${lib}"
        return 1
    fi

    echo "$tags"
}

# Get latest tag for a library
get_latest_tag() {
    local lib="$1"
    get_tags "$lib" | tail -1
}

# Clean existing release symlinks for a library
clean_symlinks() {
    local lib="$1"
    local lib_dir="${OVERLAY_DIR}/dev-libs/${lib}"

    if [[ ! -d "$lib_dir" ]]; then
        return
    fi

    for ebuild in "${lib_dir}"/${lib}-[0-9]*.ebuild; do
        if [[ -L "$ebuild" ]]; then
            local version
            version=$(basename "$ebuild" .ebuild | sed "s/${lib}-//")
            if [[ "$version" != "9999" ]]; then
                if [[ "$DRY_RUN" == true ]]; then
                    log_info "[DRY-RUN] Would remove: $ebuild"
                else
                    rm "$ebuild"
                    log_info "Removed: $(basename "$ebuild")"
                fi
            fi
        fi
    done
}

# Create symlink for a specific tag
create_symlink() {
    local lib="$1"
    local tag="$2"
    local lib_dir="${OVERLAY_DIR}/dev-libs/${lib}"
    local source_ebuild="${lib}-9999.ebuild"
    local target_ebuild="${lib}-${tag}.ebuild"

    if [[ ! -d "$lib_dir" ]]; then
        log_error "Library directory not found: $lib_dir"
        return 1
    fi

    if [[ ! -f "${lib_dir}/${source_ebuild}" ]]; then
        log_error "Source ebuild not found: ${lib_dir}/${source_ebuild}"
        return 1
    fi

    # Check if symlink already exists
    if [[ -e "${lib_dir}/${target_ebuild}" ]]; then
        if [[ -L "${lib_dir}/${target_ebuild}" ]]; then
            log_info "Symlink already exists: ${target_ebuild}"
            return 0
        else
            log_warn "Non-symlink file exists: ${target_ebuild}, skipping"
            return 1
        fi
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would create: ${lib_dir}/${target_ebuild} -> ${source_ebuild}"
    else
        cd "$lib_dir"
        ln -s "$source_ebuild" "$target_ebuild"
        log_success "Created: ${target_ebuild} -> ${source_ebuild}"
    fi
}

# Regenerate manifest for a library
regenerate_manifest() {
    local lib="$1"
    local lib_dir="${OVERLAY_DIR}/dev-libs/${lib}"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would regenerate manifest for ${lib}"
        return
    fi

    cd "$lib_dir"
    # Use the 9999 ebuild to regenerate manifest (it will include all versions)
    if ebuild "${lib}-9999.ebuild" manifest 2>/dev/null; then
        log_success "Regenerated manifest for ${lib}"
    else
        log_error "Failed to regenerate manifest for ${lib}"
    fi
}

# Process a single library
process_library() {
    local lib="$1"
    local tags_to_process=()

    log_info "Processing ${lib}..."

    # Get tags
    if [[ -n "$SPECIFIC_TAG" ]]; then
        # Verify the specific tag exists
        if get_tags "$lib" | grep -q "^${SPECIFIC_TAG}$"; then
            tags_to_process=("$SPECIFIC_TAG")
        else
            log_warn "Tag ${SPECIFIC_TAG} not found for ${lib}"
            return
        fi
    elif [[ "$LATEST_ONLY" == true ]]; then
        local latest
        latest=$(get_latest_tag "$lib")
        if [[ -n "$latest" ]]; then
            tags_to_process=("$latest")
        fi
    else
        mapfile -t tags_to_process < <(get_tags "$lib")
    fi

    if [[ ${#tags_to_process[@]} -eq 0 ]]; then
        log_warn "No tags to process for ${lib}"
        return
    fi

    # Clean if requested
    if [[ "$CLEAN" == true ]]; then
        clean_symlinks "$lib"
    fi

    # Create symlinks
    local created=0
    for tag in "${tags_to_process[@]}"; do
        if create_symlink "$lib" "$tag"; then
            ((created++)) || true
        fi
    done

    # Regenerate manifest if we created any symlinks
    if [[ $created -gt 0 ]] || [[ "$CLEAN" == true ]]; then
        regenerate_manifest "$lib"
    fi

    echo ""
}

# Main
main() {
    echo "========================================"
    echo "  libfvde-overlay Release Ebuild Creator"
    echo "========================================"
    echo ""

    check_prerequisites

    if [[ "$DRY_RUN" == true ]]; then
        log_warn "Running in dry-run mode - no changes will be made"
        echo ""
    fi

    local processed=0
    for lib in "${LIBRARIES[@]}"; do
        # Verify library is valid
        if [[ ! " ${ALL_LIBRARIES[*]} " =~ " ${lib} " ]]; then
            log_error "Unknown library: ${lib}"
            continue
        fi

        process_library "$lib"
        ((processed++)) || true
    done

    echo "========================================"
    log_success "Processed ${processed} libraries"

    if [[ "$DRY_RUN" == true ]]; then
        log_warn "This was a dry run. Run without -n to apply changes."
    fi
}

main "$@"

#!/bin/bash
set -euo pipefail
cd "$1"
probe=$(mktemp -d /tmp/pr447-discovery.XXXXXX)
trap 'rm -rf "$probe"' EXIT
for package in omawake-bin omaspeak-bin; do
  BUILD_PLAN_DIR="$probe/$package" bin/build --dry-run --package "$package" --mirror edge --arch x86_64 > "$probe/$package.log" 2>&1 || { cat "$probe/$package.log"; exit 1; }
  grep -Fxq "$package" "$probe/$package/packages"
  printf 'PASS: explicit edge x86_64 builder discovers %s\n' "$package"
done
export PKGBUILDS_DIR="$PWD/pkgbuilds"
source helpers/package-metadata.sh
for package in omawake-bin omaspeak-bin; do
  directory=$(package_dir_for_name "$package")
  package_dirs > "$probe/discovered"
  grep -Fxq "$directory" "$probe/discovered"
  package_builds_for_mirror "$directory" edge
  ! package_in_channel "$directory" rc
  ! package_in_channel "$directory" stable
  ! package_build_skipped "$directory"
  package_supports_arch "$directory" x86_64
  ! package_supports_arch "$directory" aarch64
  printf 'PASS: scheduled discovery includes %s, edge-only and x86_64-only\n' "$package"
done

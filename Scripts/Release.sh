#!/usr/bin/env bash

set -e

if [ -n "${1:-}" ]; then
  VERSION="$1"
else
  read -rp '✍️ Enter the new semantic version number: ' VERSION
fi

exit_with_error() { >&2 echo "❌ ${1}"; exit 1; }

DRY_RUN=0
is_dry_run() { [[ "$DRY_RUN" = 1 ]]; }
if [ -n "${2:-}" ]; then
  if [[ "${2}" = "--dry-run" ]]; then
    DRY_RUN=1
  else
    exit_with_error "Invalid argument '$2'. Supported: --dry-run)"
  fi
fi

set -u

export VERSION
export TAG_NAME="v$VERSION"
SCRIPTS_DIR="$(realpath "${0%/*}")"
PROJECT_ROOT="$(realpath "$SCRIPTS_DIR/..")"

cd "$PROJECT_ROOT"

echo "☁️ Ensuring local repository sync status"

if ! is_dry_run; then
  git fetch origin --tags -q
  if (git tag -l | grep -Fxq "$TAG_NAME"); then
    exit_with_error "Git tag $TAG_NAME already exists, aborting"
  fi
  if ([[ $(git status -s) ]] || ! git diff origin/latest --exit-code --quiet); then
    exit_with_error "Local state not synced with origin/latest, aborting"
  fi
  git checkout latest -q
  git pull -q
fi

XCCONFIG_PATH="$PROJECT_ROOT/Config.xcconfig"
BUNDLE_NAME="$(sed -n 's/^AAR_BUNDLE_NAME[ ]*=[ ]*//p' "$XCCONFIG_PATH")"
export BUNDLE_NAME

CONFIRM_MSG="🔔 Release $BUNDLE_NAME v$VERSION"
if ! is_dry_run; then
  read -s -rp "$CONFIRM_MSG? (y/N) "$'\n' -n1 CONFIRM
  if [[ "$CONFIRM" != "y" ]]; then
    echo "🚫 Release cancelled"
    exit 0
  fi
else
  echo "$CONFIRM_MSG [dry-run]"
fi

BUILD_TIME="$(date '+%s')"
build_date() {
  date -r "$BUILD_TIME" "${1}"
}
BUILD_NUMBER="$(build_date '+%y%m%d%H%M')"
export BUILD_NUMBER

bash "$SCRIPTS_DIR/UpdateConfig.sh" \
  AAR_VERSION="$VERSION" \
  AAR_BUILD_NUMBER="$BUILD_NUMBER"

ARCHIVE_DIR="$HOME/Library/Developer/Xcode/Archives/$(build_date '+%Y-%m-%d')"
ARCHIVE_PATH="$ARCHIVE_DIR/$BUNDLE_NAME $(build_date '+%d-%m-%Y, %H:%M:%S').xcarchive"
DESTINATION='generic/platform=macOS,name=Any Mac'

echo "🗄️ Building product archive at \"$ARCHIVE_PATH\""

xcodebuild clean -quiet
xcodebuild archive -quiet \
  -destination "$DESTINATION" \
  -scheme "$BUNDLE_NAME" \
  -target "$BUNDLE_NAME" \
  -archivePath "$ARCHIVE_PATH"

export EXPORT_PATH="${TMPDIR%/}/${BUNDLE_NAME}_v${VERSION}_${BUILD_NUMBER}"

echo "💾 Exporting product bundle at \"$EXPORT_PATH/$BUNDLE_NAME.app\""

xcodebuild -exportArchive -quiet \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$SCRIPTS_DIR/ExportOptions.plist"

echo "🏷️ Creating GitHub release for tag $TAG_NAME"

export ASSET_BASE_NAME="${BUNDLE_NAME// /_}_${TAG_NAME}_${BUILD_NUMBER}.app"
export ASSET_EXTENSIONS="zip tgz"
for EXT in ${ASSET_EXTENSIONS}; do
  echo "📦 Archiving release asset at \"$EXPORT_PATH/$ASSET_BASE_NAME.$EXT\""
  tar -acf "$EXPORT_PATH/$ASSET_BASE_NAME.$EXT" -C"$EXPORT_PATH" "$BUNDLE_NAME.app"
done
RELEASE_NOTES_PATH="$EXPORT_PATH/Release_Notes.md"

echo "📝 Generating release notes markdown at \"$RELEASE_NOTES_PATH\""

(bash "$SCRIPTS_DIR/ReleaseNotes.sh" && true 2>&1) > "$RELEASE_NOTES_PATH"

if ! is_dry_run; then
  git add "$XCCONFIG_PATH"
  git commit -S -m "chore: bump version to $VERSION"
  git push -q
  gh release create "$TAG_NAME" -t "$TAG_NAME" -F "$RELEASE_NOTES_PATH"
  git fetch origin --tags
  for EXT in ${ASSET_EXTENSIONS}; do
    gh release upload "$TAG_NAME" "$EXPORT_PATH/$ASSET_BASE_NAME.$EXT#$BUNDLE_NAME.app ($EXT)"
  done
fi

echo "✅ Version $VERSION ($BUILD_NUMBER) archived and released"

if is_dry_run; then
  rm -rf "$ARCHIVE_PATH"
fi

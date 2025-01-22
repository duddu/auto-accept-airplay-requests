#!/usr/bin/env bash

set -e

if [ -n "${1:-}" ]; then
  VERSION="$1"
else
  read -rp '✍️ Enter the new semantic version number: ' VERSION
fi

set -u

export VERSION
export TAG_NAME="v$VERSION"
export PRODUCT_NAME='Accept AirPlay Requests'
SCRIPTS_DIR="$(realpath "${0%/*}")"
PROJECT_ROOT="$(realpath "$SCRIPTS_DIR/..")"

cd "$PROJECT_ROOT"

echo '☁️ Ensuring repository status'

git fetch origin --tags -q
if (git tag -l | grep -Fxq "$TAG_NAME"); then
  >&2 echo "❌ Git tag $TAG_NAME already exists, aborting"; exit 1
fi
if ([[ $(git status -s) ]] || ! git diff origin/latest --exit-code --quiet); then
  >&2 echo '❌ Local state not up to date with origin/latest, aborting'; exit 1
fi
git checkout latest -q
git pull -q

read -s -rp "🔔 Release $PRODUCT_NAME v$VERSION? (y/N) "$'\n' -n1 CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "🚫 Release aborted"; exit 0
fi

BUILD_TIME="$(date '+%s')"
build_date() { date -r "$BUILD_TIME" "$@"; }
BUILD_NUMBER="$(build_date '+%y%m%d%H%M')"
export BUILD_NUMBER

bash "$SCRIPTS_DIR/UpdateConfig.sh" \
  AAR_VERSION="$VERSION" \
  AAR_BUILD_NUMBER="$BUILD_NUMBER"

ARCHIVE_DIR="$HOME/Library/Developer/Xcode/Archives/$(build_date '+%Y-%m-%d')"
ARCHIVE_PATH="$ARCHIVE_DIR/$PRODUCT_NAME $(build_date '+%d-%m-%Y, %H:%M:%S').xcarchive"
DESTINATION='generic/platform=macOS,name=Any Mac'

echo "📦 Producing app archive at $ARCHIVE_PATH"

xcodebuild clean -quiet
xcodebuild archive -quiet \
  -scheme "$PRODUCT_NAME" -alltargets \
  -destination "$DESTINATION" \
  -archivePath "$ARCHIVE_PATH"

export EXPORT_PATH="${TMPDIR%/}/${PRODUCT_NAME}_v${VERSION}_${BUILD_NUMBER}"

echo "💾 Exporting app copy at $EXPORT_PATH/$PRODUCT_NAME.app"

xcodebuild -exportArchive -quiet \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$SCRIPTS_DIR/ExportOptions.plist"

echo "🚀 Creating GitHub release $TAG_NAME"

export ASSET_BASE_NAME="${PRODUCT_NAME// /_}_${TAG_NAME}_${BUILD_NUMBER}.app"
RELEASE_NOTES="$(bash "$SCRIPTS_DIR/ReleaseNotes.sh")"

tar -jcf "$EXPORT_PATH/$ASSET_BASE_NAME.zip" -C"$EXPORT_PATH" "$PRODUCT_NAME.app"
tar -zcf "$EXPORT_PATH/$ASSET_BASE_NAME.tar.gz" -C"$EXPORT_PATH" "$PRODUCT_NAME.app"
git add "$PROJECT_ROOT/Config.xcconfig"
git commit -S -m "chore: bump version to $VERSION [skip ci]"
git push -q
gh release create "$TAG_NAME" -t "$TAG_NAME" \
  --notes "$RELEASE_NOTES" \
  "$EXPORT_PATH/$ASSET_BASE_NAME.zip#$PRODUCT_NAME.app (zip)" \
  "$EXPORT_PATH/$ASSET_BASE_NAME.tar.gz#$PRODUCT_NAME.app (tar.gz)"
git fetch origin --tags

echo "✅ Version $VERSION ($BUILD_NUMBER) archived and released"

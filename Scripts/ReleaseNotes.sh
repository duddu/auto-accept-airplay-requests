#!/usr/bin/env bash

set -e
set -u

: "${ASSET_BASE_NAME}"
: "${ASSET_EXTENSIONS}"
: "${BUILD_NUMBER}"
: "${BUNDLE_NAME}"
: "${EXPORT_PATH}"
: "${TAG_NAME}"
: "${VERSION}"

exit_with_error() { >&2 echo "❌ ${1}"; exit 1; }

REPO_BASE_URL="$(gh repo view --json url --jq '.url')"
if [ -z "$REPO_BASE_URL" ]; then
  exit_with_error "Failed to fetch repository url"
fi

PREVIOUS_TAG_NAME="$(gh repo view --json latestRelease --jq '.latestRelease.tagName')"
if [ -n "$PREVIOUS_TAG_NAME" ]; then
  CHANGELOG_PATH="compare/$PREVIOUS_TAG_NAME...$TAG_NAME"
else
  CHANGELOG_PATH="commits/$TAG_NAME"
fi

BUNDLE_PATH="$EXPORT_PATH/$BUNDLE_NAME.app"
if (! codesign -v -r- "$BUNDLE_PATH"); then
  exit_with_error "Cannot verify code signature"
fi
print_codesign() {
  local arch="${1}"
  local arg_param=
  if [[ "$arch" != "--all-architectures" ]]; then
    arg_param="-a"
  fi
  codesign -d -r- -vvv "$BUNDLE_PATH" $arg_param "$arch" 2>&1
}
get_codesign_cdhash() {
  print_codesign "${1}" | grep '^CDHash=' | awk -F '=' '{print $2}'
}
CODESIGN_CDHASH_ARM64="$(get_codesign_cdhash "arm64")"
CODESIGN_CDHASH_X8664="$(get_codesign_cdhash "x86_64")"
CODESIGN_ALL="$(print_codesign "--all-architectures")"
get_codesign_line() {
  local line_starts_with="${1}"
  echo "$CODESIGN_ALL" | grep "^$line_starts_with"
}

BUNDLE_SIZE="$(du -sk "$BUNDLE_PATH" | sed -rn "s/^([0-9]*).*/\1 KB/p")"

ASSET_FIRST_EXT="$(echo "$ASSET_EXTENSIONS" | awk -F ' ' '{print $1}')"
ASSETS_SHASUM_ROWS=""
for EXT in ${ASSET_EXTENSIONS}; do
  ASSETS_SHASUM_ROWS+="| $ASSET_BASE_NAME.$EXT | \`$(shasum -a 256 -U "$EXPORT_PATH/$ASSET_BASE_NAME.$EXT" | awk -F ' ' '{print $1}')\` |
"
done

echo -n "## Download:
### :package: [$BUNDLE_NAME.app ($ASSET_FIRST_EXT)]($REPO_BASE_URL/releases/download/$TAG_NAME/$ASSET_BASE_NAME.$ASSET_FIRST_EXT)

| Version | Build | Size | Format |
| :--- | :--- | :--- | :--- |
| $VERSION | $BUILD_NUMBER | $BUNDLE_SIZE | $(get_codesign_line "Format=" | awk -F '=' '{print $2}') |

<details>
<summary>:lock_with_ink_pen:&nbsp;&nbsp;Click here to inspect the <b>code signature</b> and verify it locally</summary>
<br>

Run this command from your terminal to verify the code signature of the application:
\`\`\`bash
codesign --verify --display -r- --verbose=3 \"<DIR_PATH>/$BUNDLE_NAME.app\"
# Where <DIR_PATH> is the folder where you stored the downloaded app bundle
\`\`\`
The output should contain a \`CDHash\` value matching one of these:
| Architecture | Code signature hash (CDHash) | 
| :--- | :--- |
| ARM64 | \`$CODESIGN_CDHASH_ARM64\` | 
| x68-64 | \`$CODESIGN_CDHASH_X8664\` | 

The rest of your code signature can be validated against the output below:
\`\`\`properties
$(get_codesign_line "Executable=" | sed -rn "s/^(Executable=).*\/($BUNDLE_NAME.app\/.*$)/\1<DIR_PATH>\/\2/p")
$(get_codesign_line "Identifier=")
$(get_codesign_line "Hash type=")
$(get_codesign_line "Signature size=")
$(get_codesign_line "Authority=Apple Development:" | sed -rn 's/^(.*:).*@[^\(]*(.*)$/\1 **** \2/p')
$(get_codesign_line "Authority=Apple Worldwide")
$(get_codesign_line "Authority=Apple Root")
$(get_codesign_line "Signed Time=")
$(get_codesign_line "Info.plist entries=")
$(get_codesign_line "Runtime Version=")
$(get_codesign_line "Sealed Resources version=")
$(get_codesign_line "designated =>" | sed -rn 's/^(.*Apple Development:) .*@[^\(]*(.*)$/\1 **** \2/p')
\`\`\`
</details>

<details>
<summary>:hash:&nbsp;&nbsp;Click here to display the <b>checksums</b> for the release assets</summary>
<br>

| Asset filename | Checksum (SHA-256) |
| :--- | :--- | 
$ASSETS_SHASUM_ROWS
</details>

## Changelog:

$REPO_BASE_URL/$CHANGELOG_PATH"

#!/usr/bin/env bash

set -e
set -u

: "${ASSET_BASE_NAME}"
: "${BUILD_NUMBER}"
: "${EXPORT_PATH}"
: "${PRODUCT_NAME}"
: "${TAG_NAME}"
: "${VERSION}"

REPO_BASE_URL="$(gh repo view --json url --jq '.url')"
if [ -z "$REPO_BASE_URL" ]; then
  >&2 echo '❌ Failed to fetch repository url'; exit 1
fi

PREVIOUS_TAG_NAME="$(gh repo view --json latestRelease --jq '.tagName')"
if [ -n "$PREVIOUS_TAG_NAME" ]; then
  CHANGELOG_PATH="compare/$PREVIOUS_TAG_NAME...$TAG_NAME"
else
  CHANGELOG_PATH="commits/$TAG_NAME"
fi

BUNDLE_PATH="$EXPORT_PATH/$PRODUCT_NAME.app"
if (! codesign -v -r- "$BUNDLE_PATH"); then
  >&2 echo '❌ Cannot verify code signature'; exit 1
fi
CODESIGN_ALL="$(codesign -d -vv "$BUNDLE_PATH" 2>&1)"
CODESIGN_ARM="$(codesign -a arm64 -d -vvv "$BUNDLE_PATH" 2>&1)"
CODESIGN_X86="$(codesign -a x86_64 -d -vvv "$BUNDLE_PATH" 2>&1)"

echo "### :package: [$PRODUCT_NAME.app (zip)]($REPO_BASE_URL/releases/download/$TAG_NAME/$ASSET_BASE_NAME.zip)

| Version | Build | Format | Architecture |
| :--- | :--- | :--- | :--- |
| $VERSION | $BUILD_NUMBER | macOS bundle | universal (x86_64 arm64) |

<details>
<summary>Expand code signature data</summary>
<br>

| Field | Value |
| :--- | :--- |
| Authority | $(echo "$CODESIGN_ALL" | sed -rn 's/^Authority=(Apple Development:)[^(]*/\1 *** /p') |
| CDHash (arm64) | $(echo "$CODESIGN_ARM" | sed -n 's/^CDHash=//p') |
| CDHash (x86_64) | $(echo "$CODESIGN_X86" | sed -n 's/^CDHash=//p') |
| Identifier | $(echo "$CODESIGN_ALL" | sed -n 's/^Identifier=//p') |
| Signed Time | $(echo "$CODESIGN_ALL" | sed -n 's/^Signed Time=//p') |
| TeamIdentifier | $(echo "$CODESIGN_ALL" | sed -n 's/^TeamIdentifier=//p') |

To verify the signature locally run this command and compare the outputs:
\`\`\`sh
codesign -d -r- -vvv '<PATH_TO_APP>/$PRODUCT_NAME.app'
\`\`\`
</details>

##
### Changelog

$REPO_BASE_URL/$CHANGELOG_PATH"

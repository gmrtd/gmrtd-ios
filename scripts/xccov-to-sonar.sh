#!/usr/bin/env bash
# Converts the code coverage in an Xcode result bundle to SonarQube's generic test
# coverage format (https://docs.sonarsource.com/sonarqube-cloud/enriching/test-coverage/generic-test-data/).
#
# Only the package's own sources (Sources/GmrtdKit/) are included, with paths relative to the
# repository root, because the analysis runs on a different machine from the tests.
#
# Usage: scripts/xccov-to-sonar.sh <path/to/Result.xcresult> > coverage.xml
set -euo pipefail

xcresult="${1:?usage: $0 <path/to/Result.xcresult>}"
root="$(cd "$(dirname "$0")/.." && pwd -P)"

echo '<coverage version="1">'
xcrun xccov view --archive --file-list "$xcresult" | while IFS= read -r file; do
    case "$file" in
        "$root"/Sources/GmrtdKit/*) ;;
        *) continue ;;
    esac
    echo "  <file path=\"${file#"$root"/}\">"
    # Lines look like "   12: 3" (hit count) or "   12: *" (not executable).
    xcrun xccov view --archive --file "$file" "$xcresult" | sed -n \
        -e 's/^ *\([0-9][0-9]*\): 0.*$/    <lineToCover lineNumber="\1" covered="false"\/>/p' \
        -e 's/^ *\([0-9][0-9]*\): [1-9].*$/    <lineToCover lineNumber="\1" covered="true"\/>/p'
    echo '  </file>'
done
echo '</coverage>'

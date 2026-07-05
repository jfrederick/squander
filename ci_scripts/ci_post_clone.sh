#!/bin/sh
set -e

# Xcode Cloud post-clone hook.
#
# No dependencies to install: SpendthriftCore is a local Swift package resolved
# directly from the committed .xcodeproj, and the project itself is
# committed (not generated via xcodegen or similar), so there is nothing
# else to fetch or bootstrap here.
echo "ci_post_clone: no dependencies to install"

#!/usr/bin/env bash

set -x

# shellcheck source=/dev/null
source "$HOME"/.cargo/env
source "$(dirname "$0")"/test-util.sh

PROJECT_DIR="/cloud-hypervisor"
SCRIPT_DIR="$PROJECT_DIR/scripts"
TARGET_DIR="$PROJECT_DIR/target"

pushd $PROJECT_DIR || exit

export BUILD_TARGET=${BUILD_TARGET-$(uname -m)-unknown-linux-gnu}

# GLIBC > 2.31
GRCOV_RELEASE_URL="https://github.com/mozilla/grcov/releases/download/v0.8.19/grcov-$BUILD_TARGET.tar.bz2"
wget --quiet "$GRCOV_RELEASE_URL" || exit 1
tar -xjf "grcov-$BUILD_TARGET.tar.bz2"

rustup component add llvm-tools-preview

find . -type f -name 'ch-*.profraw' -exec rm {} \;

$SCRIPT_DIR/run_integration_tests_x86_64.sh
RES=$?

if [ $RES -eq 0 ]; then
    $SCRIPT_DIR/run_integration_tests_live_migration.sh
    RES=$?
fi

rm "coverage.info"

./grcov "$(find . -name 'ch-*.profraw' -print)" -s . \
    --ignore "tests/*" \
    --ignore "test_infra/*" \
    --ignore "performance-metrics/*" \
    --binary-path "$TARGET_DIR/$BUILD_TARGET/release/" \
    --branch --ignore-not-existing -t lcov \
    -o "coverage.info"

# Generate HTML report
#OUTPUT_DIR="$TARGET_DIR/coverage"
#rm -rf $OUTPUT_DIR
#grcov . -s . --binary-path "$TARGET_DIR/$BUILD_TARGET/release/" -t html --branch --ignore-not-existing -o $OUTPUT_DIR

popd || exit 1
exit $RES

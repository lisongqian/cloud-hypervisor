#!/usr/bin/env bash
# shellcheck disable=SC2048,SC2086
set -x

# shellcheck source=/dev/null
source "$HOME"/.cargo/env
source "$(dirname "$0")"/test-util.sh

PROJECT_DIR="/cloud-hypervisor"
SCRIPT_DIR="$PROJECT_DIR/scripts"
TARGET_DIR="$PROJECT_DIR/target"
OUTPUT_FILE="lcov.info"

pushd $PROJECT_DIR || exit

BUILD_TARGET=${BUILD_TARGET-x86_64-unknown-linux-gnu}

sudo apt -y install build-essential
# rustc >= 1.74
cargo install grcov
rustup component add llvm-tools-preview

rm $OUTPUT_FILE
# Generate lcov report
grcov . -s . --binary-path "$TARGET_DIR/$BUILD_TARGET/release/" -t lcov --branch --ignore-not-existing -o $OUTPUT_FILE

# clean profraw data.
echo $LLVM_PROFILE_FILE
find . -type f -name 'ch*.profraw' -exec rm {} \;
rm -rf default*.profraw

#!/usr/bin/env bash

set -x

source "$HOME"/.cargo/env
source "$(dirname "$0")"/test-util.sh

PROJECT_DIR="/cloud-hypervisor"
SCRIPT_DIR="$PROJECT_DIR/scripts"
TARGET_DIR="$PROJECT_DIR/target"

pushd $PROJECT_DIR

libc="gnu"
if [ -z "$BUILD_TARGET" ]; then
  BUILD_TARGET="$(uname -m)-unknown-linux-$libc"
fi

# rustc >= 1.74
cargo install grcov
rustup component add llvm-tools-preview

export CARGO_INCREMENTAL=0
export RUSTFLAGS="-Cinstrument-coverage"

export LLVM_PROFILE_FILE="ch-%p-%m.profraw"
find . -type f -name 'ch*.profraw' -exec rm {} \;
rm -rf default*.profraw

bash "$SCRIPT_DIR/dev_cli.sh" tests --unit --libc $libc || exit 1

bash "$SCRIPT_DIR/dev_cli.sh" tests --integration --libc $libc

bash "$SCRIPT_DIR/dev_cli.sh" tests --integration-live-migration --libc $libc

OUTPUT_DIR="$TARGET_DIR/coverage"
rm -rf $OUTPUT_DIR
# Generate HTML report
grcov . -s . --binary-path $TARGET_DIR/$BUILD_TARGET/release/ -t html --branch --ignore-not-existing -o $OUTPUT_DIR

popd
#!/usr/bin/env bash
# shellcheck disable=SC2068

# shellcheck source=/dev/null
source "$HOME"/.cargo/env
source "$(dirname "$0")"/test-util.sh

process_common_args "$@"

cargo_args=("")

# shellcheck disable=SC2154
if [[ $hypervisor = "mshv" ]]; then
    cargo_args+=("--features $hypervisor")
elif [[ $(uname -m) = "x86_64" ]]; then
    cargo_args+=("--features tdx")
fi

GRCOV_RELEASE_URL="https://github.com/mozilla/grcov/releases/download/v0.8.19/grcov-$BUILD_TARGET.tar.bz2"
wget --quiet "$GRCOV_RELEASE_URL" || exit 1
tar -xjf "grcov-$BUILD_TARGET.tar.bz2"

rustup component add llvm-tools-preview

find . -type f -name 'ch-*.profraw' -exec rm {} \;

export RUST_BACKTRACE=1
cargo test --lib --bins --target "$BUILD_TARGET" --release --workspace ${cargo_args[@]} || exit 1
cargo test --doc --target "$BUILD_TARGET" --release --workspace ${cargo_args[@]} || exit 1

rm "coverage.info"

./grcov "$(find . -name 'ch-*.profraw' -print)" -s . \
    --ignore "tests/*" \
    --ignore "test_infra/*" \
    --ignore "performance-metrics/*" \
    --binary-path "target/$BUILD_TARGET/release/" \
    --branch --ignore-not-existing -t lcov \
    -o "coverage.info"

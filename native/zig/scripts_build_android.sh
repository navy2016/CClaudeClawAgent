#!/usr/bin/env sh
set -eu

# Example only. Requires zig and Android NDK environment variables.
# Produces libcclaudeclaw.so for arm64-v8a.

TARGET="aarch64-linux-android"
API="26"
OUT="../../app/src/main/jniLibs/arm64-v8a"
mkdir -p "$OUT"
zig build -Dtarget="$TARGET" -Doptimize=ReleaseSmall
cp zig-out/lib/libcclaudeclaw.so "$OUT/"

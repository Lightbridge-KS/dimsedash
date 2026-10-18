#!/usr/bin/env bash
set -euo pipefail
# Tool pins for hosted CI; the Flutter SDK pin remains in .fvmrc.
bin_dir="${RUNNER_TEMP:?}/dimsedash-tools"
mkdir -p "$bin_dir"
case "$(uname -s)" in
  Darwin) triple=aarch64-apple-darwin; platform=darwin; arch=arm64 ;;
  Linux) triple=x86_64-unknown-linux-musl; platform=linux; arch=x64 ;;
  *) exit 1 ;;
esac
curl --fail --location --silent --show-error "https://github.com/casey/just/releases/download/1.53.0/just-1.53.0-${triple}.tar.gz" -o "$bin_dir/just.tar.gz"
tar -xzf "$bin_dir/just.tar.gz" -C "$bin_dir" just
curl --fail --location --silent --show-error "https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_${platform}_${arch}.tar.gz" -o "$bin_dir/gitleaks.tar.gz"
tar -xzf "$bin_dir/gitleaks.tar.gz" -C "$bin_dir" gitleaks
printf '%s\n' "$bin_dir" >> "$GITHUB_PATH"
flutter_version=$(python3 -c 'import json; print(json.load(open(".fvmrc"))["flutter"])')
git clone --depth 1 --branch "$flutter_version" https://github.com/flutter/flutter.git "$RUNNER_TEMP/flutter"
printf '%s\n' "$RUNNER_TEMP/flutter/bin" >> "$GITHUB_PATH"
npm install --global pnpm@10.18.3

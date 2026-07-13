#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

cd "$ROOT"
[[ -z "$(git status --porcelain)" ]] \
  || { echo "工作区不干净，拒绝生成源码发布包" >&2; exit 1; }

OUTPUT_DIR="$ROOT/dist/source"
ARCHIVE_NAME="$SOURCE_SLUG-$PROJECT_VERSION.tar.gz"
ARCHIVE="$OUTPUT_DIR/$ARCHIVE_NAME"

mkdir -p "$OUTPUT_DIR"
git archive --format=tar.gz --prefix="$SOURCE_SLUG-$PROJECT_VERSION/" HEAD -o "$ARCHIVE"
(
  cd "$OUTPUT_DIR"
  shasum -a 256 "$ARCHIVE_NAME" > "$ARCHIVE_NAME.sha256"
  shasum -a 256 -c "$ARCHIVE_NAME.sha256"
)

echo "源码包：$ARCHIVE"
echo "校验值：$ARCHIVE.sha256"

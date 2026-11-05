#!/usr/bin/env bash
# 打包 release APK。
#
# 默认按 ABI 拆分：Flutter 的引擎与 AOT 产物是跟 CPU 指令集绑定的机器码，
# 打成一个包会把 arm64 / armeabi-v7a / x86_64 三套都塞进去（约 53MB），
# 而用户实际只会用到其中一套。拆分后单包约 20MB。
#
# 用法：
#   ./scripts/build-apk.sh              # 拆分三套 ABI
#   ./scripts/build-apk.sh --fat        # 回到单包（体积大，仅调试分发用）
set -euo pipefail

cd "$(dirname "$0")/.."

# 生产环境后端地址，按需改这里或外部覆盖。
API_BASE_URL="${API_BASE_URL:-http://111.228.24.165:8080/api}"
IMAGE_BASE_URL="${IMAGE_BASE_URL:-http://111.228.24.165:8080}"

ARGS=(
  build apk --release
  --dart-define=API_BASE_URL="${API_BASE_URL}"
  --dart-define=IMAGE_BASE_URL="${IMAGE_BASE_URL}"
  # 把调试符号抽出来：so 更小，且线上崩溃栈要靠它才能还原。
  --split-debug-info=build/symbols
)

if [[ "${1:-}" == "--fat" ]]; then
  echo ">> 构建单包 APK（包含全部 ABI）"
else
  echo ">> 构建分 ABI 的 APK（arm64 / armv7 / x86_64 各一个）"
  ARGS+=(--split-per-abi)
fi

FLUTTER="${FLUTTER:-flutter}"
"${FLUTTER}" "${ARGS[@]}"

echo
echo ">> 产物："
ls -lh build/app/outputs/flutter-apk/*.apk | awk '{print "   " $9 "  " $5}'
echo ">> 调试符号：build/symbols（请归档，用于还原崩溃栈）"

#!/bin/zsh
set -euo pipefail

# Packages dist/FloatTranslate.app for casual sharing with friends.
#
# It re-signs the app ad-hoc (`codesign -s -`) so it is NOT tied to this Mac's
# local development certificate, then zips it with `ditto` (which preserves the
# bundle layout and code signature). The result runs on another Apple Silicon
# Mac (macOS 15+) after the recipient clears Gatekeeper quarantine — see the
# printed instructions / SHARING.txt.
#
# This is NOT notarized: recipients must explicitly allow it the first time.
# For warning-free distribution to anyone, use a Developer ID + notarization.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/dist/FloatTranslate.app"
STAGE_DIR="$ROOT_DIR/dist/share-staging"
STAGE_APP="$STAGE_DIR/FloatTranslate.app"
ZIP_PATH="$ROOT_DIR/dist/FloatTranslate-share.zip"
NOTES_PATH="$ROOT_DIR/dist/SHARING.txt"

if [[ ! -d "$APP_DIR" ]]; then
    echo "dist/FloatTranslate.app not found. Run scripts/build-app.sh first." >&2
    exit 1
fi

# Work on a copy so the development app keeps its stable local-identity
# signature (re-signing in place would reset your own granted permissions).
echo "Staging a copy…"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
/usr/bin/ditto "$APP_DIR" "$STAGE_APP"

echo "Re-signing ad-hoc (not tied to the local development identity)…"
codesign --force --deep --sign - "$STAGE_APP"
codesign --verify --deep --strict "$STAGE_APP"

echo "Zipping…"
rm -f "$ZIP_PATH"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$STAGE_APP" "$ZIP_PATH"
rm -rf "$STAGE_DIR"

cat > "$NOTES_PATH" <<'NOTES'
FloatTranslate —— 安装与首次使用说明

要求：Apple 芯片（M 系列）的 Mac，macOS 15 或更新版本。

1) 解压 FloatTranslate-share.zip，把 FloatTranslate.app 拖到「应用程序」。

2) 因为这是个人自签、未经 Apple 公证的 App，首次打开会被系统拦。
   最省事的放行方法：打开「终端」，粘贴并回车（会让 App 摆脱隔离标记）：

       xattr -dr com.apple.quarantine /Applications/FloatTranslate.app

   然后正常双击打开即可。
   （或者：双击被拦后，去「系统设置 → 隐私与安全性」，最下方点「仍要打开」。）

3) 首次启动会请求两个权限，请在「系统设置 → 隐私与安全性」里允许：
   · 辅助功能（读取选中的文本）
   · 输入监控（响应全局快捷键）
   授权后建议退出 App 重开一次。

4) 用法：在任意 App 里选中文字，按 ⌥ Space（可在菜单栏图标的「设置」里改快捷键）。
   菜单栏会出现一个对话气泡图标，翻译卡片在光标旁弹出。

5) 当前版本仅支持简体中文与英文双向翻译。

说明：翻译用苹果系统的端上翻译框架，首次翻译某语言可能需要系统下载语言模型；
单词还会附带词典释义。全部在本机进行，不联网、不保存历史。
NOTES

echo ""
echo "Created:"
echo "  $ZIP_PATH"
echo "  $NOTES_PATH  (send this to your friend too)"

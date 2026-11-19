#!/bin/bash
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/libexec:$PATH"

SRC="/Applications/WeChat.app"
DST="/Applications/WeChat2.app"
BUNDLE_ID="com.tencent.xinWeChat2"
CONTAINER="$HOME/Library/Containers/com.tencent.xinWeChat2"

echo "======================================"
echo "  制作微信双开副本（WeChat2.app）"
echo "======================================"
echo
echo "会先退出正在运行的微信，再处理独立副本 WeChat2。"
echo "提示输入密码时，请输入这台 Mac 的登录密码（输入时不会显示）。"
echo

if [ ! -d "$SRC" ]; then
  if [ -d "/Applications/微信.app" ]; then
    SRC="/Applications/微信.app"
  else
    echo "未找到 /Applications/WeChat.app 或 /Applications/微信.app，请先安装官方微信。"
    echo
    read -r -p "按回车关闭窗口..."
    exit 1
  fi
fi

quit_wechat() {
  echo "正在退出微信..."
  osascript -e 'tell application "WeChat" to quit' >/dev/null 2>&1 || true
  osascript -e 'tell application "WeChat2" to quit' >/dev/null 2>&1 || true
  osascript -e 'tell application "微信" to quit' >/dev/null 2>&1 || true

  for i in {1..15}; do
    if ! pgrep -x WeChat >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  echo "微信仍在运行，改为强制退出..."
  killall WeChat >/dev/null 2>&1 || true
  sleep 2

  if pgrep -x WeChat >/dev/null 2>&1; then
    echo "无法退出微信，请先手动按 Command+Q 退出所有微信窗口后再重新双击本脚本。"
    echo
    read -r -p "按回车关闭窗口..."
    exit 1
  fi
}

open_both() {
  echo "正在打开微信和 WeChat2..."
  open -na "$SRC"
  if [ -d "$DST" ]; then
    open -na "$DST"
  fi
  echo
  echo "如果第一次打开 WeChat2 提示未验证开发者，请在访达中对它右键，选择「打开」。"
}

make_copy() {
  echo
  echo "1/4 复制微信到 $DST ..."
  sudo cp -R "$SRC" "$DST" || {
    echo "复制失败。"
    echo
    read -r -p "按回车关闭窗口..."
    exit 1
  }

  echo "2/4 修改 Bundle ID 为 $BUNDLE_ID ..."
  sudo /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$DST/Contents/Info.plist" || {
    echo "修改 Bundle ID 失败。"
    echo
    read -r -p "按回车关闭窗口..."
    exit 1
  }

  echo "3/4 清除隔离属性..."
  sudo xattr -dr com.apple.quarantine "$DST" >/dev/null 2>&1 || true

  echo "4/4 重新签名（可能需要一两分钟，请稍候）..."
  sudo codesign --force --deep --sign - "$DST" || {
    echo "签名失败。"
    echo
    read -r -p "按回车关闭窗口..."
    exit 1
  }

  actual_id="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$DST/Contents/Info.plist" 2>/dev/null || true)"
  if [ "$actual_id" != "$BUNDLE_ID" ]; then
    echo "校验失败：当前 Bundle ID 为「$actual_id」，预期为「$BUNDLE_ID」。"
    echo
    read -r -p "按回车关闭窗口..."
    exit 1
  fi
}

if [ -d "$DST" ]; then
  echo "检测到已经存在：$DST"
  if [ -d "$CONTAINER" ]; then
    echo "同时发现副本的数据目录，重建时只会替换应用程序，不会删除登录信息和聊天记录。"
  else
    echo "尚未发现副本数据目录，重建后需要重新扫码登录。"
  fi
  echo
  echo "请选择："
  echo "  1) 重建副本（覆盖 WeChat2.app，保留聊天记录）"
  echo "  2) 不重建，直接打开现有的微信和 WeChat2"
  echo "  3) 取消"
  echo
  read -r -p "请输入序号 [1/2/3]：" choice
  echo

  case "$choice" in
    1)
      quit_wechat
      echo "正在删除旧的 WeChat2.app（不会删除 Containers 数据目录）..."
      sudo rm -rf "$DST" || {
        echo "删除旧副本失败。请确认 WeChat2 已经完全退出后再试。"
        echo
        read -r -p "按回车关闭窗口..."
        exit 1
      }
      make_copy
      echo
      echo "重建完成。副本数据仍在：$CONTAINER"
      echo "请分别打开「应用程序」里的微信和 WeChat2。"
      read -r -p "是否现在打开这两个应用？[Y/n] " open_now
      case "$open_now" in
        n|N|no|NO) ;;
        *) open_both ;;
      esac
      ;;
    2)
      open_both
      ;;
    *)
      echo "已取消。"
      ;;
  esac
else
  quit_wechat
  make_copy
  echo
  echo "制作完成。"
  if [ -d "$CONTAINER" ]; then
    echo "已有数据目录，打开 WeChat2 后应能沿用之前的登录和聊天记录。"
  else
    echo "请分别打开「应用程序」里的微信和 WeChat2，各自扫码登录。"
  fi
  echo "官方微信更新后，再双击本脚本并选择「重建副本」即可；不要删除 $CONTAINER，聊天记录会保留。"
  echo
  read -r -p "是否现在打开这两个应用？[Y/n] " open_now
  case "$open_now" in
    n|N|no|NO) ;;
    *) open_both ;;
  esac
fi

echo
read -r -p "按回车关闭窗口..."

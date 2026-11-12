#!/usr/bin/env bash
# `npx cap add ios`-dan SONRA işə salınır (Mac / Codemagic üzərində).
# Info.plist icazə mətnləri, push, Firebase, entitlements və AppDelegate-i qurur.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_DIR="ios/App/App"
PLIST="$APP_DIR/Info.plist"
PB=/usr/libexec/PlistBuddy

[ -f "$PLIST" ] || { echo "❌ $PLIST yoxdur. Əvvəlcə: npx cap add ios"; exit 1; }
[ -f "$APP_DIR/GoogleService-Info.plist" ] || { echo "❌ $APP_DIR/GoogleService-Info.plist yoxdur (Firebase Console → iOS app → yüklə)"; exit 1; }

setp () { # key type value
  $PB -c "Delete :$1" "$PLIST" >/dev/null 2>&1 || true
  $PB -c "Add :$1 $2 $3" "$PLIST"
}

echo "▶ Info.plist"
setp CFBundleDisplayName string "BakuGo Kuryer"
setp NSLocationWhenInUseUsageDescription string "Yaxınlıqdakı sifarişləri göstərmək, müştəriyə marşrut qurmaq və çatdırılmanı izləmək üçün yerinizə ehtiyac var."
setp ITSAppUsesNonExemptEncryption bool false
setp FirebaseAppDelegateProxyEnabled bool true
# Yalnız portret
$PB -c "Delete :UISupportedInterfaceOrientations" "$PLIST" >/dev/null 2>&1 || true
$PB -c "Add :UISupportedInterfaceOrientations array" "$PLIST"
$PB -c "Add :UISupportedInterfaceOrientations:0 string UIInterfaceOrientationPortrait" "$PLIST"
$PB -c "Delete :UISupportedInterfaceOrientations~ipad" "$PLIST" >/dev/null 2>&1 || true
# Arxa planda push
$PB -c "Delete :UIBackgroundModes" "$PLIST" >/dev/null 2>&1 || true
$PB -c "Add :UIBackgroundModes array" "$PLIST"
$PB -c "Add :UIBackgroundModes:0 string remote-notification" "$PLIST"

echo "▶ Entitlements (Push)"
cat > "$APP_DIR/App.entitlements" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>production</string>
</dict>
</plist>
XML

echo "▶ AppDelegate.swift (Firebase)"
python3 scripts/patch_appdelegate.py "$APP_DIR/AppDelegate.swift"

echo "▶ Xcode layihəsi (entitlements, GoogleService-Info.plist, iPhone-only, versiya)"
ruby scripts/ios_project.rb

echo "✅ iOS konfiqurasiyası hazırdır"

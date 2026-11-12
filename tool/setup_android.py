#!/usr/bin/env python3
"""يعدّل مجلدي android/ و ios/ المولَّدين بالأمر `flutter create`.

- اسم التطبيق بالعربية
- اتجاه عمودي فقط
- إذن الاهتزاز (أندرويد)
"""
import pathlib
import re

APP_NAME = "ألغاز الفراعنة"
root = pathlib.Path(".")

# ---------------------------------------------------------------- أندرويد
manifest = root / "android/app/src/main/AndroidManifest.xml"
if manifest.exists():
    s = manifest.read_text(encoding="utf-8")
    s = re.sub(r'android:label="[^"]*"', 'android:label="%s"' % APP_NAME, s, count=1)
    if "android.permission.VIBRATE" not in s:
        s = s.replace(
            "<application",
            '<uses-permission android:name="android.permission.VIBRATE"/>\n    <application',
            1,
        )
    if "android:screenOrientation" not in s:
        s = s.replace("<activity", '<activity\n            android:screenOrientation="portrait"', 1)
    s = s.replace('android:allowBackup="true"', 'android:allowBackup="false"')
    manifest.write_text(s, encoding="utf-8")
    print("patched", manifest)
else:
    print("no android manifest, skipped")

# -------------------------------------------------------------------- iOS
plist = root / "ios/Runner/Info.plist"
if plist.exists():
    s = plist.read_text(encoding="utf-8")
    s = re.sub(
        r"(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)",
        lambda m: m.group(1) + APP_NAME + m.group(2),
        s,
        count=1,
    )
    s = re.sub(
        r"(<key>UISupportedInterfaceOrientations</key>\s*<array>)(.*?)(</array>)",
        lambda m: m.group(1) + "\n\t\t<string>UIInterfaceOrientationPortrait</string>\n\t" + m.group(3),
        s,
        count=1,
        flags=re.DOTALL,
    )
    plist.write_text(s, encoding="utf-8")
    print("patched", plist)
else:
    print("no ios plist, skipped")

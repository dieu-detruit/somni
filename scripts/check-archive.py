"""Reject archives without the matching iPhone and embedded Watch application."""
import plistlib
import sys
from pathlib import Path
root = Path(sys.argv[1]) / 'Products/Applications'
apps = list(root.glob('*.app'))
assert len(apps) == 1, f'Expected one iPhone app: {apps}'
def info(path):
    with (path / 'Info.plist').open('rb') as f:
        return plistlib.load(f)
phone = info(apps[0])
assert phone['CFBundleIdentifier'] == 'com.takafumi.somni'
for key in ('NSHealthShareUsageDescription', 'NSHealthUpdateUsageDescription'):
    assert phone.get(key, '').strip(), f'Missing HealthKit purpose string: {key}'
watches = list((apps[0] / 'Watch').glob('*.app'))
assert len(watches) == 1, f'Expected embedded Watch app: {watches}'
watch = info(watches[0])
assert watch['CFBundleIdentifier'] == 'com.takafumi.somni.watchkit'
assert watch['WKCompanionAppBundleIdentifier'] == phone['CFBundleIdentifier']
assert watch['CFBundleVersion'] == phone['CFBundleVersion']
assert watch['CFBundleShortVersionString'] == phone['CFBundleShortVersionString']
print('Verified iPhone + Watch bundle IDs, companion relationship and versions.')

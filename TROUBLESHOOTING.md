# Troubleshooting

## DerivedData / Info.plist Build Error

**Symptom:** Xcode reports it cannot write to DerivedData, or you see a
build error referencing `info.plist` inside the DerivedData directory.

**Cause:** This is a file-permissions issue on your Mac — not a missing
plist entry. macOS or Xcode left the DerivedData folder owned by `root`
instead of your user account.

### Quick Fix

Run the included script from the project root:

```bash
./scripts/fix-deriveddata.sh
```

The script will:
1. Delete the project-specific DerivedData cache
2. Fix folder ownership if it belongs to `root`

Then in Xcode: **Product > Clean Build Folder** (`Shift+Cmd+K`) and build
again.

### Manual Fix

If you prefer to do it by hand:

```bash
# 1. Remove the stale DerivedData cache
sudo rm -rf ~/Library/Developer/Xcode/DerivedData/Visual_Snow_Solace-*

# 2. Clean build in Xcode (Shift+Cmd+K), then build again (Cmd+B)
```

If the error keeps coming back, check who owns the DerivedData folder:

```bash
ls -la ~/Library/Developer/Xcode/DerivedData/
```

If it shows `root` instead of your username, fix it:

```bash
sudo chown -R $(whoami) ~/Library/Developer/Xcode/DerivedData/
```

---

## Camera Permission Crash

**Symptom:** The app crashes when opening Lens Mode on a physical device.

**Cause:** The `NSCameraUsageDescription` key must be present in the
build settings.

**Status:** This was added in Phase 2. The key is set in both Debug and
Release configurations inside `project.pbxproj`:

```
INFOPLIST_KEY_NSCameraUsageDescription = "Lens Mode uses the camera to show a live preview with colour-tint overlays that may help reduce visual discomfort.";
```

If you still experience a crash:

1. Open the project in Xcode
2. Select the **Visual Snow Solace** target
3. Go to **Build Settings** > search for "privacy"
4. Confirm **Privacy - Camera Usage Description** has a value
5. If empty, add the description above
6. Clean Build Folder (`Shift+Cmd+K`) and rebuild

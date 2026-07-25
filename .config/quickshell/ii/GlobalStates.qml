import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property bool barOpen: true
    property bool osdBrightnessOpen: false
    property bool osdVolumeOpen: false
    property bool overviewOpen: false
    property bool regionSelectorOpen: false
    property bool searchOpen: false
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool sessionOpen: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property bool workspaceShowNumbers: false

    property bool showBluetoothDialog: false
    property bool showWifiDialog: false
    property bool showAudioOutputDialog: false
    property bool showAudioInputDialog: false

    readonly property bool anyDialogOpen: showBluetoothDialog || showWifiDialog || showAudioOutputDialog || showAudioInputDialog

    function closeAllDialogs() {
        showBluetoothDialog = false
        showWifiDialog = false
        showAudioOutputDialog = false
        showAudioInputDialog = false
    }

    GlobalShortcut {
        name: "workspaceNumber"
        description: "Hold to show workspace numbers, release to show icons"

        onPressed: {
            root.superDown = true
        }
        onReleased: {
            root.superDown = false
        }
    }
}
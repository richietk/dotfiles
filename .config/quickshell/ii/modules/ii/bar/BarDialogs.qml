import qs
import qs.services
import qs.modules.common
import qs.modules.ii.sidebarRight.bluetoothDevices
import qs.modules.ii.sidebarRight.volumeMixer
import qs.modules.ii.sidebarRight.wifiNetworks
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth

Scope {
    PanelWindow {
        id: dialogWindow

        visible: GlobalStates.anyDialogOpen
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "quickshell:dialogs"
        WlrLayershell.keyboardFocus: GlobalStates.anyDialogOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        onVisibleChanged: {
            if (visible) GlobalFocusGrab.addDismissable(dialogWindow)
            else GlobalFocusGrab.removeDismissable(dialogWindow)
        }
        Connections {
            target: GlobalFocusGrab
            function onDismissed() { GlobalStates.closeAllDialogs() }
        }

        Loader {
            id: btLoader
            anchors.fill: parent
            active: GlobalStates.showBluetoothDialog
            onActiveChanged: if (active) { item.show = true; item.forceActiveFocus(); Bluetooth.defaultAdapter.enabled = true; Bluetooth.defaultAdapter.discovering = true }
            sourceComponent: BluetoothDialog {}
            Connections {
                target: btLoader.item
                function onDismiss() { btLoader.item.show = false; GlobalStates.showBluetoothDialog = false; Bluetooth.defaultAdapter.discovering = false }
                function onVisibleChanged() { if (!btLoader.item?.visible && !GlobalStates.showBluetoothDialog) btLoader.active = false }
            }
        }

        Loader {
            id: wifiLoader
            anchors.fill: parent
            active: GlobalStates.showWifiDialog
            onActiveChanged: if (active) { item.show = true; item.forceActiveFocus(); Network.enableWifi(); Network.rescanWifi() }
            sourceComponent: WifiDialog {}
            Connections {
                target: wifiLoader.item
                function onDismiss() { wifiLoader.item.show = false; GlobalStates.showWifiDialog = false }
                function onVisibleChanged() { if (!wifiLoader.item?.visible && !GlobalStates.showWifiDialog) wifiLoader.active = false }
            }
        }

        Loader {
            id: audioOutLoader
            anchors.fill: parent
            active: GlobalStates.showAudioOutputDialog
            onActiveChanged: if (active) { item.show = true; item.forceActiveFocus() }
            sourceComponent: VolumeDialog { isSink: true }
            Connections {
                target: audioOutLoader.item
                function onDismiss() { audioOutLoader.item.show = false; GlobalStates.showAudioOutputDialog = false }
                function onVisibleChanged() { if (!audioOutLoader.item?.visible && !GlobalStates.showAudioOutputDialog) audioOutLoader.active = false }
            }
        }

        Loader {
            id: audioInLoader
            anchors.fill: parent
            active: GlobalStates.showAudioInputDialog
            onActiveChanged: if (active) { item.show = true; item.forceActiveFocus() }
            sourceComponent: VolumeDialog { isSink: false }
            Connections {
                target: audioInLoader.item
                function onDismiss() { audioInLoader.item.show = false; GlobalStates.showAudioInputDialog = false }
                function onVisibleChanged() { if (!audioInLoader.item?.visible && !GlobalStates.showAudioInputDialog) audioInLoader.active = false }
            }
        }

    }
}

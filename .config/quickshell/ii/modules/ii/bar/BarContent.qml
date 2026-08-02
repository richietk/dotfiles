import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item { // Bar content region
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0
    readonly property int centerSideModuleWidth: (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : Appearance.sizes.barCenterSideModuleWidth

    component VerticalBarSeparator: Rectangle {
        Layout.topMargin: Appearance.sizes.baseBarHeight / 3
        Layout.bottomMargin: Appearance.sizes.baseBarHeight / 3
        Layout.fillHeight: true
        implicitWidth: 1
        color: Appearance.colors.colOutlineVariant
    }

    // Background shadow
    Loader {
        active: Config.options.bar.showBackground && Config.options.bar.cornerStyle === 1 && Config.options.bar.floatStyleShadow
        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined // The loader's anchors act on this, and this should not have any anchor
            target: barBackground
        }
    }
    // Background
    Rectangle {
        id: barBackground
        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? (Appearance.sizes.hyprlandGapsOut) : 0 // idk why but +1 is needed
        }
        color: Config.options.bar.showBackground ? Appearance.colors.colLayer0 : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    FocusedScrollMouseArea { // Left side | scroll to change brightness
        id: barLeftSideMouseArea

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: middleSection.left
        }
        implicitWidth: leftSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight

        onScrollDown: Brightness.decreaseBrightness()
        onScrollUp: Brightness.increaseBrightness()
        onMovedAway: GlobalStates.osdBrightnessOpen = false

        // Visual content
        ScrollHint {
            reveal: barLeftSideMouseArea.hovered
            icon: Hyprsunset.gamma === 100 ? "light_mode" : "wb_twilight"
            tooltipText: Translation.tr("Scroll to change brightness")
            side: "left"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        RowLayout {
            id: leftSectionRowLayout
            anchors.fill: parent
            spacing: 0

            Item { Layout.fillWidth: true }
            Resources {
                alwaysShowAllResources: root.useShortenedForm === 2
                Layout.fillWidth: root.useShortenedForm === 2
            }
            Item { Layout.fillWidth: true }
        }
    }

    Row { // Middle section
        id: middleSection
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            horizontalCenterOffset: 0
        }
        spacing: 4

        BarGroup {
            id: middleCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            padding: workspacesWidget.widgetPadding

            Workspaces {
                id: workspacesWidget
                Layout.fillHeight: true
                MouseArea {
                    // Right-click to toggle overview
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton

                    onPressed: event => {
                        if (event.button === Qt.RightButton) {
                            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                        }
                    }
                }
            }
        }

        VerticalBarSeparator {
            visible: Config.options?.bar.borderless
        }

        MouseArea {
            id: rightCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: root.centerSideModuleWidth / 1.5
            implicitHeight: rightCenterGroupContent.implicitHeight

            BarGroup {
                id: rightCenterGroupContent
                anchors.fill: parent

                ClockWidget {
                    showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                }

                UtilButtons {
                    visible: (Config.options.bar.verbose && root.useShortenedForm === 0)
                    Layout.alignment: Qt.AlignVCenter
                }

                BatteryIndicator {
                    visible: (root.useShortenedForm < 2 && Battery.available)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }

    FocusedScrollMouseArea { // Right side | scroll to change volume
        id: barRightSideMouseArea

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: middleSection.right
            right: parent.right
        }
        implicitWidth: rightSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight

        onScrollDown: Audio.decrementVolume()
        onScrollUp: Audio.incrementVolume()
        onMovedAway: GlobalStates.osdVolumeOpen = false

        ScrollHint {
            reveal: barRightSideMouseArea.hovered
            icon: "volume_up"
            tooltipText: Translation.tr("Scroll to change volume")
            side: "right"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }

        RowLayout {
            id: rightSectionRowLayout
            anchors.fill: parent
            spacing: 5
            layoutDirection: Qt.RightToLeft

            // Session
            BarIconButton {
                buttonIcon: "power_settings_new"
                Layout.rightMargin: Appearance.rounding.screenRounding
                onClicked: GlobalStates.sessionOpen = true
            }

            VerticalBarSeparator { Layout.leftMargin: 3; Layout.rightMargin: 3 }

            // Keep awake
            BarIconButton {
                buttonIcon: "coffee"
                toggled: Idle.inhibit
                onClicked: Idle.toggleInhibit()
            }

            // Notifications
            BarIconButton {
                buttonIcon: Notifications.silent ? "notifications_paused" : "notifications_active"
                toggled: !Notifications.silent
                onClicked: Notifications.silent = !Notifications.silent
            }

            VerticalBarSeparator { Layout.leftMargin: 3; Layout.rightMargin: 3 }

            // Mic
            BarIconButton {
                buttonIcon: Audio.source?.audio?.muted ? "mic_off" : "mic"
                toggled: !(Audio.source?.audio?.muted ?? false)
                onClicked: Audio.toggleMicMute()
                altAction: () => GlobalStates.showAudioInputDialog = true
            }

            // Volume
            BarIconButton {
                buttonIcon: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                toggled: !(Audio.sink?.audio?.muted ?? false)
                onClicked: Audio.toggleMute()
                altAction: () => GlobalStates.showAudioOutputDialog = true
            }

            VerticalBarSeparator { Layout.leftMargin: 3; Layout.rightMargin: 3 }

            // Bluetooth
            BarIconButton {
                visible: BluetoothStatus.available
                buttonIcon: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                toggled: BluetoothStatus.enabled
                onClicked: Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter?.enabled
                altAction: () => GlobalStates.showBluetoothDialog = true
            }

            // Network
            BarIconButton {
                buttonIcon: Network.materialSymbol
                toggled: Network.wifiStatus !== "disabled"
                onClicked: Network.toggleWifi()
                altAction: () => GlobalStates.showWifiDialog = true
            }

            // Notification count
            Revealer {
                reveal: Notifications.silent || Notifications.unread > 0
                Layout.fillHeight: true
                Layout.leftMargin: 4
                Layout.rightMargin: 2
                NotificationUnreadCount {}
            }

            SysTray {
                visible: root.useShortenedForm === 0
                Layout.fillWidth: false
                Layout.fillHeight: true
                invertSide: Config?.options.bar.bottom
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    component BarIconButton: RippleButton {
        id: barBtn
        required property string buttonIcon

        implicitWidth: 36
        implicitHeight: 30
        buttonRadius: Appearance.rounding.small
        colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
        colBackgroundHover: Appearance.colors.colLayer1Hover
        colRipple: Appearance.colors.colLayer1Active
        colBackgroundToggled: Appearance.colors.colSecondaryContainer
        colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
        colRippleToggled: Appearance.colors.colSecondaryContainerActive

        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            text: barBtn.buttonIcon
            iconSize: Appearance.font.pixelSize.larger
            fill: barBtn.toggled ? 1 : 0
            color: barBtn.toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0
            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
}

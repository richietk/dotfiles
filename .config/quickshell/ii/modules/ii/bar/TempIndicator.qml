import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool warning: ResourceUsage.moboTemp >= 85
    implicitWidth: row.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 2

        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            text: "device_thermostat"
            iconSize: Appearance.font.pixelSize.normal
            font.weight: Font.DemiBold
            fill: 1
            color: root.warning ? Appearance.colors.colError : Appearance.m3colors.m3onSecondaryContainer
        }

        Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: tempTextMetrics.width
            implicitHeight: tempText.implicitHeight

            TextMetrics {
                id: tempTextMetrics
                text: "99"
                font.pixelSize: Appearance.font.pixelSize.small
            }

            StyledText {
                id: tempText
                anchors.centerIn: parent
                color: root.warning ? Appearance.colors.colError : Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                text: ResourceUsage.moboTemp.toString()
            }
        }
    }
}

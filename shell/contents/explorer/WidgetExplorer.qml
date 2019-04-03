/*
 *   Copyright 2011 Marco Martin <mart@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.2
import QtGraphicalEffects 1.0
import QtQuick.Controls 1.1

import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kquickcontrolsaddons 2.0
import org.kde.kirigami 2.2 as Kirigami

import QtQuick.Window 2.1
import QtQuick.Layouts 1.1

import org.kde.plasma.private.shell 2.0

Item {
    id: root
    signal closed()
    property alias containment: widgetExplorer.containment

    Component.onCompleted: splitDrawer.contentX = typeSelector.width

    property int topPadding
    property int bottomPadding

    MouseArea {
        anchors.fill: parent
        drag.filterChildren: true
        drag.target: splitDrawer.open ? null : main
        drag.axis: Drag.XAxis
        drag.maximumX: 0
        onReleased: {
            if (main.x < -main.width/3) {
                removeAnim.running = true;
            } else {
                openAnim.running = true;
            }
        }
        onClicked: {
            if (mouse.x > main.width) {
                removeAnim.running = true;
            }
        }

        NumberAnimation {
            id: openAnim
            running: true
            target: main
            properties: "x"
            duration: units.longDuration
            easing.type: Easing.InOutQuad
            to: 0
        }
        SequentialAnimation {
            id: removeAnim
            NumberAnimation {
                target: main
                properties: "x"
                duration: units.longDuration
                easing.type: Easing.InOutQuad
                to: -main.width
            }
            ScriptAction {
                script: root.closed();
            }
        }
        Rectangle {
            id: main

            x: -width
            width: units.gridUnit * 10
            height: parent.height
            color: theme.backgroundColor

            //external drop events can cause a raise event causing us to lose focus and
            //therefore get deleted whilst we are still in a drag exec()
            //this is a clue to the owning dialog that hideOnWindowDeactivate should be deleted
            //See https://bugs.kde.org/show_bug.cgi?id=332733
            property bool preventWindowHide: false

            property Item getWidgetsButton
            property Item categoryButton


            function addCurrentApplet() {
                var pluginName = list.currentItem ? list.currentItem.pluginName : ""
                if (pluginName) {
                    widgetExplorer.addApplet(pluginName)
                }
            }

            LinearGradient {
                width: units.gridUnit/2
                anchors {
                    left: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    rightMargin: -1
                }
                start: Qt.point(0, 0)
                end: Qt.point(units.gridUnit/2, 0)
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(0, 0, 0, 0.3)
                    }
                    GradientStop {
                        position: 0.3
                        color: Qt.rgba(0, 0, 0, 0.15)
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
            }
            
            WidgetExplorer {
                id: widgetExplorer
                //view: desktop
                onShouldClose: removeAnim.running = true;
            }
            Flickable {
                id: splitDrawer
                visible: true
                anchors.fill: parent
                clip: true
                contentWidth: mainRow.width
                contentHeight: height
                Row {
                    id: mainRow
                    height: splitDrawer.height
                    PlasmaExtras.ScrollArea {
                        id: typeSelector
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: units.gridUnit * 10
                        ListView {
                            model: widgetExplorer.filterModel
                            delegate: PlasmaComponents.ListItem {
                                enabled: true
                                visible: !model.separator
                                height: model.separator ? 0 : implicitHeight
                                PlasmaComponents.Label {
                                    text: model.display
                                }
                                onClicked: {
                                    list.contentX = 0
                                    list.contentY = 0
                                    heading.text = model.display
                                    widgetExplorer.widgetsModel.filterQuery = model.filterData
                                    widgetExplorer.widgetsModel.filterType = model.filterType
                                }
                            }
                        }
                    }
                    
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            topMargin: root.topPadding
                            bottomMargin: root.bottomPadding
                        }
                        width: splitDrawer.width

                        spacing: units.smallSpacing

                        PlasmaExtras.Title {
                            id: heading
                            text: i18nd("plasma_shell_org.kde.plasma.desktop", "Widgets")
                            Layout.fillWidth: true

                            PlasmaComponents.ToolButton {
                                id: closeButton
                                anchors {
                                    right: parent.right
                                    verticalCenter: heading.verticalCenter
                                }
                                iconSource: "window-close"
                                onClicked: removeAnim.running = true;
                            }
                        }
/*FIXME: avoid text inputs in mycroft?
                        PlasmaComponents.TextField {
                            id: searchInput
                            clearButtonShown: true
                            placeholderText: i18nd("plasma_shell_org.kde.plasma.desktop", "Search...")
                            onTextChanged: {
                                list.positionViewAtBeginning()
                                list.currentIndex = -1
                                widgetExplorer.widgetsModel.searchTerm = text
                            }

                            Component.onCompleted: forceActiveFocus()
                            Layout.fillWidth: true
                        }*/


                        PlasmaExtras.ScrollArea {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            GridView {
                                id: list

                                model: widgetExplorer.widgetsModel
                                activeFocusOnTab: true
                                currentIndex: -1
                                keyNavigationWraps: true
                                cellWidth: units.iconSizes.enormous + units.smallSpacing * 2
                                cellHeight: cellWidth + units.gridUnit * 4 + units.smallSpacing * 2


                                delegate: AppletDelegate {}

                                //slide in to view from the left
                                add: Transition {
                                    NumberAnimation {
                                        properties: "x"
                                        from: -list.width
                                        to: 0
                                        duration: units.shortDuration * 3

                                    }
                                }

                                //slide out of view to the right
                                remove: Transition {
                                    NumberAnimation {
                                        properties: "x"
                                        to: list.width
                                        duration: units.shortDuration * 3
                                    }
                                }

                                //if we are adding other items into the view use the same animation as normal adding
                                //this makes everything slide in together
                                //if we make it move everything ends up weird
                                addDisplaced: list.add

                                //moved due to filtering
                                displaced: Transition {
                                    NumberAnimation {
                                        properties: "y"
                                        duration: units.shortDuration * 3
                                    }
                                }
                            }
                        }

                        Column {
                            id: bottomBar
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                leftMargin: units.smallSpacing
                                rightMargin: units.smallSpacing
                                bottomMargin: units.smallSpacing
                            }

                            spacing: units.smallSpacing

                            Repeater {
                                model: widgetExplorer.extraActions.length
                                PlasmaComponents.Button {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                    }
                                    iconSource: widgetExplorer.extraActions[modelData].icon
                                    text: widgetExplorer.extraActions[modelData].text
                                    onClicked: {
                                        widgetExplorer.extraActions[modelData].trigger()
                                    }
                                }
                            }
                        }

                    }
                }
            }
            Component.onCompleted: {
                main.getWidgetsButton = getWidgetsButton
                main.categoryButton = categoryButton
            }
        }
    }
}

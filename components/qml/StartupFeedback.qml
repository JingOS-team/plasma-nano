/*
 *   Copyright 2015 Marco Martin <notmart@gmail.com>
 *   Copyright (C) 2021 Dexiang Meng <dexiang.meng@jingos.com>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.12
import QtQuick.Layouts 1.1
import QtQuick.Window 2.2
import org.kde.plasma.core 2.0 as PlasmaCore
import QtGraphicalEffects 1.12

import org.kde.kirigami 2.13 as Kirigami

import org.kde.plasma.private.nanoshell 2.0 as NanoShell

import jingos.display 1.0

pragma Singleton

NanoShell.SplashWindow {
    id: window

    property alias backgroundColor: background.color
    Kirigami.ImageColors {
        id: colorGenerator
    }

    function open(splashIcon, title, x, y, sourceIconSize, color) {
        console.log(" ------ splashIcon : ",splashIcon )
        console.log(" ------ title : ",title )
        console.log(" ------ x : ",x )
        console.log(" ------ y : ",y )
        console.log(" ------ sourceIconSize : ",sourceIconSize )
        console.log(" ------ color : ",color )
        console.log(" ------ before background.state : ",background.state )

        window.showFullScreen();
        iconParent.scale = sourceIconSize/iconParent.width;
        background.scale = 0;
        backgroundParent.x = -window.width/2 + x
        backgroundParent.y = -window.height/2 + y
        window.title = title + " JSplash";
        icon.source = splashIcon;
        colorGenerator.source = splashIcon;

        if (color !== undefined) {
            // Break binding to use custom color
            background.color = color
        } else {
            // Recreate binding
            background.color = Qt.binding(function() { return colorGenerator.dominant})
        }

        background.state = "open";
        
        console.log(" ------ after background.state : ",background.state )
        console.log(" ------ window.visible : ", window.visible )

    }

    property alias state: background.state
    property alias icon: icon.source

    Timer {
        id: closeTimer
        interval: 180
        running: false
        repeat: false
        onTriggered: background.state = "closed"
    }

    width: Screen.width
    height: Screen.height
    color: "transparent"
    onVisibleChanged: {
        if (!visible) {
            closeTimer.start()
        }
    }
    onActiveChanged: {
        if (!active) {
            closeTimer.start()
        }
    }

    Item {
        id: backgroundParent
        width: window.width
        height: window.height

        Item {
            id: iconParent
            z: 2
            anchors.centerIn: background
            width: units.iconSizes.enormous
            height: width
            PlasmaCore.IconItem {
                id: icon
                anchors.fill:parent
                colorGroup: PlasmaCore.Theme.ComplementaryColorGroup
            }
            DropShadow {
                anchors.fill: icon
                horizontalOffset: JDisplay.dp(0)
                verticalOffset: JDisplay.dp(0)
                radius: JDisplay.dp(8.0)
                samples: 17
                color: "#80000000"
                source: icon
            }
        }

        Rectangle {
            id: background
            anchors.fill: parent

            color: colorGenerator.dominant

            state: "closed"

            states: [
                State {
                    name: "closed"
                    PropertyChanges {
                        target: window
                        visible: false
                    }
                    PropertyChanges {
                        target: window
                        opacity: 0
                    }
                },
                State {
                    name: "open"

                    PropertyChanges {
                        target: window
                        visible: true
                    }
                }
            ]

            transitions: [
                Transition {
                    from: "closed"
                    SequentialAnimation {
                        ScriptAction {
                            script: { 
                                window.showMaximized();
                            }
                        }
                        ParallelAnimation {
                            ScaleAnimator {
                                target: background
                                from: background.scale
                                to: 1
                                duration: units.longDuration
                                easing.type: Easing.InOutQuad
                            }
                            ScaleAnimator {
                                target: iconParent
                                from: iconParent.scale
                                to: 1
                                duration: units.longDuration
                                easing.type: Easing.InOutQuad
                            }
                            XAnimator {
                                target: backgroundParent
                                from: backgroundParent.x
                                to: JDisplay.dp(0)
                                duration: units.longDuration
                                easing.type: Easing.InOutQuad
                            }
                            YAnimator {
                                target: backgroundParent
                                from: backgroundParent.y
                                to: JDisplay.dp(0)
                                duration: units.longDuration
                                easing.type: Easing.InOutQuad
                            }
                        }
                        OpacityAnimator {
                            target: fill
                            from: 0
                            to: 1
                            duration: units.shortDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            ]
        }
    }
}

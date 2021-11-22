/*
 *  Copyright 2013 Marco Martin <mart@kde.org>
 *  Copyright (C) 2021 Dexiang Meng <dexiang.meng@jingos.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import jingos.display 1.0

Item {
    id: main

    Layout.minimumWidth: {
        switch (plasmoid.formFactor) {
        case PlasmaCore.Types.Vertical:
            return JDisplay.dp(0);
        case PlasmaCore.Types.Horizontal:
            return height;
        default:
            return units.gridUnit * 3;
        }
    }

    Layout.minimumHeight: {
        switch (plasmoid.formFactor) {
        case PlasmaCore.Types.Vertical:
            return width;
        case PlasmaCore.Types.Horizontal:
            return JDisplay.dp(0);
        default:
            return units.gridUnit * 3;
        }
    }

    PlasmaCore.IconItem {
        id: icon
        source: plasmoid.icon ? plasmoid.icon : "plasma"
        active: mouseArea.containsMouse
        colorGroup: PlasmaCore.Theme.ComplementaryColorGroup
        anchors.verticalCenter: parent.verticalCenter
    }

    MouseArea {
        id: mouseArea

        property bool wasExpanded: false

        anchors.fill: parent
        hoverEnabled: true
        onPressed: wasExpanded = plasmoid.expanded
        onClicked: plasmoid.expanded = !wasExpanded
    }
}

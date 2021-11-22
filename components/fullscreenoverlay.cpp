/***************************************************************************
 *   Copyright 2015 Marco Martin <mart@kde.org>                            *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU Library General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU Library General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU Library General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

#include "fullscreenoverlay.h"

#include <QStandardPaths>

#include <QDebug>
#include <QGuiApplication>
#include <QScreen>
#include <QPainterPath>
#include <QPolygon>

#include <kwindowsystem.h>

#include <KWayland/Client/connection_thread.h>
#include <KWayland/Client/plasmashell.h>
#include <KWayland/Client/registry.h>
#include <KWayland/Client/surface.h>
#include <KWayland/Client/blur.h>
#include <KWayland/Client/region.h>
#include <KWayland/Client/compositor.h>

FullScreenOverlay::FullScreenOverlay(QQuickWindow *parent)
    : QQuickWindow(parent)
{
    setFlags(Qt::FramelessWindowHint);
    setWindowState(Qt::WindowFullScreen);
   // connect(this, &FullScreenOverlay::activeFocusItemChanged, this, [this]() {qWarning()<<"hide()";});
    initWayland();
    setWindowStates(Qt::WindowFullScreen);
}

FullScreenOverlay::~FullScreenOverlay()
{
}

void FullScreenOverlay::setBlur(QRect rect, double xRadius, double yRadius)
{
    if (!m_surface) {
       setUpSurface();
    }

    if(qEnvironmentVariableIsSet("QT_SCALE_FACTOR")){
        qreal scale = qgetenv("QT_SCALE_FACTOR").toFloat();
        rect = QRect(rect.x() * scale, rect.y() * scale, rect.width() * scale, rect.height() * scale);
    }

    if (m_blur && m_compositor) {
        QPainterPath path;
        path.addRoundedRect(QRectF(rect),xRadius, yRadius, Qt::AbsoluteSize);
        QPolygon polygon= path.toFillPolygon().toPolygon();
        m_blur->setRegion(m_compositor->createRegion(QRegion(polygon), nullptr));
        m_blur->commit();
    }
    update();
}

bool FullScreenOverlay::setWindowType(int type)
{
    if (m_plasmaShellSurface) {
        qDebug() << Q_FUNC_INFO << __LINE__ << "window type:" << type;
        m_plasmaShellSurface->setWindowType((KWayland::Client::PlasmaShellSurface::WindowType)type);
        return true;
    }
    qWarning() << Q_FUNC_INFO << __LINE__  << "window type:" << type;
    return false;
}

void FullScreenOverlay::setUpSurface()
{
    if (m_surface) {
        // already setup
        return;
    }

    using namespace KWayland::Client;

    m_surface = Surface::fromWindow(this);
    if (!m_surface) {
        return;
    }

    m_plasmaShellSurface = m_plasmaShellInterface->createSurface(m_surface, this);
    m_plasmaShellSurface->setWindowType(PlasmaShellSurface::WindowType::TYPE_STATUS_BAR_PANEL);

    if (m_waylandBlurManager) {
        m_blur = m_waylandBlurManager->createBlur(m_surface);
    }
}

void FullScreenOverlay::initWayland()
{
    if (!QGuiApplication::platformName().startsWith(QLatin1String("wayland"), Qt::CaseInsensitive)) {
        return;
    }
    using namespace KWayland::Client;
    ConnectionThread *connection = ConnectionThread::fromApplication(this);
    if (!connection) {
        return;
    }
    m_registry = new Registry(this);
    m_registry->create(connection);

    m_surface = Surface::fromWindow(this);
    if (!m_surface) {
        return;
    }
    connect(m_registry, &Registry::plasmaShellAnnounced, this,
        [this] (quint32 name, quint32 version) {

            m_plasmaShellInterface = m_registry->createPlasmaShell(name, version, this);

            m_plasmaShellSurface = m_plasmaShellInterface->createSurface(m_surface, this);
            m_plasmaShellSurface->setSkipTaskbar(true);
            m_plasmaShellSurface->setWindowType(PlasmaShellSurface::WindowType::TYPE_STATUS_BAR_PANEL);
        }
    );

    connect(m_registry, &Registry::blurAnnounced, this,
        [this] (quint32 name, quint32 version) {
            m_waylandBlurManager = m_registry->createBlurManager(name, version, this);

            connect(m_waylandBlurManager, &KWayland::Client::BlurManager::removed, this, [this]() {
                m_waylandBlurManager->deleteLater();
                m_blur->deleteLater();
            });

            if (m_waylandBlurManager) {
                m_blur = m_waylandBlurManager->createBlur(m_surface);
            }
        }
    );

    connect(m_registry, &Registry::compositorAnnounced, this,
        [this](quint32 name, quint32 version) {
            m_compositor = m_registry->createCompositor(name, version, this);
        }
    );

    m_registry->setup();
    connection->roundtrip();
    //HACK: why the first time is shown fullscreen won't work?
    showFullScreen();
    hide();
}

bool FullScreenOverlay::event(QEvent *e)
{
    if (e->type() == QEvent::FocusIn || e->type() == QEvent::FocusOut) {
        emit activeChanged();
    } else if (e->type() == QEvent::PlatformSurface) {
        QPlatformSurfaceEvent *pe = static_cast<QPlatformSurfaceEvent*>(e);

        if (pe->surfaceEventType() == QPlatformSurfaceEvent::SurfaceCreated) {
            //KWindowSystem::setState(winId(), NET::SkipTaskbar | NET::SkipPager | NET::FullScreen);
           // setWindowStates(Qt::WindowFullScreen);
            if (m_plasmaShellSurface) {
                m_plasmaShellSurface->setSkipTaskbar(true);
            }

            if (!m_acceptsFocus) {
                setFlags(flags() | Qt::FramelessWindowHint|Qt::WindowDoesNotAcceptFocus);
                //KWindowSystem::setType(winId(), NET::Dock);
            } else {
                setFlags(flags() | Qt::FramelessWindowHint);
            }
        }
    } else if (e->type() == QEvent::Show) {
        if (m_plasmaShellSurface) {
            m_plasmaShellSurface->setSkipTaskbar(true);
        }
    } else if (e->type() == QEvent::Hide) {
        m_surface = nullptr;
    }

    return QQuickWindow::event(e);
}

#include "fullscreenoverlay.moc"

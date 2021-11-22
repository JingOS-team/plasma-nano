/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Wang Zhe <wangzhe@jingos.com>
 *
 */

#include "splashwindow.h"

#include <KWayland/Client/connection_thread.h>
#include <KWayland/Client/plasmashell.h>
#include <KWayland/Client/registry.h>
#include <KWayland/Client/surface.h>
#include <kwindowsystem.h>

#include <QGuiApplication>
#include <QDebug>

SplashWindow::SplashWindow(QQuickWindow *parent)
    : QQuickWindow(parent)
{
    setFlags(Qt::FramelessWindowHint | Qt::WindowDoesNotAcceptFocus);

    initWayland();
}

SplashWindow::~SplashWindow()
{
}

void SplashWindow::initWayland()
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
            m_plasmaShellSurface->setWindowType(PlasmaShellSurface::WindowType::TYPE_SYS_SPLASH);
        }
    );

    m_registry->setup();
    connection->roundtrip();
}

bool SplashWindow::event(QEvent *e)
{
    using namespace KWayland::Client;
    if (e->type() == QEvent::FocusIn || e->type() == QEvent::FocusOut) {
        emit activeChanged();
    } else if (e->type() == QEvent::PlatformSurface) {
        QPlatformSurfaceEvent *pe = static_cast<QPlatformSurfaceEvent*>(e);

        if (pe->surfaceEventType() == QPlatformSurfaceEvent::SurfaceCreated) {
            if (m_plasmaShellSurface) {
                m_plasmaShellSurface->setSkipTaskbar(true);
            }

            setFlags(flags() | Qt::FramelessWindowHint | Qt::WindowDoesNotAcceptFocus);
        }
    } else if (e->type() == QEvent::Expose) {
        if (m_plasmaShellSurface) {
            m_plasmaShellSurface->setSkipTaskbar(true);
        }

	m_surface = Surface::fromWindow(this);
	if (m_surface && m_plasmaShellInterface) {
            m_plasmaShellSurface = m_plasmaShellInterface->createSurface(m_surface, this);
	    m_plasmaShellSurface->setWindowType(PlasmaShellSurface::WindowType::TYPE_SYS_SPLASH);	
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

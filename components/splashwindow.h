/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Wang Zhe <wangzhe@jingos.com>
 *
 */

#ifndef SPLASHWINDOW_H
#define SPLASHWINDOW_H

#include <QQuickWindow>

namespace KWayland
{
namespace Client
{
class PlasmaWindow;
class PlasmaShell;
class PlasmaShellSurface;
class Surface;
class Registry;
}
}

class SplashWindow : public QQuickWindow
{
    Q_OBJECT
    Q_PROPERTY(bool active READ isActive NOTIFY activeChanged)

public:
    explicit SplashWindow(QQuickWindow *parent = 0);
    ~SplashWindow();

Q_SIGNALS:
    void activeChanged();

protected:
    bool event(QEvent *event) override;

private:
    void initWayland();

    KWayland::Client::PlasmaShellSurface *m_plasmaShellSurface = nullptr;
    KWayland::Client::Surface *m_surface = nullptr;
    KWayland::Client::PlasmaShell *m_plasmaShellInterface = nullptr;
    KWayland::Client::Registry *m_registry = nullptr;
};

#endif
